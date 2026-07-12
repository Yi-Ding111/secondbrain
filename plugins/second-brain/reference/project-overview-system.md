---
title: Project Overview Pipeline
id: meta/project-overview-system
category: reference
status: active
tags: [meta, project-overview, surveyor, decompose, wrap-work, source-paths, marker, infra-mapping, flow-graph, hybrid-update]
created: 2026-05-09
updated: 2026-05-17
supersedes: [[superseded-project-overview-system-2026-05-17-1919]]
---

# Project Overview Pipeline

为"周期性 refresh 一个项目的 overview + 各 logical unit doc"建立的两阶段 pipeline + "每次 task 完成时增量 reconcile" 的 wrap-work 联动机制。本文件是 `/project-survey`、`/project-decompose`、`project-surveyor` agent、以及 `/wrap-work` `source_paths` 路由 + Tier-2 SURVEYOR reconcile 的 **source of truth**——四个 skill / agent 的 SKILL.md 都引用本文件而不重复规则。

---

## 1. 为什么需要这套机制

一个项目的 doc 要做到三件事：

1. **Tier-3 是 entry point + index**——简明总架构 + 各部分 link，给读者一个 "从哪入口、跳哪去看细节" 的导航
2. **Tier-2 是 sub-overview**——每个 logical unit (feature / service / module / api) 的**永远完整、永远准确**的当前真值描述。读者从 Tier-3 跳进来，能看到这个部分的详细架构、infra 配对、组件级 flow graph
3. **Tier-1 是 task 历史**——frozen，不读不改。读者从 Tier-2 的 timeline link 跳进来，看具体某次改动的 detail

让 Tier-2 sub-overview "永远完整准确" 是难点。两个机制配合：

- **周期性全量 sweep**（`/project-survey` + `/project-decompose`）——重新扫所有 code root，把累积 drift 一次性 reconcile
- **task-driven 增量 reconcile**（`/wrap-work`）——每次 task 完成，主动 supersede 它接触到的 Tier-2 unit 的 SURVEYOR 块，反映新真值

旧版本一直存活在 superseded/ snapshot 链里——平时不读、要追溯历史时翻。

---

## 2. 整体流水线

```
代码库 (main + satellite roots)
   │
   ▼ (1) /project-survey  →  spawn project-surveyor agent
中间文件 inbox/project-survey-<proj>-<ts>.md
   │     (含 per-unit Detailed Flow Graph + Infra Mapping)
   │
   ▼ (2) /project-decompose
Tier-3 <project>.md (hub) + Tier-2 features/services/modules/api 文件
   │  (碰过的 live 文件先走 snapshot-supersede.sh)
   │  Tier-2 SURVEYOR 块含 Detailed Flow Graph + Infra Mapping
   │
   ▼ (3) /wrap-work 在新 task 完成时
   │     A. 写 Tier-1 task (frozen)
   │     B. 按 source_paths 路由找 affected Tier-2 unit(s)
   │     C. 对每个 affected unit:
   │        - Hybrid: LLM incremental 或 spawn surveyor agent re-scan
   │        - snapshot-supersede 老 SURVEYOR 块 → 写新版反映新真值
   │        - WRAP-WORK 块 append Timeline 一行 link 到 task
   │     D. Tier-3 SURVEYOR 块: 仅在 unit 集合 / 边界变化时更新
   │
   ▼ (4) 下次 /project-survey 周期再来一遍
         (全量 sweep 兜底 task-driven 没覆盖到的 drift)
```

两个 update path 对**同一份 SURVEYOR 块**写——靠 §3 marker + snapshot-supersede + scoped byte-compare 协调，不会冲突。

---

## 3. Marker convention（owner 分区）

每个由 surveyor 管的 doc（`<project>.md` Tier-3、`features/*.md`、`services/*.md`、`modules/*.md`、`api/*.md` Tier-2）用 HTML 注释 marker 把内容切两块:

```markdown
---
title: ...
... frontmatter ...
---

<!-- SURVEYOR-OWNED START last-surveyed:2026-05-17 -->

## What 功能描述
## Why 设计意图
## Inputs / Outputs
## Implementation Summary 当前实现
## Detailed Flow Graph        ← NEW (Tier-2 only)
## Infra Mapping              ← NEW (Tier-2 only, if satellite roots exist)
## Dependencies
## Consumers

<!-- SURVEYOR-OWNED END -->

<!-- WRAP-WORK-OWNED START -->

## Timeline
## Changelog
## Related
## Lessons inline

<!-- WRAP-WORK-OWNED END -->
```

### Owner 规则（hard）

| 区块 | Owner | 写规则 |
|---|---|---|
| **SURVEYOR-OWNED** | `/project-survey` + `/project-decompose` **以及** `/wrap-work` 在 Tier-2 reconcile 时 | **全量重写**——不 append、不带日期保留。每次 update 走 snapshot-supersede（老版进 superseded/） |
| **WRAP-WORK-OWNED** | `/wrap-work` | **append-only**——Timeline / Changelog 累积 entry，永不删除 |

**关键变化（vs 老规则）**：

