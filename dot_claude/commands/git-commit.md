# Generate commit messages with Conventional commits format

ステージング状況とコミット対象の変更内容を確認して、Conventional Commits に準拠した適切なコミットメッセージを提案・作成します。

## 使用方法

```
/git-commit [user-provided message]
``

- 引数あり: ユーザーの提案をベースに改善・検証したメッセージを提案
- 引数なし: AI がゼロベースでメッセージを生成して提案

## 実行フロー

### 1. メッセージ提案フェーズ

1. `git status` でステージング状況を確認
2. `git diff --staged` でステージされた変更内容を分析
3. `git log --oneline -5` で最近のコミットメッセージスタイルを確認
4. Conventional Commits 形式で 3 つのメッセージを提案
5. 提案したメッセージのスペルチェックと文法確認を実行

### 2. コミット実行フェーズ

ユーザーが選択したメッセージに対して：

1. 最終的なスペルチェックと文法確認
2. `git commit` でコミット実行

## コミットメッセージ 出力形式

以下の形式で提案してください｡
コミットメッセージは英語で 50-72 文字以内を目安とし、変更の本質を簡潔に表現してください。

```markdown
## 提案1（推奨）
<type>(scope): <description>

## 提案2
<type>(scope): <description>

## 提案3
<type>(scope): <description>
```

## 参考: Conventional Commits の type 例

see also. <https://www.conventionalcommits.org/en/v1.0.0/>

- `feat`: 新機能追加
- `fix`: バグ修正
- `docs`: ドキュメント更新
- `style`: コードスタイル変更（機能に影響しない）
- `refactor`: リファクタリング
- `perf`: パフォーマンス改善
- `test`: テスト追加・修正
- `chore`: ビルドプロセスやツール変更
- `ci`: CI 設定変更
- `build`: ビルドシステム変更
- `revert`: コミット取り消し
