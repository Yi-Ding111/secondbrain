---
description: Pre-write checklist when entering a project directory — fires when Claude reads any project-internal file
paths:
  - "**/work/*/projects/*/**/*.md"
  - "**/projects/*/**/*.md"
---

# Project-internal write checklist

You're inside a project directory. Before writing **any** file here, in order:

1. **Read `<project>/CLAUDE.md`** — scoped contract for this project (what folders to skip, hot zones, naming conventions, knowledge-extraction domains). See [[meta/project-claude-guide]]
2. **Read `<project>/wiki.md`** — directory index. Tells you the right destination folder/file. **This is how you avoid creating duplicate features or putting content in the wrong tier.**
3. **Decide which Tier you're touching** ([[CLAUDE]] §2.1):
   - Tier-3 `<project>.md` → architecture / module composition change → **snapshot-supersede required**
   - Tier-2 `features/<feat>.md` → feature behavior change → **snapshot-supersede required**
   - Tier-1 `tasks/YYYY/Mmm/*.md` → task delivery → **write-once frozen** (use `/wrap-work`)
4. **Update `<project>/log.md`** (durable change log) after non-trivial change — append-only timeline
5. **Update `<project>/wiki.md`** if file structure changed — keep index accurate

**Always show the full plan** before writing 2+ files. Multi-file ops without confirmation = silent risk.

If unsure which tier / where to write → use `/wrap-work` (project task wrap) or ask the user.
