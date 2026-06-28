#!/usr/bin/env bash
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

if [ -n "$batt" ]; then
  bat_seg="#[fg=#6c7086] │ #[fg=#f9e2af]BAT ${batt}"
fi

printf "#[fg=#a6e3a1]GPU %s#[fg=#6c7086] │ #[fg=#89b4fa]CPU %s#[fg=#6c7086] │ #[fg=#cdd6f4]MEM %s%s" \
  "$gpu" "$cpu" "$mem" "$bat_seg"
