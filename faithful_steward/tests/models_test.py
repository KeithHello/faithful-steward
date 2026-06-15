"""Unit tests for data models (enums, Transaction, BudgetConfig, etc.)."""

import pytest
from datetime import date
from faithful_steward.models import (
    Category, InputMethod, Period, ToastType,
    Transaction, BudgetConfig, ParsedResult, CategoryRowData,
)


class TestCategoryEnum:
    """Category enum 測試"""

    def test_all_cases_count(self):
        assert len(list(Category)) == 7

    def test_display_names(self):
        assert Category.TITHE.display_name == "十一奉獻"
        assert Category.FILIAL.display_name == "孝親費"
        assert Category.SOCIAL.display_name == "交際費"
        assert Category.HOUSING.display_name == "租房買房（住）"
        assert Category.DEBT.display_name == "還款存款保險投資"
        assert Category.FOOD_TRANSPORT.display_name == "生活必需（食行）"
        assert Category.FLEXIBLE.display_name == "彈性運用（衣通訊）"

    def test_short_names(self):
        assert Category.TITHE.short_name == "十一"
        assert Category.FILIAL.short_name == "孝親"
        assert Category.HOUSING.short_name == "住"

    def test_default_ratios_sum_to_one(self):
        total = sum(cat.default_ratio for cat in Category)
        assert total == pytest.approx(1.0)

    def test_default_ratio_values(self):
        assert Category.TITHE.default_ratio == 0.10
        assert Category.HOUSING.default_ratio == 0.20
        assert Category.FOOD_TRANSPORT.default_ratio == 0.30

    def test_from_short_name(self):
        assert Category.from_short_name("食行") == Category.FOOD_TRANSPORT
        assert Category.from_short_name("十一") == Category.TITHE
        assert Category.from_short_name("不存在") is None

    def test_from_raw(self):
        assert Category.from_raw("tithe") == Category.TITHE
        assert Category.from_raw("foodTransport") == Category.FOOD_TRANSPORT
        with pytest.raises(ValueError):
            Category.from_raw("invalid")

    def test_color_hex(self):
        assert Category.TITHE.color_hex == "#C47DA7"
        assert Category.FOOD_TRANSPORT.color_hex == "#5B8C5A"

    def test_color_light_hex(self):
        assert Category.TITHE.color_light_hex == "#F5E8F0"


class TestPeriodEnum:
    """Period enum 測試"""

    def test_display_names(self):
        assert Period.CURRENT_MONTH.display_name == "本月"
        assert Period.LAST_3_MONTHS.display_name == "近 3 個月"
        assert Period.LAST_6_MONTHS.display_name == "近 6 個月"
        assert Period.LAST_12_MONTHS.display_name == "近 12 個月"

    def test_month_count(self):
        assert Period.CURRENT_MONTH.month_count == 1
        assert Period.LAST_3_MONTHS.month_count == 3
        assert Period.LAST_6_MONTHS.month_count == 6
        assert Period.LAST_12_MONTHS.month_count == 12

    def test_date_range_current_month(self):
        now = date(2025, 6, 15)
        start, end = Period.CURRENT_MONTH.date_range(now)
        assert start == date(2025, 6, 1)
        assert end == date(2025, 6, 15)


class TestTransactionModel:
    """Transaction model 測試"""

    def test_create_minimal(self):
        txn = Transaction(amount=250, category=Category.FOOD_TRANSPORT)
        assert txn.amount == 250.0
        assert txn.category == Category.FOOD_TRANSPORT
        assert txn.note is None
        assert txn.input_method == InputMethod.TEXT
        assert txn.id is not None

    def test_category_raw(self):
        txn = Transaction(category=Category.TITHE)
        assert txn.category_raw == "tithe"

    def test_to_dict_and_from_dict(self):
        txn = Transaction(
            amount=500,
            category=Category.HOUSING,
            note="房租",
            input_method=InputMethod.VOICE,
        )
        d = txn.to_dict()
        restored = Transaction.from_dict(d)
        assert restored.amount == 500.0
        assert restored.category == Category.HOUSING
        assert restored.note == "房租"
        assert restored.input_method == InputMethod.VOICE
        assert str(restored.id) == str(txn.id)


class TestBudgetConfigModel:
    """BudgetConfig model 測試"""

    def test_create_default(self):
        config = BudgetConfig.create_default("2025-06", 30000)
        assert config.month_key == "2025-06"
        assert config.monthly_total == 30000.0
        assert config.ratios[Category.TITHE] == 0.10

    def test_ratios_json(self):
        config = BudgetConfig.create_default("2025-06", 30000)
        json_str = config.ratios_json
        assert "tithe" in json_str
        assert "foodTransport" in json_str

    def test_to_dict_and_from_dict(self):
        config = BudgetConfig.create_default("2025-06", 35000)
        d = config.to_dict()
        restored = BudgetConfig.from_dict(d)
        assert restored.month_key == "2025-06"
        assert restored.monthly_total == 35000.0
        assert restored.ratios[Category.TITHE] == 0.10

    def test_get_budget_amount(self):
        config = BudgetConfig.create_default("2025-06", 30000)
        assert config.get_budget_amount(Category.TITHE) == 3000.0
        assert config.get_budget_amount(Category.HOUSING) == 6000.0
        assert config.get_budget_amount(Category.FOOD_TRANSPORT) == 9000.0


class TestParsedResult:
    """ParsedResult model 測試"""

    def test_has_amount(self):
        r = ParsedResult(amount=250)
        assert r.has_amount is True

        r2 = ParsedResult(amount=0)
        assert r2.has_amount is False

        r3 = ParsedResult()
        assert r3.has_amount is False

    def test_has_category(self):
        r = ParsedResult(category=Category.TITHE)
        assert r.has_category is True

        r2 = ParsedResult()
        assert r2.has_category is False


class TestCategoryRowData:
    """CategoryRowData model 測試"""

    def test_is_over_budget(self):
        row = CategoryRowData(
            category=Category.TITHE,
            actual_ratio=0.12,
            budget_ratio=0.10,
            difference=0.02,
        )
        assert row.is_over_budget is True

        row2 = CategoryRowData(
            category=Category.FOOD_TRANSPORT,
            actual_ratio=0.28,
            budget_ratio=0.30,
            difference=-0.02,
        )
        assert row2.is_over_budget is False

    def test_display_properties(self):
        row = CategoryRowData(category=Category.TITHE)
        assert row.display_name == "十一奉獻"
        assert row.color_hex == "#C47DA7"
