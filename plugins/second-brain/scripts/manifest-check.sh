#!/usr/bin/env bash
# manifest-check.sh — detect-only sanity check for the root vault manifest.
#
# Usage:
#   meta/scripts/manifest-check.sh [manifest-path]     # default: manifest.md
#
# Checks (report-only, never edits):
#   1. COVERAGE — every top-level zone directory that has content (>=1 .md,
#      excluding dotfolders) is listed under `zones:` in the manifest.
#   2. MOC RESOLUTION — every non-null `moc:` pointer resolves to an existing
#      <target>.md somewhere in the vault.
#
# Exit codes:
#   0 — no drift
#   1 — drift found (printed)
#   2 — usage / file error
#
# Philosophy: same as /lint — surface problems, let the human fix. Run after
# adding/removing a top-level zone or renaming a zone MOC.

set -euo pipefail

manifest="${1:-manifest.md}"
root="$(cd "$(dirname "$manifest")" && pwd)"

if [[ ! -f "$manifest" ]]; then
  echo "Error: manifest not found: $manifest" >&2
  exit 2
fi

drift=0

# --- extract declared zone keys from the ```yaml block (2-space indented keys under zones:) ---
declared_zones="$(awk '
  /^zones:/ {inz=1; next}
  inz && /^[a-z]/ {inz=0}                 # a top-level yaml key ends the zones map
  inz && /^  [a-z_]+:/ {
    gsub(/[ :]/,""); print
  }
' "$manifest" | sort -u)"

# --- extract moc pointers ---
declared_mocs="$(grep -E '^\s*moc:\s*' "$manifest" | sed -E 's/^\s*moc:\s*//' | grep -v '^null$' || true)"

echo "== manifest-check: $manifest =="

# 1. COVERAGE
echo "-- coverage: top-level zones with content --"
for d in "$root"/*/; do
  z="$(basename "$d")"
  # skip dotfolders, deps, and the obsidian-sync mirror (not a content zone; obsidian-sync retired)
  case "$z" in .*|node_modules|claude-sync|plugins) continue;; esac
  # has any tracked-ish .md content?
  if find "$d" -maxdepth 3 -name '*.md' -print -quit | grep -q .; then
    if grep -qE "^\s{2}$z:" "$manifest"; then
      :
    else
      echo "  DRIFT: zone '$z/' has content but is NOT in manifest zones:"
      drift=1
    fi
  fi
done

# 2. MOC RESOLUTION
echo "-- moc pointers resolve --"
while IFS= read -r moc; do
  [[ -z "$moc" ]] && continue
  # moc is a wiki-link target (filename without .md); find it anywhere
  if find "$root" -name "${moc##*/}.md" -print -quit | grep -q .; then
    :
  else
    echo "  DRIFT: moc '$moc' → no matching ${moc##*/}.md found"
    drift=1
  fi
done <<< "$declared_mocs"

if [[ "$drift" -eq 0 ]]; then
  echo "OK — manifest in sync (zones: $(echo "$declared_zones" | wc -w | tr -d ' '), mocs checked)."
  exit 0
else
  echo "DRIFT found — fix manifest.md and re-run."
  exit 1
fi
