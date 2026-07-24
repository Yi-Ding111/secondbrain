---
source: work-capture
title: worker 静默丢任务修复 — 503 改指数退避重试
date: 2026-07-12
topic: worker retry 可靠性
tags: [work, worker, retry, reliability]
ticket: ML-1207
branch: feature/ML-1207/worker-retry
project: sapia/agents
---

## 概述 Summary
worker 在下游返回 503 时会把任务永久丢弃，导致每天零星几个任务无声消失。本次改成有上限的指数退避重试 + 死信队列，止住了任务丢失。

## 实现逻辑 Implementation Logic
在 dispatch 层包一层重试策略：对可重试错误（503、连接超时）做指数退避，最多 5 次；超限不再静默丢弃，而是投递死信队列并触发告警。重试计数与退避间隔随任务上下文传递，避免全局状态。

## 问题与方案 Problems & Solutions
### 问题 1 — 任务零星消失
- **现象**：每天有几个任务没有任何日志地"蒸发"。
- **根因**：旧代码把下游 503 当成永久失败直接 drop。
- **走过的弯路**：先怀疑消息队列 ack 丢失，查了半天 broker 日志无果。
- **最终方案**：加下游状态码埋点才定位到 503 分支 → 对 503/超时做有上限指数退避，超限进死信队列。

## 关键决策 Decisions
- **选"指数退避 + 死信队列"而非"无限重试"** — 避免下游长时间挂掉时把自己拖垮；上限 5 次因下游 SLA 恢复通常在 30s 内。

## 回忆钩子 Recall Hooks
- 就是那次"任务零星消失"的排查
- 503 被当永久失败 drop 是根因
- 加状态码埋点才破案
- 下次遇静默丢任务，先加状态码埋点
