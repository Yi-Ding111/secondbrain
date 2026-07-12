#!/usr/bin/env bash
#
# auto-log-append.sh — append audit-only entry to nearest log.md after Write/Edit on distilled content
#
# Triggered as PostToolUse hook for Write/Edit tools.
# Appends a minimal "[auto:HH:MM]" entry to the leaf folder's log.md so every distilled
# write leaves a trail, even when /ingest or /wrap-work isn't invoked.
#
# Skipped paths (no audit needed):
#   - .claude/, claude-sync/, .obsidian/, .omc/        — infrastructure, not vault content
#   - raw/                                              — immutable; raw rule covers
#   - inbox/                                            — dump zone; ingest handles
#   - archives/                                         — frozen
#   - meta/                                             — vault meta
#   - root log.md / index.md                            — top-level meta
#   - any superseded/                                   — frozen archive
#
# Skipped basenames (managed differently):
#   - log.md / wiki.md / CLAUDE.md / index.md           — themselves the destination/managed by skill
#
# Dedup: if leaf log.md's last 10 lines already mention this file's basename, skip
# (avoids double-logging when /ingest or /wrap-work also writes the entry manually).
#
# Bootstrap: leaf log.md must already exist. Hook does NOT create it (skill bootstraps on first content).
# This is intentional — no surprise log.md creation in zones the user hasn't started populating.

set -uo pipefail

LOG_ERR="${CLAUDE_PROJECT_DIR:-$HOME/Documents/YisBrain}/meta/scripts/hooks/.auto-log-append.log"
log_err() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_ERR" 2>/dev/null || true; }

INPUT=$(cat 2>/dev/null || echo '{}')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

[ -z "$FILE_PATH" ] && exit 0

VAULT="${CLAUDE_PROJECT_DIR:-$HOME/Documents/YisBrain}"

# Only fire for vault paths
case "$FILE_PATH" in
    "$VAULT/"*) ;;
    *) exit 0 ;;
esac

# Skip infrastructure / immutable / frozen zones
case "$FILE_PATH" in
    "$VAULT/.claude/"*)         exit 0 ;;
    "$VAULT/claude-sync/"*)     exit 0 ;;
    "$VAULT/.obsidian/"*)       exit 0 ;;
    "$VAULT/.omc/"*)            exit 0 ;;
    "$VAULT/raw/"*)             exit 0 ;;
    "$VAULT/inbox/"*)           exit 0 ;;
    "$VAULT/archives/"*)        exit 0 ;;
    "$VAULT/meta/"*)            exit 0 ;;
    "$VAULT/log.md")            exit 0 ;;
    "$VAULT/index.md")          exit 0 ;;
esac

# Skip superseded/ subfolders (anywhere in tree)
case "$FILE_PATH" in
    *"/superseded/"*) exit 0 ;;
esac

# Skip files that ARE log.md / wiki.md / CLAUDE.md / index.md themselves
case "$(basename "$FILE_PATH")" in
    log.md|wiki.md|CLAUDE.md|index.md) exit 0 ;;
esac

# Skip dotfiles
case "$(basename "$FILE_PATH")" in
    .*) exit 0 ;;
esac

# Find leaf folder log.md
DIR=$(dirname "$FILE_PATH")
LOG_FILE="$DIR/log.md"

# log.md must already exist; otherwise no-op (let skill bootstrap)
[ ! -f "$LOG_FILE" ] && exit 0

# Dedup: if last 10 lines already mention this basename, skip
BASENAME=$(basename "$FILE_PATH" .md)
RECENT=$(tail -10 "$LOG_FILE" 2>/dev/null || echo "")
if echo "$RECENT" | grep -qF -- "$BASENAME"; then
    # Already logged recently
    exit 0
fi

DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')
case "$TOOL_NAME" in
    Write) ACTION="created/overwritten" ;;
    Edit)  ACTION="edited" ;;
    *)     ACTION="touched" ;;
esac

# Append audit entry. Tagged [auto:HH:MM] so /ingest and /wrap-work can identify and not duplicate.
{
    echo ""
    echo "## $DATE [auto:$TIME] — $BASENAME $ACTION"
    echo "- File: \`$BASENAME.md\` ($TOOL_NAME)"
} >> "$LOG_FILE" 2>/dev/null || log_err "append failed: $LOG_FILE"

exit 0
