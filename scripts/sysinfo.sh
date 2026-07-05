#!/usr/bin/env bash
# One-line GPU/CPU/MEM/BAT summary. Formerly a tmux status-bar segment (hence
# the 5s-refresh comment below); herdr has no scriptable status-bar hook to
# feed, so this now runs standalone via the `sysinfo` alias.
#
# GPU via IOKit IOAccelerator PerformanceStatistics — same source btop uses, no sudo needed
gpu=$(ioreg -r -d 2 -c IOAccelerator 2>/dev/null \
  | grep '"PerformanceStatistics"' \
  | grep -o '"Device Utilization %"=[0-9]*' \
  | head -1 \
  | awk -F'=' '{print $2"%"}')
[ -z "$gpu" ] && gpu="—"

# CPU — top -l 1 gives the most-recent interval sample, ~0.3s, fine at 5s refresh
cpu=$(top -l 1 -n 0 | awk '/CPU usage/ {gsub(/%/,""); printf "%.0f%%", $3+$5}')

# Memory — instant via vm_stat
mem=$(vm_stat | awk '
  /Pages active/              { a = int($3) }
  /Pages wired down/          { w = int($4) }
  /occupied by compressor/    { c = int($5) }
  END { printf "%.1fG", (a + w + c) * 4096 / 1073741824 }
')

# Battery — empty on desktops/VMs, suppressed cleanly
batt=$(pmset -g batt 2>/dev/null \
  | awk -F'[;\t ]' '/InternalBattery/{for(i=1;i<=NF;i++) if($i~/^[0-9]+%$/) {print $i; exit}}')

[ -n "$batt" ] && bat_seg=" │ BAT ${batt}"

printf "GPU %s │ CPU %s │ MEM %s%s\n" "$gpu" "$cpu" "$mem" "$bat_seg"
