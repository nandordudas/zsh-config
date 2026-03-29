FROM ubuntu:24.04

# Non-interactive apt throughout the build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Create a non-root user (mirrors real install — paths like ~/.cargo depend on $HOME)
RUN apt-get update -qq && apt-get install -y --no-install-recommends sudo && \
    useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dev
WORKDIR /home/dev

# ─── 1. System packages ────────────────────────────────────────────────────────
RUN sudo apt-get update -qq && sudo apt-get upgrade -y && \
    sudo apt-get install -y --no-install-recommends \
      zsh \
      bat fd-find ripgrep \
      duf zoxide \
      exiftool \
      unrar p7zip-full \
      curl wget git \
      software-properties-common \
      ca-certificates gnupg

# ─── 2. Rust ──────────────────────────────────────────────────────────────────
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --quiet
ENV PATH="/home/dev/.cargo/bin:$PATH"

# ─── 3. Cargo tools ───────────────────────────────────────────────────────────
RUN cargo install du-dust procs cargo-update eza git-delta \
    --quiet 2>&1 | tail -5

# ─── 3b. fnm — download binary directly to match tools.zsh expected path ─────
# cargo install fnm fails to compile on Ubuntu 24.04; install script is
# unreliable in non-interactive Docker builds. Download the release binary.
RUN sudo apt-get install -y --no-install-recommends unzip && \
    curl -fsSL "https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip" \
      -o /tmp/fnm.zip && \
    unzip -q /tmp/fnm.zip -d /tmp/fnm-bin && \
    install -m755 /tmp/fnm-bin/fnm /home/dev/.cargo/bin/fnm && \
    rm -rf /tmp/fnm.zip /tmp/fnm-bin

# ─── 4. Node.js via fnm ───────────────────────────────────────────────────────
# eval "$(fnm env)" must run in the same shell as fnm commands that follow it.
RUN fnm install --lts 2>&1 | tail -3 && \
    eval "$(fnm env --shell bash)" && \
    fnm default lts-latest && fnm use lts-latest && \
    npm install --global npm@latest pnpm @antfu/ni eslint taze npkill \
      --silent 2>&1 | tail -3

# ─── 5. Go version manager (g) ────────────────────────────────────────────────
ENV GOPATH="/home/dev/go"
ENV GOROOT="/home/dev/.go"
RUN mkdir -p "$GOPATH/bin" "$GOROOT" && \
    curl -fsSL "https://raw.githubusercontent.com/stefanmaric/g/master/bin/g" \
      -o "$GOPATH/bin/g" && \
    chmod +x "$GOPATH/bin/g"
ENV PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
RUN g install latest && g use latest

# ─── 6. Starship ──────────────────────────────────────────────────────────────
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes -q

# ─── 7. direnv ────────────────────────────────────────────────────────────────
RUN curl -sfL https://direnv.net/install.sh | bash

# ─── 8. fzf (from git — apt ships an older version) ──────────────────────────
RUN git clone --quiet --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    ~/.fzf/install --key-bindings --completion --no-update-rc

# ─── 9. fastfetch ─────────────────────────────────────────────────────────────
RUN sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch -q && \
    sudo apt-get update -qq && sudo apt-get install -y fastfetch

# ─── 10. GitHub CLI ───────────────────────────────────────────────────────────
RUN sudo mkdir -p -m 755 /etc/apt/keyrings && \
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

# ─── Run test suite ───────────────────────────────────────────────────────────
RUN bash ~/.config/zsh/scripts/test.sh

ENV SHELL=/bin/zsh
CMD ["zsh", "-i"]
