# yis-brain — plugin marketplace

本目录是 **`yis-brain` marketplace**，容纳两个 plugin：`second-brain`（完整版，个人机）与 `work-capture`（轻量版，工作机）。本文件说明 marketplace 结构、两包边界、命名/版本与 bootstrap。

安装：`/plugin marketplace add <此仓库路径>` → `/plugin install second-brain@yis-brain`（个人机）/ `work-capture@yis-brain`（工作机）。

---

## 目录结构

```text
plugins/
├── .claude-plugin/
│   └── marketplace.json          # marketplace 清单（列两个 plugin）
├── second-brain/                 # 完整版 plugin（个人机）
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/                   # ingest / wrap-work / lint / project-survey / project-decompose
│   ├── agents/                   # digest-fuser / knowledge-extractor / project-surveyor
│   ├── rules/                    # 5 条 path-scoped 护栏（plugin 携带；bootstrap 落地）
│   ├── hooks/                    # hooks.json + auto-log-append.sh（不含 mirror-sync）
│   ├── scripts/                  # 维护脚本 + bootstrap-vault.sh
│   ├── templates/                # 14 个页面模板（task 记忆模板等）
│   └── reference/                # CLAUDE.md 基线 + 12 个 canonical 设计文档（[[meta/…]] link 目标）
└── work-capture/                 # 轻量版 plugin（工作机）
    └── skills/                   # 仅 work-capture skill
```

Claude Code 约定：每个 plugin 必须有 `.claude-plugin/plugin.json`；组件放默认目录（`skills/`、`agents/`、`hooks/`）即被自动发现。`marketplace.json` 放 marketplace 根的 `.claude-plugin/` 下，`plugins[].source` 为相对路径。

**rules 投递（重要机制）**：Claude Code plugin **原生组件只有 skills / agents / hooks / MCP / LSP——没有 "rules" 类型**。path-scoped 护栏（`.claude/rules/`）是 vault 项目级机制，plugin 无法自动注入。故本 plugin **携带** `rules/` 作单一真相源，安装/bootstrap 时把它们复制到目标 vault 的 `.claude/rules/`。rule 的 `paths:` glob 是 vault 相对，复制后即正确触发。

## 基线 vs override + bootstrap（vault 侧文件如何落地）

plugin 里有两类内容：**自动加载组件**（`skills/` `agents/` `hooks/`——Claude Code 装 plugin 即生效）和 **vault 侧 baseline**（`reference/`+`templates/`+`rules/`——是 vault 里的文件，plugin 不会自动放，需要 bootstrap）。

- **baseline = plugin 里的 canonical 版本**：`reference/CLAUDE.md`（宪法基线）、`reference/*.md`（12 个设计文档，即 skill 里 `[[meta/…]]` 的 link 目标）、`templates/*.md`（14 个模板）、`rules/*.md`（5 条护栏）。
- **override = vault 自己的版本优先**：`scripts/bootstrap-vault.sh` **只补缺失、绝不覆盖**——vault 已有同名文件就保留 vault 版，缺失才落 baseline 版。Yi 现有的 167 文件配置不会被动。
- **bootstrap 落地映射**：`reference/CLAUDE.md`→`CLAUDE.md`；`reference/<其它>.md`→`meta/`；`templates/*`→`meta/templates/`；`rules/*`→`.claude/rules/`。这样一来 skill 里的 `[[meta/project-overview-system]]` 等 wiki-link 在目标 vault 上就能解析，5 条 rule 也落到 `.claude/rules/` 生效。

```bash
# 安装 plugin 后，对一个 vault 跑一次（默认 $CLAUDE_PROJECT_DIR）：
${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap-vault.sh [VAULT_DIR]
```

> 注：bootstrap 是「仅补缺失」，已 bootstrap 过的 vault 若要拿模板/文档的新版，需另行同步（plugin 更新后手动 diff 落地）。

## 两包边界（哪些属谁 / 共享策略）

| 组件 | second-brain | work-capture | 说明 |
|---|:---:|:---:|---|
| skill `ingest` / `wrap-work` / `lint` | ✅ | — | vault 操作，需本地 vault |
| skill `project-survey` / `project-decompose` | ✅ | — | 需 code repo + vault |
| skill `work-capture` | — | ✅ | 工作机把 thread → 交接文案 |
| agents（3 个 read-only） | ✅ | — | 供 second-brain 的 skill 委派 |
| rules（5 条 path-scoped） | ✅ | — | 护栏针对 vault 路径 |
| hooks（auto-log-append） | ✅ | — | 写 vault leaf log |
| scripts（维护脚本） | ✅ | — | 操作 vault 结构 |
| templates（页面模板） | ✅ | — | 写 vault 页 |
| CLAUDE.md 基线 | ✅ | — | 宪法，随 second-brain 分发 |
| **记忆总结规范 + task 记忆模板** | ✅（canonical） | ✅（自带副本） | 见下方共享决策 |

**共享决策（关键）**：记忆总结规范（`memory-summary-spec`）与 task 记忆模板是两包都要遵循的。但 **work-capture 跑在没有 vault 的工作机上，无法 `[[link]]` 到 second-brain 的文件**。故采用**"canonical + 自带副本"**：second-brain 持权威版；work-capture 在自己 skill 里**内嵌一份自包含的总结规则**（不跨包依赖），保持与 canonical 一致。→ 避免跨 plugin 硬依赖，也避免"装了 work-capture 就必须装 second-brain"。

## 命名 / 版本策略

- **marketplace name**：`yis-brain`；owner = Yi。
- **plugin 名**：`second-brain`、`work-capture`（kebab，稳定，勿改——改名等于换包）。
- **版本**：semver，均从 `0.1.0` 起。`0.x` 开发期；稳定后各自升 `1.0.0`。
- **两包独立版本号**（各自 `plugin.json` 的 `version`）；marketplace 有自己的 `metadata.version`。
- version 是 `/plugin update` 的 cache key——每次改组件内容记得 bump 对应 plugin 的 `version`。

## 不纳入（obsidian-sync 遗留）

本 plugin **不含** `mirror-sync.sh` hook 与 `claude-sync/` 镜像逻辑——已关闭 Obsidian Sync，跨设备部署改由本 marketplace 安装承担。
