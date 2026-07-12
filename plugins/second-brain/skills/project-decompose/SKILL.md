---
name: project-decompose
description: 拿 /project-survey 产出的中间文件，按 logical_kind 路由到 Tier-3 + Tier-2 doc 路径，对已有 live 文件做 scoped byte-compare（仅 SURVEYOR 块）+ snapshot-supersede + carry over WRAP-WORK 块。Tier-2 SURVEYOR 块含 Detailed Flow Graph + Infra Mapping (§4.7)。无 marker 的老文件自动 migration。详见 [[meta/project-overview-system]].
triggers: ["project-decompose", "拆解 survey", "decompose project", "落地 survey", "apply project survey"]
disable-model-invocation: true
---

# Project Decompose

`/project-decompose <intermediate-file> <project-doc-path>` —— Karpathy distillation 的"distilled → wiki"后半段。把 `/project-survey` 产出的 inbox 中间文件 parse 成单个 unit doc，按 marker 规范写入 vault。

设计 source of truth: [[meta/project-overview-system]]。

## When to use

- `/project-survey` 刚跑完，inbox 有新中间文件
- 用户 review 完中间文件，确认 schema OK（unit 切分合理、没遗漏 / 错切的边界）
- 用户说 "decompose"、"拆解 survey"、"落地"、"apply"

**不适用**: 中间文件还没产出（先 `/project-survey`）；单个 task 收尾（`/wrap-work`）。

## Before starting

读这几节：

- [[CLAUDE]] §2.1 Multi-tier + §7 Supersede
- [[meta/project-overview-system]]（**必读** — marker 规范、scoped byte-compare、migration logic 都在这）
- [[meta/supersede-patterns]] §C Snapshot Supersede

## Workflow

### Step 0 — 解析参数 + 读中间文件

1. 用户传入: `/project-decompose <intermediate-file> <project-doc-path>`
   - 例: `/project-decompose inbox/project-survey-agents-2026-05-09-1430.md work/sapia/projects/agents`
2. Read 中间文件全文（一次性，整个文件不大）
3. 验证 frontmatter `source: project-survey`
4. 提取 `project`、`project_path`、`unit_count`

### Step 1 — Parse 中间文件成 unit list

按 [[meta/project-overview-system]] §5 schema，用 regex / line-based parsing 抽：

- 一个 `## Overview Section`（kind: overview）
- N 个 `## Unit: <slug>` blocks，每个抽：
  - `**logical_kind**: <value>`
  - `**source_paths**:` list（多行 `- ...`，必须含 main root prefix）
  - `**satellite_paths**:` list（多行 `- ...`，含 satellite root prefix；可空 `[]`）—— NEW (§4.7)
  - `**deps**:` list
  - `**consumers**:` list
  - `**suggested_path**: <value>`
  - `### What`、`### Why`、`### Inputs / Outputs`、`### Implementation Summary` body
  - `### Detailed Flow Graph` body（含 mermaid block + 可选 Notes）—— NEW (§4.7)
  - `### Infra Mapping` body（Infra Graph mermaid + per-satellite-root sub-sections with tables，或 `_无_`）—— NEW (§4.7)
  - `### Notes for decomposer` body（可选；含 ambiguous boundary / Ambiguous infra entries）

构建 unit dict 数组。

如 schema 不严格（missing 必填字段、格式错位）→ 报错，停止，让用户先修中间文件。具体哪行错说清楚。

**Notes for decomposer 段**：如果包含 `Ambiguous infra:` 条目（heuristic 策略 low-confidence 的配对），plan 阶段单独列出来让用户在 confirm 前调整中间文件（不在 SKILL 这里自动决议——把 schema 严格性留给用户 review）。

### Step 2 — 路由 + 计算每个 unit 的 target path

| logical_kind | default target |
|---|---|
| overview | `<project_doc_path>/<project>.md` |
| feature | `<project_doc_path>/features/<slug>.md` |
| service | `<project_doc_path>/services/<slug>.md` |
| module | `<project_doc_path>/modules/<slug>.md` |
| api | `<project_doc_path>/api/<slug>.md` |

