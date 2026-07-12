---
title: Style Guide — Language Convention + Prose Density + Markdown Layout
id: meta/style-guide
category: reference
status: active
tags: [meta, style, language, prose, markdown, vault-schema]
created: 2026-05-03
updated: 2026-05-10
---

# Style Guide — Language Convention + Prose Density + Markdown Layout

vault 写作的三个 critical 风格规则。Root `CLAUDE.md` §10 只摘最高层原则；本文是详细规则、worked examples、anti-patterns 的 source of truth。

写 `knowledge/`、`experience/lessons/`、`features/<feat>.md`、`api/<feat>.md`、`decisions/NNNN-*.md` 等 narrative 页时**必须**遵守。轻 reference（log entries、wiki.md tables、frontmatter）按各自规则。

---

## A. 语言约定 Language Convention

### 目标 Goal

让用户读得舒服（中文母语）**同时持续吸收英文技术词汇**——vault 同时充当学习工具。中文做散文骨架，英文做技术锚点；两者**不是平行翻译**，而是有机融合。

### 规则

- **`CLAUDE.md` 保持纯英文**——它是技术 reference，consistency 重于 readability
- **其他所有页**：**Chinese-leading bilingual**

### 散文 / 解释 / 分析 → Chinese-leading（核心规则）

正文段落以中文为主，英文术语**直接 inline 嵌入**句子。**禁止反向**（英文为主、括号塞中文翻译）。

#### 哪些英文术语应该 inline 保留

让它们自然待在中文句子里，**不需要括号**：

- **技术概念**：race condition、idempotent、deep-merge、optimistic write、cross-region inference、structured output、prompt injection、exactly-once、opt-in、snapshot supersede、...
- **库 / API / SDK 名**：`asyncio.create_task`、Bedrock Converse API、`Threads.patch`、`wait_for(timeout=...)`、...
- **架构词汇**：SSE、ADR、MOC、Zettelkasten、frontmatter、supersede、changelog、ingest、lint、...
- **专有名词**：AWS、Bedrock、Datadog、Redis、Postgres、Obsidian、...
- **值得学的高价值词**——即便有中文也用英文：`dedup` 而不是"去重"、`fallback` 而不是"回退"、`invariant` 而不是"不变量"。**目标是词汇 acquisition**

### Headers / Frontmatter / 代码

- **H1**：与 filename 一致（英文）。可选下一行加中文副标题
- **H2 / H3**：**中文在前 + 英文后缀**，例如：
  - `## 上下文 Context`
  - `## 模式 The pattern`
  - `## 边界情况 Edge cases`
  - `## 已知应用 Known applications`
  - 中文便于扫读、英文做跨文档一致性 + 学习锚点
- **frontmatter 值**：`title` 英文（与 filename 一致），tags 小写英文
- **代码 / 命令 / 文件路径 / config keys / 报错信息**：英文（trivially 必须）
- **模板里的占位符**：中文（`_填写：..._`）

### Why 这条规则

读母语 fast；遇到英文术语 inline 是词汇 sticking 的方式。每段都"中（英）"括号 ping-pong（`并发 (concurrency)`）反而更糟——它打断阅读 rhythm 又没真的教会读者英文。直接写"用 `asyncio.create_task` 启动一条 concurrent task"——既流畅又教学。

---

## B. 散文密度 Prose Density and Readability（CRITICAL）

### 目标 Goal

vault 页面应该读起来像**一个懂行的同事在耐心解释**——而不是密集压缩的 reference notes、假设读者已经懂每个术语。**长度本身既不是优点也不是缺点——clarity is the only thing that matters.**

### Required style 必须遵守的写法

#### 1. Narrative 优于 noun-phrase chains

陈述一个 invariant 或 property 时，带读者走一遍 *什么* 在做事、*为什么* 这些组件拼起来就能保证这个 property、这个 property 给 downstream **带来什么**。**不要堆名词短语**像：

> ❌ "first_message 直发分支与 ai/fallback 分支互斥保证 exactly-once SSE"

这一句要求读者已经精确理解"直发分支"、"互斥"、"exactly-once" 在本上下文下的含义，违背了页面存在的目的。

