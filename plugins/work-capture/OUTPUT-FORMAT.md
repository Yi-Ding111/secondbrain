# work-capture 输出格式

work-capture 产出的**自描述格式**。任何工具/人都能读懂并直接使用——本格式**不假设**任何下游系统的存在(vault、知识库、路由规则都与本工具无关)。

## Frontmatter

```yaml
---
source: work-capture      # 固定标记，标明这份文案由 work-capture 产出（唯一必需的识别字段）
title: <一句话任务标题>    # 必填
date: YYYY-MM-DD          # 必填
topic: <主题短语>         # 必填
tags: [work, <kw1>, <kw2>]
# --- 以下可选，纯通用元数据（有就填，没有就省；不含任何下游/vault 概念）---
project: <项目名>          # 可选：这次工作属于哪个项目/仓库
ticket: <TICKET-ID>       # 可选：只引用编号，不复制 ticket 正文
---
```

> `source: work-capture` 是消费方识别这份文案的唯一依据。**"这份文案该怎么用、往哪放"完全由消费方决定，与本工具无关。**

## 正文结构（6 段记忆)

1. `## 概述 Summary` — 目标 / 为什么 / 解决了什么
2. `## 流程图 Flow` — mermaid，含问题分支/解决路径（**必产**）
3. `## 实现逻辑 Implementation Logic`
4. `## 问题与方案 Problems & Solutions` — 现象 / 根因 / 弯路 / 最终方案
5. `## 关键决策 Decisions`
6. `## 回忆钩子 Recall Hooks`

**禁止**：行号/文件 diff、Commit Timeline、Before-After 代码堆砌。

## 自包含要求

一份产出必须**单独打开就完整可读**：图、frontmatter、正文都在一个文件里，无外部链接依赖、无 `[[wiki-link]]`。这样它可以被复制到任何地方直接用。