旧规则说 wrap-work "永不写 SURVEYOR 块"。新规则下 wrap-work **主动** supersede Tier-2 SURVEYOR 块（每次 task 影响到一个 unit 就 supersede 一次）——但仍受同一套 owner 区分保护：

- Wrap-work supersede SURVEYOR 块时，WRAP-WORK 块用 sed 抽出来 carry over（与 decomposer SUPERSEDE 流程相同——见 §7）
- Wrap-work 永不动**其它** unit 的 SURVEYOR 块（只动这次 task 路由到的 affected unit）
- Tier-3 SURVEYOR 块 wrap-work 不动（除非 unit 集合 / 边界变化——见 §8.4）

### last-surveyed 时间戳

`<!-- SURVEYOR-OWNED START last-surveyed:YYYY-MM-DD -->` 里的日期是这块内容**最近一次 refresh 的日期**——无论 refresh 是 `/project-survey` 还是 `/wrap-work` 触发的。读者看到日期新就放心，看到很老就知道可能 stale。

### 演变史只活在 superseded/

choice B 拍定: live 文件永远只反映"当前真值"。功能描述演变史不在 live 内 append、不带日期保留——**全量留在 superseded/ snapshot 链里**。要追溯历史: open `<project>/superseded/` 翻 timestamp 链。

---

## 4. Frontmatter 字段（Tier-2 / Tier-3）

```yaml
---
title: <name>
id: <project>/features/<slug>     # or services/ modules/ api/ project-overview
category: feature                   # or service | module | api | project-overview
status: active
tags: [...]
created: YYYY-MM-DD
updated: YYYY-MM-DD

# Surveyor 维护字段
logical_kind: feature               # feature | service | module | api | overview
source_paths:                       # glob-style; wrap-work 用这个做路由（含 root prefix）
  - app/src/auth/**
  - app/src/middleware/oauth.py
satellite_paths:                    # NEW; Tier-2 only; 这个 unit 对应的 satellite root 路径
  - infra/terraform/auth-secrets/**
  - infra/k8s/auth-deployment.yaml
last_surveyed: 2026-05-17           # 与 marker 里 last-surveyed 同步
---
```

`source_paths` = main code root 的路径——task → doc 路由真值。  
`satellite_paths` = satellite root 的路径——Infra Mapping 段渲染时用，**不**参与 task 路由（task 一般不改 infra；改了用户会单独跑 wrap-work）。

`logical_kind` 决定文件该放 `features/` 还是 `services/` 还是 `modules/` 还是 `api/`。

---

## 4.5 Main + Satellite code roots（新分类）

很多项目的"逻辑边界"≠"代码 repo 边界"：

- **主代码**在一个 repo（business logic，feature/service 都从这里来）
- **infra / deploy / shared lib**在另外几个 repo——它们**为主项目服务**，但本身不是 logical units 的来源

新机制把 code roots **显式分两类**：

- **`main` root**：surveyor 从这里识别 logical units (feature/service/module/api)
- **`satellite` root**：surveyor 不从这里出 unit，但读它的内容**配对**到 main 产生的每个 unit——结果落在 Tier-2 的 `## Infra Mapping` 段

### Named code roots with kind

`/project-survey` 接受 N 个**命名 code root**，每个标 `main` 或 `satellite`:

```
/project-survey work/sapia/projects/agents \
  main:app=/Users/yiding/code/sapia-agents \
  satellite:infra=/Users/yiding/code/sapia-infra \
  satellite:deploy=/Users/yiding/code/sapia-deploy
```

或者更简洁——`<kind>:<name>=<path>`。default kind 是 `main`（如果用户没标 kind，且只有一个 root，按 main 处理）。

### `<project>/CLAUDE.md` 持久化（新 schema）

```yaml
---
title: agents — Claude Project Instructions
id: agents/CLAUDE
...
code_roots:
  app:
    path: /Users/yiding/code/sapia-agents
    kind: main
  infra:
    path: /Users/yiding/code/sapia-infra
    kind: satellite
    role: infrastructure                  # infrastructure | deploy | shared-lib | docs
    mapping_strategy: heuristic           # heuristic | metadata-tag | manual
  deploy:
    path: /Users/yiding/code/sapia-deploy
    kind: satellite
    role: deploy
    mapping_strategy: heuristic
---
```

`role` 是给 surveyor 的提示——`infrastructure` → 读 terraform/k8s/cloudformation；`deploy` → 读 CI/CD 配置；`shared-lib` → 读包定义。

`mapping_strategy` 决定 surveyor 怎么把 satellite 内容**配对**到 main unit——详见 §4.6。

### Path prefix（强制，与现状一致）

`source_paths` + `satellite_paths` 都用 `<root-name>/` 前缀：

```yaml
source_paths:
  - app/src/auth/**
satellite_paths:
  - infra/terraform/auth/**
  - deploy/k8s/auth/**
```

Prefix 永远必填——单 root 也是。

### 代码 repo 端 `.brain-vault.json`（与现状一致）

```json
{
  "project": "work/sapia/projects/agents",
  "code_root_name": "app"
}
```

task-git-digest 读它写进 digest frontmatter，wrap-work 用 `code_root_name` 给 paths_touched 加前缀。

### Mermaid subgraph（与现状一致）

