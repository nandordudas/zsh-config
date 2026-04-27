# syntax=docker/dockerfile:1
# Build args: defaults from versions.env (update there for easier maintenance)
# Usage: docker build -t zsh-config-test .
#   or: docker build -t zsh-config-test \
#         --build-arg DELTA_VER=0.20.0 \
#         --build-arg GO_VER=go1.27.0 .
FROM ubuntu:24.04

# Use bash for all RUN commands (script uses bash array syntax)
SHELL ["/bin/bash", "-c"]

ARG DELTA_VER=0.19.2      # bare, e.g. 0.19.2
ARG DUST_VER=v1.2.4       # v-prefixed, e.g. v1.2.4
ARG PROCS_VER=v0.14.11    # v-prefixed, e.g. v0.14.11
ARG DIRENV_VER=v2.37.1    # v-prefixed, e.g. v2.37.1
ARG FASTFETCH_VER=2.61.0  # bare, e.g. 2.61.0
ARG GO_VER=go1.26.2       # go-prefixed, e.g. go1.26.2

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
    echo "dev ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers

USER dev
WORKDIR /home/dev

# ─── 1. System packages ────────────────────────────────────────────────────────
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update -qq && \
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

# ─── 2. CLI tools — parallel downloads ────────────────────────────────────────
RUN mkdir -p /home/dev/.cargo/bin /home/dev/.local/bin
ENV PATH="/home/dev/.cargo/bin:/home/dev/.local/bin:$PATH"

RUN set -e && \
    pids=() && \
    \
    ( d=$(mktemp -d) && \
      curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz" | \
      tar -xz -C "$d" && \
      sudo install -m755 "$d/eza" /usr/local/bin/eza && \
      rm -rf "$d" ) & pids+=($!) && \
    \
    ( d=$(mktemp -d) && \
      curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/delta-${DELTA_VER}-x86_64-unknown-linux-musl.tar.gz" | \
      tar -xz --strip-components=1 -C "$d" --wildcards '*/delta' && \
      sudo install -m755 "$d/delta" /usr/local/bin/delta && \
      rm -rf "$d" ) & pids+=($!) && \
    \
    ( d=$(mktemp -d) && \
      curl -fsSL "https://github.com/bootandy/dust/releases/download/${DUST_VER}/dust-${DUST_VER}-x86_64-unknown-linux-musl.tar.gz" | \
      tar -xz --strip-components=1 -C "$d" --wildcards '*/dust' && \
      sudo install -m755 "$d/dust" /usr/local/bin/dust && \
      rm -rf "$d" ) & pids+=($!) && \
    \
    ( d=$(mktemp -d) && \
      curl -fsSL "https://github.com/dalance/procs/releases/download/${PROCS_VER}/procs-${PROCS_VER}-x86_64-linux.zip" \
        -o "$d/procs.zip" && \
      unzip -q "$d/procs.zip" procs -d "$d" && \
      sudo install -m755 "$d/procs" /usr/local/bin/procs && \
      rm -rf "$d" ) & pids+=($!) && \
    \
    ( d=$(mktemp -d) && \
      curl -fsSL "https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip" \
        -o "$d/fnm.zip" && \
      unzip -q "$d/fnm.zip" -d "$d/fnm-bin" && \
      install -m755 "$d/fnm-bin/fnm" /home/dev/.cargo/bin/fnm && \
      rm -rf "$d" ) & pids+=($!) && \
    \
    ( d=$(mktemp -d) && \
      curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz" | \
      tar -xz -C "$d" && \
      sudo install -m755 "$d/starship" /usr/local/bin/starship && \
      rm -rf "$d" ) & pids+=($!) && \
    \
    ( curl -fsSL "https://github.com/direnv/direnv/releases/download/${DIRENV_VER}/direnv.linux-amd64" \
        -o /home/dev/.local/bin/direnv && \
      chmod +x /home/dev/.local/bin/direnv ) & pids+=($!) && \
    \
    ( git clone --quiet --depth 1 https://github.com/junegunn/fzf.git /home/dev/.fzf && \
      /home/dev/.fzf/install --key-bindings --completion --no-update-rc ) & pids+=($!) && \
    \
    ( d=$(mktemp -d) && \
      curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VER}/fastfetch-linux-amd64.deb" \
        -o "$d/fastfetch.deb" && \
      sudo dpkg -i "$d/fastfetch.deb" && \
      rm -rf "$d" ) & pids+=($!) && \
    \
    for pid in "${pids[@]}"; do wait "$pid" || exit 1; done

# ─── 3. Node.js via fnm ───────────────────────────────────────────────────────
# eval "$(fnm env)" must run in the same shell as fnm commands that follow it.
RUN fnm install --lts 2>&1 | tail -3 && \
    eval "$(fnm env --shell bash)" && \
    fnm default lts-latest && fnm use lts-latest && \
    npm install --global npm@latest pnpm@latest @antfu/{ni,nip} eslint taze npkill \
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
RUN curl -fsSL "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz" | \
    tar -xz --strip-components=1 -C "$GOROOT"

# ─── 9. GitHub CLI ────────────────────────────────────────────────────────────
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null && \
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null && \
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

RUN touch ~/.config/zsh/modules/local.zsh && \
    mkdir -p ~/.config/tmux && \
    ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf

# ─── Run test suite ───────────────────────────────────────────────────────────
RUN bash ~/.config/zsh/scripts/test.sh

ENV SHELL=/bin/zsh
CMD ["zsh", "-i"]
