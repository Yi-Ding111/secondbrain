---
title: <project> — Project Wiki / Directory Index
id: <project>/wiki
category: project-wiki
status: active
tags: [project-wiki, <project>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# <project> — Wiki

> Tree-architecture index of every folder/file under this project. Each entry: path · 一句话描述 · keywords · suggested write-zone hint. **Update on every wrap-work.** AI 写入前必读本文件以决定路径。

## Tree

```
<project>/
├── <project>.md              — Tier-3 architecture overview (Mermaid graph + module list)
├── CLAUDE.md                 — Project-level Claude instructions (read-budget, must-check, link-policy)
├── wiki.md                   — This file (directory index)
├── log.md                    — Project change log (durable, append-only)
├── tasks/                    — Tier-1 frozen task files
│   └── YYYY/Mmm/             — by year/month
│       └── *.md              — one task per file (frozen on write)
├── features/                 — Tier-2 feature files (live, snapshot-supersede on update)
│   └── *.md
├── superseded/               — frozen snapshots of <project>.md and features/*.md
│   └── superseded-*.md
├── decisions/                — ADR-style decisions (durable)
│   └── NNNN-*.md
├── learnings/                — bug stories, war stories (durable)
│   └── *.md
├── references/               — technical docs (semi-durable; changelog on update)
│   └── *.md
└── log/                      — ephemeral weekly logs
    └── YYYY-Www.md
```

## File-by-file index

### Root meta files

| File | Description | Keywords | Update cadence |
|------|-------------|----------|----------------|
| `<project>.md` | Tier-3 architecture overview with Mermaid graph | architecture, overview, top-level | When architecture changes (snapshot-supersede) |
| `CLAUDE.md` | Project-level Claude instructions | claude, instructions, read-budget | When project conventions evolve |
| `wiki.md` | This file — directory index | wiki, index, directory | Every wrap-work |
| `log.md` | Durable project change log | log, changelog, history | Every wrap-work |

### Features (Tier-2)

| File | Description | Keywords | Status |
|------|-------------|----------|--------|
| `features/<feat-1>.md` | _一句话描述_ | k1, k2, k3 | active |
| `features/<feat-2>.md` | ... | ... | active |

### Tasks (Tier-1, frozen)

_列最近 N 个；老的按月聚合。_

| File | Date | Title | Ticket | Frozen |
|------|------|-------|--------|--------|
| `tasks/2026/Apr/2026-04-29-<slug>-<TICKET>.md` | 2026-04-29 | <title> | <TICKET> | ✓ |

### Decisions

| File | Title | Status | Supersedes |
|------|-------|--------|------------|
| `decisions/0001-<slug>.md` | <title> | active | — |

### Learnings

| File | Title | Scope |
|------|-------|-------|
| `learnings/<slug>.md` | <title> | project-local |

### References

| File | Description | Keywords |
|------|-------------|----------|
| `references/<slug>.md` | _一句话描述_ | k1, k2 |

### Superseded (frozen, do not read)

_列出，不展开。仅在用户主动追溯演化时点开。_

- `superseded/superseded-<project>-2026-04-30-1612.md`
- `superseded/superseded-<feat-1>-2026-04-29-1503.md`

### Weekly logs (ephemeral)

- `log/2026-W17.md`
- `log/2026-W18.md`

## Write-routing hints (for AI)

- New ticket / branch wrap → `tasks/YYYY/Mmm/`
- New feature 描述 → `features/<feat>.md` (must also link from `<project>.md`)
- Architecture change → update `<project>.md` (snapshot-supersede first)
- ADR → `decisions/NNNN-<slug>.md`
- Reusable knowledge → `knowledge/<domain>/<slug>.md` (vault-level, not here)
- Reusable lesson → `experience/lessons/<slug>.md` (vault-level, not here)
- Project-specific lesson → `learnings/<slug>.md`
- Tech doc / SOP → `references/<slug>.md`
