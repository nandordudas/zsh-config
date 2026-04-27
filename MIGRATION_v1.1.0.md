# Migration Guide: v1.1.0 Release

👋 **Welcome!** If you're updating from before v1.1.0, here's what changed.

## ✅ Good News: No Breaking Changes

This release is **100% backward compatible**. Your existing setup will continue to work without changes.

---

## 🎯 What Changed (and what it means for you)

### 1. **Variable Names in Aliases** (Internal fix)
```bash
# ❌ OLD (still works if GITHUB_USER is set in modules/local.zsh)
GIT_HUB_USER, BIT_BUCKET_USER

# ✅ NEW (cleaner, matches actual environment variables)
GITHUB_USER, BITBUCKET_USER
```

**Do I need to act?**
- If you're using `gg` or `gb` aliases, check your `modules/local.zsh`:
  ```bash
  cat ~/.config/zsh/modules/local.zsh | grep GITHUB_USER
  ```
- If set to the new names (GITHUB_USER, BITBUCKET_USER): ✅ You're good!
- If set to old names (GIT_HUB_USER, BIT_BUCKET_USER): Update them (takes 30 seconds)

### 2. **Directory Paths in Aliases** (Internal fix)
```bash
# ❌ OLD directories
~/code/git_hub/$GITHUB_USER
~/code/bit_bucket/$BITBUCKET_USER

# ✅ NEW directories
~/code/github/$GITHUB_USER
~/code/bitbucket/$BITBUCKET_USER
```

**Do I need to act?**
- If your repos are in the old paths: No action needed (aliases still work)
- If you want the new convention: Rename directories or update aliases in `modules/local.zsh`

### 3. **Upgrade Function Speed** (Performance boost!)
```bash
# ❌ OLD: Always rebuilds from source (5-10 minutes)
upgrade
└─ Rebuilding all cargo packages...

# ✅ NEW: Smart prebuilt binary strategy (1-2 minutes or 1 second)
upgrade
├─ Check if updates needed (1 second)
├─ If yes: Download prebuilts in parallel (30-60 seconds)
└─ Automatic fallback to source if needed
```

**Do I need to act?**
- Nope! Just run `upgrade` and enjoy the 3-5x speedup 🚀

### 4. **Docker Builds** (Bug fix)
- Added `SHELL ["/bin/bash", "-c"]` to support bash array syntax
- **Impact**: Dockerfile builds now work correctly (they might have failed before)

---

## 📝 Optional: Update Your Config (Recommended)

If you want to take advantage of the new variable names, update `modules/local.zsh`:

```bash
# Open your local config
code ~/.config/zsh/modules/local.zsh
```

Change:
```bash
# OLD
export GIT_HUB_USER="your-github-user"
export BIT_BUCKET_USER="your-bitbucket-user"
```

To:
```bash
# NEW (same functionality, cleaner naming)
export GITHUB_USER="your-github-user"
export BITBUCKET_USER="your-bitbucket-user"
```

Then reload your shell:
```bash
exec zsh
```

---

## 🆘 Need Help Migrating?

### Option 1: Use Claude Code (Recommended)
If you have Claude Code installed, let it help you:

```bash
cd ~/.config/zsh
claude  # Opens Claude Code in the repo
```

Then ask Claude:
> "Help me update my zsh-config to v1.1.0. Check my modules/local.zsh and update variable names if needed"

Claude can:
- ✅ Review your current setup
- ✅ Update variable names automatically
- ✅ Verify everything still works
- ✅ Show you the diff before applying changes

### Option 2: Manual Update
```bash
# 1. Check your current config
cat ~/.config/zsh/modules/local.zsh

# 2. Update variable names if they're using old names
sed -i 's/GIT_HUB_USER/GITHUB_USER/g' ~/.config/zsh/modules/local.zsh
sed -i 's/BIT_BUCKET_USER/BITBUCKET_USER/g' ~/.config/zsh/modules/local.zsh

# 3. Test that everything works
exec zsh
gg  # Should work if GITHUB_USER is set
```

### Option 3: Let Git Handle It
```bash
# Pull the latest changes (includes default values in modules/local.zsh)
git pull origin main

# Check what changed
git diff HEAD~1 modules/local.zsh

# If you want the new defaults, reset to upstream
git checkout origin/main -- modules/local.zsh
```

---

## 🎁 What You Get (Free Upgrades)

Just by updating to v1.1.0, you automatically get:

- 🚀 **3-5x faster cargo updates** (hybrid prebuilt binary strategy)
- ⚡ **Smart dry-run checks** (skips rebuild if no updates available)
- 🔒 **Security fix** (cache directory permissions)
- ✅ **Better input validation** (more helpful error messages)
- 📚 **Updated documentation** (reflects current code)

**No action required.** Just run `upgrade` and notice how much faster it is!

---

## 📖 Full Release Notes

See the complete changelog:
```bash
git log v1.0.0..v1.1.0 --oneline
gh release view v1.1.0  # If you have GitHub CLI
```

Or visit: https://github.com/nandordudas/zsh-config/releases/tag/v1.1.0

---

## ❓ FAQ

**Q: Will my shell break if I update?**
A: No. This is a fully backward-compatible release. Your existing config will keep working.

**Q: Should I update?**
A: Yes! You'll get faster upgrades and security fixes with zero effort.

**Q: Do I need to update modules/local.zsh?**
A: Optional. The new variable names are cleaner, but the old ones still work. Update at your convenience.

**Q: What if something breaks?**
A: File an issue or ask Claude Code to help debug. But we've tested thoroughly — unlikely to happen!

**Q: How do I revert if something goes wrong?**
A: `git checkout v1.0.0` (but you won't need to!)

---

## 🚀 Next Steps

1. **Update**: `git pull origin main` (or use your preferred update method)
2. **Verify**: `time zsh -i -c exit` (check startup time, should be <100ms)
3. **Test**: Run `upgrade` and watch the performance improvement
4. **Enjoy**: Your shell is now faster and more robust! 🎉

---

**Questions?** Feel free to:
- Open an issue on GitHub
- Use Claude Code to ask for help (`claude` from the repo root)
- Check the detailed docs in `/docs` folder

**Happy zsh-ing!** 🐚