#### 2. 第一次出现 jargon 必须定义

哪怕是你自己临时造的词——如果你写"the direct-send branch"，**同一段**就要解释 direct-send 在这里指什么。不要让读者去猜或去翻。

#### 3. 跟一个 worked example

陈述完 invariant，紧跟一段具体的 trace：

> "Imagine a run where the user opted in and the first message has 50 characters. The worker calls `prepare` → it sees opt_in=True and len=50≥20 → writes the first_message placeholder to metadata → returns the truncated input → worker spawns the AI task → ..."

Examples 是 invariants 真正被读者**内化**的方式。

#### 4. 永远说 consequence（the "so what"）

陈述完 "exactly-once SSE" 后必须跟："**which means** the front-end can simply subscribe and overwrite on receipt — **no need to dedupe and no need to time-out-wait**"。否则读者只会想"OK，所以呢？"

#### 5. 消除歧义的 verbosity 是好的

一句话重新解释一个读者可能在 page 3 处已经忘掉的概念，**比让读者 reread 整页便宜得多**。

#### 6. 用 connective phrases 强迫自己解释因果链

"because"、"so that"、"this means"、"concretely"——这些连接词逼你**真的解释**因果链而不是只罗列事实。

### Counterexample 反例（不要这样写）

> ❌ "Exactly-once SSE per run — `prepare_title_generation` 的 first_message 直发分支与 `generate_and_publish_title` 的 ai/fallback 分支互斥保证。前端无脑订阅 `title` 事件。"

问题：读者不知道"branch"对应代码里什么、"互斥保证"在结构上什么意思、为什么这两个 function 互斥、"无脑订阅" 在实际操作上得到什么。**句子技术上正确但什么也没教**——它只是在确认那些已经懂的人本来就会写的东西。

### Good 正面范例（应该这样写）

> ✅ "**Exactly-once SSE per run** — 每次 thread run 一定恰好发出一次 `title` SSE 事件给前端，不会零次也不会多次。
>
> 怎么保证：标题流水线在代码层面有**两条互斥的路径**，每个 run 只走一条。
>
> - **路径 A**：worker 一开始就调 `prepare_title_generation`。如果这个 run 不应该走 AI（用户没 opt-in、首条消息太短或不存在等），`prepare_title_generation` **当场**就发一次 `first_message` 类型的 SSE，然后返回 None 告诉 worker '不用启动 AI 任务'。
> - **路径 B**：如果应该走 AI，`prepare_title_generation` 不发 SSE，只返回截断后的用户输入。worker 启动一个并发的 `generate_and_publish_title` 任务；这个任务无论拿到 AI 结果（发 `ai_generated`）还是失败（发 `first_message` fallback），都恰好发一次 SSE。
>
> 互斥发生在哪：`prepare_title_generation` 这个函数本身。它内部决定走哪条路径，所以两条路径绝不会同时触发。
>
> 这个承诺给前端带来什么：前端订阅 `title` channel 后可以直接覆盖渲染，**不需要 timeout 等 AI**、**不需要去重**。"

Good 版本是 bad 版本的约 5×。**这是教学时正确的比例。**

### When density is OK 何时密集是 OK 的

- **Frozen task files**（`tasks/**`）——读者画像是"6 个月后的写作者本人，已经懂这个 codebase"。bullet 密度可以接受。但 invariants section 仍要 narrative
- **Mermaid / code blocks 内**——syntax 本身就是解释
- **表格 + 清晰的列名**——schema 在 header 里
- **Changelogs / weekly logs / project log.md**——简短 bullet 是预期，这是 timeline 脚手架不是 pedagogy

### What this rule does NOT mean 这条规则不等于

- ❌ 为长度而 padding——重复自己 without 加 clarity 同样糟
- ❌ 禁止所有 jargon——技术词汇属于这里，**只是要在 first use 介绍**
- ❌ 第一段重述页面标题——从 sentence 1 就开始 add value
- ❌ 处处 "tutorial mode"——参数表、文件 layout 等 quick reference 片段保持 terse

### Where this rule applies most 重点适用区

