# work-capture plugin — 输出格式

本 plugin 两个 skill 的**自描述**输出格式。任何工具/人都能读懂并直接使用——**不假设**任何下游系统的存在。

## 公共 frontmatter

```yaml
---
source: <work-capture | branch-review>   # 固定标记，标明由哪个 skill 产出（识别用）
title: <一句话标题>        # 必填
date: YYYY-MM-DD          # 必填
tags: [work, <kw1>, <kw2>]
# --- 关联键（有就填，让同一任务的多份产出能互相关联/链接）---
ticket: <TICKET-ID>       # 关联键首选；只引用编号，不复制正文
branch: <branch 名>        # 关联键次选
# --- 其它可选，纯通用元数据 ---
project: <项目名>
topic: <主题短语>          # work-capture 用
base: <对比基准 branch>     # branch-review 用
---
```

> **关联键 `ticket` / `branch` 很关键**:同一个任务可能既跑了 `work-capture`(对话记忆)又跑了 `branch-review`(代码讲解)。填上关联键,下游消费方才能认出"这两份是一对"并互相链接。

## 两种正文结构

### work-capture(`source: work-capture`)—— 对话记忆，5 段
1. `## 概述 Summary`
2. `## 实现逻辑 Implementation Logic`
3. `## 问题与方案 Problems & Solutions`（现象/根因/弯路/最终方案）
4. `## 关键决策 Decisions`
5. `## 回忆钩子 Recall Hooks`

（**不含流程图**——流程图由 branch-review 从代码画。）

### branch-review(`source: branch-review`)—— 代码改动讲解，3 部分
1. `## 改动流程图 Change Flow`（mermaid，针对这次改动，含关键分支）
2. `## 数据流叙述 Data Flow`（选一个经典场景：输入→经过→**改动点(前后对比,重点)**→输出）
3. `## 改动详录 Change Details`（围绕改动的详细记录，按逻辑组织）

## 公共约束

- **禁止**:行号/文件 diff、Commit Timeline、Before-After 代码堆砌、逐行罗列。要"逻辑与数据流",不要"变更记录"。
- **自包含**:图、frontmatter、正文都在**一个文件**里,无外部链接依赖、无 `[[wiki-link]]`——可复制到任何地方直接用。
- **mermaid**:统一 `flowchart TD` 通用语法,任意 markdown 渲染器都能显示。
