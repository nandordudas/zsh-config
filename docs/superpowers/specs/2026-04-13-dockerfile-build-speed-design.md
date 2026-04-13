# Dockerfile Build Speed — Design

**Date:** 2026-04-13
**Goal:** Significantly reduce both cold and incremental Docker build times.

## Problem

The current Dockerfile has three main performance issues:

1. **5 GitHub API calls at runtime** — `delta`, `dust`, `procs`, `direnv`, `fastfetch` all hit `api.github.com` to resolve the latest version on every build. These are sequential, uncacheable network round trips.
2. **Sequential binary downloads** — each of the 7 tool downloads is a separate `RUN` layer, executed one after another.
3. **`apt-get upgrade -y`** — upgrades all system packages on every build, unnecessary for testing.
4. **Fragmented tail config steps** — three tiny `RUN` steps (zshenv, touch, symlink) create extra layers for no benefit.

## Approach

**Option A: Pin versions + parallel downloads + merge layers**

No registry, no base image split — single self-contained Dockerfile.

## Design

### 1. Pin tool versions as ARGs

Declare all resolved versions at the top of the Dockerfile:

```dockerfile
ARG DELTA_VER=2.4.1
ARG DUST_VER=1.1.2
ARG PROCS_VER=0.14.8
ARG DIRENV_VER=v2.35.0
ARG FASTFETCH_VER=2.43.0
ARG GO_VER=go1.24.2
```

- Eliminates 5 GitHub API calls per build
- Makes versions explicit and reviewable in git history
- Cache is stable: the download URL only changes when the ARG changes
- To update: change the ARG value, rebuild

eza, fnm, and starship use `/latest/download/` URLs that resolve via redirect without an API call — these stay as-is.

### 2. Remove `apt-get upgrade -y`

Delete the `apt-get upgrade -y` line from the system packages step. The base image packages are sufficient for testing purposes. This saves time on every build.

### 3. Merge binary downloads into one parallel RUN

Combine all 7 tool download steps into a single `RUN` block. Each download is launched as a background job (`&`), and `wait` blocks until all complete:

```dockerfile
RUN set -e && \
    # download tool A &
    # download tool B &
    # ... all tools ...
    wait
```

All downloads happen concurrently. Total time approaches the slowest single download rather than the sum of all downloads.

### 4. Merge tail config steps

The three `RUN` steps at the end (write `.zshenv`, `touch local.zsh`, create tmux symlink) are merged into one layer. No behavior change.

### Layer Order (unchanged)

```
apt packages  →  binary tools  →  Node  →  Go  →  config COPY  →  test
```

This order is already optimal: config file changes only invalidate the last two layers (COPY + test), leaving all tool installation layers cached.

## Expected Impact

| Scenario | Before | After |
|---|---|---|
| Cold build | Slow (sequential downloads + 5 API calls) | Faster (parallel downloads, no API calls) |
| Incremental (config change) | Rebuilds from COPY onward | Same — already optimal layer order |
| Incremental (version bump) | Same as cold | Change one ARG, re-downloads that tool only |

## Out of Scope

- Pre-baked base image (Option B) — adds operational overhead, deferred
- Switching base image from `ubuntu:24.04`
- Changing which tools are installed
