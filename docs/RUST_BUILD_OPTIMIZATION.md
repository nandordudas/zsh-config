# Rust Package Build Optimization

## Problem Statement

Building Rust packages from source takes **5-10 minutes** during every `upgrade()` call, even when packages haven't been updated. This is inefficient and wastes development time.

### Root Cause: Unconditional Rebuilds

**Before (modules/functions.zsh:166)**:
```bash
cargo install-update -a
```

This command **always rebuilds all cargo-installed packages**, regardless of whether newer versions exist. It:
- Downloads the latest source code for every package
- Compiles from scratch (Rust compile time is slow)
- Repeats even on subsequent upgrade calls the same day
- Takes 5-10 minutes every single time

---

## Issues Detected

### 1. **Unnecessary Full Rebuilds**
- No intelligence to check if updates are actually available first
- `cargo install-update -a` is a brute-force approach
- Wastes developer time on every system upgrade

### 2. **Inconsistent Strategy Across Stack**
- **Dockerfile** (smart): Downloads pre-built binaries directly from GitHub releases
  - Example: `eza`, `delta`, `starship`, `direnv`, `fnm`
  - Fast: parallel downloads, no compilation
- **upgrade() function** (inefficient): Rebuilds Rust tools from source
  - Example: `du-dust`, `procs`, `cargo-update`, `eza`, `git-delta`, `fnm`
  - Slow: full recompilation every time

### 3. **No Version Caching**
- Manifest of installed versions is never stored
- Each upgrade cycle must query cargo registry without context
- Missing opportunity to cache package metadata

### 4. **No Early Exit Logic**
- If packages are already up-to-date, build time is wasted anyway
- No way to skip rebuild when no updates exist

### 5. **Bad Error Handling**
- If `cargo install-update -a` fails, `set -e` will fail the entire upgrade job
- No fallback mechanism or graceful degradation

---

## Solution: Smart Cargo Package Manager

### Implementation: `_cargo_smart_update()` Function

**Location**: `modules/functions.zsh:87-148`

The new function:

1. **Manifest Tracking** (`cargo-manifest.json`)
   - Stores installed package versions in `$XDG_CACHE_HOME/zsh/`
   - Invalidated after successful update
   - Allows version comparison on next run

2. **Dry-Run Check** 
   - Uses `cargo install-update -a --dry-run` to detect updates without rebuilding
   - Analyzes output for "Updating" keyword
   - Skips full build if no updates found

3. **Intelligent Decision**
   ```
   ✓ Packages up-to-date          → Skip rebuild (1 second)
   ↻ Updates detected             → Full rebuild (5-10 minutes)
   ⚠ cargo-update check failed    → Safe skip (error handling)
   ```

4. **Benefits**
   - First run: Creates manifest, performs initial build
   - Subsequent runs: ~1 second check, skips if no updates
   - Only rebuilds when updates are actually available
   - Graceful fallback if check fails

---

## Expected Performance Improvement

### Before Optimization
```
upgrade() → rust job → cargo install-update -a (full rebuild)
└─ Time: 5-10 minutes EVERY call
```

### After Optimization  
```
upgrade() → rust job → _cargo_smart_update()
├─ Check 1: manifest exists?
│  ├─ No → Build + create manifest (first-time: 5-10 min)
│  └─ Yes → Continue to check 2
├─ Check 2: cargo install-update -a --dry-run
│  ├─ Updates found → Full rebuild (5-10 min)
│  └─ No updates → Skip rebuild, return (~1 sec)
└─ Total time: 
   - First call: 5-10 minutes
   - Subsequent calls with no updates: ~1 second
   - Subsequent calls with updates: 5-10 minutes
```

### Realistic Scenario
- **Morning upgrade**: Check finds no updates → 1 second
- **Later in week**: Check finds Node minor version update → Full rebuild once
- **Rest of week**: Check finds no updates → 1 second per call

**Estimated savings**: ~15-45 minutes per week on a typical development workflow.

---

## Monitored Packages

The function tracks these cargo-installed binaries:
- `du-dust` - Disk usage analyzer
- `procs` - Modern `ps` replacement  
- `eza` - Modern `ls` replacement
- `git-delta` - Git pager
- `cargo-update` - Self-updating
- `fnm` - Node version manager

---

## Cache File Location

- **Path**: `$XDG_CACHE_HOME/zsh/cargo-manifest.json`
- **Default**: `~/.cache/zsh/cargo-manifest.json`
- **Purpose**: Stores installed package versions
- **Auto-invalidation**: Deleted after successful update
- **Safe to delete**: Manually removes it; next upgrade rebuilds with new manifest

### Sample manifest (after first build):
```json
{
  "du-dust": "0.8.6",
  "procs": "0.14.11",
  "eza": "0.18.13",
  "git-delta": "0.19.2",
  "cargo-update": "2.11.2",
  "fnm": "1.35.1"
}
```

---

## Code Quality Issues Fixed

1. ✅ **Added intelligent version checking** before rebuild
2. ✅ **Added early exit logic** when no updates exist
3. ✅ **Added error handling** for failed checks
4. ✅ **Added progress feedback** with status messages
5. ✅ **Added manifest caching** to avoid redundant checks
6. ✅ **Maintained backward compatibility** with existing upgrade flow

---

## Testing the Optimization

### First run (creates manifest, rebuilds):
```bash
upgrade
# Output: ↻ Rebuilding cargo packages (5-10 min, first-time or updates detected)...
# [5-10 minutes later]
# Log: Successfully built all packages
```

### Subsequent run (no updates available):
```bash
upgrade
# Output in rust section:
# ✓ Cargo packages up-to-date (checked 14:32:05)
# [rust job completes in ~1 second]
```

### After upstream release (updates available):
```bash
upgrade
# Output:
# ↻ Rebuilding cargo packages (5-10 min, first-time or updates detected)...
# [5-10 minutes later]
# [Packages updated to latest versions]
```

---

## Backward Compatibility

- ✅ No breaking changes to `upgrade()` function interface
- ✅ No new dependencies added
- ✅ Graceful fallback if cargo-update is missing
- ✅ Works with existing PATH and cargo setup
- ✅ Manual cache clear still available: `rm ~/.cache/zsh/cargo-manifest.json`

---

## Future Improvements

Potential enhancements (not implemented to avoid over-engineering):

1. **Smart rebuild strategy**: Download pre-built binaries from GitHub releases instead of rebuilding
   - Would reduce 5-10 min to ~30 seconds
   - Requires managing version mappings and binary sources
   
2. **Per-package decisions**: Some packages update more frequently than others
   - Could track individual update intervals
   
3. **Parallel builds**: Use `cargo build -j N` for multi-crate projects
   - Minimal benefit for single cargo installs
   
4. **Background updates**: Rebuild in background, skip if recent build
   - Would require job locking to prevent conflicts

These are intentionally not implemented to keep the solution focused and maintainable.

---

## References

- `cargo-update` docs: https://docs.rs/cargo-update/
- Rust compilation times: https://nnethercote.github.io/perf-book/compile-times.html
- Original code: `modules/functions.zsh:160-171`
