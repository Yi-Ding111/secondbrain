---
name: branch-review
description: 纯基于代码(git diff)讲解「当前 branch 相对某个 base branch 做了什么改动」。产出一张针对这次改动的详细流程图 + 一段数据流叙述(输入→经过→改动点→输出) + 改动详录。不读任何 AI 对话，只读代码仓。产出打 source:branch-review 标记，可复制带走或入库。
triggers: ["branch-review", "review branch", "讲讲这个分支", "这个 branch 改了什么", "解释改动", "diff review"]
---

# Branch Review

**纯基于代码**讲解「**当前 branch 相对一个 base branch 做了什么改动**」,产出一份帮我看懂这次任务、也能带走/入库的文案。

**只读代码仓(git),不读任何 AI 对话**——和 work-capture(读对话)互补:work-capture 抓"当时怎么想的",branch-review 抓"代码实际改成了什么"。跑在有代码仓的机器上。

## When to use
- 一个 branch 做完(或做到一半),想**看懂/记录这次改动的逻辑**。
- 用户说 `branch-review` / "讲讲这个分支改了什么" / "解释一下这个改动"。

## 输入
- **base**(必需):对比基准 branch,如 `develop` / `main`。用户在触发时给(如 `branch-review develop`),没给就问一句。
- 对比范围:`git diff <base>...HEAD`(三点,从两个 branch 的**分叉点**起算,只看本 branch 新增的改动;而非 base 后续的推进)。

## Workflow

### Step 1 — 摸清改动
```bash
git merge-base <base> HEAD           # 分叉点
git diff --stat <base>...HEAD        # 改了哪些文件、规模
git diff <base>...HEAD               # 完整 diff
```
读 diff + **打开改动涉及的关键文件**(前后文,不只看 diff 行),搞清楚:这次改动在系统里落在哪、改了什么行为、上下游是什么。**目标是理解逻辑,不是罗列行号。**

### Step 2 — 产出三部分

**① 改动流程图**
针对**这次改动**画一张详细 `mermaid flowchart TD`——不是整个系统,是这个 change 的范围。让人一眼看懂"这个任务做了什么"。含关键分支/条件。

**② 数据流叙述(重点)**
选**一个最经典/代表性的场景**,顺着讲一条端到端的数据流:
- 数据**从哪流入**、长什么样(结构/示例)
- → 经过哪一步、哪一步
- → **到我改动的那部分**——这里**重点详述**:改动前是怎样、改动后是怎样、为什么这么改
- → 再流到哪
- → **最终输出**什么、长什么样

要有逻辑、能顺着一路读懂"输入怎么一步步变成输出、我的改动卡在哪个环节起什么作用"。

**③ 改动详录**
完全围绕这次改动的详细记录:改了哪些逻辑单元、每处的意图与作用、关键决策/取舍、注意点。**按逻辑组织,不是逐行 diff、不是文件清单。**

### Step 3 — 组装 + 交付
按 [[OUTPUT-FORMAT]](同 plugin 内 `../../OUTPUT-FORMAT.md`,branch-review 分支)组装成**一个自包含 markdown**:
- frontmatter:`source: branch-review` + `title` / `date` / `branch`(当前分支)/ `base`(对比基准)+ **关联键 `ticket`**(有就填,让下游能和同任务的 work-capture 文案互相链接)+ 可选 `project` / `tags`。
- 正文:三部分(改动流程图 / 数据流叙述 / 改动详录)。
以**代码块**呈现,方便一键复制。到此为止——文案交出去。

## 验收
给定 base branch,产出一份**纯 code-based、图文完整、可顺读懂的改动讲解**;数据流那段能"选个经典场景,输入→…→改动点(前后对比)→…→输出"一路读通。

## Anti-patterns
- ❌ 逐行罗列 diff / 文件清单 —— 要的是"这次改动的逻辑和数据流",不是变更记录
- ❌ 引用 AI 对话内容 —— 本 skill 只看代码,不看对话(那是 work-capture 的事)
- ❌ 画整个系统的大图 —— 只画**这次改动**范围的详图
- ❌ 只画 happy path —— 关键分支/条件要体现
