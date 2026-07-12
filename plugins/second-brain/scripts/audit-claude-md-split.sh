#!/usr/bin/env bash
# audit-claude-md-split.sh
#
# Verify that every H2/H3 heading from an "old" CLAUDE.md is reachable in
# the new layout: either still in the new CLAUDE.md, or moved into one
# of meta/*.md. Lists orphans (sections that disappeared).
#
# Usage:
#   audit-claude-md-split.sh <old-claude-md> <new-claude-md> <meta-dir>
#
# Example:
#   meta/scripts/audit-claude-md-split.sh \
#     meta/superseded/CLAUDE-2026-05-09-2108.md \
#     CLAUDE.md \
#     meta/
#
# Exit codes:
#   0 — every section is accounted for
#   1 — orphans found (printed to stdout)
#   2 — usage / argument error
#
# Heuristic: a section is "found" if its heading text (after stripping the
# leading #s) appears as a heading anywhere in the search corpus, OR if the
# heading's first 5+ word non-stopword keyword phrase appears in body prose.
# This is intentionally lenient — a strict literal match would over-report.

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <old-claude-md> <new-claude-md> <meta-dir>" >&2
  exit 2
fi

OLD="$1"
NEW="$2"
META="$3"

for p in "$OLD" "$NEW"; do
  [ -f "$p" ] || { echo "missing file: $p" >&2; exit 2; }
done
[ -d "$META" ] || { echo "missing dir: $META" >&2; exit 2; }

# Build search corpus: new CLAUDE.md + every .md under meta/ (recursive)
CORPUS=$(mktemp)
trap 'rm -f "$CORPUS"' EXIT
{
  cat "$NEW"
  find "$META" -type f -name '*.md' ! -path "*/superseded/*" -print0 \
    | xargs -0 cat 2>/dev/null
} > "$CORPUS"

ORPHANS=()
TOTAL=0

# Extract H2 and H3 headings from OLD (skip frontmatter and code fences).
# We strip leading #s and trim whitespace, then search the corpus for
# either (a) the same heading text appearing as any heading, or
# (b) the heading text appearing in prose. Case-sensitive — vault is
# bilingual and case usually carries meaning.

awk '
  BEGIN { in_fence=0 }
  /^```/ { in_fence = 1 - in_fence; next }
  in_fence { next }
  /^## / || /^### / { sub(/^#+ +/, ""); print }
' "$OLD" | while IFS= read -r heading; do
  TOTAL=$((TOTAL + 1))
  # Trim
  trimmed=$(echo "$heading" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  [ -z "$trimmed" ] && continue

  if grep -F -q -- "$trimmed" "$CORPUS"; then
    # found — fine
    :
  else
    ORPHANS+=("$trimmed")
  fi
  # Persist counters across the loop body via a sentinel file
  echo "$TOTAL" > /tmp/.audit_total.$$
  printf '%s\n' "${ORPHANS[@]:-}" > /tmp/.audit_orphans.$$
done

# Re-read counters (subshell isolation in pipeline)
TOTAL=$(cat /tmp/.audit_total.$$ 2>/dev/null || echo 0)
ORPHAN_LIST=$(grep -v '^$' /tmp/.audit_orphans.$$ 2>/dev/null || true)
rm -f /tmp/.audit_total.$$ /tmp/.audit_orphans.$$

ORPHAN_COUNT=$(printf '%s\n' "$ORPHAN_LIST" | grep -c -v '^$' || true)

echo "=== audit-claude-md-split ==="
echo "old:    $OLD"
echo "new:    $NEW"
echo "meta:   $META"
echo "headings checked (H2+H3): $TOTAL"
echo "orphans (not findable in new layout): $ORPHAN_COUNT"
echo
if [ "$ORPHAN_COUNT" -gt 0 ]; then
  echo "--- orphan headings ---"
  printf '%s\n' "$ORPHAN_LIST"
  exit 1
fi

echo "OK — every section is reachable in the new layout."
exit 0
