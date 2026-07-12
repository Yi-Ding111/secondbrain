---
name: lint
description: 对当前 vault 做健康检查——orphan pages、broken links、stale active 页、superseded 链完整性、MOC 覆盖率。本 SKILL.md 即 lint checklist 的 source of truth。
triggers: ["lint", "lint vault", "lint my brain", "体检", "brain health", "vault health", "健康检查"]
---

# Lint

对当前 vault（即本 `CLAUDE.md` 所在目录）做结构性健康检查。本文件就是 lint checklist 的 source of truth——root `CLAUDE.md` 不再重复列出（它只指向这里）。

**lint 只检测，不自动改**——把问题列出来，等用户确认再修。

## When to use
- 用户说 `/lint` / "体检" / "check my brain"
- 每周五做 weekly review
- 月末 / 季末 做更深范围
- 感觉图谱乱、链接断、或内容堆积时

## Scope

四档，默认 **weekly**：

| Scope | 覆盖 |
|---|---|
| **weekly** | inbox 超期、log 升级候选、新页 MOC 覆盖、broken links |
| **monthly** | + log 压缩检测、stale active 页、drafts 老化 |
| **quarterly** | + superseded 链完整性、archive 候选 |
| **full** | 全部 + orphan 检测 + 过大页面 + 矛盾检测 |

## Workflow

### Step 1 — Scope 决定
问用户或从上下文推断。默认 weekly。

### Step 2 — 按 scope 跑检查

#### Weekly checks
- **inbox 超期**
  - 找 `inbox/*.md` 中 `created` 早于 7 天前的
  - 用 Glob + Read 取 frontmatter 日期
  - 列出，建议 `/ingest` 分类或丢弃

- **Log 升级候选**
  - grep `*/log/YYYY-Www.md` 里本周的 `## 🎯 Promote candidates` 段
  - 列出未 check 的项，建议升级到 `decisions/` 或 `learnings/` 或 `knowledge/`

- **新页缺 MOC entry**
  - Glob 最近 7 天 `created` 的页
  - 检查它们有没有被最近的 `<folder>.md` 引用
  - 用 Grep 在 MOC 里找 `[[<new-page>]]` 或 `- <new-page>`

- **Broken `[[wiki-links]]`**
  - Grep `\[\[[^\]|]+(\|[^\]]*)?\]\]` 全 vault
  - 对每个 target，检查对应 `.md` 文件是否存在（考虑 Obsidian 的 shortest unique path 规则）
  - 列出断链 + 所在文件 + 行号

- **Zone `wiki.md` / `log.md` 缺失**（[[CLAUDE]] §2.2）
  - 找 distilled folders（`knowledge/`、`experience/`、`learning/`、`wiki/`、`projects/`、`work/<co>/`）下含 `.md` 内容（直接或递归）但缺 `wiki.md` 或 `log.md` 的
  - 列出，建议从 `${CLAUDE_PLUGIN_ROOT}/templates/zone-{wiki,log}.md` 模板补建

- **Zone wiki orphan**（[[CLAUDE]] §2.2）
  - 对每个 leaf folder（含 atomic 内容页），diff 实际文件 vs `wiki.md` Pages 表
  - 缺：原子页存在但 wiki 没列 → 列出，建议 `/ingest` 补
  - 多：wiki 列了但文件不存在 → 列出，建议从 wiki 删

#### Monthly checks（额外加）
- **Stale active 页**
  - 找 frontmatter 有 `status: active` 且 `updated` 早于 180 天的
  - 列出，建议 review（不自动改 status）

- **Drafts 老化**
  - `thinking/drafts/*.md` 超过 60 天的 → 建议 promote / archive / delete

- **Log 未压缩**
  - 检查上月 `work/<co>/projects/<proj>/log/*.md` 和 `work/<co>/log/*.md`
  - 看对应 MOC 的 Timeline section 有没有这个月的条目

#### Quarterly checks（额外加）
- **Superseded 链完整性**
  - grep 所有 `supersedes:` 非空的页 → 它们指向的页必须 `superseded_by:` 回来
  - grep 所有 `superseded_by:` 非空的页 → 反向同理
  - 列出不对称的情况

- **Archive 候选**
  - `work/<co>/projects/<proj>/` 里 `_moc 文件`（其实是 `<proj>.md`）的 `status` 是否应该改
  - `archives/**/*.md` 里仍标 `status: active` 的 → 批量标 archived

#### Full checks（额外加）
- **Orphan pages**
  - 每个非 MOC 的 `*.md` 必须至少被一个 MOC 或其他页引用
  - 用 Grep 反向检测：对每个 page-id，搜 `[[<page-id>]]` 出现次数
  - 零引用 = orphan

- **过大页面**
  - `wc -l` 所有 md → 超过 500 行的标记

- **矛盾检测**（启发式，不完美）
  - 对每个 MOC 的主题，读其下引用的页，让 LLM 扫一眼有无明显冲突
  - 这一项**只作为提示**，不强制

### Step 3 — 报告
生成一份 markdown 报告，结构：

```markdown
# Lint report <YYYY-MM-DD> (<scope>)

## Summary
- Orphans: N
- Broken links: N
- Stale active: N
- Missing MOC entries: N
- ...

## Details

### Inbox 超期 (N items)
- [[inbox/2026-04-15-foo]] (created 9 days ago) → propose classify
- ...

### Broken links (N)
- `knowledge/AI/rag.md:42` → `[[nonexistent-page]]`
- ...

...
```

### Step 4 — 询问修复
**不自动修**。逐类别或逐项问用户："要修哪些？"

对选中的每一条：
- broken link → 问用户正确的 target 或改为纯文本
- orphan → 问挂到哪个 MOC 或标 archived
- inbox 超期 → 触发 `/ingest` 的分类流程
- superseded 链残缺 → 补全字段

### Step 5 — Log
append 到根目录 `log.md`：
```markdown
## YYYY-MM-DD [lint:<scope>] — <摘要>
- Orphans: N (修复 Y)
- Broken links: N (修复 Y)
- Stale active: N (flag 但不改)
- MOC 缺 entry: N (补 Y)
```

## Rules
- **永不删除**：至多建议移到 `archives/`
- **stale 只提示不改**：`updated` 字段只应该在内容真的变了时改
- **broken link 先修引用**：重命名链接通常比建 stub 页好
- **>20 项按类型聚合**：一类一类问用户
- 大范围 scope 跑完后，建议接一次 weekly 的清理，锁住改进

## Tools used
- Glob（枚举文件，取 created/updated）
- Grep（broken links、orphan 检测、supersede 链）
- Read（读 frontmatter 判断 status）
- Edit（用户确认后的修复）

## Output format
- 开头一行 summary：`Lint (weekly): 3 stale inbox, 1 broken link, 0 orphans, MOC 覆盖率 94%`
- 然后分类详情，每条带 `[[link]]`
- 结尾："要我处理哪些？" 的询问
