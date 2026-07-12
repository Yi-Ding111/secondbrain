#!/usr/bin/env bash
# log-sort-and-anchor.sh
#
# Reorder a log.md so entries (each starting with `## YYYY-MM-DD`) appear in
# DESCENDING date order (newest first), with a stable secondary sort that
# preserves original file order within the same date. Inserts a unique anchor
# comment between the header and the first entry so subsequent appends can
# use Edit to replace the anchor with `<anchor>\n\n<new entry>` — which puts
# the new entry directly below the anchor and above all older entries, i.e.
# at the TOP of the entry list. This avoids reading the body on every write.
#
# Usage: log-sort-and-anchor.sh <path-to-log.md>
#
# Exit codes:
#   0 — file rewritten (or already in the right shape; idempotent)
#   2 — usage error / file missing

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <log.md>" >&2
  exit 2
fi

FILE="$1"
[ -f "$FILE" ] || { echo "missing file: $FILE" >&2; exit 2; }

ANCHOR='<!-- LOG-ANCHOR: 新条目插在这条注释之下 / prepend new entries directly below this anchor -->'

python3 - "$FILE" "$ANCHOR" <<'PY'
import re, sys
path, anchor = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    content = f.read()

# Strip any pre-existing anchor occurrences (idempotent re-runs).
content = re.sub(re.escape(anchor) + r'\n*', '', content)

# Split into header + entries. Each entry begins with `## YYYY-MM-DD` at line start.
parts = re.split(r'(?=^## \d{4}-\d{2}-\d{2})', content, flags=re.MULTILINE)
header = parts[0]
entries = parts[1:]

# Stable sort by date desc.
def date_of(e):
    m = re.match(r'^## (\d{4}-\d{2}-\d{2})', e)
    return m.group(1) if m else ""
entries.sort(key=date_of, reverse=True)

# Normalize: each entry ends with exactly one blank line so the next `## ` heading
# is visually separated.
entries = [e.rstrip() + "\n\n" for e in entries]

new = header.rstrip() + "\n\n" + anchor + "\n\n" + "".join(entries)
# Ensure single trailing newline.
new = new.rstrip() + "\n"

with open(path, "w", encoding="utf-8") as f:
    f.write(new)

print(f"sorted {len(entries)} entries; anchor inserted")
PY
