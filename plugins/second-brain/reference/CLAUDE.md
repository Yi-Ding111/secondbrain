# CLAUDE.md — Yi's Brain Vault Schema

This file is the **宪法** (constitution) of this Obsidian vault. It tells Claude how to think, write, and maintain the knowledge base across sessions.

When Claude opens this vault, read this file first. All other behavior derives from the rules here. **Detail offloads to `meta/*.md`**——本文件只保留每次 session start 都必须 always-load 的核心；展开内容靠 `[[link]]` 跳转或 path-scoped rules lazy-load。

> **唤醒第一读物**：读完本文件后，先读 [[manifest]]（机器可读的 zone 索引）——它告诉你某主题在哪个 zone、该读哪个 MOC、要不要跳过，避免全库扫描。人肉浏览入口是 [[index]]。

---

## 1. Purpose

Yi's second brain — persistent, compounding knowledge base for **Knowledge** (semantic memory)、**Experience** (lessons / decisions / retros)、**Work** (companies / projects / tickets / logs)、**Learning** (in-progress).

模型：**Karpathy LLM Wiki**（raw → distilled → wiki 三层）+ **PARA**（project/area split）+ **Zettelkasten**（atomic notes、`[[links]]`）。

---

## 2. Directory Map (top-level)

| Zone                                               | 用途                                                      | 详见                      |
| -------------------------------------------------- | ------------------------------------------------------- | ----------------------- |
| `inbox/`                                           | dump zone — 未分类 capture                                 | (see [[directory-map]]) |
| `raw/`                                             | immutable 原始 source                                     |                         |
| `work/<co>/projects/<proj>/`                       | 雇主项目 — 多 tier 结构                                        | [[multi-tier-model]]    |
| `projects/<name>/`                                 | 个人项目 — 同 multi-tier                                     | [[multi-tier-model]]    |
| `knowledge/<domain>/`                              | semantic memory，atomic pages                            | [[directory-map]]       |
| `experience/{lessons,decisions,retros,playbooks}/` | 跨项目 sediment                                            |                         |
| `learning/{reading,courses,questions,literature}/` | in-progress                                             |                         |
| `thinking/drafts/`                                 | half-baked working memory                               |                         |
| `wiki/`                                            | cross-pillar synthesis only（≥2 个 pillar 才放这）            |                         |
| `archives/`                                        | 死掉的 project / 离开的 company                               |                         |
| `meta/`                                            | templates / scripts / superseded snapshots / 本文件 mirror |                         |

完整 zone breakdown + per-zone lifecycle → [[directory-map]]

---

## 2.1 Project Multi-Tier Model (CRITICAL)

每个 project 是 **3-tier zoom hierarchy** + 3 meta files。Top-down 读: 整个项目 → 一个 logical unit → 一个 ticket。Bottom-up 写: tasks → features → project overview。

| Tier | File | 一句话 |
|------|------|--------|
| **Tier-3** | `<project>.md` | 高层架构 + Mermaid graph，entry point |
| **Tier-2** | `features/<feat>.md` / `services/` / `modules/` / `api/` | 一个 logical unit (feature/service/module/api) 的 what + why + impl summary |
| **Tier-1** | `tasks/YYYY/Mmm/*.md` | 一个 ticket 的实现细节，**frozen after write** |

Tier-3 / Tier-2 用 **owner-block marker 模型**：SURVEYOR 块（`/project-survey` + `/project-decompose` 全量 refresh）+ WRAP-WORK 块（`/wrap-work` append-only）；Tier-2 frontmatter 含 `logical_kind` + `source_paths` + `last_surveyed`。完整块结构/字段语义 → [[project-overview-system]]。

3 个 project-meta 文件: `<project>/CLAUDE.md`（写前必读）、`<project>/wiki.md`（写前 routing 决策）、`<project>/log.md`（durable change log）。

完整 tier-flow + read-direction discipline + log-layer 区分 → [[multi-tier-model]]

---

## 2.2 Zone-Level wiki + log

`knowledge/`、`experience/`、`learning/`、`wiki/`、`projects/`、`work/<co>/` 下任何**有内容的** folder 必须有 `<folder>/<folder>.md` (MOC) + `<folder>/wiki.md` + `<folder>/log.md`。`/ingest` / `/wrap-work` 会自动维护。

完整规则、leaf vs mid-level vs top-zone 差异、bootstrap 列表 → [[zone-wiki-log]]

---

## 3. Frontmatter + Naming

每页 frontmatter **最小必填**: `title`、`created`、`tags`。Tier-2 / Tier-3 doc 额外含 `logical_kind` (feature|service|module|api|overview) + `source_paths` (glob list) + `last_surveyed` (YYYY-MM-DD)——见 [[project-overview-system]] §4。完整 schema（`id`、`category`、`status`、`supersedes`、`superseded_by`、`frozen` 等）+ 所有文件类型命名 pattern → [[frontmatter-and-naming]]

