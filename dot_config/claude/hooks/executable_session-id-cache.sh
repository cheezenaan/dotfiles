#!/bin/bash
# SessionStart hook: session_id を cwd キーで cache する。
# ~/.config/claude/scripts/get-session-id.sh がこの cache を読む。
# 制約: 同一ディレクトリで並行セッションを開くと後勝ちになる。
#
# fail-open (常に exit 0)

set -uo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[[ -z "$SESSION_ID" || -z "$CWD" ]] && exit 0

CACHE_DIR="${TMPDIR:-/tmp}/claude-session-ids"
mkdir -p "$CACHE_DIR" 2>/dev/null || true
KEY=$(printf '%s' "$CWD" | md5 -q 2>/dev/null || printf '%s' "$CWD" | md5sum 2>/dev/null | cut -d' ' -f1)
[[ -z "$KEY" ]] && exit 0
printf '%s\n' "$SESSION_ID" > "$CACHE_DIR/$KEY" 2>/dev/null || true

exit 0
