#!/usr/bin/env bash
# disk-check.sh - warn about filesystems that are running low on space.
#
# Exits 1 (and prints the offenders) if any mounted filesystem is at or above
# the usage threshold, so it is useful straight from cron or a monitoring hook.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/toolkit.sh
source "$SCRIPT_DIR/../lib/toolkit.sh"

threshold=90

usage() {
    cat <<EOF
usage: disk-check.sh [-t THRESHOLD]
  -t THRESHOLD   warn at or above this use percentage (default: ${threshold})
EOF
}

while getopts ":t:h" opt; do
    case "$opt" in
        t) threshold="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

over="$(df -P | tk_df_over "$threshold")"
if [[ -n "$over" ]]; then
    echo "Filesystems at or above ${threshold}% usage:"
    echo "$over" | awk '{ print "  " $0 }'
    exit 1
fi

echo "All filesystems below ${threshold}% usage."
