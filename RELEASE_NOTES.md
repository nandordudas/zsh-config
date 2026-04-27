# 🎉 v1.1.0 Released!

## What's New

### ⚡ Performance Boost: 3-5x Faster Upgrades

```bash
# Before v1.1.0
$ upgrade
↻ Rebuilding rust packages...
[5-10 minutes later...]

# After v1.1.0  
$ upgrade
↻ Trying prebuilt binaries first...
[30-60 seconds later... or 1 second if no updates!]
```

**How it works:**
1. **Smart dry-run check** — Detects if any packages need updating (~1 second)
   - If nothing to update: ✅ Done in 1 second!
   - If updates found: Proceed to step 2
2. **Parallel prebuilt download** — Downloads binaries from GitHub (30-60s)
3. **Automatic fallback** — Falls back to source build if prebuilts unavailable

---

## 🐛 Bug Fixes

**Variable naming consistency:**
- Fixed `GIT_HUB_USER` → `GITHUB_USER`
- Fixed `BIT_BUCKET_USER` → `BITBUCKET_USER`
- Updated directory paths: `git_hub/` → `github/`, `bit_bucket/` → `bitbucket/`

**Code quality improvements:**
- Fixed undefined color variables in upgrade function
- Added cache directory permissions (security: chmod 700)
- Added input validation to all user-facing functions
- Fixed sudo validation to prevent hangs in non-TTY environments
- Better error messages with actionable solutions

**Docker improvements:**
- Added SHELL directive for bash array syntax support
- Dockerfile now builds reliably

---

## ♻️ Code Refactoring

**Better maintainability:**
- Extracted `_ztool_init()` helper (saves ~60 lines of boilerplate)
- Centralized XDG path handling with `_zcache_dir()` and `_zdata_dir()`
- Centralized color code constants (`_COLOR_*`)
- Created `versions.env` for easy version updates
- Created `Makefile` for Docker builds

---

## ✅ No Breaking Changes

This is a **100% backward-compatible** release. Your existing setup will keep working without any changes.

**But if you want to modernize**, see [MIGRATION_v1.1.0.md](MIGRATION_v1.1.0.md) for a quick optional update.

---

## 🚀 How to Update

### Already have the repo cloned?

```bash
cd ~/.config/zsh
git pull origin main
```

That's it! You'll get:
- ✨ 3-5x faster upgrades (automatic, no config needed)
- 🔒 Security improvements (automatic)
- 📚 Updated documentation (automatic)

### First time installing?

```bash
npx tiged nandordudas/zsh-config ~/.config/zsh --disable-cache
# Follow the installation steps in README.md
```

---

## 📊 Release Stats

- **7 bug fixes** (variables, colors, Docker, security, validation)
- **5 refactorings** (helpers, consolidation, maintainability)
- **30 unit tests passing** ✅
- **Docker build validated** ✅
- **Zero breaking changes** ✅

---

## 💡 Pro Tip: Use Claude Code to Migrate

If you want Claude to automatically handle any optional updates:

```bash
cd ~/.config/zsh
claude  # Opens Claude Code in the repo
```

Then ask:
> "Help me update to v1.1.0. Check my config and update variable names if needed."

Claude will:
- ✅ Review your setup
- ✅ Show you what changed
- ✅ Apply updates safely
- ✅ Verify everything works

---

## 📖 What's Included

**New files:**
- `versions.env` — Centralized tool versions
- `Makefile` — Docker build automation
- `MIGRATION_v1.1.0.md` — Migration guide for existing users
- `RELEASE_NOTES.md` — This file!

**Updated files:**
- `modules/aliases.zsh` — Fixed variable names
- `modules/functions.zsh` — Better validation, fixed colors
- `modules/tools.zsh` — Cache security, helper functions
- `Dockerfile` — Shell directive, better documentation
- `README.md` — Updated with release notice
- `docs/aliases.md` — Updated documentation
- `docs/functions.md` — Updated documentation

---

## 🎯 Next Steps

1. **Update**: `git pull origin main`
2. **Verify**: `time zsh -i -c exit` (should be <100ms)
3. **Test**: Run `upgrade` (watch it complete in 1-2 minutes!)
4. **Explore**: Check out `MIGRATION_v1.1.0.md` if interested in optional updates

---

## ❓ Questions?

- **How do I revert?** `git checkout v1.0.0` (but you won't need to!)
- **Will my shell break?** No. Fully backward compatible.
- **Do I need to update my config?** Not required. Only if you want cleaner variable names.
- **Can Claude Code help me?** Yes! Run `claude` from the repo root.

---

## 📞 Support

- 📖 **Full changelog**: `git log v1.0.0..v1.1.0 --oneline`
- 🔗 **GitHub release**: https://github.com/nandordudas/zsh-config/releases/tag/v1.1.0
- 📚 **Migration guide**: [MIGRATION_v1.1.0.md](MIGRATION_v1.1.0.md)
- 🤖 **Claude Code**: Run `claude` from the repo root for AI-powered help

---

**Enjoy the performance boost! 🚀**

Your shell is now faster, more robust, and better maintained.

Happy zsh-ing! 🐚
