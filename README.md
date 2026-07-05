# 🚀 zsh-config

> A fast, modular zsh configuration for productive terminal workflows on macOS.

**Target startup time:** < 100ms | **Platform:** macOS (Apple Silicon & Intel)

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 2. Run the installer (bootstraps Homebrew + all tools)
~/.config/zsh/install.sh

# 3. Open a new terminal and verify
zsh-health
```

That's it. The installer:

- Installs **Homebrew** if missing (`/opt/homebrew` on Apple Silicon — all bottles native arm64)
- Installs every tool the config uses via **`brew bundle`** — the package list is declared in [`Brewfile`](Brewfile) (core) and [`Brewfile.dev`](Brewfile.dev) (dev toolchains: mise, rustup, fastfetch)
- Writes `~/.zshenv`, creates `modules/local.zsh`, links the herdr config (and installs its Claude Code integration), creates the Alacritty local wrapper
- Is **idempotent** — safe to re-run anytime; existing files are backed up, never silently overwritten

### Installer options

| Flag | Effect |
|------|--------|
| `--minimal` | Core tools only — skip dev toolchains (mise runtimes, rustup) |
| `--config-only` | Only set up config files, install no packages |
| `--yes` / `-y` | Skip confirmation prompts |
| `--git-name "X" --git-email "Y"` | Also configure git identity + SSH commit signing |
| `--help` | Show all options |

```bash
# Examples
~/.config/zsh/install.sh -y
~/.config/zsh/install.sh --git-name "Jane Doe" --git-email "j@d.dev"
```

> [!TIP]
> **New MacBook?** Run the installer first thing — it bootstraps Homebrew and the entire toolchain in one go. macOS already ships zsh as the default shell, so when it finishes, just open a new terminal.

---

## What is this?

A **fully-featured zsh configuration** built with:

- [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager (turbo mode for speed)
- Curated plugins: autosuggestions, syntax highlighting, fzf-tab, forgit, history substring search
- SSH commit signing (no GPG required)
- Parallel tool updater (`upgrade`) and health diagnostics (`zsh-health`)
- XDG base directory spec compliance — `~` stays clean

**Perfect for:** Developers, DevOps engineers, and anyone who lives in the terminal.

**Not for you if:** You want a minimal config. This is **opinionated** — fork it and adapt to your needs.

---

## Features

| Feature | Benefit |
|---------|---------|
| **Fast startup** | Zinit turbo mode + cached tool initialization (~50-100ms) |
| **Smart plugin loading** | Plugins load on-demand, not at startup |
| **Git integration** | SSH commit signing, per-host identities, delta diffs, 80+ git aliases |
| **macOS-tuned git** | FSEvents `fsmonitor`, fetch/index parallelism = CPU cores |
| **Tool auto-updates** | `upgrade` updates brew, zinit, rust, mise and claude in parallel |
| **herdr session management** | agent-aware terminal multiplexer, native fuzzy pickers (`C-a g`/`C-a w`), Claude Code state hook |
| **Fuzzy finder** | fzf for file/history search, fzf-tab completion menus, forgit |
| **Diagnostics** | `zsh-health` checks tools, PATH, and config |
| **XDG compliant** | All config in `~/.config`, cache in `~/.cache` |
| **Headless mode** | `toggle_interactive off` disables Starship + plugins for scripts |

---

## Manual Installation

If you'd rather not run the installer, here's what it does:

<details>
<summary><strong>Step-by-step manual setup</strong></summary>

```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone the config (the Brewfiles live in the repo)
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 3. All tools (native arm64 bottles on Apple Silicon)
brew bundle --file=~/.config/zsh/Brewfile       # core tools
brew bundle --file=~/.config/zsh/Brewfile.dev   # dev toolchains: mise, rustup, fastfetch

# 4. Node (global) via mise; rustup manager only — all other runtimes per-project
printf 'pnpm\n@antfu/ni\ntaze\nnpkill\nccstatusline\neslint\n' > ~/.default-npm-packages
mise use -g node@lts
rustup-init -y --no-modify-path --default-toolchain none

# 5. Create ~/.zshenv (required — points zsh at the config)
cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

# 6. Machine-local config (gitignored, safe for secrets)
touch ~/.config/zsh/modules/local.zsh

# 7. Link herdr config, then install its Claude Code integration
mkdir -p ~/.config/herdr
ln -sf ~/.config/zsh/herdr/config.toml ~/.config/herdr/config.toml
herdr integration install claude   # requires herdr + claude on PATH, and ~/.claude to exist

# 8. Alacritty local wrapper (real file, not a symlink — lets you add local overrides after the import)
mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.toml << EOF
[general]
import = [
  "$HOME/.config/zsh/alacritty/alacritty.toml",
  "$HOME/.config/alacritty/theme.toml",
]
EOF

# 9. Open a new terminal — Zinit installs plugins on first start (~1-2 min)
zsh-health
```

</details>

---

## Configuration

### Machine-local settings

File: `~/.config/zsh/modules/local.zsh` (gitignored — safe for secrets)

```bash
# Machine-local zsh config (gitignored — safe for secrets and machine quirks)

# Auto-attach to a herdr session when opening VS Code's integrated terminal.
# Session name = workspace folder basename (PWD is set to workspace root by VS Code).
# exec replaces this shell process; herdr then starts a fresh zsh inside.
# `herdr --session NAME` attaches if it exists, creates it otherwise.
if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "zed" ]]; then
  exec herdr --session "${PWD:t}"
fi

# Auto-attach to a herdr session when opening Alacritty.
# Uses a fixed "main" session (no workspace context like VS Code).
# Detected via $TERM=alacritty set in alacritty.toml [env].
if [[ "$TERM" == "alacritty" ]]; then
  exec herdr --session main
fi

# GitHub and BitBucket usernames (for gg/gb navigation aliases)
export GITHUB_USER="your-github-username"
export BITBUCKET_USER="your-bitbucket-username"

# Project root for gg/gb and freespace (default: ~/Development/code).
# NOTE: if you change this, also update the [includeIf] paths in
# ~/.config/git/config so per-host git identities keep working.
# export CODE_DIR="$HOME/Developer"

