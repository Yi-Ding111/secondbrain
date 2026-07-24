#!/usr/bin/env bash
# integration-test.sh — 端到端集成检查（两个 plugin + 跨机链路 + 架构索引 + 无 sync 残留）。
# 静态可验证的部分全跑；真正的 /plugin install 运行时需在 Claude Code 会话里做。
#
# Usage: bash plugins/integration-test.sh   (from vault root)

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."   # vault root
SB=plugins/second-brain
WC=plugins/work-capture
fail=0; ok(){ echo "  ✓ $1"; }; bad(){ echo "  ✗ $1"; fail=1; }

echo "== 集成测试 =="

echo "[1] second-brain 静态验证"
bash "$SB/scripts/validate-plugin.sh" >/dev/null 2>&1 && ok "validate-plugin 全绿" || bad "validate-plugin 失败"

echo "[2] work-capture 轻量包"
python3 -c "import json;json.load(open('$WC/.claude-plugin/plugin.json'))" 2>/dev/null && ok "plugin.json 合法" || bad "work-capture json"
[ -f "$WC/skills/work-capture/SKILL.md" ] && ok "work-capture skill 存在" || bad "no work-capture skill"
[ -f "$WC/skills/branch-review/SKILL.md" ] && ok "branch-review skill 存在" || bad "no branch-review skill"
[ -f "$WC/OUTPUT-FORMAT.md" ] && ok "输出格式存在" || bad "no output format"
# 轻量：不含完整机制
if ls "$WC"/skills/{ingest,wrap-work,lint} >/dev/null 2>&1; then bad "work-capture 混入了完整机制"; else ok "轻量（无 ingest/wrap-work/lint）"; fi

echo "[3] 架构索引"
bash "$SB/scripts/manifest-check.sh" manifest.md >/dev/null 2>&1 && ok "manifest-check（zone 索引一致）" || bad "manifest drift"
grep -q "AI 读取协议" manifest.md && ok "AI 读取协议在位" || bad "no reading protocol"

echo "[4] 记忆规范落到组件"
grep -q "memory-summary-spec" "$SB/skills/wrap-work/SKILL.md" && ok "wrap-work 引用记忆规范" || bad "wrap-work 未对齐"
grep -q "回忆钩子\|Recall Hooks" "$SB/agents/digest-fuser.md" && ok "digest-fuser 6 段结构" || bad "digest-fuser 未改"
grep -q "禁\|不含\|no line diffs\|绝不" "$SB/reference/memory-summary-spec.md" && ok "禁 diff 原则成文" || bad "spec 缺禁 diff"

echo "[5] 两 skill 产出 + 关联键 + ingest 接收"
python3 - <<'PY' && ok "work-capture / branch-review 产出合规" || echo "  ✗ 产出校验失败"
import re
def fm(p):
    t=open(p,encoding="utf-8").read()
    return dict(re.findall(r'^(\w+):\s*(.+)$',t.split('---')[1],re.M)), t
# work-capture 对话记忆：5 段、无流程图、无 diff、带关联键
f,t=fm("plugins/work-capture/examples/example-capture.md")
assert f.get("source")=="work-capture"
assert f.get("ticket") or f.get("branch"), "缺关联键"
for s in ["## 概述","## 实现逻辑","## 问题与方案","## 关键决策","## 回忆钩子"]: assert s in t
assert "## 流程图" not in t, "work-capture 不该再有流程图"
assert not re.search(r'\+\d+ -\d+|第 ?\d+ 行',t)
# branch-review 代码讲解：3 部分、含 mermaid、带关联键、无行号 diff
f,t=fm("plugins/work-capture/examples/example-branch-review.md")
assert f.get("source")=="branch-review"
assert f.get("ticket") or f.get("branch"), "缺关联键"
for s in ["## 改动流程图","## 数据流叙述","## 改动详录"]: assert s in t
assert "```mermaid" in t
assert not re.search(r'第 ?\d+ 行',t)
PY
grep -q "source: work-capture" "$SB/skills/ingest/SKILL.md" && grep -q "source: branch-review" "$SB/skills/ingest/SKILL.md" && ok "ingest 识别两种 source" || bad "ingest 未接收端"

echo "[6] 无 obsidian-sync 残留（活引用）"
[ ! -d claude-sync ] && ok "claude-sync/ 已删" || bad "claude-sync 仍在"
[ ! -f meta/scripts/hooks/mirror-sync.sh ] && ok "mirror-sync.sh 已删" || bad "mirror-sync 仍在"
grep -q "mirror-sync" .claude/settings.json && bad "settings 仍挂 mirror-sync" || ok "settings 只剩 auto-log-append"

echo
if [ "$fail" -eq 0 ]; then
  echo "集成静态检查全绿。运行时（/plugin install + /ingest /wrap-work /lint 实跑 + 真跨机）需 Claude Code 会话，见 README。"; exit 0
else echo "有失败项，见上。"; exit 1; fi
