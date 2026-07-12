---
name: project-survey
description: 周期性扫描一个项目的代码库（main + satellite roots），识别 logical units（feature / service / module / api），per-unit 生成 Detailed Flow Graph + Infra Mapping，输出中间文件到 inbox/ 供 /project-decompose 消费。配合 project-surveyor agent 跑——main thread 不读源码。Re-run 时把现有 Tier-2 docs 的 SURVEYOR 块当 stylistic reference。详见 [[meta/project-overview-system]].
triggers: ["project-survey", "扫描项目", "survey project", "重生成 overview", "refresh project doc", "scan project"]
disable-model-invocation: true
---

# Project Survey

`/project-survey <project-doc-path> [<kind>:<name>=<root> ...]` —— Karpathy distillation 模型的"raw → distilled"前半段。委派 `project-surveyor` agent 浏览 main + satellite code roots + project meta 文件，产出**一个 inbox 中间文件**描述项目的 overview + 每个 logical unit（含 Detailed Flow Graph + Infra Mapping）。**不直接更新 vault doc**——那是 `/project-decompose` 的事。

设计 source of truth: [[meta/project-overview-system]]。本 skill 实现 §6 的 invocation flow。

## When to use

- 一个项目第一次纳入 vault，需要 bootstrap Tier-3 + Tier-2 doc
- 一个项目运行了一段时间（季度 / 重大重构后），doc 和代码 drift，需要 reconcile
- 用户说 "扫一下这个项目"、"重生成 overview"、"survey 这个项目"

**不适用**: 单个 task 的 wrap-up（用 `/wrap-work`，它会触发 hybrid Tier-2 reconcile）；知识 ingest（用 `/ingest`）；健康检查（用 `/lint`）。

**单 unit re-scan** 不通过本 skill 暴露——`/wrap-work` 的 hybrid R 路径直接 spawn `project-surveyor` agent with `scope: single-unit`。

## Before starting

读这几节（如果 context 没有）：

- [[CLAUDE]] §2.1 Multi-tier model
- [[meta/project-overview-system]]（设计 source of truth — **必读** §3, §4.5, §4.6, §4.7, §5）
- 目标 `<project>/CLAUDE.md`（如存在）

## Workflow

### Step 0 — Invocation parsing（**首选路径——一行命令把所有 root 配置全给出**）

用户传入: `/project-survey <project-doc-path> [<root-spec> ...]`

**Root spec 格式** (per code root，可选字段用 `:` 链式追加):

```
<kind>:<name>=<abs-path>[:<role>[:<strategy>]]
```

- `<kind>` ∈ `{main, satellite}`，省略 = `main`
- `<name>` = root 的命名（kebab-style: `app`, `infra`, `frontend`, `backend`, `deploy`, ...）
- `<abs-path>` = 代码 repo 的绝对路径
- `<role>` (仅 satellite 用) ∈ `{infrastructure, deploy, shared-lib, docs}`，main root 不需要
- `<strategy>` (仅 satellite 用) ∈ `{heuristic, metadata-tag, manual}`，默认 `heuristic`

**完整一行** (推荐——startup 时就把全部信息提供，避免进交互模式):

```
/project-survey work/sapia/projects/agents \
  main:app=/Users/yiding/code/sapia-agents \
  satellite:infra=/Users/yiding/code/sapia-infra:infrastructure:heuristic \
  satellite:deploy=/Users/yiding/code/sapia-deploy:deploy:heuristic
```

**省略 strategy** (默认 heuristic):

```
satellite:infra=/Users/yiding/code/sapia-infra:infrastructure
```

**省略 role + strategy** (会进 Step 0.5 prompt 补 role；strategy 默认 heuristic):

```
satellite:infra=/Users/yiding/code/sapia-infra
```

**单 main root** (省略 kind):

```
/project-survey projects/myproj code=/Users/yiding/code/myproj
```

### Step 0.5 — Interactive prompt（**仅当 args 不完整 + CLAUDE.md 没存时**）

**命令行有 roots** → 直接进 Step 0.6 (持久化) 然后 Step 1。

**命令行没 roots** → Read `<project_doc_path>/CLAUDE.md` frontmatter `code_roots`:
- 找到（新 nested schema 含 kind/role/mapping_strategy）→ 直接进 Step 1
- 找到（**老 flat schema** `{<name>: <path>}`）→ 提示用户 migrate (§4.5 新 schema)，引导填 kind/role/mapping_strategy 后写回
- 没找到 / 没 CLAUDE.md → **interactive 引导**：