# Auto-pull zsh-config updates on login and show what changed (opt-in).
# When enabled, the daily update check pulls automatically (fast-forward only)
# and prints the new commits so you know exactly what arrived:
#
#   ╭─ ✅ zsh-config updated to abc1234 (2 new commit(s))
#   ├─ feat: add fzf git log preview
#   ├─ fix: correct mise hook timing
#   ╰─ run `exec zsh` to reload
#
# ZSH_CONFIG_AUTO_UPDATE=1

# Custom aliases / functions / overrides
alias myproject="cd ~/projects/myproject"
```


The installer creates this wrapper automatically. To add per-machine Alacritty overrides, append settings after the `import` block — they take precedence over everything imported.

**herdr local overrides:** unlike Alacritty's `import` or tmux's `source-file`,
herdr's `config.toml` has no include directive, so there's no layered
`local.toml`. It holds no secrets (just UI/keybindings), so machine-specific
tweaks go directly into [`herdr/config.toml`](herdr/config.toml). For a
genuinely different per-machine profile, point `HERDR_CONFIG_PATH` at a
separate file instead. See [docs/herdr-guide.md](docs/herdr-guide.md).

### Customize plugins

Edit `modules/zinit.zsh` and restart the shell. See [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins) for ideas; remove plugins you don't use to improve startup time.

### Customize keybindings / aliases

- `modules/keybindings.zsh` — `Ctrl+R` history, `Ctrl+T` files, word navigation
- `modules/aliases.zsh` — `ll` (eza), `gs`/`gco`/`gcm` (git), `tm` (herdr), …

Full reference: [docs/aliases.md](docs/aliases.md), [docs/keybindings.md](docs/keybindings.md), [docs/functions.md](docs/functions.md)

---

## Common Tasks

### Update everything

```bash
upgrade              # brew, zinit, rust, mise (node/go), claude-code@latest — in parallel
upgrade --dry-run    # see what would run
upgrade --only mise  # update only mise-managed runtimes + npm globals
```

> [!NOTE]
> `starship` and Maple Mono fonts are tracked in `Brewfile`; `fastfetch` and `claude-code@latest` in `Brewfile.dev`.
> After a tool upgrade, eval caches (starship, zoxide, mise, fzf) regenerate automatically on the next shell
> start via binary `-nt` check — no manual `zsh-cache-clear` needed.

### Check system health

```bash
zsh-health           # platform, tools, PATH, config — with fix hints
```

### Clear caches

```bash
zsh-cache-clear      # removes eval caches (starship, zoxide, mise, fzf)
exec zsh             # restart shell (regenerates caches)
```

### Free up disk space

```bash
freespace --dry-run              # preview (no changes)
freespace                        # clean node_modules/vendor under ~/Development/code
freespace --aggressive           # also clean npm/pip/go/cargo/brew caches
```

Always asks for confirmation before deleting.

### Interactive git (forgit + aliases)

```bash
glo / ga / gcb / grh   # interactive log / add / checkout / reset (fzf)
gs / gco / gcm / gaa   # status / checkout / commit -m / add -A
git alias              # list all 80+ git aliases
```

### fzf shortcuts

- `Ctrl+R` → fuzzy history search
- `Ctrl+T` → fuzzy file finder (with bat preview)
- `Option+C` (⌥C) → fuzzy directory jump

### Per-project runtimes (mise)

Node is installed **globally** (always-on tools like `ccstatusline` and `taze`
need it). Everything else is pinned **per project**:

```bash
cd myproject
mise use go@1.24 python@3.13   # writes .mise.toml, installs on demand
mise ls                        # what's active here
```

Global npm tools live in `~/.default-npm-packages` — mise re-installs them
automatically into every new node version, so they survive node upgrades.

Rust is per-project too, via its own manager: commit a `rust-toolchain.toml`
and rustup auto-installs/uses that toolchain on the first build. No global
toolchain is installed; for ad-hoc rust outside a project, run
`rustup default stable` once.

**brew or mise? The rule of thumb:**

> If two projects could ever need *different versions* of it → **mise**.
> Otherwise → **brew**.

| brew | mise |
|------|------|
| Apps & daemons (Docker Desktop, etc. — casks) | Language runtimes: node, go, python, java, … |
| System CLI tools, one version forever: git, herdr, fzf, bat, ripgrep, jq, gh, delta, … | Anything pinned in a project's `.mise.toml` |
| mise itself | |

### Per-project env vars (replaces direnv)

mise also manages environment variables, so **direnv is not installed** —
[mise's docs deprecate combining them](https://mise.jdx.dev/direnv.html)
(PATH conflicts). Instead:

```bash
cd myproject
mise set NODE_ENV=development     # writes [env] into .mise.toml
mise set                          # list current env vars
```

Bonus: auto-install a project's pinned tools when you `cd` in — add to its
`.mise.toml`:

```toml
[hooks]
enter = "mise i -q"
```

### Headless / automation mode

```bash
toggle_interactive off   # disables Starship + Zinit (fast bare shell)
toggle_interactive on    # back to full features
```

---

## Updating

```bash
git -C ~/.config/zsh pull
zsh-cache-clear
exec zsh
```

A daily login check tells you when the repo has new upstream commits.

---

## Testing

```bash
# Validate the repo without touching your dotfiles
bash ~/.config/zsh/scripts/test.sh
# or
make test
```

---

## Troubleshooting

### "zsh-health: command not found"

The config didn't load. Check:

```bash
echo $ZDOTDIR          # expected: /Users/you/.config/zsh
cat ~/.zshenv          # must export ZDOTDIR
source ~/.zshenv && exec zsh
```

### Tools installed but "command not found"

```bash
exec zsh -l            # restart as login shell (rebuilds PATH)
show_path              # inspect PATH entries
zsh-health             # shows which expected dirs are missing from PATH
```

On Apple Silicon, Homebrew must be at `/opt/homebrew` — `zsh-health` flags this.

### Slow shell startup

```bash
time zsh -i -c exit    # expect ~50-100ms after first run
zinit times            # per-plugin load times
```

First start after install/update is slow (plugin downloads + cache generation) — that's normal.

### Spotlight indexing dev folders (high I/O during npm install)

`mdutil -i off` only works on whole volumes. To exclude `~/Development` from Spotlight:

```bash
touch ~/Development/.metadata_never_index
```

The installer does this automatically. If you moved your project root (`CODE_DIR`), add the marker there too.

### Git uses the wrong identity

```bash
git whoami             # show active identity (alias from git-setup.sh)
git config user.name   # check per-repo override
```

`includeIf` blocks in `~/.config/git/config` select identities by repo path.

---

## Git Setup (SSH Commit Signing)

```bash
~/.config/zsh/scripts/git-setup.sh --name "Your Name" --email "your@email.com"
```

Creates `~/.config/git/config`, generates `~/.ssh/id_ed25519` if needed, configures SSH signing (no GPG), enables FSEvents `fsmonitor`, and sets fetch/index parallelism to your CPU core count.

Then register the key on GitHub:

```bash
gh auth refresh -s admin:public_key,admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type signing
```

Verify: `git commit --allow-empty -m "test" && git log --show-signature -1`

---

## Uninstall

One command, one confirmation — the mirror image of install:

```bash
~/.config/zsh/uninstall.sh
```

It restores your original `~/.zshenv` and herdr `config.toml` from the
backups install.sh made, uninstalls herdr's Claude Code integration, moves
the config to `~/.config/zsh.uninstalled` (kept, in case `local.zsh` holds
secrets), and clears caches/plugins. Brew packages, mise runtimes, git
config, SSH keys, and shell history are left untouched — the script prints
the `brew bundle cleanup` command if you want packages gone too.

To disable plugins temporarily without uninstalling: `toggle_interactive off`.

---

## Structure

```
~/.zshenv                     # in $HOME, created by install.sh — sets ZDOTDIR
~/.config/zsh/
├── install.sh                # one-command installer (Homebrew-based)
├── uninstall.sh              # one-command uninstaller (restores backups)
├── Brewfile                  # core packages (brew bundle)
├── Brewfile.dev              # dev toolchains: mise, rustup, fastfetch
├── .zprofile                 # login shells: Homebrew, PATH, env vars
├── .zshrc                    # main orchestrator — sources modules in order
├── modules/
│   ├── options.zsh           # shell options (setopt)
│   ├── zinit.zsh             # plugin manager + all plugins
│   ├── completions.zsh       # completion rules + fzf-tab previews
│   ├── keybindings.zsh       # key mappings
│   ├── aliases.zsh           # command aliases
│   ├── functions.zsh         # upgrade, zsh-health, freespace, …
│   ├── tools.zsh             # cached tool init (starship, zoxide, mise, …)
│   └── local.zsh             # machine-local overrides (gitignored)
├── herdr/
│   └── config.toml           # herdr config (linked to ~/.config/herdr/)
├── alacritty/
│   └── alacritty.toml        # shared base config
├── scripts/
│   ├── git-setup.sh          # git identity + SSH signing factory
│   ├── sysinfo.sh            # one-liner: CPU / MEM / GPU / battery
│   └── test.sh               # test suite
└── docs/                     # aliases, functions, keybindings, plugins
```

## VS Code settings

<details>
<summary>Expand to see settings</summary>

```jsonc
{
  /*  */
  "breadcrumbs.enabled": false,
  /*  */
  "diffEditor.codeLens": false, /*  */
  "diffEditor.experimental.showMoves": true,
  "diffEditor.hideUnchangedRegions.enabled": true,
  "diffEditor.ignoreTrimWhitespace": true,
  "diffEditor.renderSideBySide": true,
  /*  */
  "editor.acceptSuggestionOnCommitCharacter": false,
  "editor.acceptSuggestionOnEnter": "smart",
  "editor.accessibilitySupport": "off",
  "editor.codeLens": false,
  "editor.colorDecorators": false,
  "editor.cursorBlinking": "phase",
  "editor.cursorSmoothCaretAnimation": "on",
  "editor.cursorStyle": "underline-thin",
  "editor.detectIndentation": false,
  "editor.emptySelectionClipboard": false,
  "editor.foldingImportsByDefault": true,
  "editor.fontFamily": "Maple Mono, Menlo, Monaco, 'Courier New', monospace",
  "editor.fontLigatures": "'cv01', 'cv34', 'cv35', 'cv36', 'cv61', 'cv62', 'cv65', 'ss05', 'ss07', 'ss11'",
  "editor.fontSize": 16,
  "editor.formatOnSave": false,
  "editor.formatOnSaveMode": "modificationsIfAvailable",
  "editor.glyphMargin": false,
  "editor.gotoLocation.multipleDefinitions": "goto",
  "editor.guides.bracketPairs": "active",
  "editor.guides.bracketPairsHorizontal": false,
  "editor.guides.indentation": false,
  "editor.inlayHints.enabled": "offUnlessPressed",
  "editor.largeFileOptimizations": true,
  "editor.lineNumbers": "off",
  "editor.matchBrackets": "near",
  "editor.maxTokenizationLineLength": 500,
  "editor.minimap.enabled": false,
  "editor.overviewRulerBorder": false,
  "editor.padding.top": 8,
  "editor.parameterHints.enabled": true,
  "editor.quickSuggestions": {
    "comments": "off",
    "other": "on",
    "strings": "on",
  },
  "editor.renderLineHighlight": "gutter",
  "editor.renderLineHighlightOnlyWhenFocus": true,
  "editor.renderWhitespace": "selection",
  "editor.rulers": [
    {
      "color": "#F49A9A20",
      "column": 120,
    },
  ],
  "editor.scrollbar.horizontal": "hidden",
  "editor.scrollbar.vertical": "visible",
  "editor.scrollBeyondLastLine": true,
  "editor.showFoldingControls": "mouseover",
  "editor.smoothScrolling": true,
  // "editor.suggest.showWords": true, /** original false */
  "editor.tabSize": 2,
  /*  */
  "explorer.autoRevealExclude": {
    "**/.git": true,
    "**/*.xml": true
  },
  "explorer.compactFolders": false,
  "explorer.confirmDelete": false,
  "explorer.confirmDragAndDrop": false,
  "explorer.confirmPasteNative": false,
  "explorer.excludeGitIgnore": false /*  */,
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.expand": false,
  "explorer.fileNesting.patterns": {
    ".agent": ".agent, .claude, .cline, .codebuddy, .codex, .commandcode, .continue, .crush, .cursor, .factory, .gemini, .goose, .junie, .kilocode, .kiro, .kode, .mcpjam, .mux, .neovate, .opencode, .openhands, .pi, .pochi, .qoder, .qwen, .roo, .trae, .windsurf, .zencoder",
    ".clang-tidy": ".clang-format, .clangd, compile_commands.json",
    ".env": "*.env, .env.*, .envrc, env.d.ts",
    ".gitignore": ".gitattributes, .gitmodules, .gitmessage, .lfsconfig, .mailmap, .git-blame*",
    ".project": ".classpath",
    "+layout.svelte": "+layout.ts,+layout.js,+layout.server.ts,+layout.server.js,+layout.gql",
    "+page.svelte": "+page.server.ts,+page.server.js,+page.ts,+page.js,+page.gql",
    "AGENTS.md": ".clinerules, .cursorrules, .replit.md, .windsurfrules, AGENT.md, CLAUDE.local.md, CLAUDE.md, GEMINI.md",
    "ansible.cfg": "ansible.cfg, .ansible-lint, requirements.yml",
    "app.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "application.properties": "*.properties",
    "artisan": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, server.php, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, webpack.mix.js, windi.config.*",
    "astro.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "build-wrapper.log": "build-wrapper*.log, build-wrapper-dump*.json, build-wrapper-win*.exe, build-wrapper-linux*, build-wrapper-macosx*",
    "BUILD.bazel": "*.bzl, *.bazel, *.bazelrc, bazel.rc, .bazelignore, .bazelproject, .bazelversion, MODULE.bazel.lock, WORKSPACE",
    "build.gradle": "settings.gradle, gradlew, gradlew.bat, gradle.properties, gradle.lockfile",
    "build.gradle.kts": "settings.gradle.kts, gradlew, gradlew.bat, gradle.properties, gradle.lockfile",
    "Cargo.toml": ".clippy.toml, .rustfmt.toml, Cargo.Bazel.lock, Cargo.lock, clippy.toml, cross.toml, insta.yaml, rust-toolchain.toml, rustfmt.toml",
    "CMakeLists.txt": "*.cmake, *.cmake.in, .cmake-format.yaml, CMakePresets.json, CMakeCache.txt",
    "composer.json": ".php*.cache, composer.lock, phpunit.xml*, psalm*.xml",
    "default.nix": "shell.nix",
    "deno.json*": "*.env, .env.*, .envrc, api-extractor.json, deno.lock, env.d.ts, import-map.json, import_map.json, jsconfig.*, tsconfig.*, tsdoc.*",
    "Dockerfile": "*.dockerfile, .devcontainer.*, .dockerignore, Dockerfile*, captain-definition, compose.*, docker-compose.*, dockerfile*",
    "flake.nix": "default.nix, shell.nix, flake.lock",
    "gatsby-config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, gatsby-browser.*, gatsby-node.*, gatsby-ssr.*, gatsby-transformer.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "gemfile": ".ruby-version, gemfile.lock",
    "go.mod": ".air*, go.sum",
    "go.work": "go.work.sum",
    "hatch.toml": ".editorconfig, .flake8, .isort.cfg, .python-version, hatch.toml, requirements*.in, requirements*.pip, requirements*.txt, tox.ini",
    "I*.cs": "$(capture).cs",
    "justfile": "*.just, .justfile",
    "Makefile": "*.mk",
    "mix.exs": ".credo.exs, .dialyzer_ignore.exs, .formatter.exs, .iex.exs, .tool-versions, mix.lock",
    "next.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, next-env.d.ts, next-i18next.config.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "nuxt.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .nuxtignore, .nuxtrc, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, nuxt.schema.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "package.json": "*.code-workspace, .autocorrectignore, .autocorrectrc, .browserslist*, .circleci*, .commitlint*, .cspell*, .cursor*, .cz-config.js, .czrc, .dlint.json, .dprint.json*, .editorconfig, .eslint*, .firebase*, .flowconfig, .github*, .gitlab*, .gitmojirc.json, .gitpod*, .huskyrc*, .jslint*, .knip.*, .lintstagedrc*, .ls-lint.yml, .markdownlint*, .node-version, .nodemon*, .npm*, .nvmrc, .oxfmtrc.json, .oxfmtrc.json.bak, .oxfmtrc.jsonc, .oxlintrc.json, .oxlintrc.json.bak, .oxlintrc.jsonc, .pm2*, .pnp.*, .pnpm*, .prettier*, .pylintrc, .release-please*.json, .releaserc*, .ruff.toml, .sentry*, .shellcheckrc, .simple-git-hooks*, .stackblitz*, .styleci*, .stylelint*, .swcrc, .tazerc*, .textlint*, .tool-versions, .travis*, .versionrc*, .vscode*, .vsls.json, .watchman*, .windsurfrules, .xo-config*, .yamllint*, .yarnrc*, Procfile, alejandra.toml, apollo.config.*, appveyor*, azure-pipelines*, biome.json*, bower.json, build.config.*, bun.lock, bun.lockb, bunfig.toml, colada.options.ts, commitlint*, crowdin*, cspell*, cz.config.*, dangerfile*, dlint.json, dprint.json*, ec.config.*, electron-builder.*, eslint*, firebase.json, grunt*, gulp*, jenkins*, knip.*, lefthook.*, lerna*, lint-staged*, nest-cli.*, netlify*, nixpacks*, nodemon*, npm-shrinkwrap.json, nx.*, oxfmt.config.*, oxlint.config.*, package-lock.json, package.nls*.json, phpcs.xml, pm2.*, pnpm*, prettier*, pullapprove*, pyrightconfig.json, release-please*.json, release-tasks.sh, release.config.*, renovate*, rolldown.config.*, rollup.config.*, rspack*, ruff.toml, sentry.*.config.ts, simple-git-hooks*, sonar-project.properties, stylelint*, taze.config.*, tsdown.config.*, tslint*, tsup.config.*, turbo*, typedoc*, unlighthouse*, vercel*, vetur.config.*, webpack*, workspace.json, wrangler.*, xo.config.*, yarn*",
    "Pipfile": ".editorconfig, .flake8, .isort.cfg, .python-version, Pipfile, Pipfile.lock, requirements*.in, requirements*.pip, requirements*.txt, tox.ini",
    "pom.xml": "mvnw*",
    "pubspec.yaml": ".metadata, .packages, all_lint_rules.yaml, analysis_options.yaml, build.yaml, pubspec.lock, pubspec_overrides.yaml",
    "pyproject.toml": ".autocorrectignore, .autocorrectrc, .commitlint*, .cspell*, .dlint.json, .dprint.json*, .editorconfig, .eslint*, .flake8, .flowconfig, .isort.cfg, .jslint*, .lintstagedrc*, .ls-lint.yml, .markdownlint*, .oxfmtrc.json, .oxfmtrc.json.bak, .oxfmtrc.jsonc, .oxlintrc.json, .oxlintrc.json.bak, .oxlintrc.jsonc, .pdm-python, .pdm.toml, .prettier*, .pylintrc, .python-version, .ruff.toml, .shellcheckrc, .stylelint*, .textlint*, .xo-config*, .yamllint*, MANIFEST.in, Pipfile, Pipfile.lock, alejandra.toml, biome.json*, commitlint*, cspell*, dangerfile*, dlint.json, dprint.json*, eslint*, hatch.toml, lint-staged*, oxfmt.config.*, oxlint.config.*, pdm.lock, phpcs.xml, poetry.lock, poetry.toml, prettier*, pyproject.toml, pyrightconfig.json, requirements*.in, requirements*.pip, requirements*.txt, ruff.toml, setup.cfg, setup.py, stylelint*, tox.ini, tslint*, uv.lock, uv.toml, xo.config.*",
    "quasar.conf*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, quasar.extensions.json, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "readme*": "AUTHORS, Authors, BACKERS*, Backers*, CHANGELOG*, CITATION*, CODEOWNERS, CODE_OF_CONDUCT*, CONTRIBUTING*, CONTRIBUTORS, CONTRIBUTORS.MD, CONTRIBUTORS.TXT, COPYING*, CREDITS, Changelog*, Citation*, Code_Of_Conduct*, Codeowners, Contributing*, Contributors, Contributors.md, Contributors.txt, Copying*, Credits, GOVERNANCE.MD, Governance.md, HISTORY.MD, History.md, LICENSE, LICENSE.MD, LICENSE.txt, License, License.md, License.txt, MAINTAINERS, Maintainers, README-*, README_*, RELEASE_NOTES*, ROADMAP.MD, Readme-*, Readme_*, Release_Notes*, Roadmap.md, SECURITY.MD, SPONSORS*, Security.md, Sponsors*, authors, backers*, changelog*, citation*, code_of_conduct*, codeowners, contributing*, contributors, contributors.md, contributors.txt, copying*, credits, governance.md, history.md, license, license.md, license.txt, maintainers, readme-*, readme_*, release_notes*, roadmap.md, security.md, sponsors*",
    "Readme*": "AUTHORS, Authors, BACKERS*, Backers*, CHANGELOG*, CITATION*, CODEOWNERS, CODE_OF_CONDUCT*, CONTRIBUTING*, CONTRIBUTORS, CONTRIBUTORS.MD, CONTRIBUTORS.TXT, COPYING*, CREDITS, Changelog*, Citation*, Code_Of_Conduct*, Codeowners, Contributing*, Contributors, Contributors.md, Contributors.txt, Copying*, Credits, GOVERNANCE.MD, Governance.md, HISTORY.MD, History.md, LICENSE, LICENSE.MD, LICENSE.txt, License, License.md, License.txt, MAINTAINERS, Maintainers, README-*, README_*, RELEASE_NOTES*, ROADMAP.MD, Readme-*, Readme_*, Release_Notes*, Roadmap.md, SECURITY.MD, SPONSORS*, Security.md, Sponsors*, authors, backers*, changelog*, citation*, code_of_conduct*, codeowners, contributing*, contributors, contributors.md, contributors.txt, copying*, credits, governance.md, history.md, license, license.md, license.txt, maintainers, readme-*, readme_*, release_notes*, roadmap.md, security.md, sponsors*",
    "README*": "AUTHORS, Authors, BACKERS*, Backers*, CHANGELOG*, CITATION*, CODEOWNERS, CODE_OF_CONDUCT*, CONTRIBUTING*, CONTRIBUTORS, CONTRIBUTORS.MD, CONTRIBUTORS.TXT, COPYING*, CREDITS, Changelog*, Citation*, Code_Of_Conduct*, Codeowners, Contributing*, Contributors, Contributors.md, Contributors.txt, Copying*, Credits, GOVERNANCE.MD, Governance.md, HISTORY.MD, History.md, LICENSE, LICENSE.MD, LICENSE.txt, License, License.md, License.txt, MAINTAINERS, Maintainers, README-*, README_*, RELEASE_NOTES*, ROADMAP.MD, Readme-*, Readme_*, Release_Notes*, Roadmap.md, SECURITY.MD, SPONSORS*, Security.md, Sponsors*, authors, backers*, changelog*, citation*, code_of_conduct*, codeowners, contributing*, contributors, contributors.md, contributors.txt, copying*, credits, governance.md, history.md, license, license.md, license.txt, maintainers, readme-*, readme_*, release_notes*, roadmap.md, security.md, sponsors*",
    "remix.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, remix.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "requirements.txt": ".editorconfig, .flake8, .isort.cfg, .python-version, requirements*.in, requirements*.pip, requirements*.txt, tox.ini",
    "rush.json": "*.code-workspace, .autocorrectignore, .autocorrectrc, .browserslist*, .circleci*, .commitlint*, .cspell*, .cursor*, .cz-config.js, .czrc, .dlint.json, .dprint.json*, .editorconfig, .eslint*, .firebase*, .flowconfig, .github*, .gitlab*, .gitmojirc.json, .gitpod*, .huskyrc*, .jslint*, .knip.*, .lintstagedrc*, .ls-lint.yml, .markdownlint*, .node-version, .nodemon*, .npm*, .nvmrc, .oxfmtrc.json, .oxfmtrc.json.bak, .oxfmtrc.jsonc, .oxlintrc.json, .oxlintrc.json.bak, .oxlintrc.jsonc, .pm2*, .pnp.*, .pnpm*, .prettier*, .pylintrc, .release-please*.json, .releaserc*, .ruff.toml, .sentry*, .shellcheckrc, .simple-git-hooks*, .stackblitz*, .styleci*, .stylelint*, .swcrc, .tazerc*, .textlint*, .tool-versions, .travis*, .versionrc*, .vscode*, .vsls.json, .watchman*, .windsurfrules, .xo-config*, .yamllint*, .yarnrc*, Procfile, alejandra.toml, apollo.config.*, appveyor*, azure-pipelines*, biome.json*, bower.json, build.config.*, bun.lock, bun.lockb, bunfig.toml, colada.options.ts, commitlint*, crowdin*, cspell*, cz.config.*, dangerfile*, dlint.json, dprint.json*, ec.config.*, electron-builder.*, eslint*, firebase.json, grunt*, gulp*, jenkins*, knip.*, lefthook.*, lerna*, lint-staged*, nest-cli.*, netlify*, nixpacks*, nodemon*, npm-shrinkwrap.json, nx.*, oxfmt.config.*, oxlint.config.*, package-lock.json, package.nls*.json, phpcs.xml, pm2.*, pnpm*, prettier*, pullapprove*, pyrightconfig.json, release-please*.json, release-tasks.sh, release.config.*, renovate*, rolldown.config.*, rollup.config.*, rspack*, ruff.toml, sentry.*.config.ts, simple-git-hooks*, sonar-project.properties, stylelint*, taze.config.*, tsdown.config.*, tslint*, tsup.config.*, turbo*, typedoc*, unlighthouse*, vercel*, vetur.config.*, webpack*, workspace.json, wrangler.*, xo.config.*, yarn*",
    "sanity.config.*": "sanity.cli.*, sanity.types.ts, schema.json",
    "setup.cfg": ".editorconfig, .flake8, .isort.cfg, .python-version, MANIFEST.in, requirements*.in, requirements*.pip, requirements*.txt, setup.cfg, tox.ini",
    "setup.py": ".editorconfig, .flake8, .isort.cfg, .python-version, MANIFEST.in, requirements*.in, requirements*.pip, requirements*.txt, setup.cfg, setup.py, tox.ini",
    "shims.d.ts": "*.d.ts",
    "svelte.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, houdini.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, mdsvex.config.js, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vite.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "tauri.conf.json": "tauri.*.conf.json",
    "tauri.conf.json5": "tauri.*.conf.json5",
    "Tauri.toml": "Tauri.*.toml",
    "tsconfig.json": "tsconfig*.tsbuildinfo, tsconfig.*.json",
    "vite.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "vue.config.*": "*.env, .babelrc*, .codecov, .cssnanorc*, .env.*, .envrc, .htmlnanorc*, .lighthouserc.*, .mocha*, .postcssrc*, .terserrc*, api-extractor.json, ava.config.*, babel.config.*, capacitor.config.*, content.config.*, contentlayer.config.*, cssnano.config.*, cypress.*, env.d.ts, formkit.config.*, formulate.config.*, histoire.config.*, htmlnanorc.*, i18n.config.*, ionic.config.*, jasmine.*, jest.config.*, jsconfig.*, karma*, lighthouserc.*, panda.config.*, playwright.config.*, postcss.config.*, puppeteer.config.*, react-router.config.*, rspack.config.*, sst.config.*, svgo.config.*, tailwind.config.*, tsconfig.*, tsdoc.*, uno.config.*, unocss.config.*, vitest.config.*, vuetify.config.*, webpack.config.*, windi.config.*",
    "*.asax": "$(capture).*.cs, $(capture).*.vb",
    "*.ascx": "$(capture).*.cs, $(capture).*.vb",
    "*.ashx": "$(capture).*.cs, $(capture).*.vb",
    "*.aspx": "$(capture).*.cs, $(capture).*.vb",
    "*.axaml": "$(capture).axaml.cs",
    "*.bloc.dart": "$(capture).event.dart, $(capture).state.dart",
    "*.c": "$(capture).h",
    "*.cc": "$(capture).hpp, $(capture).h, $(capture).hxx, $(capture).hh",
    "*.cjs": "$(capture).cjs.map, $(capture).*.cjs, $(capture)_*.cjs",
    "*.component.ts": "$(capture).component.html, $(capture).component.spec.ts, $(capture).component.css, $(capture).component.scss, $(capture).component.sass, $(capture).component.less",
    "*.cpp": "$(capture).hpp, $(capture).h, $(capture).hxx, $(capture).hh",
    "*.cs": "$(capture).*.cs, $(capture).cs.uid",
    "*.cshtml": "$(capture).cshtml.cs, $(capture).cshtml.css",
    "*.csproj": "*.config, *proj.user, appsettings.*, bundleconfig.json, packages.lock.json",
    "*.css": "$(capture).css.map, $(capture).*.css",
    "*.cxx": "$(capture).hpp, $(capture).h, $(capture).hxx, $(capture).hh",
    "*.dart": "$(capture).freezed.dart, $(capture).g.dart, $(capture).mapper.dart",
    "*.db": "*.db-shm, *.db-wal",
    "*.ex": "$(capture).html.eex, $(capture).html.heex, $(capture).html.leex",
    "*.fs": "$(capture).fs.js, $(capture).fs.js.map, $(capture).fs.jsx, $(capture).fs.ts, $(capture).fs.tsx, $(capture).fs.rs, $(capture).fs.php, $(capture).fs.dart",
    "*.fsproj": "*.config, *proj.user, appsettings.*, bundleconfig.json, packages.lock.json",
    "*.gd": "$(capture).gd.uid",
    "*.gdshader": "$(capture).gdshader.uid",
    "*.gdshaderinc": "$(capture).gdshaderinc.uid",
    "*.go": "$(capture)_test.go",
    "*.java": "$(capture).class",
    "*.js": "$(capture).js.map, $(capture).*.js, $(capture)_*.js, $(capture).d.ts, $(capture).d.ts.map, $(capture).js.flow",
    "*.jsx": "$(capture).js, $(capture).*.jsx, $(capture)_*.js, $(capture)_*.jsx, $(capture).css, $(capture).module.css, $(capture).less, $(capture).module.less, $(capture).module.less.d.ts, $(capture).scss, $(capture).module.scss, $(capture).module.scss.d.ts",
    "*.master": "$(capture).*.cs, $(capture).*.vb",
    "*.md": "$(capture).*",
    "*.mjs": "$(capture).mjs.map, $(capture).*.mjs, $(capture)_*.mjs",
    "*.module.ts": "$(capture).resolver.ts, $(capture).controller.ts, $(capture).service.ts",
    "*.mts": "$(capture).mts.map, $(capture).*.mts, $(capture)_*.mts",
    "*.proto": "$(capture).pb.go, $(capture).pb.micro.go",
    "*.pubxml": "$(capture).pubxml.user",
    "*.py": "$(capture).pyi",
    "*.razor": "$(capture).razor.cs, $(capture).razor.css, $(capture).razor.scss",
    "*.resx": "$(capture).*.resx, $(capture).designer.cs, $(capture).designer.vb",
    "*.tex": "$(capture).acn, $(capture).acr, $(capture).alg, $(capture).aux, $(capture).bbl, $(capture).bbl-SAVE-ERROR, $(capture).bcf, $(capture).bib, $(capture).blg, $(capture).fdb_latexmk, $(capture).fls, $(capture).glg, $(capture).glo, $(capture).gls, $(capture).idx, $(capture).ind, $(capture).ist, $(capture).lof, $(capture).log, $(capture).lot, $(capture).nav, $(capture).out, $(capture).run.xml, $(capture).snm, $(capture).synctex.gz, $(capture).toc, $(capture).xdv",
    "*.ts": "$(capture).js, $(capture).d.ts.map, $(capture).*.ts, $(capture)_*.js, $(capture)_*.ts",
    "*.tsx": "$(capture).ts, $(capture).*.ts, $(capture).*.tsx, $(capture)_*.ts, $(capture)_*.tsx, $(capture).css, $(capture).module.css, $(capture).less, $(capture).module.less, $(capture).module.less.d.ts, $(capture).scss, $(capture).module.scss, $(capture).module.scss.d.ts, $(capture).css.ts",
    "*.vbproj": "*.config, *proj.user, appsettings.*, bundleconfig.json, packages.lock.json",
    "*.vue": "$(capture).*.ts, $(capture).*.js, $(capture).story.vue",
    "*.w": "$(capture).*.w, I$(capture).w",
    "*.wat": "$(capture).wasm",
    "*.xaml": "$(capture).xaml.cs"
  },
  /*  */
  "extensions.autoUpdate": "on",
  "extensions.ignoreRecommendations": true,
  /*  */
  "files.autoSave": "onWindowChange",
  "files.encoding": "utf8",
  "files.eol": "\n",
  "files.exclude": {
    "**/__pycache__": true,
    "**/.git": true,
    "**/.next": true,
    "**/.nuxt": true,
    "**/.output": true,
    "**/coverage": true,
    "**/dist": true,
    "**/node_modules": true,
  },
  "files.hotExit": "onExitAndWindowClose",
  "files.insertFinalNewline": true,
  "files.simpleDialog.enable": true, /*  */
  "files.trimFinalNewlines": true,
  "files.trimTrailingWhitespace": true,
  "files.watcherExclude": {
    "**/._*": true, // macOS metadata files
    "**/.apdisk": true,
    "**/.AppleDouble": true,
    "**/.claude/**": true,
    "**/.DS_Store": true,
    "**/.eslintcache": true,
    "**/.git/**": true,
    "**/.localized": true,
    "**/.next/**": true,
    "**/.nuxt/**": true,
    "**/.nx": true,
    "**/.output/**": true,
    "**/.TemporaryItems": true,
    "**/.turbo": true,
    "**/.VolumeIcon.icns": true,
    "**/coverage/**": true,
    "**/dist/**": true,
    "**/node_modules/**": true,
    "**/out": true,
    "**/public/**": true,
    "**/Thumbs.db": true,
    "**/vendor/**": true,
    "**/venv/**": true,
    "**/__pycache__/**": true,
    "**/*.xml": true
  },
  /*  */
  // Safety guards — never allow bypassing hooks or force-pushing via the UI
  "git.allowForcePush": false,
  "git.allowNoVerifyCommit": false,
  "git.alwaysShowStagedChangesResourceGroup": true,
  // Background fetch every few minutes so branch status stays current without manual pulls
  "git.autofetch": true,
  // Stash dirty working tree automatically before rebase/checkout — mirrors rebase.autoStash in .gitconfig
  "git.autoStash": true,
  // Prevent accidental commits directly to long-lived branches
  "git.branchProtection": [
    "main",
    "master"
  ],
  // Generate random branch names (adjective-animal-color) when creating branches via the UI
  "git.branchRandomName.dictionary": [
    "adjectives",
    "animals",
    "colors"
  ],
  "git.branchRandomName.enable": true,
  // No confirmation on sync — intentional: postCommitCommand auto-pushes after every commit.
  // Set to true if you want a prompt before each push.
  "git.confirmSync": false,
  // Disable per-file git decorations in the explorer — reduces visual noise
  "git.decorations.enabled": false,
  // Submodule scanning disabled for performance; detectSubmodulesLimit is moot when false
  "git.detectSubmodules": false,
  "git.detectSubmodulesLimit": 1,
  // Show worktrees in the Source Control panel
  "git.detectWorktrees": true,
  // SSH commit signing — mirrors commit.gpgsign + gpg.format = ssh in .gitconfig
  "git.enableCommitSigning": true,
  // Commit all staged changes when the commit message box is empty (no need to stage first)
  "git.enableSmartCommit": true,
  // "git.enableStatusBarSync": false,
  // Fetch from remote before pulling so the ahead/behind count is accurate
  "git.fetchOnPull": true,
  // Push tags alongside commits on sync — mirrors push.followTags in .gitconfig
  "git.followTagsWhenSync": true,
  "git.inputValidation": true,
  // Use VS Code's built-in 3-way merge editor — mirrors merge.tool = code in .gitconfig
  "git.mergeEditor": true,
  "git.openRepositoryInParentFolders": "never",
  // Auto-push (sync) after every commit. Combined with confirmSync: false this is silent.
  // Remove this line if you prefer to push manually.
  "git.postCommitCommand": "sync",
  // Delete stale remote-tracking branches on fetch — mirrors fetch.prune in .gitconfig
  "git.pruneOnFetch": true,
  // Fetch the target branch before checkout so you start with up-to-date code
  "git.pullBeforeCheckout": true,
  // Rebase instead of merge when syncing — mirrors pull.rebase = merges in .gitconfig
  "git.rebaseWhenSync": true,
  // Replace local tags with remote ones on pull to avoid stale tag refs
  "git.replaceTagsWhenPull": true,
  // Hide the sync action button in the status bar (postCommitCommand handles sync automatically)
  "git.showActionButton": {
    "sync": false,
  },
  "git.inputValidationLength": 0,
  "git.inputValidationSubjectLength": 72,
  "git.showPushSuccessNotification": true,
  "git.terminalGitEditor": true,
  "git.timeline.showUncommitted": true,
  "git.untrackedChanges": "separate",
  "git.useCommitInputAsStashMessage": true,
  /*  */
  "merge-conflict.autoNavigateNextConflict.enabled": true,
  /*  */
  "problems.autoReveal": false,
  /*  */
  "search.exclude": {
    "**/.cache": true,
    "**/.claude": true,
    "**/.eslintcache": true,
    "**/.git": true,
    "**/.next/.cache": true,
    "**/.nuxt": true,
    "**/.nx": true,
    "**/.output": true,
    "**/.turbo": true,
    "**/.venv": true,
    "**/*-lock.yaml": true,
    "**/*.lock": true,
    "**/*.xml": true,
    "**/build": true,
    "**/dist": true,
    "**/node_modules": true,
  },
  "search.followSymlinks": false, /*  */
  "search.mode": "newEditor",
  "search.smartCase": true,
  "search.useIgnoreFiles": true,
  /*  */
  "security.workspace.trust.untrustedFiles": "open",
  /*  */
  "scm.defaultViewMode": "tree",
  "scm.diffDecorations": "gutter",
  "scm.diffDecorationsGutterVisibility": "hover",
  "scm.diffDecorationsGutterWidth": 1,
  "scm.graph.badges": "filter",
  "scm.repositories.selectionMode": "single",
  /*  */
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "underline",
  "terminal.integrated.defaultProfile.linux": "zsh",
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.enableMultiLinePasteWarning": "never",
  "terminal.integrated.enableVisualBell": false,
  "terminal.integrated.fontFamily": "Maple Mono NF, Menlo, Monaco, monospace",
  "terminal.integrated.fontLigatures.enabled": true,
  "terminal.integrated.fontSize": 12,
  "terminal.integrated.gpuAcceleration": "on",
  "terminal.integrated.initialHint": false,
  "terminal.integrated.mouseWheelScrollSensitivity": 3,
  "terminal.integrated.persistentSessionReviveProcess": "onExitAndWindowClose",
  "terminal.integrated.persistentSessionScrollback": 3000,
  "terminal.integrated.rescaleOverlappingGlyphs": true,
  "terminal.integrated.scrollback": 3000,
  "terminal.integrated.shellIntegration.enabled": true,
  "terminal.integrated.shellIntegration.history": 3000,
  "terminal.integrated.smoothScrolling": true,
  "terminal.integrated.stickyScroll.enabled": false,
  "terminal.integrated.tabs.enableAnimation": false,
  "terminal.integrated.tabs.focusMode": "singleClick",
  /*  */
  "update.mode": "default",
  /*  */
  "window.autoDetectColorScheme": true,
  "window.commandCenter": false,
  "window.dialogStyle": "custom",
  "window.restoreWindows": "none",
  "window.title": "${rootName}",
  /*  */
  "workbench.browser.showInTitleBar": true,
  "workbench.editor.closeOnFileDelete": true,
  "workbench.editor.empty.hint": "hidden",
  "workbench.editor.enablePreview": false,
  "workbench.editor.highlightModifiedTabs": true,
  "workbench.editor.historyBasedLanguageDetection": false,
  "workbench.editor.limit.enabled": true,
  "workbench.editor.limit.perEditorGroup": true,
  "workbench.editor.limit.value": 12,
  "workbench.editor.pinnedTabSizing": "compact",
  "workbench.editor.scrollToSwitchTabs": true,
  "workbench.editor.sharedViewState": true,
  "workbench.editor.tabActionCloseVisibility": false,
  "workbench.fontAliasing": "antialiased",
  "workbench.iconTheme": "flow-deep",
  "workbench.layoutControl.enabled": false,
  "workbench.list.smoothScrolling": true,
  "workbench.panel.showLabels": false,
  "workbench.preferredDarkColorTheme": "Maple Dark",
  "workbench.preferredLightColorTheme": "Maple Light",
  "workbench.productIconTheme": "icons-carbon",
  "workbench.reduceMotion": "auto",
  "workbench.secondarySideBar.defaultVisibility": "hidden",
  "workbench.settings.alwaysShowAdvancedSettings": true,
  "workbench.sideBar.location": "right",
  "workbench.startupEditor": "none",
  "workbench.tree.renderIndentGuides": "none",
  /*  */
  "cSpell.allowCompoundWords": true,
  /*  */
  "errorLens.enabledDiagnosticLevels": [
    "warning",
    "error"
  ],
  "errorLens.excludeBySource": [
    "cSpell",
    "eslint"
  ],
  "errorLens.fontStyleItalic": true,
  "errorLens.gutterIconsEnabled": true,
  "errorLens.scrollbarHackEnabled": true,
  /*  */
  "fileNestingUpdater.promptOnAutoUpdate": false,
  /*  */
  "flow-icons.hidesExplorerArrows": true,
  /*  */
  "claudeCode.allowDangerouslySkipPermissions": true,
  "claudeCode.preferredLocation": "panel",
  /*  */
}
```
</details>

---

## FAQ

**Q: Does this work on Apple Silicon (M-series) Macs?**
A: Yes, first-class. Homebrew at `/opt/homebrew` with native arm64 bottles; git tuned for the core count. No Rosetta needed.

**Q: Does this work on Linux or WSL?**
A: No — this config targets macOS only. Fork an older revision (pre-macOS-only) if you need Linux/WSL support.

**Q: Can I fork this and customize it?**
A: Yes — that's the recommendation. Put machine-specific bits in `modules/local.zsh`, structural changes in your fork.

**Q: Does this include a prompt theme?**
A: Yes, [Starship](https://starship.rs/). Customize in `~/.config/starship.toml`.

**Q: Can I use this with Oh My Zsh or Prezto?**
A: No, it's built around Zinit. Fork and adapt if you prefer another manager.

**Q: Is this security-reviewed?**
A: It's a personal config with sane practices (no `eval` of remote content, confirmation prompts before deletion, gitignored secrets file), but review it yourself before using in sensitive environments.

---

## Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [Starship Prompt](https://starship.rs/)
- [fzf — Fuzzy Finder](https://github.com/junegunn/fzf)

---

## License

MIT — Use, modify, and share freely.

**Questions?** Open an [issue](https://github.com/nandordudas/zsh-config/issues) on GitHub.
