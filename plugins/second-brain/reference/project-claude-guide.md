---
title: Project-level CLAUDE.md Guide
id: meta/project-claude-guide
category: reference
status: active
tags: [meta, project-claude, vault-schema]
created: 2026-05-03
updated: 2026-05-03
---

# Project-level CLAUDE.md Guide

每个项目（`work/<co>/projects/<proj>/` 或 `projects/<name>/`）都带一份自己的 `CLAUDE.md`——一份**scoped contract**，**补充**而非取代 root `CLAUDE.md`。它告诉 Claude 在**这一个项目内部**怎么操作，那种细节不属于 vault 层级。

Root `CLAUDE.md` §13.5 已被本文取代。

---

## A. 项目 CLAUDE.md 里放什么

完整模板见 `meta/templates/project-claude.md`。骨架结构：

```markdown
---
title: <project> — Claude Project Instructions
category: reference
status: active
tags: [project-claude, <project>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# <project> — Claude instructions

## Read budget（哪些文件夹跳过）
Skip on routine read:
- `tasks/**` — frozen ([[meta/supersede-patterns]] §D)
- `superseded/**` — frozen ([[meta/supersede-patterns]] §D)
- `log/**`（weekly logs）—— 通常 ephemeral 噪音，除非 query 是关于活动历史

Always read on entry:
- `<project>.md`
- `wiki.md`
- this `CLAUDE.md`

## Must-check files before write
进入项目内做任何 write 前必读：
1. `wiki.md` —— 找正确的 destination 文件夹 / 文件
2. `<project>.md` —— 如架构受影响，更新 Tier-3
3. The relevant `features/<feat>.md` —— 如功能受影响，更新 Tier-2

## Knowledge extraction rules
本项目 task 中提取的内容应升级到哪些 zone：
- `knowledge/<domain>/` —— 列出本项目相关的 domain（例如 langgraph, redis, sse）
- `experience/lessons/` —— 哪类 lesson 跨项目可复用
- `experience/playbooks/` —— recurring SOP

## Link policy
- 每个 `features/<feat>.md` 必须从 `<project>.md` 链回来
- 每个 `tasks/YYYY/Mmm/<task>.md` 必须至少被一个 `features/<feat>.md` 链
- 跨 feature 依赖 → `[[<feature>]]` link

## Project-specific naming / convention notes
（任何偏离 root §4 的：ticket 前缀、feature 命名约定等）

## Special files / hot zones
（几乎每个 task 都会动的文件；让 Claude 知道这些不是 trivial 改动）
```

---

## B. 何时更新项目 CLAUDE.md

只在以下情况触发：

- 新约定出现（新 ticket prefix / 新 module 文件夹）
- 新 domain 进入项目（例如项目第一次开始用 Redis → 加到 knowledge-extraction rules）
- 某文件夹变成"always-skip" 或 "always-read"

否则不要碰——它应该相对稳定。

---

## C. `/wrap-work` 怎么用项目 CLAUDE.md

`/wrap-work` Step 1 会读 `<project>/CLAUDE.md`（如果存在）来了解：

- 哪些文件夹在 grep 找相关页时应跳过
- 哪些 knowledge domain 在抽取概念时应优先考虑
- 是否有任何 project-specific naming 在用

详见 `.claude/skills/wrap-work/SKILL.md` Step 1。

---

## D. 何时创建一份新的项目 CLAUDE.md

第一次 `/wrap-work` 进一个新项目时，skill 会问用户：

> "这是新项目吗？要不要 scaffold `<project>/CLAUDE.md`？"

如果用户确认 → 从 `meta/templates/project-claude.md` 模板创建，预填合理的 inferred defaults。

---

## E. 现存的 project CLAUDE.md（参考样例）

| 路径 | 项目 | 关键内容 |
|---|---|---|
| `work/sapia/projects/agents/CLAUDE.md` | Sapia agents（tia-backend）| `api/` vs `features/` 区分；domain 列表（bedrock, sse, asyncio, langgraph, redis-pubsub, terraform）；hot zones（queue.py, openapi.tia.json）|
| `projects/LLM-obs-memory/CLAUDE.md` | 本 vault 自身的 schema/skills | source 文件 scatter 在 vault + `~/.claude/skills/` + `meta/` + `claude-sync/` mirror，必须同步；domain（llm-tooling, obsidian, karpathy-wiki, bash-awk, prompt-cache, git-reflog）|

打开它们当作 worked example——看清"项目级 contract" 应该是什么样。
