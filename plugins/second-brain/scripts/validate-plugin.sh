#!/usr/bin/env bash
# validate-plugin.sh — static structural validation of the second-brain plugin.
#
# Checks the parts that can be verified WITHOUT a Claude Code runtime:
# manifest/plugin JSON validity, component presence, SKILL/agent frontmatter,
# hooks wiring, and a bootstrap dry-run. Runtime smoke (/plugin install,
# slash-command trigger, agent spawn, rule injection, hook firing) must be
# done in an actual Claude Code session — see the project README.
#
# Usage: validate-plugin.sh            (run from anywhere; resolves plugin root)
# Exit 0 = all static checks pass; 1 = a check failed.

set -uo pipefail
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MKT="$(cd "$ROOT/.." && pwd)"   # marketplace root (plugins/)
fail=0
ok(){ echo "  ✓ $1"; }
bad(){ echo "  ✗ $1"; fail=1; }

echo "== validate second-brain plugin =="
echo "root: $ROOT"

echo "-- JSON validity --"
for f in "$MKT/.claude-plugin/marketplace.json" "$ROOT/.claude-plugin/plugin.json" "$ROOT/hooks/hooks.json"; do
  if python3 -c "import json;json.load(open('$f'))" 2>/dev/null; then ok "$(basename "$f")"; else bad "invalid JSON: $f"; fi
done

echo "-- component presence --"
[ "$(ls "$ROOT"/skills/*/SKILL.md 2>/dev/null | wc -l)" -eq 5 ] && ok "5 skills" || bad "skills != 5"
[ "$(ls "$ROOT"/agents/*.md 2>/dev/null | wc -l)" -eq 3 ] && ok "3 agents" || bad "agents != 3"
[ "$(ls "$ROOT"/rules/*.md 2>/dev/null | wc -l)" -eq 5 ] && ok "5 rules" || bad "rules != 5"
[ "$(ls "$ROOT"/templates/*.md 2>/dev/null | wc -l)" -ge 14 ] && ok "14+ templates" || bad "templates < 14"
[ -f "$ROOT/reference/CLAUDE.md" ] && ok "CLAUDE baseline" || bad "no reference/CLAUDE.md"

echo "-- frontmatter --"
for s in "$ROOT"/skills/*/SKILL.md; do grep -q "^name:" "$s" || bad "skill missing name: $s"; done
for a in "$ROOT"/agents/*.md; do grep -q "^name:" "$a" && grep -q "^tools:" "$a" || bad "agent frontmatter: $a"; done
[ "$fail" -eq 0 ] && ok "skill/agent frontmatter"

echo "-- no obsidian-sync leakage --"
if [ -f "$ROOT/hooks/mirror-sync.sh" ] || grep -q "mirror-sync" "$ROOT/hooks/hooks.json" 2>/dev/null; then bad "mirror-sync wired into hooks"; else ok "no mirror-sync in hooks"; fi

echo "-- bootstrap dry-run (temp vault) --"
TV="$(mktemp -d)"
if bash "$ROOT/scripts/bootstrap-vault.sh" "$TV" >/dev/null 2>&1 \
   && [ -f "$TV/CLAUDE.md" ] && [ -d "$TV/.claude/rules" ] && [ -d "$TV/meta/templates" ]; then
  ok "bootstrap provisions CLAUDE + rules + templates"
else bad "bootstrap dry-run failed"; fi
rm -rf "$TV"

echo
if [ "$fail" -eq 0 ]; then echo "STATIC OK — runtime smoke (/plugin install, triggers) still needs a Claude Code session."; exit 0
else echo "FAILED — fix above."; exit 1; fi
