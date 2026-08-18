#!/usr/bin/env python3
"""uniball ZENTO シグニチャーモデルの再入荷監視。

楽天市場 / Yahoo!ショッピングの公式 API と、任意の商品ページの HTML を突き合わせ、
「在庫なし -> 在庫あり」に変わった瞬間だけ Webhook へ通知する。

標準ライブラリだけで動かす。macOS 同梱の python3 でそのまま実行できることを優先し、
将来 launchd で常駐させるときに依存解決を挟みたくないため。
"""

import argparse
import html as html_lib
import json
import os
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

USER_AGENT = "zento-watch/1.0 (personal restock monitor)"
HTTP_TIMEOUT = 20
RAKUTEN_ENDPOINT = "https://app.rakuten.co.jp/services/api/IchibaItem/Search/20220601"
YAHOO_ENDPOINT = "https://shopping.yahooapis.jp/ShoppingWebService/V3/itemSearch"
DEFAULT_COOLDOWN_HOURS = 6
STALE_RECORD_DAYS = 30
# 同一プロセス内の全 HTTP に効く最低待ち時間。相手サイトを叩きすぎないための保険。
REQUEST_INTERVAL = 1.0

# --probe で在庫判定マーカーの候補を探すときの手がかり。
PROBE_HINTS = [
    "カートに入れる", "カートへ入れる", "買い物かごに入れる", "購入手続き", "ご購入手続き",
    "在庫あり", "在庫僅少", "残りわずか", "お届け",
    "SOLD OUT", "SOLDOUT", "売り切れ", "品切れ", "在庫なし", "在庫切れ",
    "入荷待ち", "再入荷", "入荷お知らせ", "入荷連絡", "販売終了", "取扱終了", "お取り寄せ",
]

_last_request_at = 0.0


# --- HTTP -------------------------------------------------------------------

def http_get(url, headers=None):
    global _last_request_at
    wait = REQUEST_INTERVAL - (time.monotonic() - _last_request_at)
    if wait > 0:
        time.sleep(wait)
    request = urllib.request.Request(url, headers=dict({"User-Agent": USER_AGENT}, **(headers or {})))
    try:
        with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
            return decode_body(response.read(), response.headers.get_content_charset())
    finally:
        _last_request_at = time.monotonic()


def decode_body(raw, header_charset):
    """文具店系には Shift_JIS 配信が残っているので meta charset まで見る。"""
    charset = header_charset
    if not charset:
        head = raw[:4096].decode("ascii", errors="ignore").lower()
        found = re.search(r'charset=["\']?([\w-]+)', head)
        charset = found.group(1) if found else "utf-8"
    try:
        return raw.decode(charset, errors="replace")
    except LookupError:
        return raw.decode("utf-8", errors="replace")


