# modules/options.zsh
# Core zsh setopt declarations. No external commands, no sourcing.

# =============================================================================
# HISTORY
# =============================================================================
setopt HIST_IGNORE_DUPS         # Don't record consecutive duplicates
setopt HIST_IGNORE_SPACE        # Don't record lines starting with a space
setopt HIST_REDUCE_BLANKS       # Strip leading/trailing blanks from history entries
setopt HIST_EXPIRE_DUPS_FIRST   # When history is full, remove duplicates first
setopt HIST_VERIFY              # Expand history to command line before executing
setopt HIST_FIND_NO_DUPS        # Skip duplicate entries when searching history
setopt EXTENDED_HISTORY         # Write :start:elapsed;command format to history file
setopt SHARE_HISTORY            # Import new history entries from other sessions
setopt INC_APPEND_HISTORY_TIME  # Write immediately with timestamps
# Note: SHARE_HISTORY + INC_APPEND_HISTORY_TIME supersede the old trio of
#       APPEND_HISTORY + INC_APPEND_HISTORY + SHARE_HISTORY.

# =============================================================================
# DIRECTORY NAVIGATION
# =============================================================================
setopt AUTO_CD           # Type a directory name to cd into it
setopt AUTO_PUSHD        # cd pushes the old directory onto the dir stack
setopt PUSHD_IGNORE_DUPS # Don't push duplicate directories
setopt CDABLE_VARS       # Allow cd to expand named directories

# =============================================================================
# GLOBBING
# =============================================================================
setopt EXTENDED_GLOB     # Enable ^pattern, (#i)pattern, etc.
setopt NO_NOMATCH        # Pass unmatched globs to the command unchanged
setopt GLOB_DOTS         # Include dotfiles in glob patterns

# =============================================================================
# JOB CONTROL
# =============================================================================
setopt NO_BEEP           # Silence terminal bell
setopt NOTIFY            # Report job status as soon as it changes
setopt BG_NICE           # Run background jobs at lower priority

# =============================================================================
# MISCELLANEOUS
# =============================================================================
setopt INTERACTIVE_COMMENTS  # Allow # comments in interactive mode
setopt RC_QUOTES             # Allow '' inside single-quoted strings to embed '
setopt COMBINING_CHARS       # Correctly handle combining Unicode characters (WSL)
