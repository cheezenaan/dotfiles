# zento-watch

uniball ZENTO シグニチャーモデル（単色 / 3色）の在庫を定期的に見て、
**在庫なし → 在庫あり** に変わったときだけ Discord / Slack の Webhook に通知する。

- 標準ライブラリだけで動く（`python3 zento_watch.py` で完結、依存インストール不要）
- 監視ソース: 楽天市場 API / Yahoo!ショッピング API / 任意の商品ページ（HTML）
- 転売価格は `max_price` で足切りする
- 一度通知した出品は、売り切れて再入荷するまで再通知しない

## セットアップ

### 1. API キーを取る（どちらも無料）

| ソース | 取得先 | 環境変数 |
| --- | --- | --- |
| 楽天市場 | https://webservice.rakuten.co.jp/ でアプリ ID を発行 | `RAKUTEN_APP_ID` |
| Yahoo!ショッピング | https://e.developer.yahoo.co.jp/register でアプリケーション ID を発行 | `YAHOO_APP_ID` |

### 2. Webhook を用意する

Discord ならチャンネル設定 → 連携サービス → ウェブフック、Slack なら Incoming Webhook。
URL のホスト名から送信フォーマットを自動で切り替える。

### 3. 設定ファイルを作る

```sh
cd tools/zento-watch
cp config.example.json config.json
```

環境変数は `.zshrc` などではなくローカル専用ファイルに置く（`*.local` は gitignore 済み）:

```sh
cat > ~/.config/zento-watch.env.local <<'EOS'
export RAKUTEN_APP_ID=...
export YAHOO_APP_ID=...
export ZENTO_WATCH_WEBHOOK_URL=https://discord.com/api/webhooks/...
EOS
```

## 使い方

```sh
source ~/.config/zento-watch.env.local

# 通知も状態保存もせず、いま何が引っかかるかだけ見る
python3 zento_watch.py --dry-run -v

# 本番。在庫なし -> 在庫ありの遷移だけ通知する
python3 zento_watch.py

# Webhook の疎通確認
python3 zento_watch.py --test-notify

# 手動常駐（5分間隔）
python3 zento_watch.py --loop 300

# 通知済みの記録を消してやり直す
python3 zento_watch.py --reset-state
```

最初は必ず `--dry-run -v` で、単色と 3色 が正しく振り分けられているか確認すること。
ヒット件数が 0 のままなら `queries` のキーワードを、関係ない商品が混ざるなら
`match.none_of` を調整する。

## 公式ストアや文具店を監視対象に足す

楽天と Yahoo は API で在庫状態が取れるが、公式ストアや文具店は
ページの文言から判定するしかないので、サイトごとに設定がいる。

```sh
# そのページに在庫マーカーの候補があるか調べる
python3 zento_watch.py --probe 'https://example.com/items/xxxx'
```

出てきた文言を `config.json` の `pages[]` に振り分けて `enabled: true` にする。

```json
{
  "id": "some-store",
  "enabled": true,
  "product_id": "signature-single",
  "label": "○○文具（単色）",
  "shop": "○○文具",
  "url": "https://example.com/items/xxxx",
  "sold_out_markers": ["SOLD OUT", "入荷お知らせ"],
  "in_stock_markers": ["カートに入れる"]
}
```

売り切れ表記を先に評価する。カートボタンが無効状態で HTML に残るサイトがあるため。
どちらのマーカーにも当たらない場合は「判定不能」として警告を出し、通知はしない
（JavaScript で在庫を描画するページはこの経路では取れない）。

## 設定リファレンス

| キー | 意味 |
| --- | --- |
| `products[].match.all_of` | OR グループの配列。全グループを満たす商品名だけ通す |
| `products[].match.none_of` | 1つでも含んだら除外（替芯やケース、3色の混入対策） |
| `products[].max_price` | この価格を超える出品は無視する（転売対策） |
| `products[].queries` | 検索キーワード。ソースごとに変えられる |
| `notify.cooldown_hours` | 同じ出品への再通知を抑える時間。既定 6 時間 |

状態ファイルは `$XDG_STATE_HOME/zento-watch/state.json`（既定 `~/.local/state/...`）。

## テスト

```sh
python3 zento_watch_test.py
```

ネットワークには出ない。HTTP 層を差し替えて判定ロジックだけを検証する。

## 制約

- **Amazon は対象外。** 規約でスクレイピングが禁止されており、PA-API は売上実績が要る。
  どうしても要るなら Keepa API（有料）を `pages` とは別のソースとして足すことになる。
- 楽天 / Yahoo の API は 1 クエリ 30 件までしか見ない。人気商品が大量に並ぶと
  取りこぼす可能性があるので、`queries` は絞り気味にしておく。
- 相手サイトへの負荷を避けるため、HTTP リクエストは最低 1 秒間隔を空ける。
  `--loop` の間隔は 5 分（300秒）より短くしないこと。
- 実店舗の入荷は検知できない。

## 常駐させる場合

いまは手動実行前提。常駐させるなら:

- **launchd**（このリポジトリと相性が良い / Mac が起きている必要がある）
  `~/Library/LaunchAgents/` に `StartInterval` 300 の plist を置く
- **GitHub Actions cron**（Mac の電源に依存しない / cron が 5〜15 分遅延することがある）
  状態ファイルを `actions/cache` に置いて引き回す

どちらも `zento_watch.py` はそのまま使える。
