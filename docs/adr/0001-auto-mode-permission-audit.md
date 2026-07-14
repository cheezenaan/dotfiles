# ADR-0001: Auto Mode Permission Audit System

## Status

Accepted (2026-07-14, simplified 2026-07-15)

## Context

Claude Code の auto mode における permission 判断履歴を構造化し、`settings.json` の permissions 最適化によるプロンプト削減と判断の可視化を実現したい。

調査で判明した制約:

- `permission_mode` フィールドは hook ペイロードに存在する（値: `"auto"`）
- **PermissionDenied** hook は classifier deny でのみ発火（`permissions.deny` ルールでは発火しない）
- deny reason のフィールド名は `reason`（`denial_reason` ではない）
- 手動モードのユーザー deny には hook が存在しない（`/fewer-permission-prompts` がカバー）

## Decisions

auto mode に限定する。
手動モードの deny 捕捉には JSONL パースが必要で複雑化し、allow は `/fewer-permission-prompts` がカバー済みのため。

単一ファイル（`permission-log.rb`）に record/audit を同居させる。
定数と規約が 1 ファイルに閉じ、ファイル間の同期コストが発生しないため。

ログにはファクトだけ記録し、decision/command_key は読み取り時に導出する。
導出ロジックの変更が全履歴に遡及適用されるため。

実装上の WHY NOT（複合コマンド除外の理由、atomic write の理由、fail-open の理由）はコード内コメントに記載。

## Known Risks

- `permissions.allow` 追加後も PostToolUse は発火し続けるため、rule-based allow が allow カウントに混入する。
  SKILL.md の既存設定突き合わせ（step 2.5）で重複提案を避ける運用でカバー
- `raw_input_summary` の 200 字 truncation 後に複合コマンド検出が走るため、201 文字目以降のパイプ等は見えない。
  個人ツールとして許容
