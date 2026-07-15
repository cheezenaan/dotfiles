# japanese-tech-writing

k16shikano 氏の[日本語技術文書の文章規範](https://gist.github.com/k16shikano/fd287c3133457c4fd8f5601d34aa817d)を Gist から取得して同梱したスキル。

## 自動セルフチェック

PostToolUse フックにより、`.md` ファイルの Edit/Write 後に規範チェックが自動実行される。
対象ディレクトリはプロジェクトごとに設定する。

`.claude/settings.local.json`:

```json
{
  "env": {
    "JAPANESE_TECH_WRITING_DIRS": "docs"
  }
}
```

未設定のプロジェクトではフックは発火しない。

## 更新

Gist の更新を取り込むには:

```bash
gh api gists/fd287c3133457c4fd8f5601d34aa817d --jq '.files["SKILL.md"].content' > dot_config/claude/skills/japanese-tech-writing/SKILL.md
```
