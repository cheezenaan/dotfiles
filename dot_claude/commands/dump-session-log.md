# Dump session log

セッションの作業内容とやりとりを構造化されたログとしてダンプします。

## 使用方法

```
/dump-session-log [task_description]
```

- `task_description`: (optional) 作業内容の簡潔な説明（ファイル名に使用）
  - ユーザーから `task_description` の入力がない場合､ `tmp/_logs` ディレクトリ内のログファイルから推測する

## 実行処理

1. `.tmp/_logs` が存在しない場合､ `mkdir -p` でディレクトリを作成
2. `~/.claude/templates/02.LOG.md` テンプレートを読み込み
3. テンプレート内の HTML コメント（`<!-- -->`）を削除
4. セッション内でのやりとりと作業ログ､ファイル変更内容を整理
5. `YYYYmmdd_hhmm_<task_description>.md` 形式で `.tmp/_logs` にファイル出力

## 出力先

- ディレクトリ: `./tmp/_logs/`
- ファイル名形式: `YYYYmmdd_hhmm_<task_description>.md`
- 例: `20250628_0945_conventional_commits_implementation.md`

## テンプレート構造

テンプレートファイル `~/.claude/templates/02.LOG.md` を使用して､一貫性のあるログ形式を生成します。

## 使用例

```bash
/dump-session-log conventional_commits_helper
# → ./tmp/_logs/20250628_0945_conventional_commits_helper.md が生成される
```
