"""Unit tests for RatioCalculator."""

import pytest
from faithful_steward.services.ratio_calculator import RatioCalculator
from faithful_steward.models import Category, Transaction, BudgetConfig, InputMethod


class TestRatioCalculator:
    """比例計算器測試"""

    def test_calculate_actual_ratios_empty(self):
        """空交易列表 → 全部 0%"""
        ratios = RatioCalculator.calculate_actual_ratios([])
        assert all(v == 0.0 for v in ratios.values())

    def test_calculate_actual_ratios_distribution(self):
        """各分類比例計算"""
        txns = [
            Transaction(amount=100, category=Category.TITHE),
            Transaction(amount=200, category=Category.FOOD_TRANSPORT),
            Transaction(amount=100, category=Category.TITHE),
            Transaction(amount=300, category=Category.HOUSING),
            Transaction(amount=300, category=Category.FOOD_TRANSPORT),
        ]
        # 總額 = 1000
        # tithe: 200/1000=0.2, foodTransport: 500/1000=0.5, housing: 300/1000=0.3
        ratios = RatioCalculator.calculate_actual_ratios(txns)
        assert ratios[Category.TITHE] == pytest.approx(0.2)
        assert ratios[Category.FOOD_TRANSPORT] == pytest.approx(0.5)
        assert ratios[Category.HOUSING] == pytest.approx(0.3)
        assert ratios[Category.FILIAL] == 0.0

    def test_calculate_actual_amounts(self):
        """各分類金額計算"""
        txns = [
            Transaction(amount=500, category=Category.TITHE),
            Transaction(amount=300, category=Category.TITHE),
            Transaction(amount=1000, category=Category.HOUSING),
        ]
        amounts = RatioCalculator.calculate_actual_amounts(txns)
        assert amounts[Category.TITHE] == 800.0
        assert amounts[Category.HOUSING] == 1000.0
        assert amounts[Category.FOOD_TRANSPORT] == 0.0

    def test_calculate_budget_ratios(self):
        """從 BudgetConfig 讀取比例"""
        config = BudgetConfig.create_default("2025-06", 30000)
        ratios = RatioCalculator.calculate_budget_ratios(config)
        assert ratios[Category.TITHE] == 0.10
        assert ratios[Category.FOOD_TRANSPORT] == 0.30

    def test_calculate_difference(self):
        """差異計算：actual - budget"""
        actual = {Category.TITHE: 0.12, Category.FOOD_TRANSPORT: 0.28}
        budget = {Category.TITHE: 0.10, Category.FOOD_TRANSPORT: 0.30}
        diff = RatioCalculator.calculate_difference(actual, budget)
        assert diff[Category.TITHE] == pytest.approx(0.02)   # 超支
        assert diff[Category.FOOD_TRANSPORT] == pytest.approx(-0.02)  # 結餘

    def test_validate_total_ratio_valid(self):
        """總和 = 100% → True"""
        ratios = {cat: cat.default_ratio for cat in Category}
        assert RatioCalculator.validate_total_ratio(ratios) is True

    def test_validate_total_ratio_invalid(self):
        """總和 != 100% → False"""
        ratios = {cat: 0.05 for cat in Category}  # 7 × 5% = 35%
        assert RatioCalculator.validate_total_ratio(ratios) is False

    def test_validate_total_ratio_tolerance(self):
        """0.001 容忍度"""
        ratios = {cat: 0.10 for cat in Category}
        ratios[Category.TITHE] = 0.1005
        # 總和 = 6 × 0.10 + 0.1005 = 0.7005 → 不通過
        assert RatioCalculator.validate_total_ratio(ratios) is False

    def test_redistribute_ratios_increase(self):
        """調整某一分類比例增加 → 其餘按比例減少"""
        ratios = {cat: cat.default_ratio for cat in Category}
        # foodTransport: 0.30 → 0.35 (+5%), 其餘 6 類等比分攤 -5%
        new_ratios = RatioCalculator.redistribute_ratios(
            ratios, Category.FOOD_TRANSPORT, 0.35
        )
        assert sum(new_ratios.values()) == pytest.approx(1.0)
        assert new_ratios[Category.FOOD_TRANSPORT] == pytest.approx(0.35)

    def test_redistribute_ratios_decrease(self):
        """調整某一分類比例減少 → 其餘按比例增加"""
        ratios = {cat: cat.default_ratio for cat in Category}
        # housing: 0.20 → 0.10 (-10%), 其餘 6 類等比分攤 +10%
        new_ratios = RatioCalculator.redistribute_ratios(
            ratios, Category.HOUSING, 0.10
        )
        assert sum(new_ratios.values()) == pytest.approx(1.0)
        assert new_ratios[Category.HOUSING] == pytest.approx(0.10)

    def test_redistribute_ratios_no_change(self):
        """無變動 → 回傳原值"""
        ratios = {cat: cat.default_ratio for cat in Category}
        new_ratios = RatioCalculator.redistribute_ratios(
            ratios, Category.TITHE, 0.10
        )
        assert new_ratios == pytest.approx(ratios)

    def test_redistribute_ratios_edge_all_zero_others(self):
        """其餘全為 0 → 均分差額"""
        ratios = {cat: 0.0 for cat in Category}
        ratios[Category.TITHE] = 1.0
        new_ratios = RatioCalculator.redistribute_ratios(
            ratios, Category.TITHE, 0.5
        )
        assert sum(new_ratios.values()) == pytest.approx(1.0)
        assert new_ratios[Category.TITHE] == pytest.approx(0.5)
