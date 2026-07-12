---
description: Inbox is dump zone, not search target — fires when Claude reads or globs inbox
paths:
  - "**/inbox/**"
---

# Inbox — dump zone, not query source

`inbox/` is **unsorted**. It's where `brain-digest` / `task-git-digest` drop their output and where the user dumps things they haven't classified yet.

**Do not**:
- Grep `inbox/` when answering user questions ("what's our policy on X") — answers live in `knowledge/`、`experience/`、project tier files, NOT here
- Auto-classify inbox files mid-conversation — wait for `/ingest` or `/wrap-work` to be invoked
- Edit inbox files directly — they're meant to be **consumed and deleted** by ingest/wrap-work, not curated in place

**When inbox files DO matter**:
- `/ingest` Step 0 — picks up any `*.md` with `source: brain-digest` or `tags: [pending-ingest]`
- `/wrap-work` Step 0 — picks up any `*.md` with `source: brain-digest` / `source: task-git-digest`
- `/lint` weekly — flags inbox items older than 7 days for classification

After `/ingest` or `/wrap-work` consumes a digest file → **the file is deleted** (it was a bridge, not raw material — see `.claude/skills/ingest/SKILL.md` Step 0 / `.claude/skills/wrap-work/SKILL.md` Step 7b).

