"""Unit tests for SpeechParser."""

import pytest
from faithful_steward.services.speech_parser import SpeechParser
from faithful_steward.models import Category


class TestSpeechParser:
    """語音辨識解析測試"""

    def test_both_amount_and_category(self):
        """「食行兩百五」→ amount=250, category=FOOD_TRANSPORT"""
        result = SpeechParser.parse("食行兩百五")
        assert result.amount == 250.0
        assert result.category == Category.FOOD_TRANSPORT

    def test_amount_only(self):
        """「三百塊」→ amount=300, category=None"""
        result = SpeechParser.parse("三百塊")
        assert result.amount == 300.0
        assert result.category is None

    def test_category_only(self):
        """「十一」→ amount=None, category=TITHE"""
        result = SpeechParser.parse("十一")
        assert result.amount is None
        assert result.category == Category.TITHE

    def test_empty_text(self):
        result = SpeechParser.parse("")
        assert result.amount is None
        assert result.category is None
        assert result.raw_text == ""

    def test_no_match(self):
        """完全無法辨識"""
        result = SpeechParser.parse("今天天氣很好")
        assert result.amount is None
        assert result.category is None

    def test_category_tithe(self):
        result = SpeechParser.parse("十一")
        assert result.category == Category.TITHE

    def test_category_filial(self):
        result = SpeechParser.parse("孝親三百")
        assert result.category == Category.FILIAL
        assert result.amount == 300.0

    def test_category_social(self):
        result = SpeechParser.parse("交際一千二")
        assert result.category == Category.SOCIAL
        assert result.amount == 1200.0

    def test_category_housing(self):
        result = SpeechParser.parse("住兩千")
        assert result.category == Category.HOUSING
        assert result.amount == 2000.0

    def test_category_debt(self):
        result = SpeechParser.parse("還款五百")
        assert result.category == Category.DEBT
        assert result.amount == 500.0

    def test_category_flexible(self):
        result = SpeechParser.parse("彈性一百")
        assert result.category == Category.FLEXIBLE
        assert result.amount == 100.0

    def test_has_amount_property(self):
        result = SpeechParser.parse("食行兩百五")
        assert result.has_amount is True

        result2 = SpeechParser.parse("食行")
        assert result2.has_amount is False

    def test_has_category_property(self):
        result = SpeechParser.parse("食行兩百五")
        assert result.has_category is True

        result2 = SpeechParser.parse("三百塊")
        assert result2.has_category is False

    def test_match_category_classmethod(self):
        assert SpeechParser.match_category("食行") == Category.FOOD_TRANSPORT
        assert SpeechParser.match_category("十一") == Category.TITHE
        assert SpeechParser.match_category("隨便") is None
