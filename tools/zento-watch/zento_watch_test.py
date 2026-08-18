#!/usr/bin/env python3
"""zento_watch のロジックテスト。ネットワークには出ない（http_get を差し替える）。

実行: python3 tools/zento-watch/zento_watch_test.py
"""

import argparse
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import zento_watch as zw

SINGLE = {
    "id": "signature-single",
    "label": "単色",
    "max_price": 4500,
    "match": {
        "all_of": [["ゼント", "zento"], ["シグニチャー", "シグネチャー", "signature"]],
        "none_of": ["3色", "三色", "替芯"],
    },
}
MULTI = {
    "id": "signature-multi",
    "label": "3色",
    "max_price": 7000,
    "match": {
        "all_of": [["ゼント", "zento"], ["シグニチャー", "シグネチャー", "signature"], ["3色", "三色"]],
        "none_of": ["替芯"],
    },
}


class TestNormalize(unittest.TestCase):
    def test_absorbs_width_case_and_space(self):
        self.assertEqual(zw.normalize("ＵＮＩ　ＺＥＮＴＯ"), "unizento")
        self.assertEqual(zw.normalize("３色"), "3色")
        self.assertEqual(zw.normalize("ｼｸﾞﾆﾁｬｰ"), "シグニチャー")


class TestMatchesProduct(unittest.TestCase):
    def test_single_matches_plain_signature(self):
        self.assertTrue(zw.matches_product(SINGLE, "三菱鉛筆 ユニボール ゼント シグニチャーモデル 0.5mm"))

    def test_single_rejects_three_color(self):
        self.assertFalse(zw.matches_product(SINGLE, "uniball ZENTO シグニチャーモデル 3色ボールペン"))

    def test_single_rejects_full_width_three_color(self):
        self.assertFalse(zw.matches_product(SINGLE, "ユニボール ゼント シグニチャー ３色"))

    def test_single_rejects_refill(self):
        self.assertFalse(zw.matches_product(SINGLE, "ユニボール ゼント シグニチャー 替芯 0.5"))

    def test_single_rejects_non_signature(self):
        self.assertFalse(zw.matches_product(SINGLE, "三菱鉛筆 ユニボール ゼント 0.5mm 黒"))

    def test_multi_requires_three_color(self):
        self.assertTrue(zw.matches_product(MULTI, "uniball ZENTO シグニチャーモデル 3色ボールペン"))
        self.assertFalse(zw.matches_product(MULTI, "uniball ZENTO シグニチャーモデル 0.5"))

    def test_alphabet_only_title_matches(self):
        self.assertTrue(zw.matches_product(SINGLE, "Mitsubishi uniball ZENTO Signature Model"))

    def test_katakana_variant_matches(self):
        self.assertTrue(zw.matches_product(SINGLE, "ユニボール ゼント シグネチャーモデル"))


class TestPriceFilter(unittest.TestCase):
    def test_rejects_resale_price(self):
        self.assertFalse(zw.within_price(SINGLE, 12000))

    def test_accepts_retail_price(self):
        self.assertTrue(zw.within_price(SINGLE, 3300))

    def test_unknown_price_passes(self):
        self.assertTrue(zw.within_price(SINGLE, None))


class TestDetectStock(unittest.TestCase):
    def test_sold_out_wins_over_cart_button(self):
        text = "カートに入れる SOLD OUT 入荷お知らせ"
        self.assertIs(zw.detect_stock(text, ["SOLD OUT"], ["カートに入れる"]), False)

    def test_in_stock(self):
        self.assertIs(zw.detect_stock("在庫あり カートに入れる", ["SOLD OUT"], ["カートに入れる"]), True)

    def test_unknown_when_no_marker(self):
        self.assertIsNone(zw.detect_stock("準備中です", ["SOLD OUT"], ["カートに入れる"]))


class TestVisibleText(unittest.TestCase):
    def test_strips_script_and_entities(self):
        html = '<div><script>var soldOut = "SOLD OUT";</script><p>&yen;3,300 在庫あり</p></div>'
        text = zw.visible_text(html)
        self.assertNotIn("SOLD OUT", text)
        self.assertIn("在庫あり", text)
        self.assertIn("¥", text)


class TestDecodeBody(unittest.TestCase):
    def test_uses_meta_charset_when_header_missing(self):
        raw = '<meta charset="shift_jis">在庫あり'.encode("shift_jis")
        self.assertIn("在庫あり", zw.decode_body(raw, None))

    def test_header_charset_wins(self):
        self.assertIn("在庫あり", zw.decode_body("在庫あり".encode("utf-8"), "utf-8"))


