---
title: <Feature Name>
id: <project>/features/<feat-slug>
category: feature
status: active
tags: [feature, <project>, <domain>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
logical_kind: feature
source_paths:
  - src/<X>/**
last_surveyed: YYYY-MM-DD
---

<!--
INSTANTIATION NOTE — read before copying this template.
- `<x>` (plain) is a placeholder — substitute when copying.
- `[[<x>]]` is a placeholder INSIDE a wiki-link — substitute the inner text AND keep the [[ ]] brackets, or delete the line entirely.
- An unsubstituted `[[<x>]]` becomes a broken Obsidian link. See [[CLAUDE]] §11.
- Markers `<!-- SURVEYOR-OWNED START/END -->` and `<!-- WRAP-WORK-OWNED START/END -->` are MANDATORY — see [[meta/project-overview-system]] §3.
- Remove this comment block when instantiating.
-->

# <Feature Name>

> Tier-2 单元描述。**SURVEYOR 块**（功能描述、架构、当前实现）由 `/project-decompose` 自动 refresh；**WRAP-WORK 块**（task timeline、changelog、related）由 `/wrap-work` 累积。两者互不踩。详见 [[meta/project-overview-system]]。

<!-- SURVEYOR-OWNED START last-surveyed:YYYY-MM-DD -->

## What 功能描述

_这是什么功能、解决什么问题、给谁用。关键行为说明（输入 / 输出 / 边界条件）。每次 `/project-survey` 时由 surveyor 全量重写——不在这里 append 旧版本带日期，演变史只活在 `superseded/` snapshot 链里。_

## Why 设计意图

_为什么这样设计；做出了什么 tradeoff；alternative 为何被否。_

## Inputs / Outputs

- **Input**: ...
- **Output**: ...

## Implementation Summary 当前实现

_当前怎么实现的；entry signatures / key flow / side effects / integration points。中文 leading bilingual + narrative。_

## Architecture 架构（如适用）

```mermaid
flowchart LR
  A[组件] -->|关系| B[组件]
```

_必要时：sequenceDiagram / stateDiagram。_

## API / Interface（如适用）

- Endpoint / function signature
- Input / output contract

## Configuration 配置（如适用）

- Env vars / config keys / feature flags

## Dependencies 依赖

- [[<dep-slug>]] — _一句话_

## Consumers 消费方

- [[<consumer-slug>]] — _一句话_

<!-- SURVEYOR-OWNED END -->

<!-- WRAP-WORK-OWNED START -->

## Timeline 时间线

_由 `/wrap-work` 累积。按时间倒序（最新在上）。每条 entry 引用对应 task。_

### YYYY-MM-DD — <task title> ([[<task-file-id>]])

- **改了什么**: _1-2 句_
- **为什么**: _1 句_
- Tier-1 详情: [[<task-file>]]

## Related

- Tier-3: [[<project>]]
- 相关 features: [[<feat>]]
- 相关 knowledge: [[<concept>]]
- 相关 decisions: [[<NNNN-slug>]]

## Changelog

- YYYY-MM-DD: snapshot before update → [[superseded-<feat>-YYYY-MM-DD-HHMM]]
- YYYY-MM-DD: initial version

<!-- WRAP-WORK-OWNED END -->
