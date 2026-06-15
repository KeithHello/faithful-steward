"""Unit tests for AmountParser."""

import pytest
from faithful_steward.services.amount_parser import AmountParser


class TestAmountParserArabic:
    """阿拉伯數字解析測試"""

    def test_simple_integer(self):
        assert AmountParser.parse("250") == 250.0

    def test_with_decimal(self):
        assert AmountParser.parse("12.5") == 12.5

    def test_with_currency_prefix(self):
        assert AmountParser.parse("NT$ 500") == 500.0

    def test_embedded_in_text(self):
        assert AmountParser.parse("食行 250") == 250.0

    def test_multiple_numbers_takes_first(self):
        assert AmountParser.parse("食行 250 交際 100") == 250.0

    def test_no_number_returns_none(self):
        assert AmountParser.parse("吃晚餐") is None

    def test_empty_string_returns_none(self):
        assert AmountParser.parse("") is None

    def test_none_returns_none(self):
        assert AmountParser.parse(None) is None

    def test_only_whitespace_returns_none(self):
        assert AmountParser.parse("   ") is None

    def test_zero(self):
        assert AmountParser.parse("0") == 0.0


class TestAmountParserChinese:
    """繁體中文口語數字解析測試"""

    def test_simple_two_hundred_fifty(self):
        """「兩百五」→ 250"""
        assert AmountParser.parse("兩百五") == 250.0

    def test_voice_format_food(self):
        """「食行兩百五」→ 250"""
        assert AmountParser.parse("食行兩百五") == 250.0

    def test_with_unit_kuai(self):
        """「三百塊」→ 300"""
        assert AmountParser.parse("三百塊") == 300.0

    def test_thousand_two(self):
        """「一千二」→ 1200"""
        assert AmountParser.parse("一千二") == 1200.0

    def test_two_thousand_three_hundred(self):
        """「兩千三百」→ 2300"""
        assert AmountParser.parse("兩千三百") == 2300.0

    def test_ten(self):
        """「十」→ 10"""
        assert AmountParser.parse("十") == 10.0

    def test_one_hundred(self):
        """「一百」→ 100"""
        assert AmountParser.parse("一百") == 100.0

    def test_voice_real_example_1(self):
        """「食行兩百五」真實語音"""
        assert AmountParser.parse("食行兩百五") == 250.0

    def test_voice_real_example_2(self):
        """「交際一千」"""
        assert AmountParser.parse("交際一千") == 1000.0

    def test_voice_real_example_3(self):
        """「兩百」→ 200 （分類關鍵字已由 SpeechParser 剝離）"""
        assert AmountParser.parse("兩百") == 200.0

    def test_no_chinese_number(self):
        """純文字無數字"""
        assert AmountParser.parse("吃晚餐花了好多錢") is None

    def test_ten_thousand(self):
        """「一萬二」→ 12000"""
        assert AmountParser.parse("一萬二") == 12000.0