- **`features/<feat>.md` 和 `api/<feat>.md`**（Tier-2）——这是用户点进去理解功能的页面。"关键不变量 / Architecture / Configuration / API" sections **必须教学**
- **`knowledge/<domain>/<concept>.md`**——这些页面存在的意义就是**解释概念**；如果读起来像 cheat-sheet 就失败了
- **`experience/lessons/<slug>.md`**——lesson 是关于*为什么*某事重要，需要 narrative
- **`decisions/NNNN-*.md`**——ADR 至少包含 Context / Options / Decision / Rationale；每个 section 都需要 prose

### Where it applies less strictly 适用较宽松的

weekly logs、change logs、frontmatter、MOC entries（一句话描述 OK）、wiki.md / log.md 索引。

---

## C. Markdown 排版 Layout（CRITICAL — visual readability）

### 目标 Goal

写出来的 Markdown 在 **Obsidian / GitHub / 任何 standard renderer** 里读起来要**视觉上有呼吸感**——不是密集压成一个块的文字砖。源文件 line break 不等于渲染换行；**渲染换行靠空行和 list 项**。

### 核心规则 The rules

#### 1. 段内枚举 ≥ 3 个 → 必须改成 list（最重要）

源里写 `(1) ... (2) ... (3) ... (4) ...` 一连串，渲染出来是**一整团没有视觉分隔的文字**——即便源里有句号也只是流水句而已。**必须**展开成实际的 numbered list（`1.` / `2.` / `3.` 各自起一行）：

❌ **Bad**（渲染成一个文字砖）：

```markdown
`TextFeatureService` 是文本特征计算的核心 service，负责：(1) 从 `supported_feature_versions.json` lazy-load + cache 支持的 feature 版本列表；(2) 对入参 feature list 做语言过滤和版本校验；(3) 用 `ThreadPoolExecutor(max_workers=4)` 并行向四个 calculator 分发；(4) 若传入 `translated_text_frame`，对翻译文本再跑一遍并合并结果。
```

✅ **Good**（每条职责一行，扫读友好）：

```markdown
`TextFeatureService` 是文本特征计算的核心 service。主要职责：

1. **Lazy-load + cache** — 从 `supported_feature_versions.json` 读取并缓存支持的 feature 版本列表
2. **语言过滤 + 版本校验** — SAIGE features 多语言免过滤，其余严格匹配语言
3. **并行分发 + 聚合** — `ThreadPoolExecutor(max_workers=4)` 向四个 `RemoteFeatureCalculator` 分发
4. **翻译文本二次合并** — 若传入 `translated_text_frame`，对翻译文本再跑一遍并 `__iadd__` 合并
```

**判断标准**：源里出现 `(1) ... (2) ... (3) ...`、"第一... 第二... 第三..."、"Step 0 → Step 1 → Step 2 → ..." 这类 inline 枚举且 **≥ 3 项** → 一律换 list。**2 项**可以保留 inline（`先 A 再 B` / `(a) X，(b) Y` 都 OK）。

#### 2. 多步骤流程描述 → numbered list（不是一段流水句）

凡是讲"先做 X、再做 Y、然后 Z、最后 W"的 procedure，写成 numbered list。每步前可以加 **bold label**，描述放在 dash 之后：

✅ **Good**：

```markdown
Build 流程（`WorkspaceSaigeController.handle_workspace_build_request`）：

0. **幂等检查** — 查 DynamoDB；version 已存在则 raise `ValueError`
1. **Generate artifacts** — `ArtifactGeneratorService.generate_artifacts` 同步生成 pickle + JSON + TI JSON 到 `/tmp`
2. **Upload to S3** — `ArtifactUploaderService.upload_artifacts`，primary bucket
3. **Register Question Bank** — `QuestionBankService.register_kpi_model`（GraphQL；失败仅 log error 不回滚）
4. **Persist metadata** — DynamoDB `put_item`，status = `AVAILABLE`
5. **Return** — DTO
```

#### 3. 段落之间留空行；段落内部按逻辑边界分段

