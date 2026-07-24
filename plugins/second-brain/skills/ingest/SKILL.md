---
name: ingest
description: Ingest 新内容到当前 vault。按 CLAUDE.md schema 分类、写入正确 zone、grep 发现相关页、建双向 [[links]]、更新 MOC、记 log。无参调用时自动扫 inbox/ 里的 brain-digest 文件。
triggers: ["ingest", "ingest this", "整理一下", "记入", "记录一下", "add to brain", "归入 brain"]
---

# Ingest

把原始输入（idea / 文章 / 决定 / 事件）处理进当前 vault（即本 `CLAUDE.md` 所在目录），严格遵循 [[CLAUDE]] 的规则。

## When to use
- 用户分享一段材料、一个想法、一次会议结果
- 用户说 "整理一下" / "记入 brain" / "ingest this" / "归入"
- 长段原始输入需要蒸馏成结构化页面
- **无参调用**：用户直接 `/ingest` 不带材料 → 走 Step 0，从 `inbox/` 捡 `brain-digest` 产出的文件

**不适用**：工作完成的收尾（用 `/wrap-work`）、健康检查（用 `/lint`）。

## Before starting

如果上下文还没有，先 Read 这几节：
- [[CLAUDE]] §2 Directory Map
- [[CLAUDE]] §3 Frontmatter Schema
- [[CLAUDE]] §4 Naming Conventions
- [[CLAUDE]] §7 ADR / Superseded Pattern（Step 0.5 用）
- [[CLAUDE]] §8 Ephemeral vs Durable
- [[CLAUDE]] §10 Language convention

## Workflow

### Step 0b — work-capture / branch-review 落位（跨机接收端）

当 inbox 里出现 work-capture plugin 的产出文件——`source: work-capture`（对话记忆，5 段：概述/实现逻辑/问题与方案/关键决策/回忆钩子）或 `source: branch-review`（代码改动讲解，3 部分：改动流程图/数据流叙述/改动详录）。这些工具**不懂 vault 结构**，路由完全由本步骤决定：

1. Read 该文件，取 frontmatter：`title` / `date`、**关联键 `ticket` / `branch`**，以及可能有的 `project`。
2. **本 skill 自行推断落点**（工具不提供 zone/tier 提示）：
   - **项目**：有 `project` 字段就用；没有则从正文内容(提到的服务/仓库/工单)推断映射到某个 `work/<co>/projects/<proj>`；实在判不出 → 留 inbox 并问用户目标项目。
   - **tier**：默认落 **Tier-1 task**（`work/<co>/projects/<proj>/tasks/YYYY/Mmm/YYYY-MM-DD-<slug>[-TICKET].md`，**frozen**）。若读正文判断这其实是某 feature 的行为变更 → 另按 **snapshot-supersede** 更新对应 Tier-2 `features/<feat>.md`（走脚本，CLAUDE §7）。
   - 写前必读 `<project>/CLAUDE.md` + `wiki.md`（project-write rule 会提醒）。
3. **重构**：直接采用文案的各段作为 task 正文——work-capture 的 5 段 / branch-review 的 3 部分（**保留 mermaid 图、保留逻辑/问题/方案/决策，绝不降级成改动清单**）。补 vault 专属 frontmatter（`category: task` / `frozen: true` / 🧊 banner / `source` 保留溯源 / `project` / `ticket` / `branch` / 本 skill 判定的 `features_touched`）。
4. **关联链接（存两份、不融合）**：同一个任务常有**两份** capture——`work-capture`（对话记忆）+ `branch-review`（代码讲解），靠 **`ticket` / `branch` 关联键**识别。发现 inbox 里或 vault 里已有**同 ticket/branch 的另一份** → **各存一份**、在两者的 Related 段**互相补 `[[link]]`**（对话记忆 ↔ 代码讲解），**不合并成一份**。
5. 把其余纯文本占位**补成 `[[link]]`**：Tier-2 feature、Tier-3 overview、相关 knowledge/decisions。
6. 更新 `<project>/wiki.md` + `log.md` + zone wiki/log + 根 `log.md`（走 anchor，不读 body）。
7. 消费完 → 删除 inbox 里的文件（它是 bridge，非 raw 素材）。

> 关键：所有"往哪放、属哪个 tier、动哪个 feature、跟哪份互链"的 **vault 路由知识都在本 skill 这一侧**——工具只交出自包含好文案,不掺和落位。同任务的多份 capture **存两份 + 互链**（Yi 定，不融合）；文案**已是记忆结构**,本步做**推断落点 + 落位 + 互链 + 补链接**,不需再 fuse/蒸馏。