`suggested_path` 字段（中间文件里的）override default。

如 target folder 不存在（如 `services/` 第一次出现） → mkdir 但延到 Step 5（用户 confirm 后再建）。

### Step 3 — 对每个 target path 决定 action

四种 action：

| 条件 | Action |
|---|---|
| Live 文件不存在 | `NEW` |
| Live 文件存在 + 有 marker + SURVEYOR 块 byte-eq 新生成（**排除 marker 行 last-surveyed 字段**） | `SKIP` |
| Live 文件存在 + 有 marker + SURVEYOR 块不等 | `SUPERSEDE` |
| Live 文件存在 + 没 marker | `MIGRATE` |

#### Byte-compare 流程

```bash
# 抽 live 文件的 SURVEYOR 块（含 marker 行）
sed -n '/<!-- SURVEYOR-OWNED START/,/<!-- SURVEYOR-OWNED END/p' "$LIVE" > /tmp/old-surveyor.md

# 把新生成的 SURVEYOR 块写到 /tmp/new-surveyor.md（main thread 渲染好后）

# 比较时排除 marker 行的 last-surveyed:YYYY-MM-DD（永远不同）
diff <(sed -E 's/last-surveyed:[0-9-]+/last-surveyed:DATE/' /tmp/old-surveyor.md) \
     <(sed -E 's/last-surveyed:[0-9-]+/last-surveyed:DATE/' /tmp/new-surveyor.md)
# exit 0 → byte-eq → SKIP；非 0 → SUPERSEDE
```

### Step 4 — Show plan + 等用户 confirm

≤ 30 行 plan：

```
Plan: decompose <intermediate-file> → <project-doc-path>

Total units: N

Tier-3:
  <project>.md          →  [SUPERSEDE]   (SURVEYOR drift)

Tier-2 (features/):
  oauth-login.md        →  [SKIP]        (no change)
  conv-history.md       →  [SUPERSEDE]   (SURVEYOR drift)
  password-reset.md     →  [NEW]         (newly identified)

Tier-2 (services/):
  api-gateway.md        →  [MIGRATE]     (no marker; wrap content + supersede old)

Removed units (从 existing_units 来但本 survey 没出现):
  legacy-auth.md        →  ⚠️ 询问: archive 还是 delete?

Wiki + log update:
  - <project>/wiki.md (regenerate doc tree + source_paths reverse index)
  - <project>/log.md (append decompose entry)

Intermediate file disposition:
  - inbox/project-survey-...-<ts>.md → archives/<YYYY>/

继续? (y / n / 只挑选: 1,3,5)
```

用户回答 → 继续 Step 5。如有 removed unit，再问一次 archive 还是 delete。

### Step 5 — 执行（按 action 类型）

#### NEW

1. 渲染文件内容（按下面 §"Tier-2 file template" / §"Tier-3 file template"）：
   - frontmatter 含 `logical_kind`、`source_paths`、`last_surveyed`
   - SURVEYOR 块: 用中间文件的 What/Why/IO/ImplSummary + Dependencies/Consumers from `deps`/`consumers`
   - WRAP-WORK 块: 空 stub，留 `## Timeline` `## Changelog` `## Related` 三个空段
2. Write 到 target path

#### SKIP

不动文件 body。仅 sed bump:

- frontmatter `last_surveyed: <today>`
- frontmatter `updated: <today>`（保现行 vault discipline）
- marker `<!-- SURVEYOR-OWNED START last-surveyed:YYYY-MM-DD -->` 的日期

```bash
sed -i.bak -E "s/^last_surveyed:.*/last_surveyed: $(date +%Y-%m-%d)/" "$LIVE"
sed -i.bak -E "s/^updated:.*/updated: $(date +%Y-%m-%d)/" "$LIVE"
sed -i.bak -E "s/(<!-- SURVEYOR-OWNED START last-surveyed:)[0-9-]+/\\1$(date +%Y-%m-%d)/" "$LIVE"
rm "${LIVE}.bak"
```