每个段落聚焦**一个 sub-claim**。当一段超过 ~5 行 rendered output 还在讲不同的事 → 在自然边界（`.`、`。`、新主语）处分段，加空行。

#### 4. Sub-section 内段落开头不需要再重复 H3 标题

H3 已经给了 section 名（"What 功能描述"、"Implementation Summary"），段落 body 直接进入正文，不要再写 "What:" 或重复标题。

#### 5. Headers 之间留空行

Markdown spec 不强制，但 Obsidian 在某些情况下吞 newline。每个 H2/H3/H4 上下都留空行。

#### 6. 何时**不**要 list

- **散文论证 / narrative**——"because X, so Y, this means Z" 这种因果链是 prose 不是 list（参见 §B 规则 6）
- **2 项 inline**——"先 A 再 B" 不需要拆 list
- **frontmatter / 表格 / log entry**——本来就有结构

### Worked example：what / implementation 改写

❌ **Before**（密集 inline 枚举 + 多 step 流水句）：

```markdown
## Implementation Summary 当前实现

`get_customer_model_response` 的执行路径：(1) `_extract_data` — 加载 EFS pickle model（`lru_cache`，32 条）、将 DTO 转换为 domain `TextFrameItem` / `UUIDInfo`；(2) `_fetch_features_and_flags` — `ThreadPoolExecutor` 并发提交 feature 计算（调 `TextFeatureService`）和 flag 计算（调 `RemoteFlagCalculator` → `flagging-service` Lambda invoke）；(3) `_generate_response` — 先检查英文 garbage/quality flags，若触发则返回 `DefaultLowScore`；否则检查 non-source-language flag；最后调 `CustomerModelService.calculate_model_score`（`model.predict(features)`，下限 0.01）。
```

✅ **After**：

```markdown
## Implementation Summary 当前实现

`get_customer_model_response` 的执行路径：

1. **`_extract_data`** — 加载 EFS pickle model（`lru_cache(maxsize=32)`），把 DTO 转换为 domain `TextFrameItem` / `UUIDInfo`
2. **`_fetch_features_and_flags`** — `ThreadPoolExecutor` 并发提交两路：feature 计算（→ `TextFeatureService`）和 flag 计算（→ `RemoteFlagCalculator` → `flagging-service` Lambda invoke）
3. **`_generate_response`** — 决定打分路径：
   - 先检查英文 garbage / quality flags；若触发则返回 `DefaultLowScore`
   - 否则检查 non-source-language flag
   - 最后调 `CustomerModelService.calculate_model_score`（`model.predict(features)`，下限 0.01）
```

### Anti-patterns 反例

- ❌ 把 3+ 项的 `(1)/(2)/(3)` 留在一句话里（源里 trailing 句号也救不了——渲染没换行）
- ❌ 用 `<br>` 强制换行——破坏 list 语义和 portability
- ❌ 整段不带 list 但塞进 5+ 个 sub-claim
- ❌ Headers 之间不留空行（Obsidian 吞掉变成大段无标题文字）
- ❌ 在已经有 numbered list 的同一 section 再重复 inline 枚举
- ❌ 嵌套 list 超过 3 级（视觉乱）

### Where this rule applies

- **本规则适用于所有 narrative 页**——`features/`、`services/`、`modules/`、`api/`、Tier-3 `<project>.md`、`knowledge/`、`experience/lessons/`、`decisions/`
- **frozen task files、changelogs、wiki tables、frontmatter** 不强制（本来就紧凑）

### 一句话 takeaway

> **源里出现 `(1) ... (2) ... (3) ...` 或 "Step 0 → Step 1 → Step 2 → ..." → 一律展开为 numbered list。** 段落超过 5 行还在讲不同的事 → 分段加空行。源 line break 不等于渲染换行——**渲染换行靠空行和 list**。

---

## 一句话 takeaway（可贴在每个写作 session 顶部）

> 写中文散文 + 英文技术术语 inline。陈述一个 invariant 时一定要 (a) 解释*什么*在保证它、(b) 给一个 worked example、(c) 说明 consequence。**3+ 项枚举或多步流程一律展开为 list；段落留空行**。Length 不是问题，clarity is the only thing that matters.
