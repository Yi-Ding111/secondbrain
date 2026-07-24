---
source: branch-review
title: worker 503 retry — 代码改动讲解
date: 2026-07-12
branch: feature/ML-1207/worker-retry
base: develop
ticket: ML-1207
project: sapia/agents
tags: [work, worker, retry, dispatch]
---

## 改动流程图 Change Flow
```mermaid
flowchart TD
  A[dispatch(task)] --> B[call_downstream]
  B -->|200| C[ack + 完成]
  B -->|503 / 超时| D{新增: attempt < max?}
  D -->|是| E[新增: 指数退避 sleep] --> B
  D -->|否| F[新增: 投递死信队列 + 告警]
  B -.旧行为(已删).-> X[直接 drop, 无日志]
```

## 数据流叙述 Data Flow
以"一个下游临时 503 的任务"为经典场景走一遍:

- **输入**:一个 `Task{ id, payload, attempt=0 }` 从队列进入 `dispatch()`。
- → `dispatch()` 调 `call_downstream(task)`,拿到下游响应。
- → **改动点(重点)**:响应分类逻辑。
  - **改动前**:`if status == 503: drop(task)` —— 直接丢弃,无重试、无记录,任务就此蒸发。
  - **改动后**:`if retryable(status): if task.attempt < MAX: schedule_retry(task, backoff(task.attempt)); else: dead_letter(task)`。`retryable` 覆盖 503 + 连接超时;`backoff` 按 `attempt` 指数增长;`attempt` 随 task 上下文传递(非全局)。
- → 重试的 task 带 `attempt+1` 回到 `dispatch()` 再走一遍(形成上图的回环),直到成功或超限。
- → **输出**:成功则正常 ack 完成;超限则落 `dead_letter` 队列并发告警 —— 无论如何**不再无声丢弃**。

## 改动详录 Change Details
- **`dispatch` 响应分类**:从"二元(成功/drop)"改成"三态(成功 / 可重试→退避 / 不可重试或超限→死信)"。核心逻辑单元。
- **新增 `backoff(attempt)`**:指数退避间隔计算;上限 `MAX=5`。
- **新增 `dead_letter(task)`**:投递死信队列 + 触发告警,替代原来的静默 drop。
- **`attempt` 计数**:随 task 上下文传递,避免全局状态在并发下串号。
- **决策/取舍**:有上限而非无限重试(防拖垮自身);`MAX=5` 依据下游 SLA 恢复通常 <30s。