理由: 真值未变，但 "刚验证过它没变" 是有用信号——读者看到 `last-surveyed` 是今天就放心。

#### SUPERSEDE

```bash
SNAPSHOT=$(${CLAUDE_PLUGIN_ROOT}/scripts/snapshot-supersede.sh "$LIVE")
```

然后 shell 拼新 live 文件——**WRAP-WORK 块不进 LLM context**：

```bash
# 1. 新 frontmatter 由 LLM 生成 → /tmp/new-frontmatter.yaml
# 2. 新 SURVEYOR 块由 LLM 生成 → /tmp/new-surveyor.md (含 marker)
# 3. 旧 WRAP-WORK 块由 sed 抽（黑盒，不进 context）

# 抽老 WRAP-WORK
sed -n '/<!-- WRAP-WORK-OWNED START/,/<!-- WRAP-WORK-OWNED END/p' "$LIVE" > /tmp/old-wrap-work.md

# 拼新文件
{
  echo '---'
  cat /tmp/new-frontmatter.yaml
  echo '---'
  echo ''
  cat /tmp/new-surveyor.md
  echo ''
  cat /tmp/old-wrap-work.md
} > "${LIVE}.new"
mv "${LIVE}.new" "$LIVE"
```

完成后 Edit 一次 `$LIVE` 在 WRAP-WORK 块的 `## Changelog` 段追加（这一次需要读那一段，但只为找 anchor 行）：

```
- YYYY-MM-DD: SURVEYOR refreshed by /project-decompose → snapshot [[<snapshot-basename-no-ext>]]
```

或者更省一步：让 LLM 生成 SURVEYOR 块时就带好 changelog ref——但那破坏 owner 分区。还是用上面 Edit 单行追加。

#### MIGRATE

老文件没 marker，需要包 marker 然后 supersede。

1. `${CLAUDE_PLUGIN_ROOT}/scripts/snapshot-supersede.sh "$LIVE"` → 拿 snapshot 路径（保历史）
2. **判断老文件 sections 哪些进哪个块**（按 [[meta/project-overview-system]] §10 mapping table）：
   - SURVEYOR 类: `## Description` / `## Mission` / `## Architecture` / `## API` / `## Configuration` / `## Implementation` / `## Modules / Features` / `## Services` / `## Integrations` / `## Tech Stack` / `## Repo / Code Layout`
   - WRAP-WORK 类: `## Timeline` / `## Changelog` / `## Related` / `## People / Owners` / `## Active Work` / `## Lessons`
3. 新 SURVEYOR 块: 用 surveyor 这轮的新内容**替换**老 description/architecture（按 choice B——旧版本完整存活在 snapshot，不在 live 保留）
4. 旧 WRAP-WORK 类内容（Timeline/Changelog/Related/...）用 sed 从 `$LIVE` 抽出来 carry over 进新 WRAP-WORK 块。**抽段**逻辑：

   ```bash
   # 抽老的 ## Timeline / ## Changelog / ## Related 段 (each 段 = ## 到下一个 ## 之间)
   awk '/^## (Timeline|Changelog|Related|People|Active Work|Lessons)/{flag=1} /^## / && !/^## (Timeline|Changelog|Related|People|Active Work|Lessons)/{flag=0} flag' "$LIVE" > /tmp/old-wrap-content.md
   ```

