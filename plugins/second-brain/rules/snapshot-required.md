---
description: Live tier files must snapshot before edit — fires when Claude reads project overview or feature pages
paths:
  - "**/work/*/projects/*/[a-z]*.md"
  - "**/projects/*/[a-z]*.md"
  - "**/features/**/*.md"
  - "**/api/**/*.md"
---

# Live tier file — snapshot before edit

This is a **live tier file** (Tier-3 `<project>.md` or Tier-2 `features/<feat>.md` / `api/<feat>.md`). It lives at a stable path so external `[[links]]` don't break.

**Before any non-trivial edit**:

```bash
SNAPSHOT=$(meta/scripts/snapshot-supersede.sh <this-file>)
```

The script does cp + frontmatter rewrite + 🧊 banner — **all in shell, no LLM context**. Then edit live file in place.

**Do not**:
- Manual `Read` + `Write` to copy old content into a snapshot — script already does it, manual approach burns tokens for nothing
- Edit live file without snapshot — destroys history (Obsidian Sync 是 destructive sync)
- Delete old description sections — append-only ([[CLAUDE]] §10): old description with date stays, new version appended below

After the script runs, in the live file:
1. Append new content (Timeline entry for features; updated module list for project overview)
2. Bump `updated:` in frontmatter
3. Add to live file's `## Changelog`: `- YYYY-MM-DD: snapshot before update → [[<snapshot-id>]]`

Full pattern + script details: [[meta/supersede-patterns]] §C.

**Exceptions** (no snapshot needed):
- `wiki.md` (frequently updated index) — direct edit OK, but bump `updated:`
- `log.md` (append-only timeline) — direct append OK
- `CLAUDE.md` (project-level) — direct edit OK
- These are not "tier" files — they're project meta
