---
name: wrap-work
description: 项目任务收尾：把 inbox 里的 task-git-digest + brain-digest 文件按"3-tier 项目模型"分发到 vault。Step 0 先确认本次面向哪些 inbox 文件（一个任务可能跨多个 digest）。然后写 Tier-1 task 文件（frozen）、提取 knowledge / experience、对 Tier-2 unit(s) 走 **hybrid SURVEYOR reconcile**（LLM incremental 或 spawn project-surveyor agent re-scan）+ snapshot-supersede 老 SURVEYOR 块 + WRAP-WORK 块 append Timeline。Tier-3 仅在 unit 集合 / 边界变化时动 SURVEYOR。task 文件 write-once，写完不再读不再改，节省后续 token。
triggers: ["wrap-work", "wrap up", "完工", "做完了", "收工", "today's work", "this week's work", "归档工作", "wrap this task"]
disable-model-invocation: true
---

# Wrap Work

`/ingest` 的**项目任务收尾专用版**，按 [[CLAUDE]] §2.1 的 3-tier 项目模型把 inbox digest 分发进 vault。

场景：一个工单 / branch / 任务结束，用户在 session 里跑了 `task-git-digest`（git 改动）和/或 `brain-digest`（session 思路），inbox 里堆了若干 digest 文件。`/wrap-work` 把它们 fuse 成**一个 Tier-1 task 文件**（frozen），并把影响**逐层往上**传播到 Tier-2 unit(s) 和 Tier-3 project overview。

**关键机制（new）**：每次 task 完成，wrap-work **主动** supersede affected Tier-2 unit 的 SURVEYOR 块——hybrid 模式：

- **LLM incremental** (默认快路径) — 用 (老 SURVEYOR + git_diff_summary + task digest) 推新 SURVEYOR，适合 bug fix / 内部 refactor
- **Surveyor agent re-scan** (升级慢路径) — spawn project-surveyor with `scope: single-unit`，重扫 unit source_paths + satellite_paths 重生 SURVEYOR，适合架构变更 / 加新组件 / 改接口

设计 source of truth: [[meta/project-overview-system]] §3 (owner 规则) + §8 (wrap-work 集成)。

## When to use
- 一个 ticket / feature / branch 完成，inbox 已收到对应的 digest
- 用户说 "wrap up"、"完工"、"做完了"、"wrap this task"

**不适用**：纯知识 ingest（用 `/ingest`）、健康检查（用 `/lint`）、还在做没收尾（让用户接着做）。

## Before starting
Read 这几节（如果上下文还没有）：
- [[CLAUDE]] §2 Directory Map
- [[CLAUDE]] §2.1 Project Multi-Tier Model（**核心**）
- [[CLAUDE]] §3 Frontmatter Schema（`frozen` 字段）
- [[CLAUDE]] §4 Naming Conventions（task 路径、superseded 命名）
- [[CLAUDE]] §7 Supersede patterns 入口（详细规则见 [[meta/supersede-patterns]]——本 skill 涉及 §C Snapshot Supersede 和 §D Frozen Files）
- [[CLAUDE]] §8 Ephemeral vs Durable
- [[CLAUDE]] §10 Claude 行为
- [[CLAUDE]] §13.5 Project-level CLAUDE.md
- [[meta/project-overview-system]] §3 (owner 规则) + §4.7 (Tier-2 SURVEYOR 内容) + §8 (wrap-work hybrid reconcile flow) + §9 (re-run policy — incremental drift 警告)

## User-facing 输出原则（hard budget）

为了控制每次 wrap-work 的 token 消耗，所有给用户看的文本（不是写进文件的内容）有硬性长度上限：

- **Plan 展示**（Step 0 末尾 / Step 4 / Step 5 给用户看的"计划"）≤ 35 行。只列：(1) inbox 候选 + 选择；(2) Tier-1 task 路径；(3) Tier-2 affected units + 各 unit 的 hybrid I/R 决策；(4) knowledge / lesson / ADR 候选；(5) 需要用户回答的问题。**禁止解释"为什么这么分类"**（用户问了再答）。**禁止贴对比表格**（除非 ≥ 3 个候选需要选）。
- **完成报告**（Step 7d）≤ 18 行。格式见 "Output format" 段。
- **Tool result 之间的过渡说明** ≤ 1 句话，不要每步都写"现在开始 X"。
- **设计取舍 / 推理叙述**已经在 vault root `log.md` 的 wrap-work entry 里记录 —— **禁止在屏幕上重复一遍**给用户。用户要看会自己打开文件。

这些 budget 是硬上限，不是建议。超 budget 比给的信息少更糟糕（token 浪费 + 用户阅读疲劳）。

## Workflow（7 阶段）

### Step 0 — Inbox triage（必做，先确认范围）

**为什么必须先确认**：一个任务可能横跨多个 digest 文件（用户在任务没彻底完成前就跑过 `task-git-digest` 和/或 `brain-digest`），inbox 里会堆几个相关文件。如果不先确认范围就一股脑处理，会把不相关的 digest 也混进当前 task。

1. **列 inbox**：
   ```bash
   ls "$VAULT/inbox/"*.md
   ```
