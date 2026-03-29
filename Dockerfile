# syntax=docker/dockerfile:1
FROM ubuntu:24.04

# Non-interactive apt throughout the build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create a non-root user (mirrors real install — paths like ~/.cargo depend on $HOME)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && apt-get install -y --no-install-recommends sudo locales && \
    locale-gen en_US.UTF-8 && \
    useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dev
WORKDIR /home/dev

# ─── 1. System packages ────────────────────────────────────────────────────────
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update -qq && sudo apt-get upgrade -y && \
    sudo apt-get install -y --no-install-recommends \
      zsh tmux \
      bat fd-find ripgrep \
      duf zoxide \
      exiftool \
      unrar p7zip-full unzip \
      curl wget git \
      openssh-client \
      python3 \
      software-properties-common \
      ca-certificates gnupg

# ─── 2. CLI tools from GitHub releases ────────────────────────────────────────
# ~/.cargo/bin is used for fnm (tools.zsh expects it there); no Rust needed.
RUN mkdir -p /home/dev/.cargo/bin
ENV PATH="/home/dev/.cargo/bin:$PATH"

# eza (ls replacement)
RUN curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz" | \
    tar -xz -C /tmp && \
    sudo install -m755 /tmp/eza /usr/local/bin/eza

# git-delta (git pager)
RUN DELTA_VER=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest | \
      python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])") && \
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/delta-${DELTA_VER}-x86_64-unknown-linux-musl.tar.gz" | \
    tar -xz --strip-components=1 -C /tmp --wildcards '*/delta' && \
    sudo install -m755 /tmp/delta /usr/local/bin/delta

# dust (du replacement)
RUN DUST_VER=$(curl -fsSL https://api.github.com/repos/bootandy/dust/releases/latest | \
      python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])") && \
    curl -fsSL "https://github.com/bootandy/dust/releases/download/${DUST_VER}/dust-${DUST_VER}-x86_64-unknown-linux-musl.tar.gz" | \
    tar -xz --strip-components=1 -C /tmp --wildcards '*/dust' && \
    sudo install -m755 /tmp/dust /usr/local/bin/dust

# procs (ps replacement)
RUN PROCS_VER=$(curl -fsSL https://api.github.com/repos/dalance/procs/releases/latest | \
      python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])") && \
    curl -fsSL "https://github.com/dalance/procs/releases/download/${PROCS_VER}/procs-${PROCS_VER}-x86_64-linux.zip" \
      -o /tmp/procs.zip && \
    unzip -q /tmp/procs.zip procs -d /tmp && \
    sudo install -m755 /tmp/procs /usr/local/bin/procs && \
    rm /tmp/procs.zip

# fnm (Node version manager) — installed to ~/.cargo/bin to match tools.zsh
RUN curl -fsSL "https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip" \
      -o /tmp/fnm.zip && \
    unzip -q /tmp/fnm.zip -d /tmp/fnm-bin && \
    install -m755 /tmp/fnm-bin/fnm /home/dev/.cargo/bin/fnm && \
    rm -rf /tmp/fnm.zip /tmp/fnm-bin

# ─── 3. Node.js via fnm ───────────────────────────────────────────────────────
# eval "$(fnm env)" must run in the same shell as fnm commands that follow it.
RUN fnm install --lts 2>&1 | tail -3 && \
    eval "$(fnm env --shell bash)" && \
    fnm default lts-latest && fnm use lts-latest && \
    npm install --global npm@latest pnpm @antfu/ni eslint taze npkill \
      --silent 2>&1 | tail -3

# ─── 4. Go version manager (g) ────────────────────────────────────────────────
ENV GOPATH="/home/dev/go"
ENV GOROOT="/home/dev/.go"
RUN mkdir -p "$GOPATH/bin" "$GOROOT" && \
    curl -fsSL "https://raw.githubusercontent.com/stefanmaric/g/master/bin/g" \
      -o "$GOPATH/bin/g" && \
    chmod +x "$GOPATH/bin/g"
ENV PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
# g install latest is unreliable in non-interactive Docker; download directly.
RUN GO_VER=$(curl -fsSL "https://go.dev/dl/?mode=json" | \
      python3 -c "import sys,json; print(json.load(sys.stdin)[0]['version'])") && \
    curl -fsSL "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz" | \
    tar -xz --strip-components=1 -C "$GOROOT"

# ─── 5. Starship ──────────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz" | \
    sudo tar -xz -C /usr/local/bin

# ─── 6. direnv ────────────────────────────────────────────────────────────────
RUN mkdir -p /home/dev/.local/bin && \
    DIRENV_VER=$(curl -fsSL "https://api.github.com/repos/direnv/direnv/releases/latest" | \
      python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])") && \
    curl -fsSL "https://github.com/direnv/direnv/releases/download/${DIRENV_VER}/direnv.linux-amd64" \
      -o /home/dev/.local/bin/direnv && \
    chmod +x /home/dev/.local/bin/direnv

# ─── 7. fzf (from git — apt ships an older version) ──────────────────────────
RUN git clone --quiet --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    ~/.fzf/install --key-bindings --completion --no-update-rc

# ─── 8. fastfetch ─────────────────────────────────────────────────────────────
RUN FASTFETCH_VER=$(curl -fsSL "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | \
      python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])") && \
    curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VER}/fastfetch-linux-amd64.deb" \
      -o /tmp/fastfetch.deb && \
    sudo dpkg -i /tmp/fastfetch.deb && \
    rm /tmp/fastfetch.deb

# ─── 9. GitHub CLI ────────────────────────────────────────────────────────────
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    sudo apt-get update -qq && sudo apt-get install -y gh

# ─── Config setup ─────────────────────────────────────────────────────────────
COPY --chown=dev:dev . /home/dev/.config/zsh

RUN cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

RUN touch ~/.config/zsh/modules/local.zsh

RUN mkdir -p ~/.config/tmux && \
    ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf

# ─── Run test suite ───────────────────────────────────────────────────────────
RUN bash ~/.config/zsh/scripts/test.sh

ENV SHELL=/bin/zsh
CMD ["zsh", "-i"]