Tier-3 Architecture mermaid 用 subgraph 区分 main / satellite area。Satellite area 的节点用不同样式（如 `[(双圆柱)]` 或 dashed border）。

---

## 4.6 Infra mapping 策略

把 satellite root 的内容**配对**到 main unit 有三种策略，per-satellite 配置（每个 satellite root 可以选不同策略）：

### Strategy A — heuristic（默认）

Surveyor 自动启发式配对，基于：

- **文件名 / 文件夹名匹配**：`infra/terraform/auth/` ↔ `app/src/auth/` (unit slug = `auth`)
- **关键词匹配**：unit 名出现在 IaC resource name / k8s deployment name
- **README 配对**：satellite 文件夹里如有 README 提到 unit 名，作为强信号
- **resource type → unit type 启发式**：k8s Deployment / Service 通常对应 service unit；Ingress 对应 api unit

**输出**：

- High-confidence 配对 → 直接写进 unit 的 `satellite_paths` + `## Infra Mapping` 段
- Low-confidence / 多候选 → unit 的 `### Notes for decomposer` 段列 "Ambiguous infra: ..."，decompose 时让用户确认
- 无任何配对 → 跳过；在 NOTES_FOR_MAIN_THREAD 段列 "Unmapped satellite paths: ..."（让用户决定要不要专门建一个 unit / 加到某个现有 unit / 接受 unmapped）

**适合**：satellite repo 命名结构清晰（文件夹按 feature/service 分），改动成本低。**风险**：命名糟糕的 repo 会高错配率——但用户可以 review 中间文件改。

### Strategy B — metadata-tag

要求 satellite repo 每个资源（terraform module / k8s manifest / dockerfile）顶部加 metadata comment：

```hcl
# brain-vault: unit=oauth-login
resource "aws_secretsmanager_secret" "oauth_secret" { ... }
```

```yaml
# brain-vault: unit=api-gateway
apiVersion: networking.k8s.io/v1
kind: Ingress
...
```

Surveyor 按 tag 配对——精确度最高。

**适合**：你能自己控制 satellite repo（个人项目 / 公司内部你能改的 repo）。**不适合**：第三方 / 外部 IaC repo。

### Strategy C — manual rules

在 `<project>/CLAUDE.md` 写显式 mapping rules：

```yaml
---
...
infra_mapping_rules:
  oauth-login:
    - infra/terraform/auth/**
    - infra/k8s/auth-deployment.yaml
    - deploy/ci/auth-secrets.yml
  api-gateway:
    - infra/terraform/api-gateway/**
    - infra/k8s/ingress-api.yaml
  conv-history:
    - infra/terraform/rds-conv/**
unmapped_satellite_paths:               # 显式记下"不属于任何 unit"
  - infra/terraform/shared-vpc/**
  - infra/terraform/dns/**
---
```

Surveyor 完全按规则配，不启发。`unmapped_satellite_paths` 是 escape hatch——存在共享 infra 不属于任何 unit 的情况。

**适合**：你愿意维护这份 mapping（项目稳定、unit 数量可控）。**最准但人力成本高**。

### 选择决策树

`/project-survey` invocation 时：

1. 主代码以外有 satellite root → 引导用户选 strategy
2. 推荐顺序：
   - satellite 是你能改的 repo → 建议 B (metadata-tag)
   - satellite 命名结构清晰（文件夹按 feature 切）→ 建议 A (heuristic)
   - 否则 → C (manual)
3. 写进 `<project>/CLAUDE.md` 持久化，下次 re-run 不用重选

---

## 4.7 SURVEYOR 块内容深化（Tier-2）

Tier-2 SURVEYOR 块新增两个段（在已有 What/Why/IO/ImplSummary 之后、Dependencies 之前）：

### `## Detailed Flow Graph`

一张 Mermaid `flowchart` 图，**组件级**——粒度比 Tier-3 整体 architecture 细，但**不到代码行级**。每个节点是这个 unit 内部的一个 component（class / module / handler / function group），边是数据流 / 调用关系 / 控制流。

```markdown
## Detailed Flow Graph

```mermaid
flowchart LR
  subgraph "oauth-login"
    Entry[POST /auth/login] --> Validator[validate_request]
    Validator -->|valid| Provider[OAuth Provider Adapter]
    Validator -->|invalid| Err400[400 Bad Request]
    Provider -->|google| GoogleAdapter[Google OAuth Client]
    Provider -->|github| GitHubAdapter[GitHub OAuth Client]
    GoogleAdapter --> SessionMgr[Session Manager]
    GitHubAdapter --> SessionMgr
    SessionMgr --> SecretStore[(Vault: API Secrets)]
    SessionMgr -->|persist| DB[(Postgres: sessions)]
    SessionMgr --> ResponseBuilder[build_response]
  end
\```

Notes:
- `validate_request` 阻断格式错的 request；OAuth provider 切换在 Adapter 层完成
- Secrets 永远从 Vault 拉，不进环境变量
```

如果 unit 有**重要 runtime sequence**（多角色协作 / async pattern），surveyor **可以**再加一张 `sequenceDiagram`。默认只一张 flowchart。

