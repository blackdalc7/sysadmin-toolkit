# sysadmin-toolkit

[![CI](https://github.com/blackdalc7/sysadmin-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/blackdalc7/sysadmin-toolkit/actions/workflows/ci.yml)

A handful of small Bash scripts for everyday Linux housekeeping: check disk
usage, watch an auth log for brute-force attempts, make pruning backups, and
print a quick health summary. The shared logic lives in one sourceable library
so it can be unit tested without touching the live system.

All scripts use `set -euo pipefail` and are checked with ShellCheck in CI.

## The scripts

| Script | What it does |
|---|---|
| `bin/disk-check.sh` | Lists filesystems at/above a usage threshold; exits 1 if any (cron-friendly) |
| `bin/auth-watch.sh` | Counts failed SSH logins per source IP and flags repeat offenders |
| `bin/backup.sh` | Timestamped `tar.gz` of a directory, keeping only the newest *N* |
| `bin/sysinfo.sh` | One-screen summary: host, kernel, uptime, memory, disk |

## Usage

```bash
# warn if any filesystem is 85%+ full
bin/disk-check.sh -t 85

# show IPs with 10+ failed SSH logins in a given log
bin/auth-watch.sh -m 10 /var/log/auth.log

# back up /etc into /srv/backups, keeping the 7 most recent
bin/backup.sh -k 7 /etc /srv/backups

# quick health screen
bin/sysinfo.sh
```

`disk-check.sh` exiting non-zero when something is wrong means you can drop it
straight into cron or a CI health step:

```cron
*/30 * * * * /opt/sysadmin-toolkit/bin/disk-check.sh -t 90 || mail -s "disk alert" root
```

## How it is organised

```text
bin/              the four command-line scripts (thin wrappers)
lib/toolkit.sh    pure helper functions, read stdin -> write stdout:
                    tk_df_over, tk_failed_logins, tk_top_offenders,
                    tk_prune_list, tk_bytes_human
tests/
    run-tests.sh      dependency-free test harness (sources the library)
    fixtures/         sample df output and an auth.log
```

The design idea: anything with real logic is a function in `lib/toolkit.sh`
that reads standard input and writes standard output. That makes it testable
against fixtures, and keeps the scripts in `bin/` down to argument parsing plus
one call into the library.

## Tests

```bash
bash tests/run-tests.sh
```

The harness sources the library and asserts on its output against committed
fixtures — disk thresholds, failed-login counting and ranking, backup pruning
(which newest files are kept), and human-readable sizes. No Bats or other
framework required; CI additionally runs ShellCheck over every script.

## Safety notes

- `auth-watch.sh` only **reads** a log you point it at; it takes no action on
  any host or address. It is a monitoring aid, not a blocker.
- `backup.sh` deletes only archives it would have created (files matching
  `<name>-*.tar.gz` in the destination), never anything in the source.

## Licence

MIT. See [LICENSE](LICENSE).