2. **过滤 digest 候选**：frontmatter 里 `source: brain-digest` 或 `source: task-git-digest` 或 `source: task-digest`（兼容老名）的视为 digest。其他 `.md` 视为"手动放进来的，不自动处理"。
3. **轻读元数据**（**禁止读全文**）：每个候选 `Read` 时**严格用 `limit: 60`**（够拿到 frontmatter + Outline / Task Summary 第一段）。**不许**把全文塞进 context —— 后续 Step 2 写作阶段会按 topic 局部读（offset+limit 定位到具体 topic 标题行）。这条是 token 优化的关键之一。
4. **展示候选清单**给用户，按 created 时间升序。每行包含：
   - filename
   - source（task-git-digest / brain-digest）
   - 关键 frontmatter（task-git-digest 看 `project` + `branch` + `commit_count`；brain-digest 看 `topic_count` + classification_hints）
   - 一句话摘要
5. **询问范围**：
   ```
   本次 wrap-work 处理哪些文件？
     [a] 全部
     [b] 同一任务相关（请选编号，例：1,3）
     [c] 全部跳过
   ```
6. **关键判断**（如果用户选 b）：让用户给出"本次任务的关键标识"（branch 名 / ticket 号 / 项目+功能描述）。**这一步决定 Tier-1 task 文件的命名和 Tier-2 unit 路由**。

如果 inbox 里没有 digest 候选 → 告知用户"没有可处理的 digest"，停止。

#### When NOT to use TaskCreate

Wrap-work 是**线性流程**（triage → 写 task → 写 knowledge/lesson/ADR → 更新 Tier-2/Tier-3 → 更新 meta → cleanup），每步顺序执行、互相依赖，不会忘。**不要为线性流程建 TaskCreate tracker**。每次 TaskCreate / TaskUpdate 调用都触发 hook 噪音（"Spawning agent: unknown"、"Multiple tasks delegated"），这些是空成本。如果某步发现遗漏需要回头补，直接做即可。

例外：当任务**真的需要并行追踪多个独立子任务**（如同时跑多个 digest 的不同 wrap）才用 TaskCreate。本 skill 默认场景永远不需要。

### Step 1 — 项目识别 + 读项目级 CLAUDE.md

从选中的 digest 中提取项目名（task-git-digest 有 `project:` 字段；brain-digest 看 classification-hint 的 project 提示）。

1. 解析项目路径：`work/<co>/projects/<proj>/` 或 `projects/<name>/`。
2. **如果路径不存在** → 告知用户"项目目录不存在，先创建项目骨架吗？"。如果用户同意：
   - mkdir 项目目录 + `tasks/`、`features/`、`superseded/`、`decisions/`、`learnings/`、`references/`、`log/`
   - 用 `${CLAUDE_PLUGIN_ROOT}/templates/project-overview.md`、`project-wiki.md`、`project-claude.md`、`project-log.md` 初始化 `<proj>.md`、`wiki.md`、`CLAUDE.md`、`log.md`（模板不存在则按 §13.5 + §2.1 现写）
3. **读 `<project>/CLAUDE.md`**（[[CLAUDE]] §13.5）：
   - 哪些文件夹跳过 grep（`tasks/**`、`superseded/**` 默认跳过）
   - 哪些文件必读
   - 知识抽取规则（什么 domain 的内容应升到 `knowledge/`）
   - **`code_roots`** nested schema（含 kind/role/mapping_strategy）— Step 4 hybrid R 路径 spawn surveyor 时要传
   - **`infra_mapping_rules`** / **`unmapped_satellite_paths`** — 如有 manual strategy 的 satellite
4. **读 `<project>/wiki.md`**：拿到当前项目目录索引，知道现有有哪些 units，避免新建重复。
5. **读 `<project>/<project>.md`**：Tier-3 视图，了解整体架构，判断本任务是否会触发 Tier-3 update。

### Step 2 — 写 Tier-1 task 文件（frozen，write-once）—— **委派给 `digest-fuser` agent**

**Main thread 不再直接读 digest 内容**。Step 0 已经从 frontmatter 拿到 metadata + outline；Step 2 把"读所有 digest 全文 + 按规则 fuse 成 task 文件 body"完整委派给 `digest-fuser` agent（Agent tool，`subagent_type: digest-fuser`——plugin 自带，按名解析）。这是 token 优化的核心机制——digest 内容（常 10-30k chars 每个）**永不进入 main 线程 context**。

#### 2a. 决定 task 文件路径

按 [[CLAUDE]] §3 / [[meta/frontmatter-and-naming]] 命名：

```
<project>/tasks/YYYY/Mmm/YYYY-MM-DD-<task-slug>[-TICKET].md
```

- `YYYY-MM-DD` = task 主要工作日期（task-git-digest 的 `created` / 用户给的日期）
- `<task-slug>` = 3-6 词 kebab，最能描述任务（branch 名 / 用户给的标识）
- `[-TICKET]` = 可选 ticket 后缀（`-ED-1514` / `-ML-1196`）；无则省略
- `Mmm` = 三字母月份

#### 2b. 调 digest-fuser agent

用 Agent tool，`subagent_type: digest-fuser`。Prompt 给它**所有它需要的输入**（自包含——它没看 main 上下文）：

```
请 fuse 以下 inbox digests 成一个 Tier-1 task 文件 body。

digest_paths:
  - <vault>/inbox/<digest-1>.md
  - <vault>/inbox/<digest-2>.md   (如有)

project_path: work/sapia/projects/agents   (或 projects/<name>)
task_title: <人类决定的标题>
task_date: YYYY-MM-DD
task_slug: <kebab slug>
ticket: ML-1196                            (无则空字符串)
vault_root: /Users/yiding/Documents/YisBrain

按你的 SKILL.md 输出 TASK_FILE_BODY + NOTES_FOR_MAIN_THREAD 双段落。
```