5. frontmatter 加 `logical_kind` (从中间文件 unit) + `source_paths` (从中间文件 unit) + `last_surveyed: <today>`
6. shell 拼新文件:

   ```bash
   {
     echo '---'
     cat /tmp/new-frontmatter.yaml
     echo '---'
     echo ''
     echo '<!-- SURVEYOR-OWNED START last-surveyed:'$(date +%Y-%m-%d)' -->'
     echo ''
     cat /tmp/new-surveyor-body.md
     echo ''
     echo '<!-- SURVEYOR-OWNED END -->'
     echo ''
     echo '<!-- WRAP-WORK-OWNED START -->'
     echo ''
     cat /tmp/old-wrap-content.md
     echo ''
     echo '<!-- WRAP-WORK-OWNED END -->'
   } > "${LIVE}.new"
   mv "${LIVE}.new" "$LIVE"
   ```

7. Edit 一次 `$LIVE` 在 `## Changelog` 段追加 migration entry:
   ```
   - YYYY-MM-DD: migrated to marker-based owner split by /project-decompose; snapshot of pre-migration state → [[<snapshot-basename>]]
   ```

#### Removed unit handling

如用户选择 archive：
```bash
mv "$LIVE" "$VAULT/archives/<project>/features/<slug>-<YYYY-MM-DD>.md"
```
+ 在 `<project>/log.md` 记一笔。

如用户选择 delete: `rm "$LIVE"`（先确认）。

### Step 6 — 自动织 cross-link + 更新 wiki/log

#### 6a. 双向链接 verify

对每个 unit 的 SURVEYOR 块的 Dependencies / Consumers 段：

- 每个 `[[<slug>]]` → `Glob` 检查 `<project_doc_path>/{features,services,modules,api}/<slug>.md` 是否真存在
- 不存在 → 报警告（不阻塞），让用户决定后续 manual fix

#### 6b. Tier-3 `<project>.md` Module list

surveyor 已在 Overview Section 的 Modules / Services list 段列了所有 `[[<slug>]]`。decomposer 写 `<project>.md` 时直接用。

#### 6c. `<project>/wiki.md` regenerate

wiki.md 是 frequently-updated 索引，**不走 §C supersede**——直接 Write 全文 regenerate。新增段:

