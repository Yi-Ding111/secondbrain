# work-capture — 独立捕获工具

把一段 AI 对话整理成一份**可复制、自包含**的结构化记忆文案。**只做这一件事**——独立、无依赖,不假设任何下游系统。

## 它是什么(和不是什么)

- ✅ 是:"AI 对话 → 好文案"的打包器。产出图文完整、单独打开即可读、可直接粘去任何地方。
- ❌ 不是:归档工具。它**不知道也不关心**这份文案最后往哪放——那是你(或某个消费方)的事。

## 内容(刻意最小)

```
work-capture/
├── .claude-plugin/plugin.json
├── OUTPUT-FORMAT.md               # 输出格式(自描述,与下游无关)
├── skills/work-capture/SKILL.md   # 唯一 skill(记忆规则内嵌,自包含)
└── examples/example-capture.md    # 一份样例产出
```

**不含**任何知识库/vault 机制。记忆格式规则(6 段 + mermaid 约定 + 禁 diff)内嵌在 SKILL.md 里——装它就能独立工作,不需要别的 plugin、不需要 vault。

## 安装

```
/plugin marketplace add <yis-brain marketplace 仓库/路径>
/plugin install work-capture@yis-brain
```

无需 vault、无需 bootstrap、无需任何其它 plugin。装好后在任意 AI 会话里触发。

## 用法

1. 一段对话结束 → 说 `work-capture` / "整理这次对话" → 得到一份 markdown(代码块,便于复制)。
2. 复制走 —— 想怎么用就怎么用(存进笔记库 / 贴进文档 / 发给别人 / 归档)。

产出严守记忆格式:**流程图 + 逻辑 + 问题/方案 + 决策 + 回忆钩子,绝不含行号 diff**。

## 与其它系统对接(可选)

产出的 frontmatter 打了 `source: work-capture` 标记。任何消费方(比如一个知识库的导入流程)可以据此识别并**自行**决定怎么处理这份文案——**这些逻辑全在消费方,不在本工具**。
