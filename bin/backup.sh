#!/usr/bin/env bash
# backup.sh - make a timestamped tar.gz of a directory and prune old ones.
#
# Creates DEST/<name>-YYYYmmdd-HHMMSS.tar.gz from SRC, then keeps only the
# newest KEEP archives for that name and deletes the rest.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/toolkit.sh
source "$SCRIPT_DIR/../lib/toolkit.sh"

keep=7

usage() {
    cat <<EOF
usage: backup.sh [-k KEEP] SRC DEST
  -k KEEP   number of archives to retain per source (default: ${keep})
  SRC       directory to back up
  DEST      directory to write archives into (created if missing)
EOF
}

while getopts ":k:h" opt; do
    case "$opt" in
        k) keep="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -ne 2 ]]; then
    usage >&2
    exit 2
fi
src="$1"
dest="$2"

if [[ ! -d "$src" ]]; then
    echo "backup: source $src is not a directory" >&2
    exit 1
fi
mkdir -p "$dest"

name="$(basename "$(cd "$src" && pwd)")"
stamp="$(date +%Y%m%d-%H%M%S)"
archive="$dest/${name}-${stamp}.tar.gz"

# -C so paths inside the archive are relative to the source's parent.
tar -czf "$archive" -C "$(dirname "$(cd "$src" && pwd)")" "$name"
size_kb="$(du -k "$archive" | cut -f1)"
echo "Created $archive ($(tk_bytes_human "$size_kb"))"

# Prune older archives for this source name.
pruned=0
while IFS= read -r old; do
    [[ -z "$old" ]] && continue
    rm -f "$old"
    echo "Pruned $old"
    pruned=$((pruned + 1))
done < <(tk_prune_list "$dest" "$keep" "${name}-*.tar.gz")

echo "Kept up to ${keep} archive(s); pruned ${pruned}."
