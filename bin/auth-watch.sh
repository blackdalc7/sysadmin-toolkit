#!/usr/bin/env bash
# auth-watch.sh - summarise failed SSH logins from an auth log.
#
# A small defensive-monitoring helper: it counts sshd "Failed password"
# attempts per source IP and lists the ones over a threshold, so repeated
# brute-force sources stand out. It only reads a log file you point it at.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/toolkit.sh
source "$SCRIPT_DIR/../lib/toolkit.sh"

min=5
logfile="/var/log/auth.log"

usage() {
    cat <<EOF
usage: auth-watch.sh [-m MIN] [LOGFILE]
  -m MIN     only show IPs with at least MIN failures (default: ${min})
  LOGFILE    auth log to read (default: ${logfile})
EOF
}

while getopts ":m:h" opt; do
    case "$opt" in
        m) min="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -ge 1 ]] && logfile="$1"

if [[ ! -r "$logfile" ]]; then
    echo "auth-watch: cannot read $logfile" >&2
    exit 1
fi

# `|| true` so a clean log (grep finds nothing) does not trip `set -e`/pipefail.
offenders="$(tk_failed_logins < "$logfile" | tk_top_offenders "$min" || true)"
if [[ -z "$offenders" ]]; then
    echo "No source IP reached ${min} failed logins in $logfile."
    exit 0
fi

echo "Source IPs with >= ${min} failed SSH logins in $logfile:"
printf '%s\n' "$offenders" | awk '{ printf "  %5d  %s\n", $1, $2 }'