def http_post_json(url, payload):
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url, data=body, method="POST",
        headers={"User-Agent": USER_AGENT, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
        return response.status


# --- 商品マッチング ---------------------------------------------------------

def normalize(text):
    """全角半角・大文字小文字・空白の揺れを吸収した突き合わせ用の文字列にする。"""
    folded = unicodedata.normalize("NFKC", text or "").casefold()
    return re.sub(r"\s+", "", folded)


def matches_product(product, title):
    """all_of の各グループを OR、グループ同士を AND として突き合わせる。

    「シグニチャー かつ (3色 または 三色)」のような条件を設定だけで書けるようにするため、
    include_all / include_any の 2 本立てではなく OR グループの AND 連結にしている。
    """
    text = normalize(title)
    rule = product.get("match", {})
    for group in rule.get("all_of", []):
        terms = [group] if isinstance(group, str) else group
        if not any(normalize(term) in text for term in terms):
            return False
    if any(normalize(term) in text for term in rule.get("none_of", [])):
        return False
    return True


def within_price(product, price):
    """定価から離れた転売価格を弾く。価格不明のものは落とさず通す。"""
    if price is None:
        return True
    max_price = product.get("max_price")
    min_price = product.get("min_price")
    if max_price is not None and price > max_price:
        return False
    if min_price is not None and price < min_price:
        return False
    return True


def to_int(value):
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return None


# --- 在庫ソース -------------------------------------------------------------

def fetch_rakuten(product, app_id):
    query = product.get("queries", {}).get("rakuten") or product["label"]
    params = {
        "applicationId": app_id,
        "format": "json",
        "keyword": query,
        "availability": "1",  # 在庫ありのみ
        "hits": "30",
        "sort": "+itemPrice",
    }
    data = json.loads(http_get(RAKUTEN_ENDPOINT + "?" + urllib.parse.urlencode(params)))
    offers = []
    for entry in data.get("Items", []) or []:
        # API バージョンによって Item ラップの有無が変わるので両方受ける
        item = entry.get("Item", entry) if isinstance(entry, dict) else {}
        title = item.get("itemName", "")
        if not matches_product(product, title):
            continue
        offers.append({
            "source": "rakuten",
            "code": item.get("itemCode") or item.get("itemUrl", ""),
            "title": title,
            "price": to_int(item.get("itemPrice")),
            "url": item.get("itemUrl", ""),
            "shop": item.get("shopName", ""),
            "product_id": product["id"],
            "in_stock": True,
        })
    return offers


def fetch_yahoo(product, app_id):
    query = product.get("queries", {}).get("yahoo") or product["label"]
    params = {
        "appid": app_id,
        "query": query,
        "in_stock": "true",
        "results": "30",
        "sort": "+price",
    }
    data = json.loads(http_get(YAHOO_ENDPOINT + "?" + urllib.parse.urlencode(params)))
    offers = []
    for hit in data.get("hits", []) or []:
        title = hit.get("name", "")
        if not matches_product(product, title):
            continue
        offers.append({
            "source": "yahoo",
            "code": hit.get("code") or hit.get("url", ""),
            "title": title,
            "price": to_int(hit.get("price")),
            "url": hit.get("url", ""),
            "shop": (hit.get("seller") or {}).get("name", ""),
            "product_id": product["id"],
            "in_stock": True,
        })
    return offers


def visible_text(html):
    without_code = re.sub(r"(?is)<(script|style)\b.*?</\1>", " ", html)
    return html_lib.unescape(re.sub(r"(?s)<[^>]+>", " ", without_code))


def detect_stock(text, sold_out_markers, in_stock_markers):
    """在庫マーカーから True / False / None（判定不能）を返す。

    売り切れ表記を先に見るのは、カートボタンが無効状態で残るサイトがあるため。
    """
    body = normalize(text)
    if any(normalize(marker) in body for marker in sold_out_markers):
        return False
    if any(normalize(marker) in body for marker in in_stock_markers):
        return True
    return None


def check_page(page):
    text = visible_text(http_get(page["url"]))
    in_stock = detect_stock(text, page.get("sold_out_markers", []), page.get("in_stock_markers", []))
    return {
        "source": "page",
        "code": page["id"],
        "title": page.get("label", page["id"]),
        "price": page.get("price"),
        "url": page["url"],
        "shop": page.get("shop", ""),
        "product_id": page.get("product_id", ""),
        "in_stock": in_stock,
    }


def collect_offers(config, log):
    """全ソースを回して在庫候補を集める。1 ソースの失敗で他を巻き添えにしない。"""
    offers = []
    failures = []
    sources = config.get("sources", {})
    for product in config.get("products", []):
        for name, fetch in (("rakuten", fetch_rakuten), ("yahoo", fetch_yahoo)):
            source = sources.get(name, {})
            if not source.get("enabled", False):
                continue
            app_id = os.environ.get(source.get("app_id_env", ""), "")
            if not app_id:
                failures.append("%s: 環境変数 %s が未設定のためスキップ" % (name, source.get("app_id_env")))
                continue
            try:
                found = fetch(product, app_id)
            except (urllib.error.URLError, OSError, ValueError, KeyError) as error:
                failures.append("%s/%s: %s" % (name, product["id"], error))
                continue
            kept = [offer for offer in found if within_price(product, offer["price"])]
            log("  %s/%s: %d 件ヒット / 価格条件通過 %d 件" % (name, product["id"], len(found), len(kept)))
            offers.extend(kept)

    for page in config.get("pages", []):
        if not page.get("enabled", False):
            continue
        try:
            offer = check_page(page)
        except (urllib.error.URLError, OSError) as error:
            failures.append("page/%s: %s" % (page["id"], error))
            continue
        if offer["in_stock"] is None:
            failures.append("page/%s: 在庫マーカーに一致せず判定不能（--probe で見直してください）" % page["id"])
        log("  page/%s: in_stock=%s" % (page["id"], offer["in_stock"]))
        offers.append(offer)

    return offers, failures


# --- 状態 -------------------------------------------------------------------

def default_state_path():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(base, "zento-watch", "state.json")


def load_state(path):
    try:
        with open(path, encoding="utf-8") as handle:
            state = json.load(handle)
    except (FileNotFoundError, ValueError):
        return {"offers": {}}
    state.setdefault("offers", {})
    return state


def save_state(path, state):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # 途中で落ちても壊れた state を残さないよう置き換えで書く
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        json.dump(state, handle, ensure_ascii=False, indent=2, sort_keys=True)
    os.replace(tmp, path)


def offer_key(offer):
    return "%s:%s" % (offer["source"], offer["code"])


def decide_notifications(offers, state, cooldown_hours, now):
    """在庫なし -> 在庫あり の遷移だけを通知対象にし、state を現在値へ更新する。"""
    cooldown = cooldown_hours * 3600
    records = state["offers"]
    to_notify = []
    seen = set()

    for offer in offers:
        key = offer_key(offer)
        seen.add(key)
        record = records.setdefault(key, {})
        was_in_stock = record.get("in_stock", False)
        if offer["in_stock"] is None:
            # 判定不能はデータを持たない。前回値を書き換えると誤通知の起点になる。
            record["last_seen"] = now
            continue
        last_notified = record.get("notified_at")
        # 未通知 (None) を 0 で埋めない。cooldown 判定に巻き込まれて初回検知を取りこぼすため。
        fresh = last_notified is None or now - last_notified >= cooldown
        if offer["in_stock"] and not was_in_stock and fresh:
            to_notify.append(offer)
            record["notified_at"] = now
        record["in_stock"] = offer["in_stock"]
        record["last_seen"] = now
        record["title"] = offer["title"]
        record["url"] = offer["url"]
        record.setdefault("first_seen", now)

    # 検索結果から消えた = 売り切れ。次に現れたときに再通知できるよう倒しておく。
    stale = now - STALE_RECORD_DAYS * 86400
    for key, record in list(records.items()):
        if key in seen:
            continue
        record["in_stock"] = False
        if record.get("last_seen", 0) < stale:
            del records[key]

    return to_notify


# --- 通知 -------------------------------------------------------------------

def format_message(offers, products):
    labels = {product["id"]: product["label"] for product in products}
    lines = ["🖊️ uniball ZENTO 在庫検知 (%s)" % datetime.now(timezone.utc).astimezone().strftime("%m/%d %H:%M")]
    for product_id in sorted({offer["product_id"] for offer in offers}):
        lines.append("")
        lines.append("[%s]" % labels.get(product_id, product_id or "その他"))
        for offer in [o for o in offers if o["product_id"] == product_id]:
            price = "¥{:,}".format(offer["price"]) if offer.get("price") else "価格不明"
            shop = offer.get("shop") or offer["source"]
            lines.append("- %s / %s" % (shop, price))
            lines.append("  %s" % offer["title"])
            lines.append("  %s" % offer["url"])
    return "\n".join(lines)


def build_payload(webhook_url, message):
    host = urllib.parse.urlparse(webhook_url).hostname or ""
    if host.endswith("discord.com") or host.endswith("discordapp.com"):
        # Discord の content は 2000 文字上限
        return {"content": message[:1900], "flags": 0}
    return {"text": message}


def notify(webhook_url, message):
    return http_post_json(webhook_url, build_payload(webhook_url, message))


# --- コマンド ---------------------------------------------------------------

def load_config(path):
    with open(path, encoding="utf-8") as handle:
        config = json.load(handle)
    if not config.get("products"):
        raise ValueError("config に products がありません")
    for product in config["products"]:
        if "id" not in product or "label" not in product:
            raise ValueError("product には id と label が必要です: %r" % product)
    return config


def command_probe(url):
    text = visible_text(http_get(url))
    body = normalize(text)
    hits = [hint for hint in PROBE_HINTS if normalize(hint) in body]
    print("URL: %s" % url)
    print("本文長: %d 文字" % len(text))
    if hits:
        print("見つかった在庫マーカー候補:")
        for hint in hits:
            print("  - %s" % hint)
        print("\nこれらを config の sold_out_markers / in_stock_markers に振り分けてください。")
    else:
        print("候補が見つかりませんでした。JS で在庫を描画するページの可能性があります。")
    return 0


def command_check(args):
    config = load_config(args.config)
    state_file = args.state or default_state_path()
    log = (lambda message: print(message)) if args.verbose else (lambda message: None)

    log("設定: %s / 状態: %s" % (args.config, state_file))
    offers, failures = collect_offers(config, log)
    for failure in failures:
        print("警告: %s" % failure, file=sys.stderr)

    state = load_state(state_file)
    now = time.time()
    cooldown = config.get("notify", {}).get("cooldown_hours", DEFAULT_COOLDOWN_HOURS)
    to_notify = decide_notifications(offers, state, cooldown, now)

    in_stock_count = len([offer for offer in offers if offer["in_stock"]])
    print("在庫あり %d 件 / 新規検知 %d 件" % (in_stock_count, len(to_notify)))

    if to_notify:
        message = format_message(to_notify, config["products"])
        print(message)
        if not args.dry_run:
            webhook_url = os.environ.get(config.get("notify", {}).get("webhook_url_env", "ZENTO_WATCH_WEBHOOK_URL"), "")
            if not webhook_url:
                print("エラー: Webhook URL の環境変数が未設定です", file=sys.stderr)
                return 1
            notify(webhook_url, message)
            print("通知を送信しました")

    if not args.dry_run:
        save_state(state_file, state)

    # 全ソースが落ちたときだけ異常終了。部分失敗は警告どまりにする。
    return 1 if failures and not offers else 0


def main():
    parser = argparse.ArgumentParser(description="uniball ZENTO の再入荷を監視して Webhook に通知する")
    here = os.path.dirname(os.path.abspath(__file__))
    parser.add_argument("--config", default=os.path.join(here, "config.json"), help="設定ファイル (既定: 同ディレクトリの config.json)")
    parser.add_argument("--state", help="状態ファイル (既定: $XDG_STATE_HOME/zento-watch/state.json)")
    parser.add_argument("--dry-run", action="store_true", help="通知も状態更新もせず結果だけ表示する")
    parser.add_argument("--verbose", "-v", action="store_true", help="ソースごとの内訳を表示する")
    parser.add_argument("--loop", type=int, metavar="SECONDS", help="指定秒間隔で繰り返す")
    parser.add_argument("--probe", metavar="URL", help="ページの在庫マーカー候補を調べる")
    parser.add_argument("--test-notify", action="store_true", help="Webhook にテスト通知を送る")
    parser.add_argument("--reset-state", action="store_true", help="状態ファイルを削除する")
    args = parser.parse_args()

    if args.probe:
        return command_probe(args.probe)

    if args.reset_state:
        path = args.state or default_state_path()
        try:
            os.remove(path)
            print("削除しました: %s" % path)
        except FileNotFoundError:
            print("状態ファイルはありません: %s" % path)
        return 0

    if args.test_notify:
        config = load_config(args.config)
        webhook_url = os.environ.get(config.get("notify", {}).get("webhook_url_env", "ZENTO_WATCH_WEBHOOK_URL"), "")
        if not webhook_url:
            print("エラー: Webhook URL の環境変数が未設定です", file=sys.stderr)
            return 1
        notify(webhook_url, "🖊️ zento-watch テスト通知")
        print("送信しました")
        return 0

    if args.loop:
        while True:
            try:
                command_check(args)
            except (urllib.error.URLError, OSError) as error:
                print("エラー: %s" % error, file=sys.stderr)
            time.sleep(args.loop)

    return command_check(args)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