class TestDecideNotifications(unittest.TestCase):
    def setUp(self):
        self.offer = {
            "source": "rakuten", "code": "shop:item1", "title": "ゼント シグニチャー",
            "price": 3300, "url": "https://example.test/i", "shop": "文具店",
            "product_id": "signature-single", "in_stock": True,
        }

    def test_first_sighting_notifies(self):
        state = {"offers": {}}
        self.assertEqual(len(zw.decide_notifications([self.offer], state, 6, 1000.0)), 1)

    def test_second_run_is_silent(self):
        state = {"offers": {}}
        zw.decide_notifications([self.offer], state, 6, 1000.0)
        self.assertEqual(zw.decide_notifications([self.offer], state, 6, 2000.0), [])

    def test_disappearing_then_returning_notifies_again(self):
        state = {"offers": {}}
        zw.decide_notifications([self.offer], state, 6, 1000.0)
        zw.decide_notifications([], state, 6, 2000.0)  # 売り切れて検索結果から消えた
        self.assertFalse(state["offers"]["rakuten:shop:item1"]["in_stock"])
        later = 1000.0 + 7 * 3600
        self.assertEqual(len(zw.decide_notifications([self.offer], state, 6, later)), 1)

    def test_cooldown_suppresses_flapping(self):
        state = {"offers": {}}
        zw.decide_notifications([self.offer], state, 6, 1000.0)
        zw.decide_notifications([], state, 6, 1100.0)
        self.assertEqual(zw.decide_notifications([self.offer], state, 6, 1200.0), [])

    def test_unknown_stock_does_not_touch_previous_value(self):
        state = {"offers": {"page:x": {"in_stock": True, "notified_at": 500.0, "last_seen": 500.0}}}
        unknown = dict(self.offer, source="page", code="x", in_stock=None)
        self.assertEqual(zw.decide_notifications([unknown], state, 6, 1000.0), [])
        self.assertTrue(state["offers"]["page:x"]["in_stock"])

    def test_stale_records_are_pruned(self):
        old = 1000.0
        state = {"offers": {"rakuten:gone": {"in_stock": True, "last_seen": old}}}
        zw.decide_notifications([], state, 6, old + (zw.STALE_RECORD_DAYS + 1) * 86400)
        self.assertNotIn("rakuten:gone", state["offers"])


class TestPayload(unittest.TestCase):
    def test_discord_uses_content(self):
        payload = zw.build_payload("https://discord.com/api/webhooks/1/abc", "hi")
        self.assertEqual(payload["content"], "hi")

    def test_slack_uses_text(self):
        payload = zw.build_payload("https://hooks.slack.com/services/T/B/x", "hi")
        self.assertEqual(payload["text"], "hi")

    def test_discord_content_is_truncated(self):
        payload = zw.build_payload("https://discord.com/api/webhooks/1/abc", "あ" * 3000)
        self.assertLessEqual(len(payload["content"]), 1900)


class TestFormatMessage(unittest.TestCase):
    def test_groups_by_product_and_shows_url(self):
        offers = [{
            "source": "yahoo", "code": "c", "title": "ゼント シグニチャー", "price": 3300,
            "url": "https://example.test/item", "shop": "ぶんぐ屋",
            "product_id": "signature-single", "in_stock": True,
        }]
        message = zw.format_message(offers, [SINGLE, MULTI])
        self.assertIn("単色", message)
        self.assertIn("¥3,300", message)
        self.assertIn("https://example.test/item", message)
        self.assertIn("ぶんぐ屋", message)


class TestFetchers(unittest.TestCase):
    def setUp(self):
        self._original = zw.http_get

    def tearDown(self):
        zw.http_get = self._original

    def stub(self, payload):
        zw.http_get = lambda url, headers=None: json.dumps(payload)

    def test_rakuten_unwraps_item_and_filters(self):
        self.stub({"Items": [
            {"Item": {"itemName": "ユニボール ゼント シグニチャーモデル", "itemCode": "a:1",
                      "itemPrice": 3300, "itemUrl": "https://r.test/1", "shopName": "文具A"}},
            {"Item": {"itemName": "ユニボール ゼント 通常モデル", "itemCode": "a:2",
                      "itemPrice": 550, "itemUrl": "https://r.test/2", "shopName": "文具A"}},
        ]})
        offers = zw.fetch_rakuten(SINGLE, "dummy")
        self.assertEqual([o["code"] for o in offers], ["a:1"])
        self.assertTrue(offers[0]["in_stock"])

    def test_rakuten_accepts_flat_items(self):
        self.stub({"Items": [{"itemName": "ゼント シグニチャー", "itemCode": "b:1",
                              "itemPrice": 3300, "itemUrl": "https://r.test/1", "shopName": "文具B"}]})
        self.assertEqual(len(zw.fetch_rakuten(SINGLE, "dummy")), 1)

    def test_yahoo_maps_seller_name(self):
        self.stub({"hits": [{"name": "uniball ZENTO シグニチャーモデル", "code": "y1", "price": 3300,
                             "url": "https://y.test/1", "seller": {"name": "ヤフ文具"}}]})
        offers = zw.fetch_yahoo(SINGLE, "dummy")
        self.assertEqual(offers[0]["shop"], "ヤフ文具")

    def test_empty_response_is_not_an_error(self):
        self.stub({"hits": None})
        self.assertEqual(zw.fetch_yahoo(SINGLE, "dummy"), [])


