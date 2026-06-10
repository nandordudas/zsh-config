# Brewfile — core packages for zsh-config
# Install with: brew bundle --file=~/.config/zsh/Brewfile
# (install.sh does this for you)

# Shell essentials
brew "git"
brew "tmux"
brew "fzf"        # fuzzy finder (Ctrl+R / Ctrl+T / Alt+C)
brew "zoxide"     # smart cd (z)
brew "starship"   # prompt
# direnv intentionally absent: mise replaces it ([env] in mise.toml, `mise set`)
# and mise's docs deprecate running both — PATH conflicts.
# https://mise.jdx.dev/direnv.html

# Modern CLI replacements
brew "bat"        # cat with syntax highlighting
brew "eza"        # ls replacement (ls/ll/la/lt aliases)
brew "fd"         # find replacement
brew "ripgrep"    # grep replacement (rg)
brew "dust"       # du replacement (du alias)
brew "duf"        # df replacement (df alias)
brew "procs"      # ps replacement (pss alias)
brew "jq"         # JSON processor

# Git tooling
brew "gh"         # GitHub CLI (auth, PRs, SSH key registration)
brew "git-delta"  # diff pager (configured by git-setup.sh)

# Archives — sevenzip provides `7zz`, used by extract() for .7z and .rar
brew "sevenzip"
