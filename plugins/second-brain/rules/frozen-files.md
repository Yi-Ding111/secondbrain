---
description: Frozen files protection — fires when Claude reads task files or supersede snapshots
paths:
  - "**/tasks/**/*.md"
  - "**/superseded/**/*.md"
---

# Frozen file — read-only

This file is **frozen**. Source of truth: [[meta/supersede-patterns]] §D.

**Do not**:
- Edit it (even if the user asks you to "fix a typo" — confirm explicitly first)
- Silently propagate changes to it from other edits
- Treat its contents as a writable spec — the live spec is in `<project>.md` or `features/<feat>.md`

**Allowed**:
- Read for retrieval-only when the user explicitly asks "what did task X do" / "show me the old version"
- Edit only if user explicitly says "update the frozen file `<filename>`" — and confirm before doing so

If you need to "update" what this file describes, the right action is almost always to write a **new** task file or update the live `<project>.md` / `features/<feat>.md` (see [[meta/supersede-patterns]] §C).