### Step 0 — Inbox pickup（无参调用时）

如果用户直接 `/ingest` 不带材料，或者上下文里没有可 ingest 的内容：

1. Glob `inbox/*.md`
2. 过滤：frontmatter 有 `source: brain-digest` 或 `tags: [pending-ingest]` 的视为 **digest 文件**；有 **`source: work-capture`** 或 **`source: branch-review`** 的视为 **work-capture plugin 产出** → 走下方 Step 0b 专门分支（不当普通 digest 处理）
3. 列出所有 digest 文件（按 created 时间升序），给用户看 title + 文件名
4. 询问：
   - "全部按顺序处理？"（默认）
   - "只处理某几个？"
   - "全部跳过？"（用户只是想看看 inbox）
5. 对每个选中的 digest 文件：
   - Read 整个文件——5 块结构已经备好
   - 把它**当作 Step 1 的输入**：category 从 `## Suggested zone` 段取候选，关键词从 `## Keywords` 段取
   - 跑完整流程 **Step 0.5 → Step 1-8**（digest 也可能是更新已有页，必须先经 0.5 判定）
   - **Step 9 之后** Delete 这个 inbox 文件（它是 bridge，分类完就消失——和普通 raw 保留不同，因为本质是 session summary 而非外部原件）
6. 如果 `inbox/` 没有 digest 文件但有其他 `.md`（手动放进来的）→ 告知用户这些是"需要你提供上下文"的，不自动处理

**注意**：digest 文件已有 5 块结构，意味着 Step 2（Raw 保存）**跳过**——session summary 不需要 raw 副本。

### Step 0.5 — Update-or-new 判定

**在分类之前**先判断：这段输入是更新已有页面，还是独立的新内容？这是避免静默覆盖的护栏（[[CLAUDE]] §7）。

1. 从输入提 3-5 个关键概念（同 Step 5 的提取方式）
2. Grep 跨 zone 找候选：
   ```
   grep -lri "<concept>" knowledge/ experience/ work/ projects/ wiki/
   ```
3. 排名：title 命中 > frontmatter tag 命中 > body 高密度命中
4. **如果 top 1 显著命中**（title 命中，或 body 多次命中同一主题），向用户确认：
   > "看起来这是更新 [[<candidate>]] 的内容。是更新已有页，还是独立新页？"
   - 用户说独立新页 → 跳到 Step 1，正常流程
   - 用户说更新 → 继续判范围（5）

5. **判更新范围**（参考 [[CLAUDE]] §7 决策表）：

   | 信号 | 走法 |
   |---|---|
   | 参数微调 / 补一个段落 / 修 typo / 加新例子 | (a) Changelog |
   | 修一个先前理解错的描述 | (a) Changelog（标 "Corrected:"）|
   | 架构变了 / 决策推翻 / 关键概念重新定义 | (b) Supersede |
   | 老结论在新场景不再成立但旧场景还成立 | (b) Supersede（两份并存）|

   拿不准 → **默认 (b) supersede**。多一份历史不亏，silent overwrite 才是真损失。

   #### (a) Changelog 路径（小修补）
   - Edit 老页对应位置改内容
   - 底部 `## Changelog` 段 append 一行：`- YYYY-MM-DD: <一句话改了什么 + 简要原因>`
     - 如果老页没有 Changelog 段，先建一个
   - 老页 frontmatter `updated:` 改成今天
   - **跳过 Step 1-7，直接到 Step 8（log）**
   - log 条目用 `[ingest:changelog]` 前缀，引用被改的 `[[<page>]]`

   #### (b) Supersede 路径（实质性变化）
   - 新建页：filename 体现新版含义（如 `<old-slug>-v2.md`，或更具体的命名）
   - 新页 frontmatter `supersedes: [<old-id>]`
   - Edit 老页：
     - frontmatter 改 `status: superseded`，加 `superseded_by: <new-id>`
     - 顶部加 banner：`> ⚠️ **Superseded by [[<new-page>]]** on YYYY-MM-DD. Kept for history.`
   - 然后跑 Step 3-9（用新页跑）
   - **Step 5 找相关页时**：grep 谁在引用老页 (`[[<old-id>]]`) → 列给用户判断哪些链接换到新页、哪些保留指向历史版本（一般：当前 active 页换链接；引用历史决策的页保留原链）
   - log 条目用 `[ingest:supersede]` 前缀，写 `[[<old]] → [[<new>]]`

