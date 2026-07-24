---
name: track
description: Plane ticket 生命周期 × vault 整理的信封 workflow。开始整理某块内容前,先 **live 查询 Plane**(绝不用写死的项目列表)找对应 project → 返回给用户确认 → 项目内找对应 ticket(按名字/内容)→ 确认;没找到则问用户是否创建 → 跑中间整理(/ingest 或 /wrap-work)→ 完成后回写 structured comment + 状态置 Done。三处确认闸都交给用户。
triggers: ["track", "track this", "整理并记录", "记到 plane", "track 一下", "整理这块并同步 plane"]
---

# Track — Plane ↔ vault 整理信封

把 vault 的一次整理操作**夹在 Plane ticket 生命周期里**:前面查 Plane 定位 ticket、后面回写 comment + 状态。中间那一步是**现有的整理操作本身**(`/ingest` 或 `/wrap-work`)——本 skill 不重写它,只在它前后套上 Plane 账本。

**心智模型**:一个 Plane ticket = "一块待整理进 second brain 的内容"。整理完 = 这块内容已落地进 vault → comment 记账 + 状态 Done。

## When to use
- 用户要**整理一块内容并同步到 Plane**:说 "track"、"整理并记录到 plane"、"track 一下这块"
- 同时整理**多块**内容 → 每块各跑一遍信封(Step 1–5 循环)
- always-on rule `plane-track.md` 也会在用户"开始整理"时提醒走本 skill

**不适用**:纯 vault 整理不需要 Plane 账本(直接 `/ingest`)、健康检查(`/lint`)。

## Before starting
- 读 [[CLAUDE]] §6 The Four Operations(中间步会调 ingest/wrap-work)
- **不要**在脑子里假设有哪些 Plane 项目——项目集随时新增,**每次实时查**(Step 1)

## Workflow

### Step 0 — 读取目标内容
先搞清楚"要整理的是哪一块":inbox 里的 digest / work-capture 文件、用户贴的内容、或用户口述的"某个部分"。提取 3–5 个关键词(项目名/服务/工单号/主题),供 Step 1–2 匹配用。

### Step 1 — 定位 Plane 项目(live 查询 → ✋确认)
1. **`list_projects`**(每次都查,**绝不用写死的项目列表**——项目随时会新增)
2. 软跳过 Plane 自带 demo(identifier `MEMOR` / name `memory`),除非用户内容明确指向它
3. 用 Step 0 关键词对每个项目的 **name + description** 打分排名,选出最可能的 1(至多 2)个候选
4. **返回给用户确认**:"看起来该记到 **<project name>**(`<IDENTIFIER>`),对吗?"
   - 用户纠正 → 用用户指定的项目
   - 完全判不出 → 列出全部 project 让用户选

> 拿到确认后记下 `project_id`。

### Step 2 — 定位 ticket(按名字/内容 → ✋确认)
1. **`search_work_items(query=<关键词>)`**(workspace 级,匹配 name / sequence id / project identifier)→ 过滤到已确认 `project_id`
2. 若命中弱或为空,补一发 **`list_work_items(project_id, pql='name ~ "<关键词>"')`** 兜底
3. 列 top 候选(identifier + name + 当前 state)给用户 → **✋确认选哪个**
4. **没找到** → 明确告诉用户"该项目下没匹配到 ticket" → **✋问用户是否创建**:
   - 用户要建 → **`create_work_item(project_id, name=<取自内容>, description=<一句话>, )`**
     - 若该项目强制 work item type(如 mywork)→ 先 `list_work_item_types(project_id)` 或 `resolve_work_item_type` 取默认 type,带 `type_id`
     - 新建默认落 **Todo** 状态(收尾时才转 Done);Todo 的 state_id 从 `list_states(project_id)` 里 `group=="unstarted"` 取
     - 建完把 identifier + link 返回用户确认
   - 用户不建 → 停下问用户怎么办(可能是内容归属判断错了,回 Step 1)

> 拿到确认后记下 `work_item_id`。

### Step 3 — 执行整理(中间步)
判断走哪个整理操作,跑它、产出落进 vault:
- **默认 `/ingest`** —— 笔记 / 想法 / 学习记录 / 生活灵感 / 外部素材蒸馏 / 总结
- **`/wrap-work`** —— 这块是"完成的工作 ticket + 代码改动"(inbox 有 `task-git-digest` / work-capture 产出、涉及 3-tier 项目模型)
- 判不准 → 问用户一句走哪个

**记住整理产出**:新建/更新了哪些 vault 文件(路径/文件名)、核心一句话摘要——Step 4 要写进 comment。

### Step 4 — 回写 comment(structured + 落地链接)
**`create_work_item_comment(project_id, work_item_id, comment_html=...)`**,内容结构固定:

```
✅ 已整合入 second brain — YYYY-MM-DD

<一句话概述这块内容捕获了什么>

落地:
- <zone/path/file-a.md> — 一句话
- <zone/path/file-b.md> — 一句话
（如是 wrap-work:Tier-1 task + 影响的 feature/overview）
```

> comment 只记**摘要 + 落地路径**,不整段搬运 vault 正文(vault 才是 source of truth,Plane 是账本)。路径用 vault 相对路径(Plane 不识别 `[[wiki-link]]`)。

### Step 5 — 状态置 Done
**`update_work_item(project_id, work_item_id, state=<Done state_id>)`**
- Done 的 state_id 从 `list_states(project_id)` 里 `group=="completed"` 取
- **只在这块内容确实完整整合后才置 Done**;若只整理了一部分 → 不改状态,comment 里标注进度(与"只收尾更新"约定一致:开工不动状态)

### Step 6 — 汇报用户
中文汇报:
- **ticket**:`<IDENTIFIER> — <name>` + link
- **落地**:整理产出的 vault 文件清单
- **comment**:已贴(引用刚写的那段)
- **状态**:→ Done(或说明为何仍 In Progress/未改)

### 多块 / 多项目同时整理
用户一次给多块 → **可先批量走 Step 1–2 把每块的 (project, ticket) 都确认齐**,再逐块跑 Step 3–5。每个 ticket 独立记账、独立置 Done。

## Rules
- **项目集动态,永远 live 查** —— Step 1 必须 `list_projects`,**绝不主观假设/写死项目列表**(用户明确要求)
- **三处 ✋ 确认闸不可跳**:①项目 ②ticket ③没 ticket 时是否创建。用户没确认不往下走
- **状态只收尾**:开工不碰状态;完整整合才 Done
- **comment 不搬正文**:摘要 + 落地路径,vault 是 source of truth
- **中间步复用现有 skill**:不在本 skill 里重写 ingest/wrap-work 的分类/落位逻辑
- **失败不静默**:Plane 调用失败(找不到项目/建不了 ticket)→ 明确告诉用户,别假装记好了

## Tools used
- Plane:`list_projects`、`search_work_items`、`list_work_items`、`list_states`、`list_work_item_types`/`resolve_work_item_type`、`create_work_item`、`create_work_item_comment`、`update_work_item`
- 中间步:`/ingest` 或 `/wrap-work`(各自的 Read/Grep/Write/Edit)

## Output format
完成后一条中文汇报:**ticket(link) · 落地文件 · comment 已贴 · 状态 Done**。多块则逐条列。