#### 2c. Agent 返回 → 写文件

Agent 返回两段（用 marker 包裹）：

- `TASK_FILE_BODY: ... END_TASK_FILE_BODY` —— 完整 task 文件内容，**严格遵循 [[memory-summary-spec]] 的 6 段记忆结构**（概述 / 流程图 / 实现逻辑 / 问题与方案 / 关键决策 / 回忆钩子）+ frontmatter + 🧊 banner + Related。**mermaid 流程图必产**（见 spec §6）；**禁止**行号/文件 diff、Commit Timeline、Before-After 代码堆砌——git 改动只作素材，翻译成"做了什么/为什么/怎么解决/沉淀什么"。
- `NOTES_FOR_MAIN_THREAD: ... END_NOTES` —— 给 main 用的元信息：
  - `digests fused: <count>`
  - `features candidates`: agent 从 digest 内容提取的 likely feature 名（**Step 4 用——决定 Tier-2 update 时的候选**）
  - `paths_touched`: 改动文件列表（Step 4 路由用）
  - `code_root_name`: digest 写入的 root prefix（Step 4 prefix 拼接用）
  - `git_diff_summary`: per-file change summary（**仅** Step 4 hybrid I 路径 / Tier-2 SURVEYOR 推断用——**不进 task 记忆正文**，task body 只留逻辑/问题/决策）
  - `task_change_kind_overall`: 任务整体改动类型（**Step 4 hybrid 决策的 primary signal**）
  - `knowledge candidates`: brain-digest 里 non-project-task 的 topic 列表（**Step 3 用——这些要 dispatch 给 `knowledge-extractor` agent**）
  - `discrepancies`: 两个 digest 间冲突点（如有，main 决定怎么处理）

Main 提取 TASK_FILE_BODY 内容 → `Write` 到 2a 决定的路径。文件**写完即冻结**（[[CLAUDE]] §7 / [[meta/supersede-patterns]] §D）；frontmatter 已含 `frozen: true` + 🧊 banner。

#### 2d. 缓存 NOTES 给 Step 3 / Step 4 用

Main 把 NOTES 各字段（features candidates, paths_touched, code_root_name, git_diff_summary, task_change_kind_overall, knowledge candidates）存在脑子里（或一个临时 plan 显示给用户）。**不要再去打开 digest 文件**——下游所有需要 digest 内容的工作已经由 agent 做完。

**Anti-patterns**:
- ❌ Main thread 用 Read 打开 digest 全文——digest-fuser 的存在就是为了避免这个
- ❌ Main thread 用 Read offset+limit 读 digest 部分段——也不需要，agent 已 fuse 完
- ❌ 跳过 agent 直接 inline 写 task 文件——除非 trivial 1-digest 0-topic 场景且 digest <2k chars，否则**总是走 agent**

### Step 3 — Knowledge / Experience / Decision 提取 —— **委派给并行 `knowledge-extractor` agents**

Step 2 的 NOTES 已列出 `knowledge candidates`——brain-digest 里 `classification` 不是 `project-task` 的 topic 列表（含 topic header + classification hint）。Step 3 把每个 topic **并行**分发给 `knowledge-extractor` agent（`subagent_type: knowledge-extractor`——plugin 自带，按名解析）处理，main thread 只协调推荐 + 用户确认 + 实际 Write。

#### 3a. 并行 spawn N 个 knowledge-extractor

对每个 candidate topic（**同一个 message 里多个 Agent tool call** 让它们并行跑）：

```
subagent_type: knowledge-extractor

请分析此 topic 并推荐写入位置。

digest_path: <vault>/inbox/<brain-digest-file>.md
topic_header: ## <topic title>      (Step 2 NOTES 给的)
topic_classification: knowledge     (or experience / decision / other)
vault_root: /Users/yiding/Documents/YisBrain
project_path: <Step 1 决定的路径>

按你的 SKILL.md 输出 RECOMMENDATION + TOPIC_BODY 双段落。
```

并行收益：N 个 topic 几乎同时分析完，main 拿到 N 份 recommendation——比串行省 N-1 个 LLM round-trip。

#### 3b. 整理推荐 + 询问用户（一次性）

收齐所有 agent 返回后，在**一个 plan**（≤35 行 user-facing）里列：

```
Knowledge / Experience / Decision 候选（agents 分析完）：

1. <topic A> → NEW knowledge/<domain>/<slug>.md
   related: [[page-1]], [[page-2]]
2. <topic B> → UPDATE-CHANGELOG knowledge/<existing>.md
   related: [[page-3]]
3. <topic C> → NEW experience/lessons/<slug>.md
   related: [[page-4]]
4. <topic D> → INBOX (无明确归属，让我后续 ingest)

要写入哪些？(1,3 / all / none)
```

用户回答后：

#### 3c. 按用户选择写入

对每个用户确认的 recommendation，main thread Write 文件：

- **NEW**：用 agent 返回的 TOPIC_BODY 当 draft + 加 frontmatter（per [[meta/frontmatter-and-naming]]）+ Write。然后跑 `/ingest` Step 5-7 的简化版（cross-zone grep + 双向 link + MOC + zone wiki/log update）
- **UPDATE-CHANGELOG**：Edit 老页 + 加 `## Changelog` 行（[[meta/supersede-patterns]] §B）
- **UPDATE-SUPERSEDE**：按 [[meta/supersede-patterns]] §A 流程（新建 + 老页 banner）
- **INBOX**：写到 `inbox/<slug>.md`，告知用户"半成品已存 inbox，等成熟再 ingest"

