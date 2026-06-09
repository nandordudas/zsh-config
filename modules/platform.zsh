# modules/platform.zsh
# OS detection and portable command resolution. Sourced first so every other
# module can rely on these variables instead of hardcoding platform names.
#
# Exports:
#   IS_MACOS / IS_LINUX  — 1 or 0
#   IS_WSL               — set in .zprofile; fallback detection here
#   ZSH_BAT_CMD          — "bat" (macOS/most) or "batcat" (Debian/Ubuntu)
#   ZSH_FD_CMD           — "fd" (macOS/most) or "fdfind" (Debian/Ubuntu)

case "$OSTYPE" in
  darwin*) export IS_MACOS=1 IS_LINUX=0 ;;
  linux*)  export IS_MACOS=0 IS_LINUX=1 ;;
  *)       export IS_MACOS=0 IS_LINUX=0 ;;
esac

# Fallback WSL detection for non-login shells where .zprofile didn't run
if [[ -z "$IS_WSL" ]]; then
  if (( IS_LINUX )) && [[ -r /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    export IS_WSL=1
  else
    export IS_WSL=0
  fi
fi

# Debian/Ubuntu rename bat→batcat and fd→fdfind; resolve once here.
if (( $+commands[bat] )); then
  export ZSH_BAT_CMD=bat
elif (( $+commands[batcat] )); then
  export ZSH_BAT_CMD=batcat
else
  export ZSH_BAT_CMD=cat
fi

if (( $+commands[fd] )); then
  export ZSH_FD_CMD=fd
elif (( $+commands[fdfind] )); then
  export ZSH_FD_CMD=fdfind
else
  export ZSH_FD_CMD=find
fi
