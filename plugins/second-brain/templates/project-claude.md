---
title: <project> — Claude Project Instructions
id: <project>/CLAUDE
category: reference
status: active
tags: [project-claude, <project>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
code_roots:
  # name → abs path; used by /project-survey + /wrap-work source_paths routing
  # see [[meta/project-overview-system]] §4.5
  app: /Users/yiding/code/<project>
  # infra: /Users/yiding/code/<project>-infra
---

<!--
INSTANTIATION NOTE — read before copying.
`<x>` and `[[<x>]]` are placeholders — substitute when copying. An unsubstituted `[[<x>]]` becomes a broken Obsidian link. See [[CLAUDE]] §11.
Remove this comment when instantiating.
-->

# <project> — Claude Instructions

> Project-scoped contract. Complements (does not replace) the vault-root [[CLAUDE]]. Read this **first** when entering the project, before any write or grep.

## Read budget — which folders to skip

**Skip on routine read** (saves tokens):
- `tasks/**` — frozen (CLAUDE §7.6); only open when user asks for task-level detail
- `superseded/**` — frozen; only open when tracing evolution
- `log/**` weekly logs — usually ephemeral noise unless query is about activity history

**Always read on entry**:
- `<project>.md` — Tier-3 overview
- `wiki.md` — directory index (decides where to write)
- This `CLAUDE.md` — project conventions

**Read on demand**:
- `features/<feat>.md` — when working on / referencing a specific feature
- `decisions/NNNN-*.md` — when context needs prior decisions
- `references/*.md` — when looking up tech-doc

## Must-check files before write

Before **any** write inside this project, in this order:

1. `wiki.md` — to find the right destination folder/file (avoid creating duplicates)
2. `<project>.md` — to assess whether Tier-3 needs update (architecture impact?)
3. The relevant `features/<feat>.md` — to update Tier-2 timeline (if task touches a feature)

## Knowledge extraction rules

What kinds of content extracted from this project's tasks should be promoted to vault-level zones:

- **`knowledge/<domain>/`** (vault-level): when extracting reusable technical concepts. Domains relevant to this project:
  - `<domain-1>` — _e.g. langgraph_
  - `<domain-2>` — _e.g. redis_
  - `<domain-3>` — _e.g. sse_

- **`experience/lessons/`** (vault-level): when the lesson is reusable beyond this project. Examples that qualify:
  - _e.g. cross-project debugging patterns, framework-agnostic best practices_

- **`experience/playbooks/`** (vault-level): recurring SOPs, multi-step procedures.

- **`learnings/`** (project-local): single-project bugs, war stories, project-specific gotchas.

## Link policy

- Every `features/<feat>.md` **must** be linked from `<project>.md` (Tier-3 → Tier-2)
- Every `tasks/YYYY/Mmm/<task>.md` **must** be linked from at least one `features/<feat>.md` (Tier-2 → Tier-1)
- Cross-feature dependencies → `[[<feature>]]` link in the dependent feature
- Snapshot files (`superseded/*.md`) referenced from the live file's `## Changelog`

## Doc maintenance / refresh cadence

This project's `<project>.md` (Tier-3) and `features/` / `services/` / `modules/` / `api/` (Tier-2) docs use the **SURVEYOR / WRAP-WORK marker model** — see [[meta/project-overview-system]].

- **SURVEYOR block**: current truth (description, architecture, current implementation summary). Refreshed by `/project-survey` + `/project-decompose`. **Never edited inline by `/wrap-work`** — re-survey to update.
- **WRAP-WORK block**: append-only history (Timeline, Changelog, Related). Updated by `/wrap-work` per task.
- **Refresh cadence**: every _<N months>_ or on major refactor. Last surveyed: _<YYYY-MM-DD>_.

Source path → doc routing is encoded in each Tier-2 doc's frontmatter `source_paths` field; `/wrap-work` uses this to route task-touched paths to the right WRAP-WORK block.

## Project-specific naming / conventions

- Ticket prefix: `<TICKET-PREFIX>` (e.g. `ED-`, `ML-`)
- Branch convention: `<feature/fix/chore>/<slug>-<TICKET>` (or document the actual convention)
- Feature naming: <kebab-case-with-domain-prefix or just kebab-case>
- Other: _项目特有的约定_

## Special files / hot zones

_Files touched in almost every task; Claude should be aware these are non-trivial._

- `<file-1>` — _why hot_
- `<file-2>` — _why hot_

## Active modules / domains

_What's currently being actively developed; useful for grep biasing._

- `<module-1>` — _e.g. agents-runtime_
- `<module-2>` — _e.g. observability_

## Open conventions / TBD

_Conventions not yet decided; flag when relevant._

- _e.g. "feature naming convention TBD"_