#### 3d. 更新 task 文件 `## Related` 段

把所有写入的 [[link]] append 到 task 文件的 `## Related` → `Knowledge extracted:` / `Decisions extracted:` 行（这是 task 文件**唯一**允许写完后改的字段；其他保持 frozen）。

**Anti-patterns**:
- ❌ Main thread 自己 grep / 决定 NEW vs UPDATE——agent 已经 evaluate 过，trust the recommendation（除非用户 reject）
- ❌ 串行处理 candidates——并行 spawn 所有 agent 才有意义
- ❌ Main thread 重复读 brain-digest 的 topic 内容——agent 返回的 TOPIC_BODY 已经够用

### Step 4 — Tier-2 SURVEYOR + WRAP-WORK reconcile（hybrid 模式）

任务的"功能视角"。每个任务影响 1-N 个 Tier-2 doc（feature / service / module / api）。

**核心新机制（[[meta/project-overview-system]] §8）**：

- **SURVEYOR 块**: wrap-work 主动 supersede——hybrid 路径决定 incremental (I) vs re-scan (R)。这是和老规则的最大差别——老规则下 wrap-work 只动 WRAP-WORK 块，新规则下 SURVEYOR 块也是 wrap-work 的 writer 之一（与 /project-decompose 共享 SURVEYOR ownership，靠 snapshot-supersede 协调）
- **WRAP-WORK 块**: 仍 append-only——加 Timeline entry + bump Changelog

#### 4a. 自动路由 from source_paths（含 code_root prefix）

从 digest-fuser NOTES 拿:

- `paths_touched`: 改动文件列表
- `code_root_name`: 本 digest 属哪个 root（用于加前缀）
- `git_diff_summary`: per-file change summary（**hybrid I 路径输入**）
- `task_change_kind_overall`: 任务整体改动类型（**hybrid 决策的 primary signal**）

**Prefix paths 再 match**: 把每条 path prefix 上 `<code_root_name>/`:

```
paths_touched_prefixed = ["<code_root_name>/<path>" for path in paths_touched]
```

例: `code_root_name: app` + `paths_touched: [src/auth/oauth.py]` → `[app/src/auth/oauth.py]`

对项目内每个 Tier-2 doc 用 Glob + Read frontmatter 拿 `source_paths` 字段（这些已带 prefix）:

```bash
for f in "$project"/{features,services,modules,api}/*.md; do
  [[ -f "$f" ]] || continue
  # Read 该文件 frontmatter 的 source_paths（仅 frontmatter，不读全文）
done
```

对每个 (prefixed_touched_path, doc.source_paths) 做 glob 匹配（shell `case` 或 fnmatch）。命中即 candidate doc。

**没有 `code_root_name`**（老 digest 没这个字段）:
- 提示用户："本 digest 没 code_root_name；建议在 code repo 加 .brain-vault.json + 重跑 digest（schema 见 [[meta/project-overview-system]] §4.5）"
- 用户选择继续 → fallback: 不带 prefix 直接匹配

#### 4b. Show plan + 选 hybrid 路径 per affected unit

Main thread 基于 `task_change_kind_overall` + `git_diff_summary` 给每个 affected unit 推 hybrid I/R 默认建议:

**建议 I (LLM incremental)** when:

- `task_change_kind_overall` ∈ {`bug-fix`, `internal-refactor`, `add-dependency`（仅 dep 加一个）}
- 改动只 touch 该 unit 已有 source_paths 范围内的文件
- 不引入新 component / 不改外部接口

**建议 R (surveyor re-scan)** when:

- `task_change_kind_overall` ∈ {`add-component`, `remove-component`, `change-contract`, `infra-change`}
- source_paths 边界变化（task 改了该 unit `source_paths` 范围外的文件，用户决定纳入该 unit）
- satellite_paths 变化（动了 infra repo / deploy repo）

**`mixed` 或不确定** → ask user。

```
本任务影响以下 Tier-2 unit（按 source_paths 自动路由）:

  Path routing (auto):
    ✅ features/oauth-login.md   (matched app/src/auth/oauth.py)
    ✅ features/auth-session.md  (matched app/src/middleware/auth.py)

  未匹配:
    - tests/auth/test_oauth.py (test 通常无需 doc)
    - app/src/billing/new-feature.py (新功能? 加进现有 unit / 新建?)

  Task change kind overall: add-component
  Hybrid SURVEYOR reconcile strategy per unit:

    [I] LLM incremental — main 推老 SURVEYOR + diff summary 出新版（快 / 便宜）
    [R] Surveyor agent re-scan — spawn agent 重读 unit source_paths + satellite_paths（准 / 慢）

    建议:
      - oauth-login:  R  (add-component → 涉及新组件，flow graph 要重画)
      - auth-session: I  (改动较小，flow graph 不变)

  确认 affected list + 各 unit strategy? (y / 调整 / override)
```

#### 4c. 对每个 confirmed unit, 执行 hybrid + supersede + append

**先 marker check**: `grep -q '<!-- SURVEYOR-OWNED START' "$LIVE"`
- 没 marker → 4f bootstrap fallback
- 有 marker → 走下面分支

##### 4c-I. LLM incremental 路径