class TestCollectOffers(unittest.TestCase):
    def test_missing_app_id_is_reported_not_fatal(self):
        config = {"products": [SINGLE], "sources": {"rakuten": {"enabled": True, "app_id_env": "ZW_TEST_ABSENT"}}}
        os.environ.pop("ZW_TEST_ABSENT", None)
        offers, failures = zw.collect_offers(config, lambda _: None)
        self.assertEqual(offers, [])
        self.assertEqual(len(failures), 1)
        self.assertIn("ZW_TEST_ABSENT", failures[0])


class TestConfigExample(unittest.TestCase):
    def test_example_config_is_valid(self):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.example.json")
        config = zw.load_config(path)
        ids = [product["id"] for product in config["products"]]
        self.assertEqual(ids, ["signature-single", "signature-multi"])

    def test_example_products_separate_single_and_multi(self):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.example.json")
        single, multi = zw.load_config(path)["products"]
        title = "uniball ZENTO シグニチャーモデル 3色ボールペン 回転繰り出し式"
        self.assertFalse(zw.matches_product(single, title))
        self.assertTrue(zw.matches_product(multi, title))


class TestCommandCheckEndToEnd(unittest.TestCase):
    """設定読み込みから通知送信までを、HTTP だけ差し替えて通す。"""

    def setUp(self):
        self._get, self._post = zw.http_get, zw.http_post_json
        self.sent = []
        zw.http_post_json = lambda url, payload: self.sent.append((url, payload)) or 204
        zw.http_get = lambda url, headers=None: json.dumps({"Items": [
            {"Item": {"itemName": "三菱鉛筆 ユニボール ゼント シグニチャーモデル 0.5",
                      "itemCode": "shop:1", "itemPrice": 3300,
                      "itemUrl": "https://r.test/1", "shopName": "文具C"}},
            {"Item": {"itemName": "ユニボール ゼント シグニチャー 転売品",
                      "itemCode": "shop:2", "itemPrice": 19800,
                      "itemUrl": "https://r.test/2", "shopName": "転売C"}},
        ]})
        self.tmp = tempfile.mkdtemp()
        self.config_path = os.path.join(self.tmp, "config.json")
        with open(self.config_path, "w", encoding="utf-8") as handle:
            json.dump({
                "products": [SINGLE],
                "sources": {"rakuten": {"enabled": True, "app_id_env": "ZW_TEST_RAKUTEN"}},
                "notify": {"webhook_url_env": "ZW_TEST_WEBHOOK", "cooldown_hours": 6},
            }, handle)
        os.environ["ZW_TEST_RAKUTEN"] = "dummy-app-id"
        os.environ["ZW_TEST_WEBHOOK"] = "https://discord.com/api/webhooks/1/abc"

    def tearDown(self):
        zw.http_get, zw.http_post_json = self._get, self._post
        shutil.rmtree(self.tmp, ignore_errors=True)
        os.environ.pop("ZW_TEST_RAKUTEN", None)
        os.environ.pop("ZW_TEST_WEBHOOK", None)

    def args(self, dry_run=False):
        return argparse.Namespace(
            config=self.config_path, state=os.path.join(self.tmp, "state.json"),
            dry_run=dry_run, verbose=False,
        )

    def test_notifies_once_then_stays_quiet(self):
        self.assertEqual(zw.command_check(self.args()), 0)
        self.assertEqual(len(self.sent), 1)
        url, payload = self.sent[0]
        self.assertIn("https://r.test/1", payload["content"])
        self.assertNotIn("https://r.test/2", payload["content"])  # 転売価格は除外
        self.assertEqual(zw.command_check(self.args()), 0)
        self.assertEqual(len(self.sent), 1)

    def test_dry_run_sends_nothing_and_keeps_no_state(self):
        self.assertEqual(zw.command_check(self.args(dry_run=True)), 0)
        self.assertEqual(self.sent, [])
        self.assertFalse(os.path.exists(os.path.join(self.tmp, "state.json")))


if __name__ == "__main__":
    unittest.main(verbosity=2)
