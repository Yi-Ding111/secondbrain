---
title: Supersede Patterns
id: meta/supersede-patterns
category: reference
status: active
tags: [meta, supersede, frozen, vault-schema]
created: 2026-05-03
updated: 2026-05-03
---

# Supersede Patterns

vault 里的 durable 内容（decisions / knowledge / project overview / features）**永不静默覆盖**。本文件是三种 supersede 模式的 source of truth——root `CLAUDE.md` 只摘核心原则，详细规则、frontmatter 字段、自动化脚本走法都在这里。

适用场景一句话总结：

| 文件类型 | 走哪种模式 | 原因 |
|---|---|---|
| `decisions/NNNN-*.md` 决策 | **§A: ADR Supersede** | 决策按编号路径存（`0001`、`0002`），新建即新文件，并存可见 |
| `knowledge/<domain>/*.md` 概念页（小修） | **§B: Changelog** | 微调 / 补段 / 修 typo 用 changelog 行，不需要新文件 |
| `<project>.md`（Tier-3 项目总览） | **§C: Snapshot Supersede** | 必须留在固定 path（外部 link 不能断），历史搬到 `superseded/` |
| `features/<feat>.md`（Tier-2 功能页） | **§C: Snapshot Supersede** | 同上 |
| `tasks/YYYY/Mmm/*.md` | **§D: Frozen**（write-once） | 写完即冻结，不再读不再编辑 |
| `superseded/*.md` 快照本身 | **§D: Frozen**（archive） | 写完即冻结，不再读不再编辑 |

下面按模式展开。

---

## A. ADR Supersede（适用于 `decisions/NNNN-*.md`）

决策页的路径里带递增编号（`0001-use-postgres.md`），所以替换决策 = 新建 `NNNN+1` 文件，老文件保留并打 banner。两份文件并排可见，链接不断。

### 替换流程

1. **保留旧页**，frontmatter 改：
   ```yaml
   status: superseded
   superseded_by: <new-id>
   ```

2. **新页**：filename = `NNNN+1-<new-slug>.md`，frontmatter：
   ```yaml
   supersedes: [<old-id>]
   ```

3. **旧页顶部加 banner**：
   ```markdown
   > ⚠️ **Superseded by [[NNNN-new-slug]]** on YYYY-MM-DD. Kept for history.
   ```

### 何时用

- 架构方向变了（"我们以前选 Postgres，现在改用 DynamoDB"）
- 决策被推翻（"以前决定走 microservice，现在收敛回 monolith"）
- 关键概念重新定义

---

## B. Changelog（适用于 `knowledge/<domain>/*.md` 小修补）

知识页内容微调时不必新建文件，在底部 `## Changelog` 段加一行即可。

### 流程

```markdown
## Changelog
- 2026-08-15: Updated for v2 API (async writes)
- 2026-05-01: Initial version
```

### 何时用 Changelog vs 何时升级到 Supersede

| 信号 | 走法 |
|---|---|
| 参数微调 / 补段落 / 修 typo / 加新例子 | Changelog |
| 修一个先前理解错的描述 | Changelog（标 "Corrected:"）|
| 架构变了 / 决策推翻 / 概念重定义 | Supersede |
| 老结论在新场景不再成立但旧场景还成立 | Supersede（两份并存）|

**拿不准 → 默认 Supersede**。多一份历史不亏，silent overwrite 才是真损失。

---

## C. Snapshot Supersede（适用于 `<project>.md` 和 `features/<feat>.md`）

这两类文件必须留在**固定 path**——读者点进 `[[<project>]]` / `[[<feature>]]` 永远要落到当前 live 版本。所以替换不能换路径，而是把旧版**快照搬到 `superseded/` 子目录**，然后原地改 live 文件。

### 命名约定

```
<project>/superseded/superseded-<basename>-YYYY-MM-DD-HHMM.md
```

- 项目总览：basename = project 名，例如 `superseded-agents-2026-04-30-1612.md`
- feature：basename = feature 名，例如 `superseded-thread-html-view-2026-04-30-1612.md`

`superseded-` 前缀和时间戳后缀都是**强制**的（[[CLAUDE]] §4 命名规则）。**永远不要覆盖已有快照**——同一时间戳的快照不会冲突，但即便冲突也应该 +1 分钟。

### 自动化脚本（强制使用）

`meta/scripts/snapshot-supersede.sh` 已经把 cp + frontmatter 改写 + banner 注入全部封装了。**用脚本，不要 LLM 手动 Read+Write**：

```bash
SNAPSHOT=$(meta/scripts/snapshot-supersede.sh <project>/features/<feat>.md)
# SNAPSHOT 是 snapshot 的相对路径，例如:
#   work/sapia/projects/agents/superseded/superseded-<feat>-2026-05-03-1530.md
```

