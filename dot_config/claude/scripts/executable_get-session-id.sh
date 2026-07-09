#!/bin/bash
# 現在の Claude Code セッションの session_id を標準出力に出す。
# SessionStart hook (~/.config/claude/hooks/session-id-cache.sh) が書いた cache を読む。
#
# 使い方: get-session-id.sh [作業ディレクトリ]  （省略時はカレントディレクトリ）
# 制約: 同一ディレクトリで並行セッションを開いた場合は後勝ち。
# 見つからない場合は exit 1（呼び出し側は「取得不能」として停止すること）

set -uo pipefail

CWD="${1:-$PWD}"
CACHE_DIR="${TMPDIR:-/tmp}/claude-session-ids"
KEY=$(printf '%s' "$CWD" | md5 -q 2>/dev/null || printf '%s' "$CWD" | md5sum 2>/dev/null | cut -d' ' -f1)
CACHE="$CACHE_DIR/$KEY"

if [[ -n "$KEY" && -f "$CACHE" ]]; then
  cat "$CACHE"
  exit 0
fi

echo "session_id cache not found for: $CWD (SessionStart hook が未発火。新しいセッションで再試行)" >&2
exit 1
