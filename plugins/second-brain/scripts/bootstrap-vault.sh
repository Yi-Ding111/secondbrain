#!/usr/bin/env bash
# bootstrap-vault.sh — provision a vault from the second-brain plugin baseline.
#
# Copies the plugin's carried baseline (CLAUDE constitution, meta reference docs,
# page templates, path-scoped rules) into a target vault. Fill-missing ONLY —
# an existing file in the vault is never overwritten (the vault's version wins).
#
# Usage:
#   bootstrap-vault.sh [VAULT_DIR]
#     VAULT_DIR defaults to $CLAUDE_PROJECT_DIR, then $HOME/Documents/YisBrain.
#
# Why this exists: Claude Code plugins auto-load skills/agents/hooks, but NOT
# rules, templates, CLAUDE.md, or reference docs. Those are vault-level files.
# The plugin carries them as the canonical baseline; this script lays them into
# a vault so a fresh install yields a working vault, without clobbering an
# existing one.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VAULT="${1:-${CLAUDE_PROJECT_DIR:-$HOME/Documents/YisBrain}}"

if [[ ! -d "$VAULT" ]]; then
  echo "Error: vault dir not found: $VAULT" >&2
  exit 1
fi

copied=0
kept=0

# place <src> at <dest> only if <dest> is missing
place() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    kept=$((kept+1))
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    copied=$((copied+1))
    echo "  + $dest"
  fi
}

echo "== bootstrap-vault =="
echo "plugin: $PLUGIN_ROOT"
echo "vault:  $VAULT"
echo "(fill-missing only; existing vault files are kept)"

# 1) CLAUDE constitution baseline
[[ -f "$PLUGIN_ROOT/reference/CLAUDE.md" ]] && place "$PLUGIN_ROOT/reference/CLAUDE.md" "$VAULT/CLAUDE.md"

# 2) meta reference design docs (everything in reference/ except CLAUDE.md)
for f in "$PLUGIN_ROOT"/reference/*.md; do
  base="$(basename "$f")"
  [[ "$base" == "CLAUDE.md" ]] && continue
  place "$f" "$VAULT/meta/$base"
done

# 3) page templates
for f in "$PLUGIN_ROOT"/templates/*.md; do
  [[ -e "$f" ]] || continue
  place "$f" "$VAULT/meta/templates/$(basename "$f")"
done

# 4) path-scoped rules → vault .claude/rules/
for f in "$PLUGIN_ROOT"/rules/*.md; do
  [[ -e "$f" ]] || continue
  place "$f" "$VAULT/.claude/rules/$(basename "$f")"
done

echo "done — copied $copied, kept $kept (existing)."
echo "note: skills / agents / hooks load from the plugin itself; not copied here."
