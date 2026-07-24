# work-capture — 工作机捕获工具集

把工作时的产出整理成**可复制、自包含**的结构化记忆文案。**独立、无依赖**,不假设任何下游系统。含**两个 skill**,按来源分工:

| skill | 读什么 | 产出 |
|---|---|---|
| **`work-capture`** | 当前 **AI 对话** | 对话记忆(5 段):概述 / 实现逻辑 / 问题与方案 / 关键决策 / 回忆钩子 |
| **`branch-review`** | **代码仓(git diff)** | 代码改动讲解(3 部分):改动流程图 / 数据流叙述 / 改动详录 |

两者互补:work-capture 抓"当时怎么想的",branch-review 抓"代码实际改成了什么"。同一任务两者都跑时,靠 frontmatter 的 **`ticket` / `branch` 关联键**让下游把两份文案关联起来。

## 内容(刻意最小)

```
work-capture/
├── .claude-plugin/plugin.json
├── OUTPUT-FORMAT.md               # 两个 skill 的输出格式(自描述,与下游无关)
├── skills/
│   ├── work-capture/SKILL.md      # 读对话 → 记忆
│   └── branch-review/SKILL.md     # 读代码 → 改动讲解
└── examples/
    ├── example-capture.md
    └── example-branch-review.md
```

**不含**任何知识库/vault 机制。每个 skill 的规则内嵌在自己的 SKILL.md 里——装它就能独立工作,不需要别的 plugin、不需要 vault。

## 安装

```
/plugin marketplace add <yis-brain marketplace 仓库/路径>
/plugin install work-capture@yis-brain
```

无需 vault、无需 bootstrap、无需任何其它 plugin。

## 用法

- **对话结束** → 说 `work-capture` → 得到一份对话记忆(markdown 代码块)。
- **一个 branch 做完** → 说 `branch-review develop`(给 base branch)→ 得到一份代码改动讲解。
- 复制走 —— 想怎么用就怎么用(存进笔记库 / 贴进文档 / 归档)。

产出严守"记忆而非机械 diff":逻辑、数据流、问题/方案、决策——**绝不含行号 diff**。

## 与其它系统对接(可选)

产出 frontmatter 打了 `source: work-capture` 或 `source: branch-review` 标记 + `ticket`/`branch` 关联键。任何消费方(如某知识库的导入流程)可据此识别、**并把同一任务的两份产出关联起来**——这些逻辑全在消费方,不在本工具。