Cheat-sheet: 普通页 `<slug>.md` (kebab) | 决策 `NNNN-<slug>.md` | Task `tasks/YYYY/Mmm/YYYY-MM-DD-<slug>[-TICKET].md` (frozen) | Snapshot `superseded/superseded-<basename>-YYYY-MM-DD-HHMM.md` (frozen) | MOC `<folder>.md`。**无空格、无 emoji**。

---

## 5. Linking Rules

- 全用 Obsidian `[[wiki-link]]`，**永远不写相对路径**
- Link target = filename without `.md`（e.g., `[[0001-use-postgres]]`）
- 概念跨多页 → 建 MOC（一个 `<folder>.md`），从那 link
- **不复制内容** — link
- Multi-tier link path 是 hard：`<project>.md` 列每个 `[[<feature>]]`；`features/<feat>.md` 列每个 `[[<task-file>]]`

---

## 6. The Four Operations (Karpathy Model)

| Op | Trigger | Skill | 一句话 |
|---|---|---|---|
| **Ingest** | 新内容、inbox digest | `/ingest` | 分类 → 写入正确 zone → grep 找相关 → 双向 link → 更新 MOC + zone wiki/log → 根 log |
| **Wrap-Work** | task / branch / ticket 完成 | `/wrap-work` | inbox digest fuse 成 Tier-1 task（frozen）→ 提取 knowledge/experience → snapshot-supersede Tier-2/3 |
| **Query** | 用户问问题 | (无 skill) | grep 跨 zone（**跳过** `tasks/**` 和 `superseded/**`）→ 读相关页 top-down → 带 `[[citation]]` synthesize |
| **Lint** | 周期 review | `/lint` | weekly / monthly / quarterly / full 四档 detect-only |

每个操作的完整 step-by-step workflow 都在对应 SKILL.md。

**Periodic project doc refresh**（项目级 doc 周期 reconcile，与四操作互补）：`/project-survey`（spawn `project-surveyor` 扫 code repo → inbox 中间文件）→ `/project-decompose`（parse 中间文件 → 路由 Tier-3/2 + snapshot-supersede）。详见 [[project-overview-system]] + 各 SKILL.md。

**Plane 账本 wrapper**（整理内容前后同步 Plane ticket 生命周期）：`/track` —— 整理任何一块内容前先 **`list_projects` live 查询**（项目随时新增，**绝不用写死列表主观判断**）定位 project → 用户确认 → 项目内找 ticket → 确认（没找到问是否创建）→ 中间跑 `/ingest` 或 `/wrap-work` → 完成后回写 structured comment（`✅ 已整合` + 落地路径 + 日期）+ 状态置 **Done**。三处确认闸交给用户；状态只在收尾动。完整流程 `.claude/skills/track/SKILL.md`（`plane-track.md` rule 触碰整理路径时 auto-load）。

---

## 7. Supersede Patterns（核心规则——绝不静默覆盖）

| 文件类型 | 模式 | 一句话 |
|---|---|---|
| `decisions/NNNN-*.md` | **ADR Supersede** | 新建 `NNNN+1` 文件，老文件加 banner + `superseded_by` |
| `knowledge/<domain>/*.md` 小修补 | **Changelog** | 底部 `## Changelog` 加一行 |
| `<project>.md` / `features/` / `services/` / `modules/` / `api/*.md` | **Snapshot Supersede** | 跑 `meta/scripts/snapshot-supersede.sh <live-file>`；marker 文件 supersede 后用 sed 在 shell 拼新文件 = 新 SURVEYOR + 旧 WRAP-WORK 块 carry over（见 [[project-overview-system]]）|
| `tasks/**`、`superseded/**` | **Frozen** | 写完即封印 |

**两条硬性原则**：拿不准 changelog 还是 supersede → **默认 supersede**；snapshot 必须走脚本，**不要手动 Read+Write**——旧文件不该进 LLM context。

完整规则、anti-patterns、脚本输出格式、`/project-decompose` 的 scoped byte-compare → [[supersede-patterns]] / [[project-overview-system]]

---

## 8. Ephemeral vs Durable

| Type | 例子 | 位置 | Lifecycle |
|------|----|----|----|
| **Ephemeral** | weekly logs | `*/log/YYYY-Www.md` | 月度 compress、年度 archive |
| **Durable (live)** | project overview / features / decisions / lessons / knowledge / playbooks / project log / wiki | 各 zone | Snapshot/ADR-superseded（§7）|
| **Semi-durable** | references / playbooks | `references/` `playbooks/` | Changelog on update |
| **Frozen** | task files / superseded snapshots | `tasks/**`、`superseded/**` | Write once, never read or edit |
| **Immutable** | raw sources | `raw/` | Never edited |

最常见 failure mode: 把 ephemeral 内容放进 durable zone。纪律: 日/周日常留在 `log/YYYY-Www.md`；6 个月后还重要才 promote。Task 一旦 wrap → frozen，不再是 living doc。