1. **抽老 SURVEYOR 块**（shell，不读文件全文进 context）：
   ```bash
   sed -n '/<!-- SURVEYOR-OWNED START/,/<!-- SURVEYOR-OWNED END/p' "$LIVE" > /tmp/old-surveyor-<slug>.md
   ```
2. **Read /tmp/old-surveyor-<slug>.md** 把老 SURVEYOR 块内容入 main context
3. **Filter git_diff_summary**: 从 NOTES 中只挑 paths 匹配该 unit `source_paths` 的 diff entries
4. **LLM 推新 SURVEYOR**: main thread 拿 (老 SURVEYOR 块 + 该 unit filtered git_diff_summary + task title/summary + task_change_kind_overall) 推新 SURVEYOR body。保留 What/Why/IO/ImplSummary/Detailed Flow Graph/Infra Mapping/Dependencies/Consumers 全部段。
   - **粒度规则**: Detailed Flow Graph 在 incremental 模式下，**只重画发生变化的子图**；不变部分照搬 verbatim
   - **Infra Mapping 段在 incremental 模式下**: 默认保持不变（infra 一般不在 main task 里改）；如 git_diff_summary 有 satellite 路径（含 satellite root prefix），则提示升级到 R 路径
5. **写 /tmp/new-surveyor-<slug>.md**: 含 marker 行（last-surveyed 更新为今天）
6. **Snapshot supersede**:
   ```bash
   SNAPSHOT=$(${CLAUDE_PLUGIN_ROOT}/scripts/snapshot-supersede.sh "$LIVE")
   ```
7. **Shell 拼新 live**（旧 WRAP-WORK 块用 sed 抽，**不进 LLM context**）：
   ```bash
   sed -n '/<!-- WRAP-WORK-OWNED START/,/<!-- WRAP-WORK-OWNED END/p' "$LIVE" > /tmp/old-wrap-work-<slug>.md

   # main thread 已经把新 frontmatter 写到 /tmp/new-frontmatter-<slug>.yaml
   {
     echo '---'
     cat /tmp/new-frontmatter-<slug>.yaml
     echo '---'
     echo ''
     cat /tmp/new-surveyor-<slug>.md
     echo ''
     cat /tmp/old-wrap-work-<slug>.md
   } > "${LIVE}.new"
   mv "${LIVE}.new" "$LIVE"
   ```
8. **Edit Changelog**: 在 WRAP-WORK 块 `## Changelog` 段加：
   ```
   - YYYY-MM-DD: SURVEYOR reconciled by /wrap-work (incremental) → snapshot [[<snapshot-basename-no-ext>]]
   ```

##### 4c-R. Surveyor agent re-scan 路径

1. **抽老 SURVEYOR 块**（用于 agent 的 stylistic reference）：
   ```bash
   sed -n '/<!-- SURVEYOR-OWNED START/,/<!-- SURVEYOR-OWNED END/p' "$LIVE" > /tmp/old-surveyor-<slug>.md
   ```
2. **Read 该 unit doc 的 frontmatter** 拿 `source_paths` + `satellite_paths`
3. **Spawn project-surveyor agent** with `scope: single-unit`:
   ```
   subagent_type: project-surveyor

   请重扫单 unit 并产出新 SURVEYOR 块 body。

   scope: single-unit
   project_doc_path: <project>
   code_roots: <full code_roots from <project>/CLAUDE.md>
   vault_root: /Users/yiding/Documents/YisBrain
   surveyor_run: 2
   project_claude: |
     <CLAUDE.md 内容>
   target_unit_slug: <slug>
   target_unit_source_paths:
     - <from doc frontmatter>
   target_unit_satellite_paths:
     - <from doc frontmatter>
   target_unit_existing_surveyor: |
     <内容 from /tmp/old-surveyor-<slug>.md>

   按你的 SKILL.md scope:single-unit 输出。
   ```
4. **Agent 返回** SURVEY_FILE_BODY 包含一个 Unit section + NOTES。Main thread 抽出 Unit 部分（不含 Overview）→ 转换成 SURVEYOR 块 body 写到 /tmp/new-surveyor-<slug>.md（含 marker 行）
5-7. **同 incremental 流程** (snapshot-supersede + shell 拼新 live + Edit Changelog)
8. **Edit Changelog**: `- YYYY-MM-DD: SURVEYOR reconciled by /wrap-work (re-scan via project-surveyor) → snapshot [[<basename>]]`

#### 4d. Append WRAP-WORK Timeline (每个 confirmed unit, 不论 I 还是 R)

Use Edit 在 WRAP-WORK 块 `## Timeline` 段（即 `<!-- WRAP-WORK-OWNED START -->` 之后的 `## Timeline`）追加新 entry：

```markdown
### YYYY-MM-DD — <task title> ([[<task-file-id>]])
- **改了什么**: _1-2 句_
- **为什么**: _1 句_
- **SURVEYOR 更新**: incremental | re-scan
- Tier-1 详情: [[<task-file>]]
```

bump frontmatter `updated:` + `last_surveyed:` (= today)（last_surveyed 同步 marker 行的 last-surveyed）。

#### 4e. 更新 task 文件 frontmatter

`features_touched: [...]`（Step 2 留的占位）+ `## Related` 段加 `[[<feat>]]`。

如果 task 引入架构变化（add-component / remove-component / change-contract）→ frontmatter 加 `architecture_changed: true`（Step 5 用来决定是否提示用户跑 /project-survey）。

#### 4f. Bootstrap fallback（unit 还没 marker）

