---
title: Directory Map (full)
created: 2026-05-09
tags: [meta, vault-schema]
---

# Directory Map — full reference

This is the full directory tree for the vault, with per-zone description and lifecycle. The root [[CLAUDE]] only keeps the top-level zone names — all detail lives here.

---

## 捕获层 Capture layer

- `inbox/` — everything unsorted. Dump first, classify weekly. Never search this for answers.

## Layer 1: RAW (immutable)

- `raw/articles/` — clipped articles
- `raw/books/` — book highlights / summaries
- `raw/videos/` — video notes, transcripts
- `raw/clips/` — screenshots, quick captures

**Rule**: raw content is **never edited**. Annotations go in separate distilled pages that link back.

## Layer 2: DISTILLED (user writes, Claude assists)

### Work (employed) — project-internal layout

详见 [[multi-tier-model]] for the 3-tier structure used inside every project. Below is the file inventory.

- `work/<company>/<company>.md` — big picture of the company (people, stack, culture, project list). Filename equals folder name.
- `work/<company>/projects/<project>/` — a specific deliverable. Inside each project:
  - `<project>.md` — **TIER-3 top-level architecture**. High-level view of the whole project: modules, services, deployments, integrations. **Must contain a Mermaid graph** showing module relationships. All sub-content is reachable via `[[links]]` from here. Frequently updated; **snapshot-supersede** before each non-trivial update (see [[supersede-patterns]]).
  - `CLAUDE.md` — **project-level instructions for Claude** (see [[project-claude-guide]]). Describes which folders to skip on read, which files must be checked before writing, link-policy, knowledge-extraction rules. Read this **before** any project-internal write.
  - `wiki.md` — **project directory index**. Tree of all folders/files under this project, with description + keywords + suggested write-zone for each. Frequently updated. Claude **must** read this before deciding where to write within the project.
  - `log.md` — **project change log** (single-file, append-only timeline). Distinct from `log/` weekly logs: `log.md` is the durable change log of project structure / features / architecture; `log/` weekly is ephemeral activity.
  - `tasks/YYYY/Mmm/` — **TIER-1 finest grain**. Each task one file: `YYYY-MM-DD-<task-slug>[-TICKET].md`. **Frozen after write** — Claude does not read or edit unless the user explicitly says "update task X". Mmm = `Jan` / `Feb` / ... / `Dec`.
  - `features/<feature>.md` — **TIER-2 functional descriptions**. One feature = one file. Integrates the *what* and *why* of the feature, with a timeline of changes (do not delete old content; append). **Snapshot-supersede** before each non-trivial update. Linked from `<project>.md`.
  - `superseded/` — **frozen archive**. Old snapshots of `<project>.md` and `features/*.md` go here as `superseded-<name>-YYYY-MM-DD-HHMM.md`. **Write-only** — never read, never edit.
  - `decisions/NNNN-slug.md` — ADR-style decisions (durable; ADR-supersede per [[supersede-patterns]]).
  - `learnings/<slug>.md` — bugs, insights, war stories (durable).
  - `references/<slug>.md` — technical docs you wrote (semi-durable; changelog on update).
  - `log/YYYY-Www.md` — weekly activity log (ephemeral; compressed monthly).
- `work/<company>/log/` — company-level weekly logs (meetings, 1-on-1s).
- `work/<company>/decisions/` — company-level decisions (not project-specific).

### Personal projects

- `projects/<name>/` — same multi-tier structure as work projects (see [[multi-tier-model]]).

### Knowledge (semantic memory)

- `knowledge/<domain>/<domain>.md` — map of content for the domain (filename equals folder name)
- `knowledge/<domain>/<atomic-concept>.md` — one idea per page

### Experience (cross-project sediment)

- `experience/lessons/` — lessons extracted from multiple projects
- `experience/decisions/` — decisions that span projects/companies
- `experience/retros/{weekly,monthly,yearly}/` — retrospectives by cadence
- `experience/playbooks/` — reusable SOPs

### Learning (in-progress)

- `learning/reading/` — books/articles currently reading
- `learning/courses/` — courses in progress
- `learning/questions/` — open questions, things to figure out
- `learning/literature/` — Zettelkasten-style literature notes (raw → distilled bridge)

### Working memory

- `thinking/drafts/` — half-baked ideas, explorations, not yet knowledge

## Layer 3: WIKI (Claude synthesizes)

- `wiki/` — **cross-pillar synthesis pages only**. Pages here integrate content from 2+ of {work, projects, knowledge, experience, learning}. Single-domain content goes to `knowledge/<domain>/`, not here.

## Archive & meta

- `archives/` — dead projects, companies you've left. Move, don't delete.
- `meta/CLAUDE.md` — vault constitution mirror (root copy is canonical for Claude Code)
- `meta/templates/` — page templates
- `meta/scripts/` — shell utilities (snapshot-supersede.sh, hooks/, audit scripts)
- `meta/superseded/` — snapshots of root-level docs (e.g. CLAUDE.md history)
- `index.md` — vault homepage (root)
- `log.md` — Claude operation log (root)
