# Dockerfile Build Speed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce both cold and incremental Docker build times by pinning tool versions, removing unnecessary apt upgrade, parallelising binary downloads, and merging small config layers.

**Architecture:** Single Dockerfile — no structural split, no registry. All changes are in-place edits that preserve the existing layer order (apt → binaries → Node → Go → COPY → test). Parallelism is achieved via shell background jobs inside a single `RUN`.

**Tech Stack:** Docker BuildKit, bash background jobs (`&` / `wait`), GitHub Releases

---

### Task 1: Pin tool versions as ARGs

**Files:**
- Modify: `Dockerfile`

- [ ] **Step 1: Add ARG declarations after the FROM line**

Open [Dockerfile](Dockerfile). After line 1 (`# syntax=docker/dockerfile:1`) and line 2 (`FROM ubuntu:24.04`), insert the following block (before the first `ENV`):

```dockerfile
ARG DELTA_VER=0.19.2
ARG DUST_VER=v1.2.4
ARG PROCS_VER=v0.14.11
ARG DIRENV_VER=v2.37.1
ARG FASTFETCH_VER=2.61.0
ARG GO_VER=go1.26.2
```

- [ ] **Step 2: Replace the delta download step to use the ARG**

Find the `# git-delta` RUN block (currently lines 48–52). Replace it with:

```dockerfile
# git-delta (git pager)
RUN --mount=type=cache,target=/tmp/dl,sharing=locked \
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/delta-${DELTA_VER}-x86_64-unknown-linux-musl.tar.gz" | \
    tar -xz --strip-components=1 -C /tmp --wildcards '*/delta' && \
    sudo install -m755 /tmp/delta /usr/local/bin/delta
```

- [ ] **Step 3: Replace the dust download step to use the ARG**

Find the `# dust` RUN block. Replace with:

```dockerfile
# dust (du replacement)
RUN curl -fsSL "https://github.com/bootandy/dust/releases/download/${DUST_VER}/dust-${DUST_VER}-x86_64-unknown-linux-musl.tar.gz" | \
    tar -xz --strip-components=1 -C /tmp --wildcards '*/dust' && \
    sudo install -m755 /tmp/dust /usr/local/bin/dust
```

- [ ] **Step 4: Replace the procs download step to use the ARG**

```dockerfile
# procs (ps replacement)
RUN curl -fsSL "https://github.com/dalance/procs/releases/download/${PROCS_VER}/procs-${PROCS_VER}-x86_64-linux.zip" \
      -o /tmp/procs.zip && \
    unzip -q /tmp/procs.zip procs -d /tmp && \
    sudo install -m755 /tmp/procs /usr/local/bin/procs && \
    rm /tmp/procs.zip
```

- [ ] **Step 5: Replace the direnv download step to use the ARG**

```dockerfile
# direnv
RUN mkdir -p /home/dev/.local/bin && \
    curl -fsSL "https://github.com/direnv/direnv/releases/download/${DIRENV_VER}/direnv.linux-amd64" \
      -o /home/dev/.local/bin/direnv && \
    chmod +x /home/dev/.local/bin/direnv
```

- [ ] **Step 6: Replace the fastfetch download step to use the ARG**

```dockerfile
# fastfetch
RUN curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VER}/fastfetch-linux-amd64.deb" \
      -o /tmp/fastfetch.deb && \
    sudo dpkg -i /tmp/fastfetch.deb && \
    rm /tmp/fastfetch.deb
```

- [ ] **Step 7: Replace the Go version lookup to use the ARG**

Find the Go `RUN` block that calls `go.dev/dl/?mode=json`. Replace the entire block with:

```dockerfile
# ─── 4. Go version manager (g) ────────────────────────────────────────────────
ENV GOPATH="/home/dev/go"
ENV GOROOT="/home/dev/.go"
RUN mkdir -p "$GOPATH/bin" "$GOROOT" && \
    curl -fsSL "https://raw.githubusercontent.com/stefanmaric/g/master/bin/g" \
      -o "$GOPATH/bin/g" && \
    chmod +x "$GOPATH/bin/g"
ENV PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
RUN curl -fsSL "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz" | \
    tar -xz --strip-components=1 -C "$GOROOT"
```

- [ ] **Step 8: Verify the Dockerfile still builds**

```bash
docker build --progress=plain -t zsh-config-test . 2>&1 | tail -20
```

Expected: build completes successfully, no API call output visible in layer logs.

- [ ] **Step 9: Commit**

```bash
git add Dockerfile
git commit -m "perf: pin tool versions as ARGs to eliminate GitHub API calls"
```

---

### Task 2: Remove `apt-get upgrade -y`

**Files:**
- Modify: `Dockerfile`

- [ ] **Step 1: Delete the upgrade line**

Find the system packages `RUN` block (section 1). Remove the line:

```dockerfile
    sudo apt-get upgrade -y && \
```

The block should go directly from `apt-get update -qq` to `apt-get install -y`.

- [ ] **Step 2: Verify build**

```bash
docker build --progress=plain -t zsh-config-test . 2>&1 | tail -20
```

Expected: build completes successfully.

- [ ] **Step 3: Commit**