如果 affected unit 的 live 文件**没有 SURVEYOR marker**（项目还没 survey 过 / 这是新 unit）：

- 提示用户先跑 `/project-survey` + `/project-decompose`
- 用户拒绝立刻跑 → 走老 inline 模式（不动 SURVEYOR，只 Timeline append + bump updated:），提示这是 deprecated 路径；下次 `/project-survey` 跑 MIGRATE 时修

#### 4g. 未匹配 paths 处理

如用户决定**新建 Tier-2** → 推荐先跑 `/project-survey` 让 surveyor 抓全。如用户坚持立刻建 stub → 写 marker 占位文件:

```markdown
---
title: <Feature Name>
id: <project>/features/<feat>
category: feature
status: active
tags: [feature, <project>, ...]
created: YYYY-MM-DD
updated: YYYY-MM-DD
logical_kind: feature
source_paths:
  - <用户给的 paths>
satellite_paths: []
last_surveyed: pending
---

# <Feature Name>

<!-- SURVEYOR-OWNED START last-surveyed:pending -->

_Not yet surveyed. Run `/project-survey` + `/project-decompose` to fill this block._

<!-- SURVEYOR-OWNED END -->

<!-- WRAP-WORK-OWNED START -->

## Timeline
### YYYY-MM-DD — <task title> ([[<task-file>]])
- ...

## Changelog
- YYYY-MM-DD: created by /wrap-work (not yet surveyed; SURVEYOR block is placeholder)

## Related
- Tier-3: [[<project>]]

<!-- WRAP-WORK-OWNED END -->
```

`last_surveyed: pending` 提醒下次必跑 survey。

如用户决定**加进现有 doc 的 `source_paths`** → Edit 那个 doc 的 frontmatter `source_paths` 列表，再走 4c 流程。

### Step 5 — Tier-3 Project Overview 更新（仅 unit 集合 / 边界变化时动 SURVEYOR）

**规则（[[meta/project-overview-system]] §8.4）**：Tier-3 SURVEYOR 块（Mission / Architecture mermaid / Modules list / Integrations / Tech Stack）**仅在 unit 集合 / 边界变化时**更新。Unit 内部改动不动 Tier-3。

#### 5a. 决定要不要动 Tier-3 SURVEYOR

| 情况 | 处理 |
|---|---|
| Task 内部改 unit 实现（unit 没新增 / 没删） | **不动 Tier-3 SURVEYOR**。可能动 WRAP-WORK 块（5b） |
| Task 新增 unit | **提示用户跑 `/project-survey`** 全量 refresh Tier-3；或激进选项：wrap-work 现在 spawn project-surveyor 单跑 Overview Section re-scan + supersede Tier-3 SURVEYOR |
| Task 删除 / 合并 unit | 同上 |
| Task 改 unit slug (rename) | 同上 + 改所有引用 [[link]] |

默认: **不动 Tier-3 SURVEYOR**。task frontmatter 加 `architecture_changed: true`，在完成报告里提示：

```
本任务引入架构变化（add-component / remove-unit / ...）。
建议下次方便时跑 /project-survey 让 Tier-3 mermaid + Modules list refresh。
```

`<project>/log.md` 的 entry 里标 `Architecture: changed (pending re-survey)`（Step 6a）。

#### 5b. WRAP-WORK 块 update（Active Work / People / Repo Layout — 不走 snapshot）

1. **Marker check**: `grep -q '<!-- SURVEYOR-OWNED START' <project>.md` 确认已被 survey 过
   - **没 marker** → 提示用户跑 `/project-survey`；wrap-work 不 fallback 写 Tier-3 SURVEYOR 块
2. **如本 task 是 active focus** → 用 Edit 在 `## Active Work` 段（WRAP-WORK 块内）加：
   ```markdown
   - [[<task-file>]] — <一句话> (touched: [[<feat-1>]], [[<feat-2>]])
   ```

bump `<project>.md` frontmatter `updated:`（Active Work 段被改时）。

### Step 6 — Project Meta 更新

#### 6a. `<project>/log.md`（durable 项目变更日志）
**append-only**。一行 entry：
```markdown
## YYYY-MM-DD — <task title>
- Task: [[<task-file-id>]]
- Features touched: [[<feat-1>]]、[[<feat-2>]]
- SURVEYOR reconcile: incremental N / re-scan M
- Snapshots: [[superseded-<feat-1>-...]] × N
- Architecture: changed (pending re-survey) | unchanged
- Knowledge extracted: [[<concept>]]（如有）
- Decisions: [[<NNNN-slug>]]（如有）
```

#### 6b. `<project>/wiki.md`（频繁更新的目录索引）
按 tree architecture 维护当前项目所有文件的索引。每条：
- 路径
- 一句话描述
- 关键词（精准）
- "下次写到这里的合适内容是什么"

本次 wrap-work 涉及的新文件 / 改动文件都要在 wiki.md 里有 entry。**这是下次 wrap-work / ingest 决定写入路径的依据**，要保持精准。

更新策略：
- 新建 task / feature / superseded 文件 → 在 wiki.md 对应 section 追加
- 已有文件描述变了（如 feature 描述变化）→ 更新 wiki.md 中的描述
- bump wiki.md 的 `updated:`

#### 6c. `<project>/log/<YYYY-Www>.md`（ephemeral 周日志）
保留旧机制 —— 在本周文件追加一行简短 bullet：
```markdown
## 周X
- 完成 <task title>：<结果>。Task: [[<task-file>]]
```

