# ADR-0002: japanese-tech-writing フックの発火戦略

## Status

Accepted (2026-07-14)

## Context

japanese-tech-writing スキルによる自動セルフチェックを PostToolUse フックで実現する際、どのファイルの編集で発火させるかを決める必要がある。

技術記事や設計文書の `.md` ファイルにだけチェックを適用したいが、Claude Code は CLAUDE.md、SKILL.md、settings 関連のファイルなど、技術文書でない `.md` ファイルも頻繁に編集する。
発火条件の設計を誤ると、無関係な編集でもチェックが走り、作業効率を落とす。

## Decisions

環境変数 `JAPANESE_TECH_WRITING_DIRS` による opt-in 方式を採用する。
フックスクリプトはグローバル設定（`~/.config/claude/settings.json`）に登録する。
対象ディレクトリは、プロジェクトごとの `.claude/settings.local.json` の `env` で `JAPANESE_TECH_WRITING_DIRS` を設定して有効化する。
未設定のプロジェクトではフックが発火しない。

グローバルにフックを配置し、ローカルで有効化する二層構造とする。
フックスクリプト自体は chezmoi で全環境に展開されるため、プロジェクトごとにスクリプトをコピーする必要がない。

不採用とした案:

1. 全 `.md` ファイルで発火し、除外リストで制御する → 除外リストの保守が煩雑になる。Claude Code が新しい設定ファイルを導入した場合に除外漏れが起きる
2. 手動トリガーのみ → Edit/Write 直後に即座のチェックが走らない。推敲依頼を何度も繰り返すことになり作業のリズムを崩す
3. プロジェクトローカルフックのみ → フックスクリプトの実体をプロジェクトごとにコピーする二重管理が発生する

## Known Risks

- 環境変数の設定を忘れるとフックが発火しない。設定方法は `skills/japanese-tech-writing/README.md` に記載済み
