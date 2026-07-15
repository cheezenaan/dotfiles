#!/bin/bash
# PostToolUse hook: 指定ディレクトリの .md 編集後に
# japanese-tech-writing 規範のセルフチェック指示を注入する。
#
# JAPANESE_TECH_WRITING_DIRS 環境変数（カンマ区切り）で対象ディレクトリを指定。
# 未設定なら何もしない（opt-in）。
# fail-open (常に exit 0)

set -uo pipefail

[[ -z "${JAPANESE_TECH_WRITING_DIRS:-}" ]] && exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -z "$FILE_PATH" || "$FILE_PATH" != *.md ]] && exit 0

matches_dir() {
  IFS=',' read -ra dirs <<< "$JAPANESE_TECH_WRITING_DIRS"
  for d in "${dirs[@]}"; do
    d="${d#"${d%%[![:space:]]*}"}"
    d="${d%"${d##*[![:space:]]}"}"
    [[ -n "$d" ]] && case "$FILE_PATH" in */"$d"/* | "$d"/*) return 0 ;; esac
  done
  return 1
}

matches_dir || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[WRITING CHECK] 直前の編集内容を japanese-tech-writing スキルの規範に照らして確認せよ。\\n規範に反する箇所があれば修正せよ。問題がなければ「規範チェック: 問題なし」とだけ報告せよ。"}}\n'
