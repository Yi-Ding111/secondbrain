#!/usr/bin/env bash
# snapshot-supersede.sh — execute CLAUDE.md §7.5 snapshot supersede
#
# Usage:
#   meta/scripts/snapshot-supersede.sh <live-file-path>
#
# What it does (purely local, no LLM context required):
#   1. cp <live-file> → <dir>/superseded/superseded-<basename>-<YYYY-MM-DD-HHMM>.md
#   2. Rewrite snapshot frontmatter:
#        - status:    → superseded
#        - category:  → superseded
#        - id:        → <original-id>/superseded/<basename>-<ts>
#        - frozen:    → true   (added if missing)
#   3. Insert frozen banner + horizontal rule after frontmatter close
#   4. Print snapshot file path to stdout (caller uses it for changelog reference)
#
# Designed so the caller never has to Read the live file content into LLM
# context just to write the snapshot — file content stays in shell only.
#
# After this script runs, the caller's remaining work is:
#   - Edit the live file in place (the actual content change)
#   - Append `## Changelog` line referencing $(basename "$snapshot" .md)

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <live-file-path>" >&2
  exit 2
fi

live="$1"
if [[ ! -f "$live" ]]; then
  echo "Error: live file not found: $live" >&2
  exit 1
fi

if ! head -1 "$live" | grep -q '^---$'; then
  echo "Warning: $live does not appear to start with YAML frontmatter; banner injection will be skipped." >&2
fi

ts="$(date +%Y-%m-%d-%H%M)"
ts_human="$(date '+%Y-%m-%d %H:%M')"
dir="$(dirname "$live")"
basename="$(basename "$live" .md)"
snap_dir="$dir/superseded"
snap_path="$snap_dir/superseded-${basename}-${ts}.md"

if [[ -f "$snap_path" ]]; then
  echo "Error: snapshot already exists at $snap_path (timestamp collision; wait 1 minute and retry)" >&2
  exit 1
fi

mkdir -p "$snap_dir"

awk -v ts="$ts" -v ts_human="$ts_human" -v basename="$basename" '
  BEGIN {
    in_fm = 0
    fm_seen = 0
    status_seen = 0
    category_seen = 0
    frozen_seen = 0
  }

  # Open of frontmatter (first --- in file)
  /^---$/ && !fm_seen {
    in_fm = 1
    fm_seen = 1
    print
    next
  }

  # Close of frontmatter (second --- while in_fm)
  /^---$/ && in_fm {
    if (!status_seen)   print "status: superseded"
    if (!category_seen) print "category: superseded"
    if (!frozen_seen)   print "frozen: true"
    print "---"
    print ""
    print "> 🧊 **Frozen snapshot of [[" basename "]] taken at " ts_human ".** Do not read or edit."
    print ""
    print "---"
    # No trailing blank — the original blank after `---` in the source provides it.
    # If source has no blank there, the HR will adjoin the body (rare in this vault).
    in_fm = 0
    next
  }

  # Inside frontmatter — rewrite specific keys
  in_fm {
    if ($0 ~ /^status:/)   { print "status: superseded";   status_seen = 1;   next }
    if ($0 ~ /^category:/) { print "category: superseded"; category_seen = 1; next }
    if ($0 ~ /^frozen:/)   { print "frozen: true";         frozen_seen = 1;   next }
    if ($0 ~ /^id:/) {
      orig = $0
      sub(/^id:[ \t]*/, "", orig)
      print "id: " orig "/superseded/" basename "-" ts
      next
    }
    print
    next
  }

  # After frontmatter — pass through verbatim
  { print }
' "$live" > "$snap_path"

echo "$snap_path"
