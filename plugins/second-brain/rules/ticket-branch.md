---
description: Ticket branch guard — before doing a ticket's work in this vault, cut a feature branch from main; never work on main, never commit/merge for the user
paths:
  - "**/work/*/projects/*/**/*.md"
  - "**/projects/*/**/*.md"
  - "**/tasks/**/*.md"
---

# 开工前先切 ticket 分支 Ticket branch guard

你正准备在这个 vault 里做**一个 ticket 的工作**——写 Tier-1 task 文件、改 project overview / features、ingest 某个 ticket 的产物、或 `/wrap-work` 一个 ticket。动手写之前，**先确认分支**。

## 规则 The rule

**当前若在 `main`（或任何非本 ticket 的分支）→ 停，先从 `main` 切一条 ticket 分支：**

```bash
git -C "$CLAUDE_PROJECT_DIR" checkout -b feature/<TICKET-ID>/<short-kebab-desc> main
```

- 命名 = `feature/<TICKET-ID>/<desc>`，例：`feature/ED-1509/fix-race-condition`
  - `<TICKET-ID>`：真实 ticket 号（Plane / JIRA / Linear）。拿不到 ID **就问用户**，不要瞎编
  - `<desc>`：3–5 词 kebab 描述，取自 ticket 标题 / 内容
- 命令末尾的 `main` = **始终 base off `main`**，即使你当前在别的分支上
- 一律带 `<desc>` 第三段：不能同时存在 `feature/ED-1509` 和 `feature/ED-1509/desc`（git ref D/F 冲突）

## 硬性边界 Hard boundaries

- **一个 ticket 一条分支**。已经在对应 ticket 分支上 → 直接干，别重切、别叠切
- **绝不替用户 commit 或 merge** —— commit / merge / push 全由用户自己执行。你只负责：切分支 + 在分支上完成改动
- 不动 remote（不 `push`、不改 upstream），除非用户明确要求
- 拿不准这是不是"一个 ticket 的工作"（例：只是修个 typo、调 meta 配置、更 CLAUDE.md）→ 问用户，或按当前分支继续，别强行切

Source of truth: 本文件。根 [[CLAUDE]] §10 有一句 always-load 兜底（path rule 在 compaction 后会丢，兜底那句不会）。
