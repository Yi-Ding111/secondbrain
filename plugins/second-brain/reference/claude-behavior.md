---
title: How Claude Should Behave (full posture)
created: 2026-05-09
tags: [meta, claude-instructions]
---

# How Claude Should Behave

Root [[CLAUDE]] keeps only the 5-bullet default posture. This file holds the per-operation detail.

---

## Default posture

- **Be surgical**: small, targeted edits. Never rewrite existing durable content silently.
- **Cite everything**: when answering from the vault, every non-trivial claim gets `[[page-id]]`.
- **Ask before crossing layers**: moving from `thinking/drafts/` to `knowledge/` is a promotion — confirm with user first.
- **Log writes — prepend via anchor, never read body**:
  - Root `log.md` 和每个 zone 的 `log.md` 都按 **newest-first** 维护。每个 log 文件在 header 之下、entries 之上有一行 unique 注释 `<!-- LOG-ANCHOR: 新条目插在这条注释之下 / prepend new entries directly below this anchor -->`
  - 写新 entry 的方法：**只用 Edit tool**，`old_string` 是 anchor 整行；`new_string` 是 anchor + 空行 + `## YYYY-MM-DD — <topic>` + body。这样新 entry 落在 anchor 正下方、所有旧 entry 之上
  - **绝不 Read log.md 的 body**——anchor 字符串足够 unique 让 Edit 定位，body 可能上万 tokens 完全不必入 context
  - 第一次为某个 log 文件插 anchor / 给已有 log 重新 sort：跑 `meta/scripts/log-sort-and-anchor.sh <path-to-log.md>`（python3，按 `## YYYY-MM-DD` 切分 + stable date desc sort + anchor 注入；幂等）
- **Path-scoped 行为护栏**：进入 `tasks/**`、`superseded/**`、`raw/**`、`inbox/**`、项目目录、live tier 文件时，path-scoped rules 自动加载提醒（见 [[rules-registry]]）

## On ingest

- Infer the right zone but **show your plan** before writing multiple files
- In distilled pages, write in the user's own words, not copy-paste

## On wrap-work

- **Always confirm** which inbox digest files belong to this task (one task may span several digests because user runs `task-git-digest` + `brain-digest` mid-stream).
- **Tier-1 task file is write-once** — once written, do not edit unless user explicitly asks.
- **Show the full plan** before writing: which task file, which feature(s), which knowledge candidates, which meta files.

## On query

- Grep first, read narrow (specific files), synthesize
- Top-down: Tier-3 → Tier-2 → Tier-1 (only descend if higher tier doesn't answer)
- If the answer genuinely exists nowhere in the vault, say so — don't make it up
- Offer to persist good synthesis back to the vault

## On uncertain classification

When a piece of content could go in multiple zones, prefer in this order:

1. `inbox/` (if genuinely unclassified)
2. The most **specific** zone (project > company > experience > knowledge)
3. Cross-link via `[[wiki-links]]` rather than duplicating

## On conflicts with prior content

- For `decisions/` / `knowledge/` → ADR supersede or changelog (see [[supersede-patterns]])
- For `<project>.md` / `features/*.md` → snapshot supersede (snapshot to `superseded/`, edit live file)
- Never silently overwrite

## Style (language + prose density)

**完整规则、worked examples、anti-patterns 都在 [[style-guide]]**。这里只列三条核心原则，写任何 narrative 页（features / knowledge / lessons / ADR）前**必须**已经内化它们：

1. **Chinese-leading bilingual**（除 `CLAUDE.md` 外的所有页）。中文做散文骨架，英文术语 inline 嵌入（race condition、idempotent、`asyncio.create_task`、Bedrock、SSE 等）。**禁止反向**——不要 "英文 (中文)" 括号 ping-pong。H2/H3 用 `## 中文 English` 形式
2. **Narrative over noun-phrase chains**。每个 invariant / property 后面必须跟 (a) 怎么保证它、(b) 一个 worked example trace、(c) consequence（"so what"——下游因此可以简化什么）
3. **Length 不是问题，clarity is the only thing that matters**。一句话重新解释一个读者可能忘了的概念，比让读者重读整页便宜。**不要为长度而 padding**，但也**不要为简洁而堆名词短语**

适用强度：features / api / knowledge / lessons / ADR **必须严格**；wiki.md / log.md / MOC 一句话描述 / changelog bullet **可以 terse**。

详细 worked examples（含 ❌/✅ 5× 长度对比）、术语词表、何处可以 dense → [[style-guide]]。
