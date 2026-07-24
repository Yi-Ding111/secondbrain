---
title: Rules + Skills + Agents + Hooks Registry
created: 2026-05-09
tags: [meta, claude-config, rules, skills, agents, hooks]
---

# Rules + Skills + Agents + Hooks Registry

Root [[CLAUDE]] keeps the routing tables (path → rule, command → skill). This file holds the explanation prose: how each component is wired, what compaction-survival looks like, what to know when extending the system.

---

## Rules (`.claude/rules/`)

Path-scoped lazy-load. 只在 Claude 读匹配路径文件时进 context——这是 vault 真正的"自动护栏 + 写前 checklist"。**Always-load 的 CLAUDE.md 不再重复这些 path-specific 内容**。

| Rule | 触发路径 | 干什么 |
|---|---|---|
| `frozen-files.md` | `**/tasks/**`、`**/superseded/**` | 提醒 "frozen，别编辑、别 silently propagate" |
| `raw-immutable.md` | `**/raw/**` | 提醒 "raw immutable，annotation 写到 distilled" |
| `project-write.md` | `**/work/*/projects/*/**`、`**/projects/*/**` | 进项目目录的写前 checklist（读 CLAUDE.md → wiki.md → 决定 Tier）|
| `snapshot-required.md` | `**/<project>.md`、`**/features/**`、`**/api/**` | 提醒 "编辑前必跑 `meta/scripts/snapshot-supersede.sh`" |
| `inbox-handling.md` | `**/inbox/**` | 提醒 "dump zone 不是 query 源；待 ingest/wrap-work 消费" |
| `ticket-branch.md` | `**/work/*/projects/*/**`、`**/projects/*/**`、`**/tasks/**` | 开工前从 `main` 切 `feature/<TICKET-ID>/<desc>`；绝不在 main 上做 ticket work，绝不替用户 commit/merge（根 [[CLAUDE]] §10 有 always-load 兜底）|
| `plane-track.md` | `**/inbox/**`、`**/knowledge/**`、`**/experience/**`、`**/learning/**`、`**/work/*/projects/*/**`、`**/projects/*/**`、`**/wiki/**` | 整理内容前后走 Plane 账本：开工前 `list_projects` live 查项目 + 找 ticket（均确认）→ 整理 → 回写 comment + 状态 Done。实现 = `/track`（根 [[CLAUDE]] §6 有 always-load 兜底）|

**Compaction 后丢失** — `paths:` rules 在 compaction 后 LOST 直到再读到匹配文件。所以**写法要让 "再读到时就够 self-contained"**，关键 invariant 也要在根 [[CLAUDE]] 里有一句兜底。

详细 rule 文件本身就是 source of truth——这里只列触发表。

---

## Subagents (`.claude/agents/`)

让 digest 全文 / topic 分析在**子 context** 跑，main thread 只协调 + 写入。两个都是 read-only（无 Write 工具），写文件由 main thread 在用户确认后做。

| Agent | 输入 | 输出 | 用在哪 |
|---|---|---|---|
| `digest-fuser` | 1-N digest paths + 任务 metadata | TASK_FILE_BODY + NOTES（features 候选 + knowledge 候选）| `/wrap-work` Step 2——digest 全文不进 main |
| `knowledge-extractor` | 1 个 brain-digest topic | RECOMMENDATION（NEW vs UPDATE-changelog vs UPDATE-supersede vs INBOX）+ TOPIC_BODY | `/wrap-work` Step 3——并行 spawn N 个 agent，每个 1 topic |

调用：`Agent` tool 加 `subagent_type: <name>`。多个 knowledge-extractor 并行时，**同一个 message 里多个 Agent tool call** 让它们 concurrent 跑。

---

## Skills (`.claude/skills/`)

命令触发 lazy-load。

| Skill | Triggers | 详见 |
|---|---|---|
| `/ingest` | "ingest"、"整理一下"、"记入 brain" | `.claude/skills/ingest/SKILL.md` |
| `/wrap-work` | "wrap up"、"完工"、"做完了" | `.claude/skills/wrap-work/SKILL.md` |
| `/lint` | "lint"、"体检"、"check my brain" | `.claude/skills/lint/SKILL.md` |
| `/track` | "track"、"整理并记录到 plane"、"记到 plane" | `.claude/skills/track/SKILL.md` |

`/track` 是 Plane ↔ vault 的**信封 wrapper**：前 live 查 Plane 定位 project+ticket（确认闸）→ 中间调 `/ingest` 或 `/wrap-work` → 后回写 comment + 状态 Done。由 `plane-track.md` rule 提示、根 [[CLAUDE]] §6 兜底。

三个 skill 共同约定：用 native tools 而非 MCP wiki（后者绑死 `.omc/wiki/`）；规则 defer 到 [[CLAUDE]]（skill 是 *how*，CLAUDE.md 是 *what*）；每次操作 append 一行根 `log.md`。

---

## Upstream feeders (user-global, in `~/.claude/skills/`)

两个 feeder 跑在**任何**其他 Claude Code session（工作 repo、研究 session 等），把产物放进本 vault `inbox/`，等 `/wrap-work` 或 `/ingest` 消费。读 `$BRAIN_VAULT` 环境变量（默认 `$HOME/Documents/YisBrain`）。

| Skill | 抓什么 | 何时用 |
|---|---|---|
| `brain-digest` | session prose（思路、worked example、决策叙述）| "thinking session"——研究 / 调试 / 设计 |
| `task-git-digest` | git diff + commit timeline | "coding session"——完成 ticket、wrap branch |

同一 session 可以两个都跑（不同层）；`/wrap-work` 会 fuse 它们进同一个 task 文件。

---

## Cross-device sync — deprecated

跨设备同步已改由 **plugin 安装**（`yis-brain` marketplace）承担。旧的 `claude-sync/` 镜像与 `mirror-sync.sh` hook 已于 2026-07 移除。source of truth 仍是 `.claude/` 与 plugin。

---


## Hooks (`meta/scripts/hooks/`)

| Hook | 触发 | 干什么 |
|---|---|---|
| `auto-log-append.sh` | PostToolUse on Write/Edit 到 distilled zone | 自动 append 一行 `## YYYY-MM-DD [auto:HH:MM]` 到 leaf folder 的 `log.md`（带 dedup，不会和 `/ingest`/`/wrap-work` 的 rich entry 冲突）|

错误日志在 `meta/scripts/hooks/.<hook-name>.log`，hook 永不阻塞操作。
