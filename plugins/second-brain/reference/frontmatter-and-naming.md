---
title: Frontmatter Schema and Naming Conventions
id: meta/frontmatter-and-naming
category: reference
status: active
tags: [meta, frontmatter, naming, vault-schema]
created: 2026-05-03
updated: 2026-05-03
---

# Frontmatter Schema and Naming Conventions

vault 里**每个 markdown 页**的 frontmatter 字段定义 + 文件命名规则。Root `CLAUDE.md` §3/§4 只摘最小必填集合；本文是完整 schema + 各文件类型的命名 pattern。

---

## A. Frontmatter Schema

每个 markdown 页顶部都有 YAML frontmatter：

```yaml
---
title: Descriptive Title
id: <zone>/<slug>                   # stable ID for cross-references
category: knowledge | decision | lesson | log | retro | playbook | literature | draft | moc | reference | task | feature | project-overview | project-wiki | project-log | superseded
status: draft | active | superseded | archived | frozen
tags: [tag1, tag2]                  # domain tags: #ai, #postgres. status tags: #draft, #active, #frozen
created: YYYY-MM-DD
updated: YYYY-MM-DD
supersedes: []                      # optional: list of page IDs this replaces
superseded_by: null                 # optional: page ID that replaced this one
source: null                        # optional: link to raw/ page or external URL
frozen: false                       # if true, Claude must not read or edit this page (see [[meta/supersede-patterns]] §D). Default false.
---
```

### 最小必填集合

每个页面 frontmatter **至少**有：

- `title`
- `created`
- `tags`

其他字段按页面类型补：
- 跨引用页面（durable）→ 加 `id`、`category`、`status`、`updated`
- 决策 / 知识页 → 可能用 `supersedes` / `superseded_by`
- raw 派生的 distilled 页 → 加 `source: raw/...`
- task / superseded 文件 → 加 `frozen: true`、`status: frozen` / `superseded`

### `frozen: true` 适用范围

- 所有 `tasks/YYYY/Mmm/*.md` 文件（首次写入后立即冻结）
- 所有 `superseded/*.md` 快照

详见 [[meta/supersede-patterns]] §D。

### Status 字段的 lifecycle

```
draft → active → superseded（被取代）
              → archived（项目下线）
              → frozen（task / snapshot 写完即冻）
```

`status: active` 且 `updated` 早于 180 天的页面，会在 monthly lint 触发 review prompt（见 `.claude/skills/lint/SKILL.md`）。

---

## B. Naming Conventions

### 通用规则

- Filenames：`kebab-case.md`
- **不允许**空格、emoji
- 跨引用一律用 Obsidian `[[wiki-link]]`，filename 去掉 `.md`

### 按文件类型

#### 普通页面

`<slug>.md`，例如 `idempotent-writes.md`。

#### 日期 / 周日志

- 日：`YYYY-MM-DD-<slug>.md`，例如 `2026-04-15-meeting-with-pm.md`
- 周：`YYYY-Www.md`（ISO week），例如 `2026-W17.md`

#### 决策（ADR）

`NNNN-slug.md` —— 4 位零填充递增编号，**目录内 unique**。

```
decisions/
├── 0001-use-postgres.md
├── 0002-async-writes.md
└── 0003-bedrock-converse-api.md
```

新建决策前用 `ls decisions/` 找最大号 +1。

#### 任务（Tier-1，frozen）

```
<project>/tasks/YYYY/Mmm/YYYY-MM-DD-<task-slug>[-TICKET].md
```

- `YYYY` = 年份
- `Mmm` = 三字母月份：`Jan` / `Feb` / `Mar` / `Apr` / `May` / `Jun` / `Jul` / `Aug` / `Sep` / `Oct` / `Nov` / `Dec`
- `<task-slug>` = 3-6 个 kebab 词，最能描述任务（branch 名 / 用户给的标识）
- `[-TICKET]` = 可选 ticket 后缀（`-ED-1514` / `-ML-1196`）。无 ticket 省略。**永远是 `.md` 之前的最后一段**

例子：

```
work/sapia/projects/agents/tasks/2026/Apr/2026-04-29-thread-html-view-endpoint-ED-1514.md
work/sapia/projects/agents/tasks/2026/Apr/2026-04-30-cache-warmup-fix.md
```

#### Superseded snapshots

```
<project>/superseded/superseded-<original-name>-YYYY-MM-DD-HHMM.md
```

- `superseded-` 前缀强制
- `YYYY-MM-DD-HHMM` 时间戳后缀强制
- **永远不要覆盖已有 snapshot**——同分钟冲突时 +1 分钟

例子：

```
work/sapia/projects/agents/superseded/superseded-agents-2026-04-30-1612.md
work/sapia/projects/agents/superseded/superseded-thread-html-view-2026-04-30-1612.md
```

详见 [[meta/supersede-patterns]] §C。

#### MOC pages（folder notes）

**与 parent folder 同名**：

```
work/sapia/sapia.md         ← MOC for work/sapia/
knowledge/AI/AI.md          ← MOC for knowledge/AI/
projects/quantT/quantT.md   ← MOC for projects/quantT/
```

**例外**：vault root 用 `index.md`（不是 `YisBrain.md`）。

详见 [[CLAUDE]] §11 / [[meta/obsidian-conventions]] 关于 Obsidian "folder notes" 插件。

#### Zone wiki + log（每个 distilled 文件夹的索引和变更）

按 [[CLAUDE]] §2.2：

- `<folder>/wiki.md` —— 目录索引
- `<folder>/log.md` —— 变更日志

文件名固定（`wiki.md` / `log.md`，**小写、无前缀**）。

#### 项目 meta（Tier-3 + 项目级 CLAUDE）

每个项目目录下：

- `<project>/<project>.md` —— Tier-3 项目总览
- `<project>/CLAUDE.md` —— 项目级 Claude 指令（详见 [[meta/project-claude-guide]]）
- `<project>/wiki.md` —— 项目目录索引
- `<project>/log.md` —— 项目 durable 变更日志

---

## C. Cheat-sheet（最常查的）

| 文件 | 命名 |
|---|---|
| 普通 distilled 页 | `<slug>.md` (kebab) |
| 决策 | `NNNN-<slug>.md` |
| Task | `YYYY-MM-DD-<slug>[-TICKET].md` 在 `tasks/YYYY/Mmm/` |
| Snapshot | `superseded-<basename>-YYYY-MM-DD-HHMM.md` 在 `superseded/` |
| MOC | `<folder>.md`（与文件夹同名）|
| 周日志 | `YYYY-Www.md` 在 `*/log/` |
| Zone 索引 | `wiki.md` |
| Zone 变更 | `log.md` |

frontmatter 最小集合：`title` + `created` + `tags`。其他按页面类型补。