#### 6d. `<project>/CLAUDE.md`（按需更新）
只在以下情况触发更新（[[CLAUDE]] §13.5）：
- 引入了新的 ticket prefix / branch convention
- 新增了一个 domain（项目第一次用 langgraph / redis / ...）
- 某个文件夹首次出现 → 更新 read-budget / must-check 列表

询问用户：
```
本任务是否引入了新约定？需要更新 <project>/CLAUDE.md 吗？
```
不需要 → 跳过。

### Step 7 — Vault 根 log + 收尾

#### 7a. 根 `log.md`
追加：
```markdown
## YYYY-MM-DD [wrap-work] — <project>: <task title>
- 处理 inbox 文件: <list>
- Tier-1 task: [[<task-file>]]
- Tier-2 units: [[<feat-1>]]、...（SURVEYOR: incremental N / re-scan M, snapshots × N+M）
- Tier-3 overview: changed (pending re-survey) | unchanged
- Knowledge / experience extracted: [[<concept>]]、...
- Decisions: [[<NNNN-slug>]]（如有）
- Project meta updated: log.md, wiki.md（+CLAUDE.md 如有）
```

#### 7b. Inbox 清理
**删除**已 fuse 的 digest 文件：
```bash
rm <vault>/inbox/<task-git-digest>.md
rm <vault>/inbox/<brain-digest>.md
```

#### 7c. Light lint
对**这次操作涉及的所有文件**做快速检查：
- task 文件 frontmatter `frozen: true` ✓
- superseded 文件 frontmatter `frozen: true` + banner ✓
- 所有新加的 `[[link]]` resolve ✓
- 每个 supersede 过的 Tier-2 doc 新 SURVEYOR 块 marker last-surveyed = today ✓
- 每个 supersede 过的 Tier-2 doc WRAP-WORK Timeline 含本 task entry ✓
- `wiki.md` 反映了所有新文件 ✓
- `<project>.md` 中的 link 全部 resolve ✓

报告任何问题。

#### 7d. 完成报告
按下面 "Output format" 给用户。

## Rules

### 内容规则
- **Tier-1 task 是 write-once**：写完冻结，不再读不再编辑（§7）。这是节省 token 的核心机制。
- **Tier-2 SURVEYOR 块 wrap-work 主动 supersede**（新规则——[[meta/project-overview-system]] §8）：每次 task 影响一个 unit 就走 hybrid I/R supersede，先 snapshot 老的再写新的。永不静默 Edit SURVEYOR 块某行。
- **Tier-2 / Tier-3 修改必先 snapshot**：§7 是硬规则，不允许 silent overwrite。**用 `${CLAUDE_PLUGIN_ROOT}/scripts/snapshot-supersede.sh` 脚本，不要手动 Read+Write 复制**。
- **WRAP-WORK 块永远 append-only**：Timeline + Changelog + Related 累积；hybrid supersede 流程**用 sed 抽老 WRAP-WORK 块**逐字 carry over 到新 live，不进 LLM context。
- **`wiki.md` 是写入路径的真相**：决定新内容写到哪之前，先看 wiki.md（不要瞎建结构）。
- **`<project>/CLAUDE.md` 决定项目内行为**：进项目第一件事就是读它（如果存在）。
- **Project-task 不进 knowledge**：实现细节归 task 文件；只有真正可泛化的概念才 promote 到 `knowledge/`。
- **Tickets 不复制**：JIRA / Linear 是 source of truth，task 文件只承载 ticket 上下文 + 实现细节 + 思路。
- **多文件前 show plan**：Step 4 + Step 5 通常会触发 2-5 个新页和 1-2 个 supersede → 先列计划再写。
- **路径不存在不要瞎建**：项目目录不存在 → 先确认是不是新项目。
- **Hybrid 默认选 I（incremental）**：除非 task_change_kind_overall 是 add-component / remove-component / change-contract / infra-change；其余都默认 I，省 surveyor agent spawn cost。
- **Tier-3 SURVEYOR 默认不动**：仅在 unit 集合 / 边界变化时才考虑动；默认 task frontmatter 加 `architecture_changed: true` 等下次 /project-survey。
- **Incremental drift 警告**：连续多次 I 路径会让 SURVEYOR 慢慢 drift（每次小推断的误差累积）。**建议季度 /project-survey 全量 sweep 兜底**。完成报告里也提示。
- **Prose 风格 (CRITICAL — [[CLAUDE]] §10 / [[meta/style-guide]])**: 写 Tier-2 unit / knowledge / lesson / ADR 时**必须用 narrative**，不许 telegraphic noun-phrase chains。Detailed Flow Graph mermaid block 后的 Notes 也按 narrative。每个 invariant 配 (a) 怎么保证它 (b) example trace (c) consequence。

### Token 经济规则（hard rules）