### `## Infra Mapping`

两部分：(1) **Infra Graph**——一张 mermaid 图显示**本 unit 涉及的 infra 资源之间的 wiring**（让读者一眼看清 infra 内部关系）；(2) **per-satellite-root tables**——main 组件 ↔ satellite 资源**一一对应**的表格（精确路径绑定）。

```markdown
## Infra Mapping

### Infra Graph

\```mermaid
flowchart LR
  subgraph "infra (satellite, terraform)"
    AuthSecrets[(Secrets Manager: prod/oauth/*)]
    AuthRDS[(RDS Postgres: sessions-db)]
    AuthVPC[VPC: shared-prod]
  end
  subgraph "deploy (satellite, k8s)"
    AuthIngress[Ingress: auth-api.example.com]
    AuthSvc[Service: auth-api]
    AuthDeploy[Deployment: auth-api]
    AuthHPA[HorizontalPodAutoscaler]
  end
  AuthIngress --> AuthSvc --> AuthDeploy
  AuthHPA -.scales.-> AuthDeploy
  AuthDeploy -.reads secrets.-> AuthSecrets
  AuthDeploy -.connects.-> AuthRDS
  AuthRDS -.lives in.-> AuthVPC
\```

### infra (satellite, role: infrastructure, strategy: heuristic)

| Main 组件 | Infra 资源 | 路径 |
|---|---|---|
| Session Manager → SecretStore | AWS Secrets Manager: `prod/oauth/*` | [infra/terraform/auth-secrets/main.tf](satellite:infra/terraform/auth-secrets/main.tf) |
| Session Manager → DB | RDS Postgres instance `sessions-db` | [infra/terraform/rds-sessions/](satellite:infra/terraform/rds-sessions/) |

### deploy (satellite, role: deploy, strategy: heuristic)

| Main 组件 | Deploy 资源 | 路径 |
|---|---|---|
| POST /auth/login endpoint | K8s Ingress + Service + Deployment `auth-api` | [deploy/k8s/auth/](satellite:deploy/k8s/auth/) |
| OAuth Provider config | CI secret injection step `inject-oauth-creds` | [deploy/ci/auth-pipeline.yml#L42-58](satellite:deploy/ci/auth-pipeline.yml) |
```

**Infra Graph 设计规则**:

- 每个 satellite root 一个 subgraph，标 `(satellite, <tech>)`——`tech` 是具体技术栈（terraform / k8s / cloudformation / ansible / pulumi）
- 节点 = 单个 infra 资源（一个 terraform resource / k8s manifest / dockerfile / pipeline job）。用专有形状暗示类型：`[(双圆柱)]` 数据库、`[Service]` k8s 资源、`(圆角矩形)` 普通资源
- 实线箭头 = 强依赖（A 必须 B 才能存在）；虚线 `-.label.->` = 运行时引用 / 配置依赖
- **跨 satellite 边允许**——k8s Deployment（在 deploy 子图）→ Secrets Manager（在 infra 子图）是常见组合
- **不画 main → infra 边**——那是表格的工作；graph 只画 infra-internal wiring。读者想知道 main 哪里 consume 这些 infra 资源，去看下面的表格

每个 satellite root 一个 table sub-section。每行：main 组件名 + 依赖的具体 infra 资源 + satellite repo 内的路径（用伪 `satellite:` 链接前缀让读者知道这指向 satellite repo，不是 vault 内）。

**没有 satellite root**：这一整段省略。

**有 satellite root 但全无配对**：写：

```markdown
## Infra Mapping

_无对应 infra 资源被 surveyor 配对到本 unit。如有需要请检查 [[<project>/CLAUDE.md]] 的 `infra_mapping_rules` 或 satellite repo 的 tag。_
```

**有部分配对但 Infra Graph 节点 ≤ 2**：可省略 Infra Graph 段（节点太少画图无意义），直接走 tables。

---

## 5. 中间文件 schema

`/project-survey` 跑完产出一个文件，落在：

```
inbox/project-survey-<project>-<YYYY-MM-DD-HHMM>.md
```

### Frontmatter

```yaml
---
source: project-survey
project: <project name>
project_path: <vault-relative path>
generated: YYYY-MM-DD-HHMM
surveyor_run: <integer, 1 = first run>
unit_count: <N>
code_roots:                              # 本次 survey 用的 roots
  app: {path: /Users/yiding/..., kind: main}
  infra: {path: /Users/yiding/..., kind: satellite, role: infrastructure, mapping_strategy: heuristic}
---
```

### Body 结构

```markdown
# Project Survey: <project>

## Overview Section

**logical_kind**: overview
**suggested_path**: <project>.md

### Mission
<2-5 sentences narrative — 这个项目存在的理由、解决什么问题、scope 边界（什么属本项目，什么属外部）>

### Architecture (Mermaid — main code units only)
\```mermaid
flowchart TB
  subgraph "<main-root-name>"
    Unit1
    Unit2
    Unit3
  end
  Unit1 --> Unit2
  Unit2 --> Unit3
\```

<2-4 sentences narrative — main component 之间怎么组织、data flow 方向、key abstraction、入口在哪>

### Infrastructure Architecture (Mermaid — satellite resources + inter-wiring)
<只在有 ≥1 satellite root 时产出；纯 main 项目省略整段>

\```mermaid
flowchart TB
  subgraph "<satellite-1-name> (satellite, <tech>)"
    Res1[(Resource A)]
    Res2[(Resource B)]
  end
  subgraph "<satellite-2-name> (satellite, <tech>)"
    Res3[Resource C]
  end
  Res3 -.references.-> Res1
  Res3 -.references.-> Res2
\```

<3-6 sentences narrative — 整体 infra topology / 什么跑在什么环境 / secret 管理策略 / 网络边界 / deploy pipeline / scaling 模式>

每个 main unit 具体对应哪些 infra 资源 → 见对应 Tier-2 doc 的 `## Infra Mapping` 段。本图仅展示 infra **内部** wiring（不画 main → infra 边）。

### Modules / Services 详细描述
<per-unit `####` subsection，每个 unit 一段 narrative。**不再 single-line list**>

#### [[<unit-slug-1>]] (<logical_kind>)

<3-5 sentences narrative — 这个 unit 做什么 / 关键 responsibility / 上游谁触发它 / 下游它调用什么 / 为什么这样设计>

详细 component-level architecture + infra mapping + history → [[<unit-slug-1>]]

#### [[<unit-slug-2>]] (<logical_kind>)

<3-5 sentences narrative>

详 → [[<unit-slug-2>]]

(repeat per unit)

### Integrations
- **上游**: <谁触发本项目 + 一句话场景说明>
- **下游**: <本项目调用谁 + 一句话场景说明>
- **第三方 SDK / API**: <用了什么外部服务 + 一句话用途>

### Tech stack
- **Language / Framework**: <技术 + 选型理由 if non-obvious>
- **Storage**: <技术 + 用途分工>
- **Runtime / Infra**: <K8s? Lambda? 裸机?>
- **Deploy**: <CI tool + pipeline 风格>
- **Observability**: <日志 / metrics / tracing stack>（如有）

---

## Unit: <slug-1>

**logical_kind**: feature
**source_paths**:
- app/src/X/**
- app/src/Y/foo.py
**satellite_paths**:
- infra/terraform/X/**
- deploy/ci/X-pipeline.yml
**deps**: [other-unit-slug, ...]
**consumers**: [other-unit-slug, ...]
**suggested_path**: features/<slug-1>.md

### What 功能描述
<narrative>

### Why 设计意图
<narrative>

### Inputs / Outputs
- **Input**: ...
- **Output**: ...

### Implementation Summary 当前实现
<narrative>

### Detailed Flow Graph
\```mermaid
flowchart LR
  ...
\```
<可选 Notes>

### Infra Mapping
<Infra Graph (mermaid) + per-satellite-root tables; 见 §4.7>

### Notes for decomposer
<可选; ambiguous boundary / ambiguous infra / suggested rename / 合并建议>

---

## Unit: <slug-2>
...
```

### Schema 严格性

每个 Unit section **必须有**：

- `logical_kind` 字段
- `source_paths` 列表（含 main root prefix）
- `satellite_paths` 列表（含 satellite root prefix，可空 `[]`）
- `deps` 列表（可空 `[]`）
- `consumers` 列表（可空 `[]`）
- `suggested_path` 字段
- `### What`、`### Why`、`### Inputs / Outputs`、`### Implementation Summary`、`### Detailed Flow Graph`、`### Infra Mapping` 六个 sub-section（`Infra Mapping` 在无 satellite 时仍写但段内说明"_无_"）

decomposer 用 regex 解析这些字段；schema 不严格 → decomposer 报错让用户先修中间文件。

---

## 6. /project-survey 工作流（interactive）

### Step 0 — Invocation parsing

`/project-survey <project-doc-path> [code-roots...]`

- 命令行有 code_roots → parse `<kind>:<name>=<path>` 形式（kind 缺省 = main）
- 命令行没 code_roots → Read `<project>/CLAUDE.md` frontmatter `code_roots` 字段：找到 → 用这些；没找到 → 进 Step 0.5 引导

### Step 0.5 — Interactive root discovery（首次或缺信息时）

询问用户：

```
本项目的代码仓库（main + satellite）?

  Main code root（业务逻辑代码，feature/service 的来源）:
    格式: <name>=<abs-path>
    例: app=/Users/yiding/code/sapia-agents

  Satellite code roots（infra / deploy / shared-lib 等服务于 main 的 repo，可多个，可省）:
    格式: <name>=<abs-path>:<role>
    role ∈ {infrastructure, deploy, shared-lib, docs}
    例: infra=/Users/yiding/code/sapia-infra:infrastructure
    例: deploy=/Users/yiding/code/sapia-deploy:deploy

  没有 satellite → 直接回车跳过
```

每个 satellite root，问 mapping strategy：

```
satellite root `infra` 的 mapping strategy?
  [a] heuristic (默认) — surveyor 启发式猜配对，模糊的列出让你确认
  [b] metadata-tag    — 要求 infra repo 每个资源加 `# brain-vault: unit=...` tag
  [c] manual          — 你在 <project>/CLAUDE.md 写 infra_mapping_rules
```

如选 (c)，提示用户先去 CLAUDE.md 写规则再回来跑 survey（或者引导 surveyor 跑完后写 stub rules）。

### Step 0.6 — 写回 `<project>/CLAUDE.md`

把解析好的 `code_roots` 持久化进 `<project>/CLAUDE.md` frontmatter，下次 re-run 不用再问。

### Step 1 — Read project meta（main thread）

并行 Read：

- `<project>/CLAUDE.md` — skip rules / hot zones / `infra_mapping_rules`（如 strategy=c）
- `<project>/wiki.md` — 现有 doc 索引
- `<project>/<project>.md` — 看是否已有 SURVEYOR marker

判断 `surveyor_run`: 没现有 Tier-2 → 1 (first run)；有 → 2+ (re-run)。

Re-run 时组装 `existing_units` 列表（Glob `<project>/{features,services,modules,api}/*.md`）。

### Step 2 — Spawn project-surveyor agent

传 `code_roots`（dict with kind/role/mapping_strategy）、`vault_root`、`surveyor_run`、`existing_units`、`project_claude`（含 `infra_mapping_rules`）。Agent 按 §4.7 + §5 schema 产出 SURVEY_FILE_BODY + NOTES_FOR_MAIN_THREAD。

### Step 3 — Write 中间文件

Main thread 提取 SURVEY_FILE_BODY → Write `inbox/project-survey-<proj>-<ts>.md`。解析 NOTES 统计。

### Step 4 — 报告 + 不自动 decompose

≤ 15 行报告（含 unit 数、ambiguous boundaries、unmapped satellite paths、suggested re-survey cadence）。提示用户 review → 跑 `/project-decompose`。

详见 `.claude/skills/project-survey/SKILL.md`。

---

## 7. /project-decompose 工作流

简述（与现状一致 + 新 sections）：

1. Parse 中间文件成 unit list（含新 fields: satellite_paths, Detailed Flow Graph, Infra Mapping）
2. 路由 logical_kind → target path（与现状一致）
3. 每个 target 决定 action（NEW / SKIP / SUPERSEDE / MIGRATE，scoped byte-compare 与现状一致）
4. Show plan 给用户 → 等 confirm
5. 执行：用新 Tier-2 template（含 Detailed Flow Graph + Infra Mapping 段）

### Tier-2 template（新版，含新段）

```markdown
---
title: <name>
id: <project>/features/<slug>
category: feature
status: active
tags: [...]
created: YYYY-MM-DD
updated: YYYY-MM-DD
logical_kind: feature
source_paths:
  - app/src/X/**
satellite_paths:
  - infra/terraform/X/**
last_surveyed: YYYY-MM-DD
---

# <Unit Name>

<!-- SURVEYOR-OWNED START last-surveyed:YYYY-MM-DD -->

## What 功能描述
<from intermediate>

## Why 设计意图
<from intermediate>

## Inputs / Outputs
<from intermediate>

## Implementation Summary 当前实现
<from intermediate>

## Detailed Flow Graph
\```mermaid
<from intermediate>
\```

## Infra Mapping
<from intermediate; per-satellite-root tables>

## Dependencies
- [[<dep-slug>]] — 一句话

## Consumers
- [[<consumer-slug>]] — 一句话

<!-- SURVEYOR-OWNED END -->

<!-- WRAP-WORK-OWNED START -->

## Timeline
_由 /wrap-work 累积。最新在上。_

## Changelog
- YYYY-MM-DD: initial decompose from [[project-survey-<proj>-<ts>]]

## Related
- Tier-3: [[<project>]]

<!-- WRAP-WORK-OWNED END -->
```

### Tier-3 template（与现状基本一致 — Tier-3 仍是 hub，不深化）

Tier-3 `<project>.md` 仍然是简明 entry point：Mission + Architecture mermaid (with main/satellite subgraphs) + Modules/Services list (link to Tier-2) + Integrations + Tech Stack。**不**加 Detailed Flow Graph / Infra Mapping——那些都在 Tier-2 sub-overview 里。

详见 `.claude/skills/project-decompose/SKILL.md`。

---

## 8. /wrap-work 集成（重大更新）

### 8.1 旧规则 vs 新规则

旧规则：wrap-work 只动 WRAP-WORK 块（Timeline / Changelog / Related），SURVEYOR 块完全不碰，等下次 `/project-survey` reconcile。

新规则：**每次 task 完成，wrap-work 主动 supersede affected Tier-2 unit 的 SURVEYOR 块**，反映新真值。WRAP-WORK 块仍然 append-only。

### 8.2 完整 wrap-work flow（新 Step 4）

Step 0-3 与现状一致（inbox triage → 写 Tier-1 task → 提取 knowledge / experience）。Step 4 重写：

**Step 4a — 路由 affected Tier-2**

- `digest-fuser` NOTES 给 `paths_touched` + `code_root_name`
- Prefix paths（与现状一致），glob match Tier-2 `source_paths`
- 输出 candidate list

**Step 4b — Show plan + 确认**

```
本任务影响以下 Tier-2 unit（按 source_paths 路由）:

  ✅ features/oauth-login.md   (匹配 app/src/auth/oauth.py)
  ✅ features/auth-session.md  (匹配 app/src/middleware/auth.py)

  ❓ 未匹配:
     - tests/auth/test_oauth.py (test 通常无需 doc)
     - app/src/billing/new-feature.py (新功能? 加进现有 unit / 新建?)

  对每个 affected unit，SURVEYOR 块更新策略:
    [I] LLM incremental (默认快路径) — 适合 bug fix / 内部 refactor
    [R] Surveyor agent re-scan       — 适合架构变更 / 加新组件 / 改接口

  建议:
    - oauth-login:   I  (task 看起来是 bug fix)
    - auth-session:  R  (task 提到加了新组件 SessionRotator)

确认 affected list + 更新策略? (y / 调整)
```

**Step 4c — 对每个 confirmed unit, supersede SURVEYOR 块**

走 hybrid：

- **LLM incremental** (路径 I):
  1. Read 老 live 文件的 SURVEYOR 块（sed 抽，不读全文）
  2. LLM 收 (老 SURVEYOR + task digest summary + paths_touched + git diff 摘要) → 写新 SURVEYOR 块
  3. `meta/scripts/snapshot-supersede.sh <live>` → 拿 snapshot 路径
  4. Shell 拼新 live: 新 frontmatter + 新 SURVEYOR + carry-over 老 WRAP-WORK（sed 抽）
  5. Edit `## Changelog` 段 append：`- YYYY-MM-DD: SURVEYOR reconciled by /wrap-work (incremental) → snapshot [[<basename>]]`

- **Surveyor agent re-scan** (路径 R):
  1. Spawn `project-surveyor` agent，传单 unit 的 `source_paths` + `satellite_paths` 当 scope
  2. Agent 重扫源码 + satellite，重生 SURVEYOR 块 body（包含新 flow graph + infra mapping）
  3. Main thread 拿 body → snapshot-supersede → 拼新 live → 同上

**Step 4d — Append WRAP-WORK Timeline**

每个 affected unit 的 WRAP-WORK 块 `## Timeline` 段加 entry：

```markdown
### YYYY-MM-DD — <task title> ([[<task-file-id>]])
- **改了什么**: _1-2 句_
- **为什么**: _1 句_
- **SURVEYOR 更新**: incremental | re-scan
- Tier-1 详情: [[<task-file>]]
```

bump frontmatter `updated:` + `last_surveyed:` (= today)。

### 8.3 Hybrid 决策 — incremental vs re-scan

Main thread LLM 看 task 内容判断默认建议 (per affected unit)：

**建议 I (LLM incremental)** 当 task 是：

- 修 bug（不改外部接口）
- 内部 refactor（不改架构）
- 加日志 / 监控
- 改性能（实现内部）
- 改文案 / 配置常量

**建议 R (surveyor re-scan)** 当 task：

- 加 / 删 / 重构组件
- 改外部接口 / API contract
- 加 / 删依赖
- 改架构（数据流变化）
- 改 infra mapping（动了 satellite 路径 / 加了新资源）
- source_paths 边界变化（task 改了 unit `source_paths` 列出范围**之外**的文件，但用户决定纳入该 unit）

**ask user** 当：

- LLM 不确定属于哪一类
- Task digest 描述模糊
- 跨多个 unit 且各 unit 改动幅度不同

用户在 Step 4b plan 阶段一次性确认（含 override 建议）。

### 8.4 Tier-3 SURVEYOR 块的更新规则

Tier-3 `<project>.md` 的 SURVEYOR 块（Mission / Architecture mermaid / Modules list / Integrations / Tech stack）**仅在 unit 集合 / 边界变化时更新**：

| 触发 | 处理 |
|---|---|
| Task 内部改 unit 实现（unit 没新增 / 没删） | **不动 Tier-3** |
| Task 新增 unit | 提示用户跑 `/project-survey` 重生 Tier-3 (轻量 mode 仅 Overview Section);  或 wrap-work 直接 supersede Tier-3 SURVEYOR (调单元路径) |
| Task 删除 unit / 合并 unit | 同上 |
| Task 改 unit 名 (slug) | 同上 + 改所有引用 [[link]] |

默认行为：**不动 Tier-3**，task frontmatter 加 `architecture_changed: true` 提示用户日后跑 `/project-survey`。

激进选项（用户在 plan 阶段选）：wrap-work 直接 supersede Tier-3 SURVEYOR——本质是 re-scan 主 Overview Section + 重生 Modules/Services list。

### 8.5 多 unit task 的处理

一个 task 改了多个 unit 的 source_paths（如 oauth-login + auth-session）：

- **Sequential** 处理：对每个 affected unit 各跑一次 4c 流程（snapshot-supersede + 写新 SURVEYOR + append timeline）
- 每个 unit 产一个独立 snapshot
- 完成报告里列每个 unit 的 snapshot link

### 8.6 Bootstrap fallback（unit 还没 marker）

如果 affected unit 的 live 文件**没有 SURVEYOR marker**（项目还没 survey 过 / 这是新 unit）：

- 提示用户先跑 `/project-survey` + `/project-decompose`
- 用户拒绝立即跑 → 走老 inline 模式（不动 SURVEYOR，只 append WRAP-WORK Timeline + bump updated:）；提示这是 deprecated 路径，下次 survey 时 MIGRATE 修

### 8.7 digest-fuser NOTES 扩展

`NOTES_FOR_MAIN_THREAD` 段新增字段：

```
paths_touched:
  - src/auth/oauth.py
  - src/middleware/auth.py
git_diff_summary:                      # NEW (用于 LLM incremental update)
  - file: src/auth/oauth.py
    change_kind: modified
    summary: 加了 OAuth provider 切换 fallback 逻辑，新增 GitHubAdapter 类
  - file: src/middleware/auth.py
    change_kind: modified
    summary: SessionManager 多了一个 rotate_session() 入口
change_kind_overall:                   # NEW (LLM 自己粗判，hybrid 决策的 input)
  oauth-login: refactor-with-new-component
  auth-session: bug-fix
```

`git_diff_summary` 给 main thread 做 LLM incremental update 时当输入（不读完整 diff 全文）。`change_kind_overall` 是 LLM 给的粗判 hint，main thread 用来推 hybrid 建议。

---

## 9. Re-run policy（与现状一致 + 新维度）

**默认: full fresh + scoped byte-compare + skip-if-identical**

- Surveyor 完全 ignore 旧 doc 的 SURVEYOR 块**内容**（不基于旧版差量；从代码 reconstruct）
- Surveyor **只读旧 doc 的 SURVEYOR 块当 stylistic reference**
- Decomposer scoped 比较 SURVEYOR 块：byte-equal → skip；不等 → supersede
- WRAP-WORK 块永远逐字 carry over

**新维度**：wrap-work 的 incremental update 是个**轻量 reconcile**——不重扫源码，只基于 task digest 推变化。这意味着多次连续 incremental 之后 SURVEYOR 块可能逐渐 drift（每次小幅推断的误差累积）。**定期 `/project-survey` 全量 sweep 兜底**——建议季度一次或重大重构后立刻一次。

---

## 10. Migration（与现状一致）

第一次 `/project-decompose` 跑到一个**已经有内容但没有 marker**的 feature/overview 文件时，自动 migration（见旧版 §10，规则不变）。

新加的两个段 (`Detailed Flow Graph` / `Infra Mapping`) 在 migration 时由 surveyor 这轮 fresh 生成——老文件本来就没这些段。

---

## 11. Anti-patterns

- ❌ Wrap-work 单独修改 SURVEYOR 段里某一句话（不走 supersede）——破坏 owner 规则 + 丢历史
- ❌ Surveyor / decomposer 写 WRAP-WORK 块——owner 反向
- ❌ 跳过 marker 直接 Edit Tier-2 文件——破坏 scoped byte-compare 机制
- ❌ Decomposer / wrap-work 不走 snapshot-supersede 直接覆盖 live——丢历史
- ❌ `source_paths` / `satellite_paths` 写得过宽（如整个 `app/**`）——路由崩溃
- ❌ 中间文件不严格遵守 schema——decomposer 解析失败
- ❌ Surveyor 一次性读所有源码文件——context 爆炸；按 unit boundary 抽样 1-3 个 representative file
- ❌ Decomposer / wrap-work 把旧 live 全文 Read 进 LLM context——sed/awk shell 抽 WRAP-WORK 块即可
- ❌ Wrap-work 每个 task 都 spawn surveyor agent 重扫——hybrid 默认 LLM incremental，re-scan 只在重大改动时
- ❌ Wrap-work 改动 Tier-3 SURVEYOR 块但 unit 集合没变——unit 内部改动只更 Tier-2
- ❌ Infra mapping 策略选 manual 但 `infra_mapping_rules` 没写——surveyor 没东西可配，应回退到 heuristic 或报错
- ❌ Detailed Flow Graph 画到代码行级——保留组件级 / handler 级；行级 detail 在 task 文件里

---

## 12. Related

- [[CLAUDE]] §2.1 Multi-tier 项目模型
- [[supersede-patterns]] §C Snapshot Supersede + §D Frozen
- `.claude/skills/project-survey/SKILL.md`
- `.claude/skills/project-decompose/SKILL.md`
- `.claude/skills/wrap-work/SKILL.md`（待 §8 改动落地）
- `.claude/agents/project-surveyor.md`（待 §4.7 + §5 schema 改动落地）
- `.claude/agents/digest-fuser.md`（待 NOTES `git_diff_summary` / `change_kind_overall` 扩展落地）

## Changelog

- 2026-05-17: major redesign — main/satellite code root distinction (§4.5), infra mapping strategies (§4.6), Tier-2 SURVEYOR 内容深化 with Detailed Flow Graph + Infra Mapping (§4.7), wrap-work 改为主动 supersede Tier-2 SURVEYOR 块 with hybrid LLM-incremental / surveyor-re-scan mechanism (§8), digest-fuser NOTES 扩展 git_diff_summary + change_kind_overall (§8.7). 老版 snapshot: [[superseded-project-overview-system-2026-05-17-1919]]
- 2026-05-09: initial version (choice B / scoped byte-compare / migration via decomposer / last-surveyed marker)
