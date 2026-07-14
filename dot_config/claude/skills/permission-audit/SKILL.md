---
name: permission-audit
description: |
  Auto mode の permission ログを集計し、settings.json の permissions 改善候補を提案する。
  MANDATORY TRIGGERS: /permission-audit, permission-audit, パーミッション監査, 権限監査, permission 集計。
  DO NOT TRIGGER: /fewer-permission-prompts, permissions の手動編集、auto mode の設定変更。
argument-hint: "[--all] [--since YYYY-MM] [--min N]"
allowed-tools: Read, Edit, Bash(ruby:*)
---

# permission-audit

Auto mode の permission ログを集計し、`settings.json` の permissions 改善候補を提案する。

## 手順

### 1. 集計スクリプトを実行する

```bash
ruby ~/.config/claude/hooks/permission-log.rb audit [--all] [--since YYYY-MM] [--min N]
```

- 引数なし: カレントプロジェクト、直近 90 日分
- `--all`: 全プロジェクト横断
- `--since YYYY-MM`: 指定月以降
- `--min N`: 最小出現回数（デフォルト 3）

出力は JSON。
`error` キーがあればエラー（ログ未検出等）なのでユーザーに案内する。
`summary.date_end` が数日前より古ければ logger の故障を疑う。

### 2. 結果を解釈してユーザーに提示する

`candidates` の `allow` / `deny` / `review` を確認する。

- **allow**: `permissions.allow` への追加候補。ただし副作用コマンド（curl, rm, git push, docker run, npm install 等）が含まれていたら、examples を確認して慎重に判断する
- **deny**: `permissions.deny` への追加候補
- **review**: `examples` と `deny_reasons` をユーザーに提示し判断を仰ぐ

### 2.5. 既存 settings との突き合わせ

候補を提示する前に、以下の settings ファイルの `permissions.allow` / `permissions.deny` を Read で確認する:

- `~/.config/claude/settings.json`（ユーザーグローバル）
- `.claude/settings.json`（プロジェクト）
- `.claude/settings.local.json`（プロジェクトローカル）

既に登録済みのパターンは「設定済み」として報告のみ行う。
glob の包含関係も考慮し、重複提案を避ける。

### 3. 適用先をユーザーに確認する

承認された候補のみ、選択された settings ファイルに追記する。
既存のエントリを削除、上書きしない。

## ログがない場合

1. `permission-log.rb` hook が settings.json に登録されているか確認を促す
2. auto mode でセッションを実行するとログが蓄積されることを説明
3. `/fewer-permission-prompts` で手動モードの頻度ベース提案が利用可能であることを案内