```
本项目的代码仓库（main + satellite）?

  Main code root（业务逻辑代码，feature/service 的来源）:
    格式: <name>=<abs-path>
    例: app=/Users/yiding/code/sapia-agents

  Satellite code roots（infra / deploy / shared-lib 等服务于 main 的 repo，可多个，可省略）:
    格式: <name>=<abs-path>:<role>
    role ∈ {infrastructure, deploy, shared-lib, docs}
    例: infra=/Users/yiding/code/sapia-infra:infrastructure
    例: deploy=/Users/yiding/code/sapia-deploy:deploy

  没有 satellite → 直接回车跳过
```

为每个 satellite root **再问 mapping strategy**:

```
satellite root `<name>` 的 mapping strategy?
  [a] heuristic (默认推荐) — surveyor 启发式猜配对，模糊的列出让你确认
  [b] metadata-tag       — 要求 satellite repo 每个资源加 `# brain-vault: unit=<slug>` tag
  [c] manual             — 你在 <project>/CLAUDE.md 写 infra_mapping_rules
```

如选 (c)，**先暂停**让用户去 `<project>/CLAUDE.md` 加 `infra_mapping_rules:` 段（按 §4.6 schema），然后回来继续。或者用户选 "先用 heuristic 跑一遍看结果，再考虑要不要 manual" → 走 (a)。

### Step 0.6 — 持久化 code_roots 到 `<project>/CLAUDE.md`

把 Step 0 / 0.5 收集到的 code_roots（新 nested schema 含 kind/role/mapping_strategy）写回 `<project>/CLAUDE.md` frontmatter，下次 re-run 不用重输。

如果 `<project>/CLAUDE.md` 不存在 + project 目录也不存在 → 询问是否 bootstrap 新项目（与现状一致）。用模板创建骨架 + 写入 code_roots。

**验证每个 root path**: `[[ -d "<root-path>" ]]`，不存在则报错停止。

### Step 1 — Read project meta + 列现有 unit

并行 Read（只读这几个，不读源码）：

- `<project_doc_path>/CLAUDE.md`（含新 nested `code_roots` + 可选 `infra_mapping_rules` / `unmapped_satellite_paths`）
- `<project_doc_path>/wiki.md`（如存在）— 列现有 features / services / modules / api docs
- `<project_doc_path>/<project>.md`（如存在）— 看是否已有 SURVEYOR marker

判断 surveyor_run：

- vault 中没现有 Tier-2 docs → `surveyor_run: 1` (first run)
- 有现有 docs → `surveyor_run: 2+` (re-run)

如果是 re-run，组装 `existing_units` 列表（用 Glob `<project_doc_path>/{features,services,modules,api}/*.md`）：

```
[
  {path: "work/sapia/projects/agents/features/oauth-login.md",
   logical_kind: "feature",
   slug: "oauth-login"},
  ...
]
```

### Step 2 — Spawn project-surveyor agent

用 Agent tool, `subagent_type: project-surveyor`. Prompt 自包含：

```
请扫描以下项目并产出 survey 中间文件 body。

scope: full
project_doc_path: work/sapia/projects/agents
code_roots:
  app:
    path: /Users/yiding/code/sapia-agents
    kind: main
  infra:
    path: /Users/yiding/code/sapia-infra
    kind: satellite
    role: infrastructure
    mapping_strategy: heuristic
  deploy:
    path: /Users/yiding/code/sapia-deploy
    kind: satellite
    role: deploy
    mapping_strategy: heuristic
vault_root: /Users/yiding/Documents/YisBrain
surveyor_run: 2
existing_units:
  - {path: "work/sapia/projects/agents/features/oauth-login.md", logical_kind: "feature", slug: "oauth-login"}
  - {path: "work/sapia/projects/agents/features/conv-history.md", logical_kind: "feature", slug: "conv-history"}
project_claude: |
  <CLAUDE.md 内容贴在这里 — main thread 已 Read>

按你的 SKILL.md 输出 SURVEY_FILE_BODY + NOTES_FOR_MAIN_THREAD 双段。
```

### Step 3 — Agent 返回 → 写中间文件

Agent 返回两段：

- `SURVEY_FILE_BODY: ... END_SURVEY_FILE_BODY`
- `NOTES_FOR_MAIN_THREAD: ... END_NOTES`

Main thread:

1. 决定中间文件路径：
   ```
   inbox/project-survey-<project-slug>-<YYYY-MM-DD-HHMM>.md
   ```
   `<project-slug>` = project 名（kebab）；时间戳用 `date +%Y-%m-%d-%H%M`
2. Write `SURVEY_FILE_BODY` 内容到该路径
3. 解析 `NOTES_FOR_MAIN_THREAD` 提取统计（含新 fields: `satellite_roots_used`、`ambiguous_infra_mappings`、`unmapped_satellite_paths`）

### Step 4 — 报告 + 不自动 decompose

给用户 ≤ 18 行报告：

```
✅ Survey 完成

Project: <name>
Main roots: <name1>=<path1>, ...
Satellite roots: <name2>=<path2> (role: <role>, strategy: <strategy>), ...
中间文件: [[project-survey-<proj>-<ts>]]

Units identified: <total>
- overview: 1
- feature: N
- service: N
- module: N
- api: N

New units (新增): <list 或 none>
Removed units (代码里没了): <list 或 none>
Ambiguous boundaries: <list 或 none>
Ambiguous infra mappings: <list 或 none>     ← 需 review 中间文件人工 disambiguate
Unmapped satellite paths: <list 或 none>     ← 共享 infra / 没规则覆盖的；user 决定
Suggested re-survey cadence: <agent 建议>

下一步: 阅读中间文件 → 跑
  /project-decompose <intermediate-file> <project-doc-path>
```

**故意不自动 decompose**——让用户先 review schema：

- 发现 ambiguous boundary 时手动调整中间文件再 decompose
- 发现 ambiguous infra mapping 时在中间文件里给确定答案
- 发现 unmapped satellite paths 时决定是加 rule / 标 shared / 接受 unmapped
- 发现 removed unit 时决定是 archive 还是 delete

## Rules

- **Main thread 不读源码**：全靠 surveyor agent 在子 context 读。Main thread 只 Read meta 文件
- **中间文件落 inbox/**：不进 distilled zone；inbox 是 dump zone，等 decompose 消费
- **不直接更新 Tier-3/Tier-2 doc**：survey 只产出 raw 中间文件
- **Re-run 时传 existing_units**：否则 surveyor 不知道这是 re-run，不会读旧 SURVEYOR 块当 reference
- **Code roots 走 nested schema**：新版必须含 `kind` 字段。老 flat schema (`{name: path}`) 提示 migrate
- **Satellite roots 必须配 mapping_strategy**：默认 heuristic；其它两种由用户显式选
- **First-run bootstrap**：如项目目录不存在，先 mkdir 骨架（`tasks/`、`features/`、`superseded/`、`decisions/`、`learnings/`、`references/`、`log/`）+ 用模板初始化 `CLAUDE.md`、`wiki.md`、`log.md`（surveyor 之后填 `<project>.md`）；CLAUDE.md frontmatter 含 nested code_roots
- **Scope: single-unit 不走本 skill**：那是 wrap-work 直接 spawn agent 的事（hybrid R 路径），本 skill 永远 scope: full

## Tools used

- **Agent** (`subagent_type: project-surveyor`) — 核心
- Read (main thread 只读 meta 文件 + 现有 doc 的 SURVEYOR 块用于 existing_units)
- Glob (列现有 features/ services/ modules/ api docs)
- Bash (`mkdir` 项目骨架；`date` 生成时间戳；`ls`)
- Write (中间文件)
- Edit (`<project>/CLAUDE.md` frontmatter — 持久化 code_roots in Step 0.6)

## Output format

完成后报告 ≤ 18 行（hard limit），格式见 Step 4。比老版多 3 行（satellite roots + ambiguous infra + unmapped satellite）。

## Anti-patterns

- ❌ Main thread 用 Read 浏览源码——surveyor agent 的存在就是为了避免这个
- ❌ Survey 完直接 decompose——给用户 review 中间文件的机会（尤其是新 ambiguous infra / unmapped satellite 信号）
- ❌ 把中间文件写到 distilled zone（features/ 之类）——必须落 inbox/
- ❌ 跳过 `<project>/CLAUDE.md` 的读取——skip rules / hot zones / mapping rules 是 surveyor 重要输入
- ❌ Re-run 时不传 existing_units——surveyor 没法读旧 SURVEYOR 块当 reference，byte-compare 命中率会低
- ❌ 跳过 Step 0.6 持久化 code_roots——下次 re-run 用户又要重输
- ❌ 用 flat schema 写 code_roots——新 nested schema 是 §4.5 规范，flat 是已 deprecated
- ❌ 把 satellite root 当 main root 处理——satellite 不产 unit，只产 Infra Mapping 内容
- ❌ Bootstrap 时漏 `infra_mapping_rules`（如用户选了 manual strategy）—— surveyor 会报错
