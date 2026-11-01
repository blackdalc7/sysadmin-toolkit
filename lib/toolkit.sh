#!/usr/bin/env bash
# toolkit.sh - shared helper functions for the sysadmin scripts.
#
# The functions here read from stdin and write to stdout so they can be unit
# tested against fixtures, with no dependency on the live system. The scripts
# in bin/ are thin wrappers that feed them real system data.

# tk_df_over THRESHOLD
# Read `df -P` style output on stdin and print "USE% MOUNT" for every
# filesystem whose use percentage is >= THRESHOLD. The df header and
# pseudo-filesystems with no real size are ignored.
tk_df_over() {
    local threshold="$1"
    awk -v t="$threshold" '
        NR == 1 { next }                     # skip header
        {
            pct = $5; gsub(/%/, "", pct)
            if (pct ~ /^[0-9]+$/ && pct + 0 >= t) {
                print pct "% " $6
            }
        }
    '
}

# tk_failed_logins
# Read an auth log on stdin and print "COUNT IP" for each source address seen
# in an sshd "Failed password ... from <ip>" line, most frequent first.
tk_failed_logins() {
    grep -oE 'Failed password .* from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort \
        | uniq -c \
        | sort -rn \
        | awk '{ print $1 " " $2 }'
}

# tk_top_offenders MIN
# Read "COUNT IP" lines on stdin and keep only those with COUNT >= MIN.
tk_top_offenders() {
    local min="$1"
    awk -v m="$min" '$1 + 0 >= m { print }'
}

# tk_prune_list DIR KEEP PATTERN
# Print the files in DIR matching PATTERN that are OLDER than the KEEP newest
# (i.e. the ones a pruning run would delete), oldest last. Prints nothing if
# there are KEEP or fewer matches.
tk_prune_list() {
    local dir="$1" keep="$2" pattern="$3"
    # List matches newest-first by mtime, then drop the first KEEP lines.
    find "$dir" -maxdepth 1 -type f -name "$pattern" -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn \
        | awk -v k="$keep" 'NR > k { print $2 }'
}

# tk_bytes_human KILOBYTES
# Format a size given in KiB as a human-readable string.
tk_bytes_human() {
    awk -v kb="$1" 'BEGIN {
        split("KiB MiB GiB TiB PiB", unit, " ")
        v = kb; i = 1
        while (v >= 1024 && i < 5) { v /= 1024; i++ }
        printf (v == int(v) ? "%d %s\n" : "%.1f %s\n"), v, unit[i]
    }'
}
