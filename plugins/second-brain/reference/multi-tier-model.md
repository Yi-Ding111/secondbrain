---
title: Project Multi-Tier Model
created: 2026-05-09
tags: [meta, vault-schema, projects]
---

# Project Multi-Tier Model

Each project (under `work/<co>/projects/<proj>/` or `projects/<name>/`) is organized as a **3-tier zoom hierarchy**, plus 3 meta files. Reading top-down moves from "the whole project" to "this one ticket". Writing flows up: tasks → features → project overview.

---

## 三个内容层 The 3 content tiers

| Tier | File pattern | What it captures | When written | Read pattern |
|------|--------------|------------------|--------------|--------------|
| **Tier-3 Project** | `<project>.md` | High-level architecture: modules, services, deployments, integrations. **Must include a Mermaid graph.** Entry point — read this to understand the whole project. | Updated when architecture / module composition changes. Snapshot-supersede before update. | Always read first when entering the project. |
| **Tier-2 Feature** | `features/<feat>.md` | One feature's *what* and *why*. Integrates how the feature is built, what it does, why it exists. Timeline section accumulates changes (append-only, no deletion of old content). | Updated whenever a task touches this feature. Snapshot-supersede before each non-trivial update. | Read when working on a specific feature. |
| **Tier-1 Task** | `tasks/YYYY/Mmm/YYYY-MM-DD-<slug>[-TICKET].md` | One ticket / one branch / one delivery: full implementation detail, before/after, commit timeline. | Written **once** when task wraps up. **Frozen after write** — Claude does not re-read or edit unless user explicitly says to. | Read only when user asks "show me the details of task X" or grep cannot find the answer at higher tiers. |

## 一个 tier 怎么 flow 到下一层 How a tier flows up to the next

When a task wraps (`/wrap-work`):

1. **Tier-1 task file** is written from the inbox digests (frozen after write).
2. The task's effect on the relevant **Tier-2 feature file** is propagated:
   - If the feature already exists → snapshot the current `features/<feat>.md` to `superseded/feat-<feat>-<timestamp>.md`, then update the live file (append timeline entry, edit description as needed). **Old content is preserved, not deleted.**
   - If the feature is new → create `features/<feat>.md`, link from `<project>.md`.
3. The task's effect on **Tier-3 project overview** is propagated only if the architecture changed (new module, new service, deployment shift). Same snapshot-supersede pattern.
4. Meta files (`log.md`, `wiki.md`, project-`CLAUDE.md`) are touched as needed.

## 阅读方向 Read-direction discipline

- Want to grok the project → read `<project>.md` (Tier-3).
- Want to understand a feature → click into `features/<feat>.md` (Tier-2).
- Want the implementation details of one change → drill to `tasks/YYYY/Mmm/<file>.md` (Tier-1).
- This is the link-graph that makes Obsidian shine. **Do not duplicate** content across tiers — link.

## 三个 project-meta 文件 The 3 project-meta files

| File | Job | Update cadence | Special rule |
|------|-----|----------------|--------------|
| `<project>/CLAUDE.md` | Project-level instructions for Claude (which folders to skip, which files to check, link-policy, etc.) | Reviewed when project conventions evolve | **Always read before any project-internal write** (see [[project-claude-guide]]) |
| `<project>/wiki.md` | Tree-architecture index of every folder/file under this project, with description + keywords + suggested write-zone | **Frequently updated** — every wrap-work touches it | Claude reads this **before deciding where to write** within the project |
| `<project>/log.md` | Durable change log: append-only timeline of project structural / architectural / feature changes | Append on every wrap-work | Distinct from `log/` weekly (which is ephemeral activity) |

## 两层 log 不要混 Two log layers (do not confuse)

- `<project>/log.md` — **durable** project change log (single file, append-only). What changed structurally and why.
- `<project>/log/YYYY-Www.md` — **ephemeral** weekly activity log (one file per ISO week). Day-to-day work entries; compressed monthly into the project MOC timeline.

Both are kept.