```markdown
## Source paths reverse index

| Source path glob | Tier-2 doc |
|---|---|
| `src/auth/**` | `[[oauth-login]]` |
| `src/middleware/oauth.py` | `[[oauth-login]]` |
| `src/conversation/**` | `[[conv-history]]` |
| ... | ... |
```

这是 wrap-work 路由的 reverse index。也可以让 wrap-work 直接 grep 项目内所有 Tier-2 doc 的 frontmatter（更准），但 wiki 里有一份直观索引方便 human review。

#### 6d. `<project>/log.md` append

```markdown
## YYYY-MM-DD — /project-decompose run

- Survey input: [[project-survey-<proj>-<ts>]]
- Units processed: N (NEW: a, SUPERSEDE: b, MIGRATE: c, SKIP: d)
- Removed units: <list 或 none>
- Tier-3: updated | unchanged
- Snapshots: [[superseded-...]] × X
- Wiki regenerated
```

### Step 7 — 中间文件归档

```bash
year=$(date +%Y)
mkdir -p "$VAULT/archives/$year"
mv "$INTERMEDIATE_FILE" "$VAULT/archives/$year/"
```

不删——保 audit trail。

### Step 8 — 完成报告

≤ 15 行：

```
✅ Decompose 完成

Project: <name>
Units processed: N
- NEW: a
- SUPERSEDE: b
- MIGRATE: c
- SKIP: d

Snapshots: <count>
Wiki: regenerated
Log: appended

Tier-3 Mermaid: refreshed | unchanged

中间文件归档: archives/<YYYY>/<file>
```

---

## Tier-2 file template (NEW / SUPERSEDE 都用)

```markdown
---
title: <human title or slug>
id: <project>/features/<slug>     # adjust per logical_kind: services/modules/api
category: feature                   # or service | module | api
status: active
tags: [feature, <project>, <domain-keywords>]
created: YYYY-MM-DD                 # NEW = today; SUPERSEDE = carry over
updated: YYYY-MM-DD                 # = today
logical_kind: feature
source_paths:                       # main root paths (含 root prefix)
  - app/src/X/**
satellite_paths:                    # NEW §4.7 — satellite root paths bound to this unit; 可空 []
  - infra/terraform/X/**
  - deploy/ci/X-pipeline.yml
last_surveyed: YYYY-MM-DD
---

# <Unit Title>

> Tier-2 单元描述。SURVEYOR 块由 /project-decompose + /wrap-work（hybrid 模式）refresh；WRAP-WORK 块由 /wrap-work append-only 累积 task history。

<!-- SURVEYOR-OWNED START last-surveyed:YYYY-MM-DD -->

## What 功能描述

<from intermediate ### What>

## Why 设计意图

<from intermediate ### Why>

## Inputs / Outputs

<from intermediate ### Inputs / Outputs>

## Implementation Summary 当前实现

<from intermediate ### Implementation Summary>

## Detailed Flow Graph

<from intermediate ### Detailed Flow Graph — mermaid block + 可选 Notes>

## Infra Mapping

<from intermediate ### Infra Mapping — Infra Graph (mermaid, infra-internal wiring) + per-satellite-root sub-sections with tables (main 组件 ↔ infra 资源)>
<!-- 如完全无 satellite 配对，写 "_无_" -->
<!-- 如配对节点 ≤ 2，可省 Infra Graph 段直接走 tables -->

## Dependencies 依赖

- [[<dep-slug>]] — <一句话>
<!-- 如 deps 空，写 "_无_" -->

## Consumers 消费方

- [[<consumer-slug>]] — <一句话>
<!-- 如 consumers 空，写 "_无_" -->

<!-- SURVEYOR-OWNED END -->

<!-- WRAP-WORK-OWNED START -->

## Timeline 时间线

_由 /wrap-work 累积。最新在上。_

## Changelog

- YYYY-MM-DD: initial decompose from [[project-survey-<proj>-<ts>]]

## Related

- Tier-3: [[<project>]]
- 相关 knowledge: _(by /wrap-work)_
- 相关 decisions: _(by /wrap-work)_

<!-- WRAP-WORK-OWNED END -->
```

## Tier-3 file template (NEW / SUPERSEDE 都用)

```markdown
---
title: <project>
id: <co>/projects/<project>
category: project-overview
status: active
tags: [project-overview, <project>, <co>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
logical_kind: overview
last_surveyed: YYYY-MM-DD
---

# <project>

> Tier-3 项目高层视图。本页是项目入口——读完 Mission + 两张架构图 (Main / Infrastructure) + 各 unit 详细描述段，能完整把握项目"做什么、由哪些 unit 组成、靠什么 infra 跑、怎么集成外部"。深入到 unit 内部细节请 click 对应 [[link]] 进 Tier-2。

<!-- SURVEYOR-OWNED START last-surveyed:YYYY-MM-DD -->

## Mission 项目目标

<from overview ### Mission — 2-5 sentences narrative>

## Architecture 主架构 (main code units)

```mermaid
<from overview ### Architecture mermaid block>
```

<from overview Architecture 紧随的 2-4 sentences narrative — main component 组织 / data flow / key abstraction>

## Infrastructure Architecture 基础设施架构

<只在 surveyor 中间文件含此段时才写——纯 main 项目无 satellite 时整段省略>

```mermaid
<from overview ### Infrastructure Architecture mermaid block>
```

<from overview Infrastructure Architecture 紧随的 3-6 sentences narrative — infra topology / 部署环境 / secret / 网络 / deploy pipeline>

每个 main unit 具体对应的 infra 资源 → 见对应 Tier-2 doc 的 `## Infra Mapping`。

## Modules / Services 详细描述

<from overview ### Modules / Services 详细描述 — 含 per-unit `####` subsections，每个 unit 一段 3-5 sentences narrative + `详 → [[<unit>]]` 跳转行>

## Integrations 集成

<from overview ### Integrations — 上游 / 下游 / 第三方 SDK，每条带场景说明>

## Tech Stack 技术栈

<from overview ### Tech stack — Language / Storage / Runtime / Deploy / Observability，每条带选型理由 if non-obvious>

<!-- SURVEYOR-OWNED END -->

<!-- WRAP-WORK-OWNED START -->

## Active Work 在进行的工作

_由 /wrap-work 维护——每条 [[task-link]] 一行加 touched units 标注。_

## Repo / Code Layout 代码组织

<可选；如果 surveyor 没产出，wrap-work 可手补>

## Changelog

- YYYY-MM-DD: initial decompose from [[project-survey-<proj>-<ts>]]

<!-- WRAP-WORK-OWNED END -->
```

## Rules

- **Snapshot 必先**: 任何 SUPERSEDE / MIGRATE 必先跑 `${CLAUDE_PLUGIN_ROOT}/scripts/snapshot-supersede.sh`，再写新 live。永不静默覆盖
- **WRAP-WORK 块逐字 carry**: 用 sed/awk 在 shell 抽，不进 LLM context。LLM 只产新 SURVEYOR 内容
- **NEW 文件包空 WRAP-WORK 块**: 即便没 history，也写出 `<!-- WRAP-WORK-OWNED START / END -->` + 三个空 placeholder section（Timeline / Changelog / Related），让后续 wrap-work 有锚点
- **SKIP 时仍 bump last-surveyed**: 真值没变也是 valuable 信号
- **Wiki regenerate、不 supersede**: wiki.md 是 frequently-updated 索引，直接 Write 全文重写
- **Log append-only**: log.md 永远 append（用 anchor 注入；见 [[CLAUDE]] §10）
- **中间文件归档不删**: 保 audit trail
- **MIGRATE 旧版进 snapshot**: 老 description / architecture 不在 live append、不带日期保留——全留 snapshot 链
- **Markdown 排版按 [[meta/style-guide]] §C**: 渲染 SURVEYOR body 到 live doc 时——源里看到 `(1) ... (2) ... (3) ...` ≥ 3 项 inline 枚举或 "Step 0 → Step 1 → Step 2 → ..." 多步流程，**一律展开成 numbered list**（每项 `1.` `2.` `3.` 各起一行，可加 `**bold label** — 说明` 形式）。源 line break ≠ 渲染换行——渲染换行靠空行和 list 项。即便 surveyor 中间文件给的是流水句，decomposer 渲染时**必须改写**。What 段、Implementation Summary 段是高发区

## Tools used

- Read（中间文件、live 文件 frontmatter / 旧 SURVEYOR 块用于 byte-compare、template 文件）
- Bash（**核心**：snapshot-supersede.sh、sed/awk 抽 SURVEYOR / WRAP-WORK 块、shell 拼新文件、mv 中间文件归档、`date` 时间戳）
- Write（新 live 文件、wiki.md regenerate）
- Edit（log.md append、SKIP 时 bump frontmatter `last_surveyed` + marker、SUPERSEDE/MIGRATE 后追加 changelog 行）
- Glob（列项目下现有 features/services/modules/api docs、verify cross-link target 存在）
- TaskCreate（**禁用** — 线性流程不需要 tracker）

## Anti-patterns

- ❌ 跳过 snapshot 直接 Edit/Write 旧 live 文件——丢历史
- ❌ Read 旧 live 文件全文进 LLM context——浪费 token；sed 在 shell 抽就够
- ❌ MIGRATE 时把老 description 当 stylistic reference 给 surveyor——surveyor 已经独立产出，不要混
- ❌ 自动跑 decompose 不让用户 review plan——必须 show plan + 等 confirm
- ❌ wiki.md 也走 supersede——wiki 是 frequently-updated 索引，regenerate 即可
- ❌ 删中间文件——必归档到 archives/
- ❌ 跳过 byte-compare 直接 SUPERSEDE 所有文件——浪费 snapshot 空间 + 制造无变化 diff 噪音

## Output format

完成后报告 ≤ 15 行（hard limit），格式见 Step 8。