6. 如果没显著命中或用户确认是新内容 → Step 1

### Step 1 — Classify 分类
问（或从上下文推断）两件事：

1. **内容类型**：
   - `knowledge` — 稳定的事实/概念
   - `decision` — ADR（考虑过选项，做了选择）
   - `lesson` — 从经验提炼的教训
   - `literature` — 对某份外部来源的密集笔记
   - `log` — 时间轴日志条目
   - `draft` — 还没成型的 thinking

2. **目标 zone**：
   - `knowledge/<domain>/`（单领域事实）
   - `work/<co>/projects/<proj>/{decisions,learnings,references}/`
   - `projects/<name>/{decisions,learnings}/`
   - `experience/{lessons,decisions,playbooks}/`
   - `learning/literature/`
   - `thinking/drafts/`（还没定型）
   - `wiki/`（**仅限** 跨 2+ 支柱的合成页）
   - `inbox/`（真的不知道放哪）

不确定时：提 2 个最合理选项，让用户选。

### Step 2 — Raw 保存（如果是外部来源）
如果输入来自外部（URL / 长段粘贴 / 书摘）：
- 先把原文存到 `raw/<type>/YYYY-MM-DD-<slug>.md`（type = articles / books / videos / clips）
- 原文**不改写、不编辑**
- distilled 页面的 frontmatter `source:` 指向这份 raw 文件

### Step 3 — Name & Template
- Filename: `kebab-case.md`
  - Decisions: `NNNN-slug.md`（在目标 `decisions/` 里 `ls` 找最大号 +1，零填充到 4 位）
  - Dated: `YYYY-MM-DD-slug.md`（日志类）
  - Regular: `<slug>.md`
- 从 `${CLAUDE_PLUGIN_ROOT}/templates/` 取对应模板：`decision.md` / `knowledge.md` / `lesson.md` / `literature.md` / `retro.md` / `log-weekly.md`
- 预填 frontmatter：`title`, `id`, `category`, `status: active`, `tags`, `created`, `updated`（按 CLAUDE.md §3）

### Step 4 — Write content
- **语言**：中文散文 + 英文技术术语（[[CLAUDE]] §10）
- **用自己的话**：不允许从 raw 直接复制粘贴（Ahrens 铁律）
- **一页一 idea**：Zettelkasten 原则。超过 ~300 行考虑拆分
- 模板里的每个 section 都要填（填不了就保留占位但标记 `_待补充_`）

### Step 5 — Discover related 找相关页
这是 Obsidian graph 变得有意义的关键。

1. 从新内容提取 **3-5 个关键概念**（名词、专有名词、技术栈、项目名）
2. 对每个概念跨 zone grep：
   ```
   grep -lri "<concept>" knowledge/ experience/ work/ projects/ wiki/ learning/
   ```
   跳过 `raw/` 和 `archives/`
3. 排名候选：**title 命中 > frontmatter tag 命中 > body 命中**
4. 展示 top 5 给用户，请选择要 link 的（默认全选，用户可减）

这模拟了 Obsidian 的 **Unlinked mentions** 机制——找到有关联但还没 `[[link]]` 的页。

### Step 6 — Build bidirectional links 建双向链接
Obsidian 的 Backlinks panel 会自动显示反向链接，但**前提是有正向 `[[link]]`**。所以要双向：

1. **新页**：添加 `## Related` 段，列出每个选中的 `[[page-id]]`
2. **每个相关页**：在它的 `## Related` 段（如无则新建）加一行 `[[<new-page-id>]]`，附一句话说明关系

这样两边都是 **Linked Mention**，graph 节点之间出现实线。

### Step 7 — Update MOC + zone wiki + log（[[CLAUDE]] §2.2）

#### 7a. MOC（concept-level entry）
找到**最近的父文件夹 MOC**（`<folder>.md`，比如 `knowledge/AI/AI.md` / `work/sapia/sapia.md`）：
- 在最合适的 section 下加一条 `- [[<new-page>]] — 一句话描述`
- 如果现有 section 都不合适，先建议新增一个 section，让用户确认
- 如果新页跨多个 zone 的 MOC（罕见）→ 考虑它是否属于 `wiki/`

更新该 MOC 的 frontmatter `updated:` 为今天。

