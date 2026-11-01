#!/usr/bin/env bash
# sysinfo.sh - a one-screen health summary of the machine.
#
# Pulls together hostname, uptime, load, memory and disk usage. Everything is
# read-only; it is handy as a login banner or a quick "how is this box doing".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/toolkit.sh
source "$SCRIPT_DIR/../lib/toolkit.sh"

line() { printf '%-14s %s\n' "$1" "$2"; }

echo "== system info =="
line "Host:" "$(hostname)"
line "Kernel:" "$(uname -sr)"

if command -v uptime >/dev/null 2>&1; then
    line "Uptime:" "$(uptime -p 2>/dev/null || uptime)"
fi

# Memory, from /proc/meminfo when available (Linux).
if [[ -r /proc/meminfo ]]; then
    total_kb="$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)"
    avail_kb="$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo)"
    used_kb=$((total_kb - avail_kb))
    line "Memory used:" "$(tk_bytes_human "$used_kb") / $(tk_bytes_human "$total_kb")"
fi

echo
echo "== disk usage =="
df -P -h | awk 'NR == 1 || $1 !~ /^(tmpfs|devtmpfs|overlay)$/'

echo
echo "== filesystems over 90% =="
over="$(df -P | tk_df_over 90)"
if [[ -n "$over" ]]; then
    echo "$over" | awk '{ print "  " $0 }'
else
    echo "  (none)"
fi
