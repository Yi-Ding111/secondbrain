---
description: Plane tracking posture — before organizing any content into the vault, locate the matching Plane project + ticket (confirm with user); after finishing, write a comment + set the ticket Done. Use /track.
paths:
  - "**/inbox/**/*.md"
  - "**/knowledge/**/*.md"
  - "**/experience/**/*.md"
  - "**/learning/**/*.md"
  - "**/work/*/projects/*/**/*.md"
  - "**/projects/*/**/*.md"
  - "**/wiki/**/*.md"
---

# 整理内容前后要走 Plane 账本 Plane tracking

你正准备把一块内容整理进 vault(ingest / wrap-work / 任何往 knowledge·experience·learning·project·wiki 写的操作)。这个 vault 记录 Yi 的**所有**项目(个人 / 工作 / 生活灵感 / 学习 / 总结),每一块整理都应该在 **Plane 里有账**。

## 规则 The rule

**用 `/track` 把整理夹进 Plane ticket 生命周期**——它是这套流程的实现(完整步骤见 `.claude/skills/track/SKILL.md`)。核心信封:

1. **开工前 · 定位 Plane 项目** —— **`list_projects` live 查询**(项目随时新增,**绝不用写死的列表主观判断**)→ 按内容匹配 → **返回用户确认**
2. **开工前 · 定位 ticket** —— 项目内按名字/内容搜 → **返回用户确认**;**没找到就告诉用户、问是否创建**,别擅自跳过
3. **中间 · 整理** —— 跑 `/ingest`(默认)或 `/wrap-work`,产出落进 vault
4. **完成后 · 回写** —— 给 ticket 加 **structured comment**(`✅ 已整合` + 落地路径 + 日期 + 一句话摘要)+ 状态置 **Done**

## 硬性边界 Hard boundaries

- **项目集是动态的** —— 每次实时 `list_projects`,不假设、不硬编码项目名单
- **三处确认闸交给用户**:项目 / ticket / 是否创建新 ticket。用户没点头不往下走
- **状态只在收尾动** —— 开工不改状态;只有内容**完整**整合才置 Done,部分整合留原状态 + comment 说明进度
- **comment 不搬 vault 正文** —— 只记摘要 + 落地路径(vault 是 source of truth,Plane 是账本)
- 拿不准这块内容要不要上 Plane(例:纯 draft、还没定型的 thinking)→ 问用户,别强行建 ticket

Source of truth: `.claude/skills/track/SKILL.md`。根 [[CLAUDE]] §6 有一句 always-load 兜底。