#### 7b. Zone wiki.md（directory index）
**leaf folder 必动；ancestors 仅在结构变化时动**。规则见 [[CLAUDE]] §2.2。

- **Leaf folder `<folder>/wiki.md`**：在 Pages 表里加一行：
  ```markdown
  | `<filename>.md` | _一句话描述_ | k1, k2, k3 | _什么情境下应该 cite 这页_ |
  ```
  bump frontmatter `updated:`
- **Ancestor folders 的 `wiki.md`**：仅在新建 sub-folder / 重大结构变化时才动（添加新 row 到 Subdirectories 表）。纯加新原子页不动 ancestor wiki
- **Wiki 不存在** → 用 `${CLAUDE_PLUGIN_ROOT}/templates/zone-wiki.md` 模板创建（leaf 第一次有内容时触发）

#### 7c. Zone log.md（durable change log）

- **Leaf folder `<folder>/log.md`**：append 一条：
  ```markdown
  ## YYYY-MM-DD — <一句话总结>
  - Added: [[<new-page-id>]]
  - 来源：<例如 ML-1196 wrap-work / 直接 ingest>
  ```
- **Ancestor logs**：仅在结构变化（新建 sub-folder、移动、合并）时 append；纯加原子页**不**动 ancestor log
- **Log 不存在** → 用 `${CLAUDE_PLUGIN_ROOT}/templates/zone-log.md` 模板创建（leaf 第一次有内容时触发）

#### 7d. 不要漏的层

- 如果新页位于 `knowledge/clouds/aws/bedrock/`，那么写 leaf 的 wiki + log = `knowledge/clouds/aws/bedrock/{wiki,log}.md`
- 如果同时新建了 sub-folder（例如本次顺手建了 `knowledge/clouds/aws/`），需要也建该层的 wiki + log + 在 ancestor `knowledge/clouds/wiki.md` 加 Subdirectories 行
- 项目内部 task / feature 走的是 §2.1 的 project wiki + log（不是 §2.2）—— 由 `/wrap-work` 维护，不在这里

### Step 8 — Log
append 到根目录 `log.md`：
```markdown
## YYYY-MM-DD [ingest] — <new-page-title>
- 写入 `<zone>/<new-page>.md`（category: <cat>）
- Raw 保留：`raw/...`（如有）
- 关联：[[page-a]], [[page-b]], [[page-c]]
- 更新 MOC：[[<folder>]]
```

### Step 9 — Light lint（收尾）
对**这次操作涉及的文件**做快速检查：
- 新页 frontmatter 字段完整？
- 所有新加的 `[[links]]` 都 resolve 到存在的文件？
- MOC 里有没有忘了加？

报告任何问题。

## Rules

- **永远先跑 Step 0.5**：判更新还是新增。冲突时按 [[CLAUDE]] §7 supersede，**绝不静默覆盖**
- **拿不准就 supersede**：silent overwrite 是真损失，多一份历史不亏
- **外部素材必先 raw**：这是 Karpathy 三层的铁律
- **多文件操作先 show plan**：列出将写的文件、要建的 link、要更新的 MOC，等用户确认
- **分不清就 inbox**：宁可放 `inbox/` 稍后分类，也不要瞎归类
- **thinking/drafts/ 是合法终点**：半成品就该待在那里，别硬升级到 knowledge
- **Prose 风格 (CRITICAL — [[CLAUDE]] §10 "Prose density and readability")**: 写 knowledge / lesson / ADR / reference 页时**必须用 narrative**：每个声明都要解释 *什么* / *为什么* / *给读者带来什么*，不许把多个名词短语堆起来当 "证明"。在 invariant / property 后面跟一段 worked example。长度不是问题，**clarity is the only thing that matters**。

## Tools used
- Read（查 CLAUDE.md、模板、相关页）
- Glob（`decisions/` 目录下已有 NNNN 编号）
- Grep（Step 0.5 探更新、Step 5 找相关页、supersede 时找反向引用）
- Write / Edit（新页、MOC 更新、双向 link、Changelog append、supersede banner）

## Output format

完成后报告（中文），包含：
- **新建文件**：路径 + 一句话说这页讲什么
- **Raw 保留**：如果适用，`raw/...` 路径
- **双向链接**：`新页 ↔ [[A]], [[B]], [[C]]`
- **MOC 更新**：哪个 `<folder>.md` 的哪个 section
- **Log 条目**：引用刚加入 `log.md` 的那段
- **Lint warnings**：如有