- **Edit 合并**：同一个文件多处改动**必须合并成 1 次 Edit**。用更大的 `old_string` / `new_string` 包住所有改动段落。`replace_all` 仅在真的全局替换时用。**禁止对同一文件做 3+ 次 Edit**。
- **TaskCreate 禁用 / Subagent 鼓励**：Wrap-work 是线性流程，**不要建 TaskCreate tracker**（Step 0 末尾"When NOT to use TaskCreate"）。但 **Agent tool（subagent）是另外一回事且强烈推荐**——`digest-fuser`（Step 2）、`knowledge-extractor`（Step 3 并行）、`project-surveyor` with scope:single-unit（Step 4c-R）让大内容**不进 main context**。
- **不读 digest 全文（main thread）**：Step 0 triage main 用 `limit: 60`；**之后 main 永不再 Read digest**——所有 digest 全文消费由 `digest-fuser` 在子 context 完成。
- **不读 Tier-2 doc 全文**：hybrid I 路径只 Read SURVEYOR 块（sed 抽到 /tmp 再 Read 那个 tmp）；hybrid R 路径主线程根本不 Read live doc 内容（只读 frontmatter 拿 source_paths/satellite_paths）。WRAP-WORK 块全程不进 main context（sed 抽 + shell 拼）。
- **Snapshot 走脚本**：`${CLAUDE_PLUGIN_ROOT}/scripts/snapshot-supersede.sh <live-file>` —— 脚本里完成 cp + frontmatter 改写 + banner，旧内容**不进 LLM context**。
- **User-facing 输出有 budget**：详见本文件顶部 "User-facing 输出原则"。Plan ≤ 35 行，完成报告 ≤ 18 行。

## Tools used
- **Agent**（**核心**——委派大内容消费给子 context）：
  - `subagent_type: digest-fuser` —— Step 2 fuse 1-N digest 成 task body + 输出 NOTES（含 git_diff_summary / task_change_kind_overall）
  - `subagent_type: knowledge-extractor` —— Step 3 **并行**分析每个 non-project-task topic
  - `subagent_type: project-surveyor` (scope: single-unit) —— Step 4c-R 单 unit re-scan
- Read（main thread 只读：CLAUDE.md、`<project>/CLAUDE.md`、`wiki.md`、`<project>.md`、Tier-2 doc 的 frontmatter (拿 source_paths/satellite_paths)、Step 4 sed 抽出来的 SURVEYOR 块 tmp 文件、Step 0 digest 元数据 `limit:60`）—— **不**读 digest 内容段、**不**读 Tier-2 doc body 全文
- Glob（`tasks/YYYY/Mmm/` 已存在文件、`decisions/` 最大 NNNN、`features/` 列表）
- Grep（Step 4 marker check；Step 7c lint 验证用；Step 3 cross-zone discovery 由 knowledge-extractor 内部做）
- Write（task 文件 body 来自 digest-fuser；新 feature 文件、新 knowledge 文件 body 部分来自 knowledge-extractor；4f bootstrap stub）
- Edit（live `<project>.md` / `features/<feat>.md` / `wiki.md` / `log.md` / `<project>/CLAUDE.md` —— Step 4d Timeline append、Step 4c Changelog append、Step 5b Active Work append；**同文件多处改动合并成 1 次 Edit**）
- Bash（**核心**：`${CLAUDE_PLUGIN_ROOT}/scripts/snapshot-supersede.sh` 做 §7 snapshot；`sed -n` 抽 SURVEYOR / WRAP-WORK 块；shell 拼新 live；`mkdir` 项目骨架；`rm` 已 fuse 的 inbox 文件；最后 lint 验证）
- TaskCreate / TaskUpdate（**禁用** —— wrap-work 是线性流程，详见 Step 0）

## Output format

完成后报告 **≤ 18 行**（hard limit）。一行一项：

- **Inbox processed**：N 个文件 fuse（列文件名，不列路径）
- **Tier-1 task**：`[[<task-id>]]` + frozen ✓
- **Tier-2 units**：`[[<feat>]]` ×N（SURVEYOR mode: incremental | re-scan；snapshot: `[[<snapshot-id>]]`）
- **Tier-3 overview**：unchanged | architecture_changed (pending re-survey) | full re-scan
- **Knowledge / experience extracted**：`[[<concept>]]` ×N
- **Decisions**：`[[<NNNN-slug>]]` ×N
- **Project meta**：log.md / wiki.md / CLAUDE.md / weekly log（列改了哪几个）
- **Inbox cleanup**：删除了 N 个 digest
- **Lint**：✓ 全过 / ⚠️ 警告列表
- **Drift warning** (如本 task 多个 unit 都走 I): "本次有 N 个 unit 走 incremental。Drift 累积；建议季度跑 /project-survey 全量 reconcile" (一行)

**严禁**重复 vault root `log.md` 已经写过的"设计取舍"段、跨链接计数、等等。用户要看会自己开 vault。

## Anti-patterns

- ❌ Main thread 用 Read 读 Tier-2 doc 全文——hybrid I 路径只 Read sed 抽好的 SURVEYOR 块 tmp 文件；R 路径根本不需要主线程读 doc body
- ❌ Hybrid 决策不让用户 confirm——必须 show plan 列每个 affected unit 的 I/R 决定，允许 override
- ❌ Incremental 路径 LLM 推 SURVEYOR 时改了 Detailed Flow Graph 大半（除真要重画）——保留不变的子图 verbatim，只动 changed 部分
- ❌ Incremental 路径动 Infra Mapping 段（除非 task 真改了 satellite 路径——这种情况应升级 R）
- ❌ Re-scan 路径 main thread 自己读源码——这是 surveyor agent (scope: single-unit) 的活
- ❌ 跳过 snapshot 直接 overwrite 老 Tier-2 live——丢历史
- ❌ Tier-3 SURVEYOR 块在 unit 集合不变时也动——按 §8.4 默认不动
- ❌ 不在完成报告里提示 incremental drift——用户需要知道 SURVEYOR 累积误差，季度跑 /project-survey
