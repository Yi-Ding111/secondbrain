---
title: Obsidian-Specific Conventions
id: meta/obsidian-conventions
category: reference
status: active
tags: [meta, obsidian, vault-schema]
created: 2026-05-03
updated: 2026-05-03
---

# Obsidian-Specific Conventions

vault 在 Obsidian 里如何表现 / 怎么配 / template 占位符规则。Root `CLAUDE.md` §11 已被本文取代。

---

## A. MOC（Map of Content）pattern

MOC 文件命名为 `<folder>.md`（与父文件夹同名）。这是 Obsidian "folder notes" plugin 的约定——点 folder 即打开该 MOC，把 navigation 体验串起来。

- 手工 curated，不自动生成
- 列出该 folder 下的关键页面 + 一句话描述
- 跟 `<folder>/wiki.md` **不同**：MOC 给人读理解用（"这个 domain 是关于什么"），wiki.md 给 AI 决定 write-routing 用（"哪个文件存什么 keyword bag"）

参考 [[CLAUDE]] §2.2 wiki vs MOC 对比表。

---

## B. Daily / Weekly Notes

Obsidian 的 Daily Notes plugin 兼容。建议路径：

- 工作日志：`work/<company>/log/YYYY-Www.md`
- 项目日志：`work/<co>/projects/<proj>/log/YYYY-Www.md`

按需配置 plugin → Settings → Daily Notes → 模板用 `meta/templates/log-weekly.md`。

---

## C. Tags

**优先 frontmatter `tags: [...]` 字段，不用 inline `#tags`**。

理由：
- frontmatter tags 在 Obsidian search / dataview 里 first-class
- inline `#tags` 容易混进 prose（误命中、多余 tag）
- frontmatter tags 在 grep / lint 里好处理

格式：

```yaml
tags: [ai, postgres, race-condition]
```

全部小写英文 kebab，单词性。

---

## D. Templates

模板放在 `meta/templates/`。配置 Obsidian → Settings → Templates → Template folder location 指向这里。

现有模板：

- `decision.md` —— ADR 4 段
- `feature.md` —— Tier-2 feature
- `knowledge.md` —— atomic 知识页
- `lesson.md` —— `experience/lessons/`
- `literature.md` —— Zettelkasten 文献笔记
- `log-weekly.md` —— 周日志
- `project-claude.md` —— 项目级 CLAUDE.md（见 [[meta/project-claude-guide]]）
- `project-log.md` —— 项目 durable log.md
- `project-overview.md` —— Tier-3 `<project>.md`
- `project-wiki.md` —— 项目 wiki.md
- `retro.md` —— 回顾（weekly / monthly / yearly）
- `task.md` —— Tier-1 task
- `zone-log.md` —— zone-level log
- `zone-wiki.md` —— zone-level wiki

---

## E. Template 占位符约定（critical——避免漏替换）

Template 里有两种占位符语法，**替换规则不同**：

### `<placeholder>`（裸文本，不带括号）

替换时**直接换值**：

| 模板里 | 实例化后 |
|---|---|
| `<Feature Name>` | `Thread Title Generation` |
| `<task-slug>` | `cache-warmup-fix` |
| `<TICKET>` | `ED-1514` |

### `[[<placeholder>]]`（在 wiki-link 括号里）

替换 **inner text**，**保留 `[[ ]]` 括号**：

| 模板里 | 实例化后 |
|---|---|
| `[[<feature>]]` | `[[thread-title-generation]]` |
| `[[<task-id>]]` | `[[2026-04-29-thread-html-view-ED-1514]]` |

### ⚠️ 漏替换 = broken link

**未替换的 `[[<x>]]` 在 Obsidian 里是 broken link**——Obsidian 会尝试 resolve `<x>` 字面量为文件名然后失败。所以：

- **永远替换**所有 `[[<...>]]`
- 如果用不上某个占位符，**整行删除**
- lint 的 broken-links 检查会抓到这种漏网

### HTML comment 块

模板顶部常见 `<!-- INSTANTIATION NOTE ... -->` 块。Obsidian **不渲染**它（只在编辑视图可见），但实例化前**必须读它**——里面写了哪些字段必填、哪些段可选。

---

## F. Project `<project>.md` Mermaid + `[[link]]` = navigation backbone

每个 Tier-3 项目总览**必含** Mermaid 架构图，节点上挂 `click <node> "obsidian://...&file=<feature-id>"` 或直接 `[[<feature>]]` 链接。

- Obsidian 的 link preview（Ctrl/Cmd + hover）让 top-down 浏览整个项目变得自然
- Mermaid 图本身就是 architecture summary——读者扫一眼就有整体感
- 搭配 graph view（Obsidian 自带），整个项目的 link 拓扑可视化

详见 [[CLAUDE]] §2.1 Tier-3 描述。

---

## G. 跨设备（deprecated sync）

Obsidian Sync 已关闭。跨设备部署改由 **plugin 安装**（`yis-brain` marketplace）+ `bootstrap-vault.sh` 承担，不再用 `claude-sync/` 镜像（已移除）。
