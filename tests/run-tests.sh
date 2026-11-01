#!/usr/bin/env bash
# run-tests.sh - a tiny test harness for the toolkit library.
#
# No external framework: it sources lib/toolkit.sh and checks the pure helper
# functions against the fixtures in tests/fixtures. Each assertion prints a
# line; the script exits non-zero if any fail.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=../lib/toolkit.sh
source "$ROOT/lib/toolkit.sh"

pass=0
fail=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "ok   - $desc"
        pass=$((pass + 1))
    else
        echo "FAIL - $desc" >&2
        echo "       expected: [$expected]" >&2
        echo "       actual:   [$actual]" >&2
        fail=$((fail + 1))
    fi
}

# --- tk_df_over -------------------------------------------------------------
got="$(tk_df_over 90 < "$HERE/fixtures/df.txt")"
assert_eq "df_over 90 finds the two full filesystems" $'95% /\n92% /var' "$got"

got="$(tk_df_over 99 < "$HERE/fixtures/df.txt")"
assert_eq "df_over 99 finds nothing" "" "$got"

# --- tk_failed_logins -------------------------------------------------------
got="$(tk_failed_logins < "$HERE/fixtures/auth.log")"
assert_eq "failed_logins counts per IP, most frequent first" \
    $'6 203.0.113.9\n3 198.51.100.7\n1 192.0.2.5' "$got"

# --- tk_top_offenders -------------------------------------------------------
got="$(tk_failed_logins < "$HERE/fixtures/auth.log" | tk_top_offenders 5)"
assert_eq "top_offenders 5 keeps only the brute-force source" "6 203.0.113.9" "$got"

got="$(tk_failed_logins < "$HERE/fixtures/auth.log" | tk_top_offenders 3)"
assert_eq "top_offenders 3 keeps two sources" $'6 203.0.113.9\n3 198.51.100.7' "$got"

# --- tk_bytes_human ---------------------------------------------------------
assert_eq "bytes_human 512 KiB"  "512 KiB" "$(tk_bytes_human 512)"
assert_eq "bytes_human 1.5 MiB"  "1.5 MiB" "$(tk_bytes_human 1536)"
assert_eq "bytes_human 1 GiB"    "1 GiB"   "$(tk_bytes_human 1048576)"

# --- tk_prune_list ----------------------------------------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for i in 1 2 3 4 5; do
    f="$tmp/app-2026010${i}.tar.gz"
    touch "$f"
    # Stagger mtimes so ordering is deterministic (file 5 newest).
    touch -d "2026-01-0${i} 00:00:00" "$f"
done
touch "$tmp/other.txt"   # must be ignored by the pattern
got="$(tk_prune_list "$tmp" 2 'app-*.tar.gz' | sort)"
want="$(printf '%s\n' "$tmp/app-20260101.tar.gz" "$tmp/app-20260102.tar.gz" "$tmp/app-20260103.tar.gz" | sort)"
assert_eq "prune_list keeps 2 newest, lists the 3 oldest" "$want" "$got"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