```bash
git add Dockerfile
git commit -m "perf: remove apt-get upgrade to speed up builds"
```

---

### Task 3: Merge binary downloads into one parallel RUN

**Files:**
- Modify: `Dockerfile`

- [ ] **Step 1: Replace all individual binary RUN blocks with one parallel block**

Remove the separate RUN steps for eza, delta, dust, procs, fnm, starship, direnv, fzf, fastfetch (sections 2–8 of the binary install area). Replace them with a single `RUN` block:

```dockerfile
# ─── 2. CLI tools — parallel downloads ────────────────────────────────────────
RUN mkdir -p /home/dev/.cargo/bin /home/dev/.local/bin /home/dev/.fzf
ENV PATH="/home/dev/.cargo/bin:/home/dev/.local/bin:$PATH"

RUN set -e && \
    \
    # eza
    ( curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz" | \
      tar -xz -C /tmp && \
      sudo install -m755 /tmp/eza /usr/local/bin/eza ) & \
    \
    # git-delta
    ( curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/delta-${DELTA_VER}-x86_64-unknown-linux-musl.tar.gz" | \
      tar -xz --strip-components=1 -C /tmp --wildcards '*/delta' && \
      sudo install -m755 /tmp/delta /usr/local/bin/delta ) & \
    \
    # dust
    ( curl -fsSL "https://github.com/bootandy/dust/releases/download/${DUST_VER}/dust-${DUST_VER}-x86_64-unknown-linux-musl.tar.gz" | \
      tar -xz --strip-components=1 -C /tmp --wildcards '*/dust' && \
      sudo install -m755 /tmp/dust /usr/local/bin/dust ) & \
    \
    # procs
    ( curl -fsSL "https://github.com/dalance/procs/releases/download/${PROCS_VER}/procs-${PROCS_VER}-x86_64-linux.zip" \
        -o /tmp/procs.zip && \
      unzip -q /tmp/procs.zip procs -d /tmp && \
      sudo install -m755 /tmp/procs /usr/local/bin/procs && \
      rm /tmp/procs.zip ) & \
    \
    # fnm
    ( curl -fsSL "https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip" \
        -o /tmp/fnm.zip && \
      unzip -q /tmp/fnm.zip -d /tmp/fnm-bin && \
      install -m755 /tmp/fnm-bin/fnm /home/dev/.cargo/bin/fnm && \
      rm -rf /tmp/fnm.zip /tmp/fnm-bin ) & \
    \
    # starship
    ( curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz" | \
      sudo tar -xz -C /usr/local/bin ) & \
    \
    # direnv
    ( curl -fsSL "https://github.com/direnv/direnv/releases/download/${DIRENV_VER}/direnv.linux-amd64" \
        -o /home/dev/.local/bin/direnv && \
      chmod +x /home/dev/.local/bin/direnv ) & \
    \
    # fzf
    ( git clone --quiet --depth 1 https://github.com/junegunn/fzf.git /home/dev/.fzf && \
      /home/dev/.fzf/install --key-bindings --completion --no-update-rc ) & \
    \
    # fastfetch
    ( curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VER}/fastfetch-linux-amd64.deb" \
        -o /tmp/fastfetch.deb && \
      sudo dpkg -i /tmp/fastfetch.deb && \
      rm /tmp/fastfetch.deb ) & \
    \
    wait
```

Note: `fzf` was previously installed via `~/.fzf` (which resolves to `/home/dev/.fzf`). The explicit path is used here since background subshells may not expand `~` reliably.

- [ ] **Step 2: Verify build**

```bash
docker build --progress=plain -t zsh-config-test . 2>&1 | tail -30
```

Expected: build completes successfully. All tools present.

- [ ] **Step 3: Spot-check installed tools inside the image**

```bash
docker run --rm zsh-config-test zsh -c "for t in eza delta dust procs fnm starship direnv fzf fastfetch; do which \$t && echo ok; done"
```

Expected: each tool prints its path followed by `ok`.

- [ ] **Step 4: Commit**

```bash
git add Dockerfile
git commit -m "perf: merge binary downloads into one parallel RUN"
```

---

### Task 4: Merge tail config RUN steps

**Files:**
- Modify: `Dockerfile`

- [ ] **Step 1: Merge the three config RUN steps into one**

Find these three consecutive `RUN` blocks near the end of the Dockerfile:

```dockerfile
RUN cat > ~/.zshenv << 'EOF'
...
EOF

RUN touch ~/.config/zsh/modules/local.zsh

RUN mkdir -p ~/.config/tmux && \
    ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf
```

Replace with:

```dockerfile
RUN cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

RUN touch ~/.config/zsh/modules/local.zsh && \
    mkdir -p ~/.config/tmux && \
    ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf
```

(The zshenv heredoc must remain its own `RUN` — heredocs cannot be combined with `&&` chains in a single `RUN`. The other two steps can be merged.)

- [ ] **Step 2: Verify build**

```bash
docker build --progress=plain -t zsh-config-test . 2>&1 | tail -20
```

Expected: build completes successfully, test suite passes.

- [ ] **Step 3: Commit**

```bash
git add Dockerfile
git commit -m "perf: merge tail config RUN steps to reduce layer count"
```