---

## 9. Lint

`/lint` —— weekly / monthly / quarterly / full 四档健康检查。覆盖 inbox 超期、broken links、orphan pages、stale active 页、superseded 链完整性、zone wiki/log 一致性。完整 checklist → `.claude/skills/lint/SKILL.md`

---

## 10. How Claude Should Behave (default posture)

- **Be surgical** — small targeted edits，不静默重写 durable
- **Cite everything** — vault 内回答每条 non-trivial claim 带 `[[page-id]]`
- **Ask before crossing layers** — `thinking/drafts/` → `knowledge/` 是 promotion，先确认
- **Log writes — prepend via anchor, do NOT read body** — 多页操作完后写 `log.md`（root 或 zone）：用 **Edit tool 把 `<!-- LOG-ANCHOR ... -->` 整行替换为 `<anchor>\n\n## YYYY-MM-DD — <topic>\n\n<body>`**——新 entry 落在 anchor 正下方、所有旧 entry 之上（newest 始终在 entry list 顶端）。**绝不 Read log.md body**，anchor 足够 unique。新 log 文件用 `meta/scripts/log-sort-and-anchor.sh <path>` 一次性插 anchor。详细 → [[claude-behavior]]
- **开工前切 ticket 分支** — 领到一个 ticket、准备在 vault 里做它的工作前，先从 `main` 切 `feature/<TICKET-ID>/<desc>`（例 `feature/ED-1509/fix-race`）；**绝不在 `main` 上做 ticket work，绝不替用户 commit / merge**。完整规则 `.claude/rules/ticket-branch.md`（触碰 project/task 路径时 auto-load）
- **Path-scoped 行为护栏 auto-load** — `tasks/**`、`superseded/**`、`raw/**`、`inbox/**`、project / live tier 文件由 `.claude/rules/` 触发提醒（见 §13）

完整 per-operation posture（ingest / wrap-work / query / 分类不确定 / 冲突 / style）→ [[claude-behavior]]
Style 三条核心 + worked examples → [[style-guide]]

---

## 11. Obsidian Conventions

MOC pattern、daily/weekly notes plugin、tags 偏好、模板放法、template 占位符替换规则（critical——`[[<x>]]` 漏替换 = broken link）、Mermaid + link 作 navigation backbone → [[obsidian-conventions]]

---

## 12. What NOT to Do

- ❌ 不在 project 里建 `wiki/` 子目录（wiki 是 top-level cross-pillar 层；project 用 `wiki.md` 这一个文件，是不同概念）
- ❌ 不复制 JIRA / Linear ticket（已有 source of truth）
- ❌ 不静默 overwrite decisions / knowledge / project overview / features — 用 §7 supersede
- ❌ 不删 `features/<feat>.md` 老内容 — append timeline，snapshot 旧版
- ❌ 不创建无 frontmatter 页
- ❌ 不写 1000-line 页（task 文件除外，inherently rich）
- ❌ 不用相对路径（`../knowledge/AI/foo.md`）— 用 `[[foo]]`

Path-scoped 护栏（frozen / raw / inbox / project / supersede 触发）由 `.claude/rules/` 在触碰对应路径时**自动注入**——见 §13，不在这里重复。

---

## 13. Rules + Skills + Agents + Hooks

| 入口 | 路径 | 干什么 |
|---|---|---|
| **Rules** | `.claude/rules/*.md` | path-scoped lazy-load 护栏 — frozen / raw-immutable / project-write / snapshot-required / inbox-handling |
| **Skills** | `.claude/skills/{ingest,wrap-work,lint,project-survey,project-decompose}/SKILL.md` | 命令触发的 workflow how-to |
| **Subagents** | `.claude/agents/{digest-fuser,knowledge-extractor,project-surveyor}.md` | 子 context 委派（read-only）；前两个 `/wrap-work` 用、`project-surveyor` `/project-survey` 用 |
| **Hooks** | `meta/scripts/hooks/auto-log-append.sh` (registered in `.claude/settings.json`) | PostToolUse on Write/Edit — auto leaf log |
| **Upstream feeders** | `~/.claude/skills/{brain-digest,task-git-digest}/` | 跨 session 把产物投递到 `inbox/` |

完整触发表、compaction-survival 行为、mirror map、agent I/O contract → [[rules-registry]]

---

## 13.5 Project-level CLAUDE.md

每个项目带一份自己的 `CLAUDE.md` —— **scoped contract**，**补充**而非取代本文件。它告诉 Claude 在**这一个项目内部**怎么操作（哪些文件夹跳过、必读哪些文件、knowledge extraction 偏好哪些 domain、link policy、project-specific 命名）。

完整模板、何时更新、`/wrap-work` 怎么用它、现有样例 → [[project-claude-guide]]
模板文件: `meta/templates/project-claude.md`