脚本完成的事：
1. cp live → `superseded/superseded-<basename>-<timestamp>.md`
2. 改写 snapshot frontmatter：`status: superseded`、`category: superseded`、`frozen: true`、id 重写
3. 顶部注入 banner：
   ```markdown
   > 🧊 **Frozen snapshot of [[<original-name>]] taken at YYYY-MM-DD HH:MM.** Do not read or edit.
   ```
4. stdout 打印 snapshot 路径供 caller 用

**为什么必须走脚本**：旧 live 文件的内容**完全不需要进 LLM context**——shell 端 cp + sed 完成所有操作。手动 Read+Write 会把整个旧文件喂进 context，纯粹烧 token。

### 更新 live 文件

snapshot 完成后，在原 path 改 live 文件：

- **features**: 在 `## Timeline` 段（无则建）追加新条目；**绝不删除**已有 description（[[CLAUDE]] §10 append, not replace）。如果功能描述本身需要更新，**追加**新版本说明，旧描述带日期标注保留
- **project overview**: 如果架构变了，刷新 Mermaid 图、模块列表；只新增模块时优先 `Edit` 而非整文件 rewrite

每次更新都要：

1. bump frontmatter `updated:` 为今天
2. 在 live 文件 `## Changelog` 加一行引用 snapshot：
   ```markdown
   - 2026-04-30: snapshot before architecture refresh → [[superseded-agents-2026-04-30-1612]]
   ```

### 模式对比：A vs C 一句话

- **A (ADR)**: 路径自带编号（`0001`、`0002`），新版本 = 新文件，老文件原地不动加 banner
- **C (Snapshot)**: 路径必须保持稳定（外部 link 依赖），所以**搬旧、改新**——旧版搬到 `superseded/`，live 文件原地更新

---

## D. Frozen Files（write-once，不读不编辑）

某些文件写完即封印，Claude **不主动读、不 grep、不编辑**。这是 token 优化的核心机制：让大量历史内容存在 vault 里但不消耗 context。

### 哪些文件 frozen

| 路径 pattern | frontmatter | 写入方 | 用途 |
|---|---|---|---|
| `tasks/YYYY/Mmm/*.md` | `frozen: true`, `status: frozen` | `/wrap-work` 从 inbox digest 一次性写 | 一个任务的完整实现历史，封印后只供检索 |
| `superseded/*.md` | `frozen: true`, `status: superseded` | snapshot-supersede.sh 脚本写 | `<project>.md` / `features/*.md` 的历史快照，append-only 归档 |

### 行为规则

- **不主动读** during 日常 query / wrap-work / ingest / lint。省 token
- **不编辑**——写完即封印
- **例外 1**：用户明说"更新 task X" / "fix the frozen task file Y" → 可以编辑，但 Claude 必须先确认
- **例外 2**：用户问"task X 干了啥" / "feature Y 旧版怎么写的" → 单次查询可以读，但不修改
- **Lint 检查**：每季度 lint 验证 `frozen: true` 这个 invariant 在这两个 path 下没破

### 为什么 frozen 是省 token 的关键

vault 体量持续增长——任务越积越多、feature 越改越多。如果每次 wrap-work / lint / query 都要 grep 全部历史，context 会爆。frozen 机制把"历史"和"当前"切开：当前内容（`<project>.md`、`features/<feat>.md`、`knowledge/`、`experience/`）始终活、可读、可改；历史内容（`tasks/`、`superseded/`）一次写完就退出 working set。

---

## 在三个 skills 里怎么用

| Skill | 涉及的 supersede 模式 |
|---|---|
| `/ingest` | §A（decisions 替换）、§B（knowledge 小修）；详见 `.claude/skills/ingest/SKILL.md` Step 0.5 |
| `/wrap-work` | §C（每次更新 features / project overview 都先跑脚本）、§D（写完 task 文件冻结）；详见 `.claude/skills/wrap-work/SKILL.md` Step 4–5 |
| `/lint` | §D 不变量验证（季度 lint）、§A/§C supersede 链完整性（季度 lint）；详见 `.claude/skills/lint/SKILL.md` Step 2 quarterly |

---

## Anti-patterns（不要这样做）

- ❌ 直接 Edit `<project>.md` / `features/<feat>.md` 而不跑脚本——破坏历史
- ❌ 手动 Read 旧 live 文件 → Write snapshot——烧 token，脚本已经做了
- ❌ 删除老 description 段写新版——破坏 append-only
- ❌ Read / Edit `tasks/**` 或 `superseded/**`——除非用户明说
- ❌ 同一个 path 重复覆盖 snapshot（同时间戳冲突要 +1 分钟，不要覆盖）
- ❌ 把改动塞进 changelog 一行 ≤ 5 字（changelog 要让未来读者看懂改了什么 + 简要原因）
