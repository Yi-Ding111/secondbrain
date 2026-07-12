---
description: Raw content is immutable — fires when Claude reads anything under raw/
paths:
  - "**/raw/**"
---

# Raw is immutable

`raw/` holds external originals (articles、book highlights、video transcripts、clips). **Never edit** these files.

If you have annotations / commentary / takeaways:
- Write them to a **separate distilled page** in `knowledge/`、`learning/literature/`、or `experience/lessons/`
- The distilled page's frontmatter `source:` field points back to this raw file (`source: raw/articles/2026-04-15-foo.md`)
- Use the `/ingest` skill — it preserves raw verbatim and only writes to distilled zones

**Do not**:
- Edit raw content even to fix typos / format markdown / clean up
- Move raw files between subfolders without explicit user request
- Delete raw files (the source of truth principle)
