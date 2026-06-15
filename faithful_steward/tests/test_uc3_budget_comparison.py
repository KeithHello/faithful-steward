"""
UC3: 檢視預算比例對比 — 完整測試。

PRD §3.3 Use Case 3:
- 主流程：切換到總覽 → 顯示本月資料 → 計算各分類實際比例 → 差異標註 → 超支紅色 ⚠
- 替代流程 A：切換週期 → 重新計算
- 例外流程 E1：該週期無任何紀錄 → EmptyState
- 例外流程 E2：某分類花費為 0 → 實際比例 0%，差異 -100%
"""

import pytest
from datetime import date, datetime
from faithful_steward.viewmodels import BudgetOverviewViewModel
from faithful_steward.models import Category, Period


class TestUC3MainFlow:
    """UC3 主流程測試"""

    def test_load_current_month_data(self, seeded_db, june_2025):
        """主流程：載入本月資料 → 7 條 CategoryRowData"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.load_data(june_2025)

        assert vm.is_empty is False
        assert len(vm.category_rows) == 7

        # 檢查總花費
        assert vm.total_spent == pytest.approx(30600.0)

        # 檢查每個分類都有 row data
        categories_seen = {row.category for row in vm.category_rows}
        assert len(categories_seen) == 7

    def test_main_flow_budget_vs_actual_comparison(self, seeded_db, june_2025):
        """主流程：檢查預算 vs 實際比例對比"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.load_data(june_2025)

        # 食行：10500/30600 ≈ 34.3%, 預算 30% → 超支約 4.3%
        food_row = next(r for r in vm.category_rows if r.category == Category.FOOD_TRANSPORT)
        assert food_row.actual_ratio == pytest.approx(10500 / 30600, rel=0.01)
        assert food_row.budget_ratio == 0.30
        assert food_row.difference > 0  # 超支
        assert food_row.is_over_budget is True

        # 十一：3000/30600 ≈ 9.8%, 預算 10% → 結餘約 0.2%
        tithe_row = next(r for r in vm.category_rows if r.category == Category.TITHE)
        assert tithe_row.actual_ratio == pytest.approx(3000 / 30600, rel=0.01)
        assert tithe_row.budget_ratio == 0.10
        assert tithe_row.difference < 0  # 結餘
        assert tithe_row.is_over_budget is False

    def test_budget_total_is_displayed(self, seeded_db, june_2025):
        """主流程：顯示預算總額"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.load_data(june_2025)

        # 本月預算 total = 30000
        assert vm.budget_total == pytest.approx(30000.0)

    def test_total_spent_displayed(self, seeded_db, june_2025):
        """主流程：顯示總花費"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.load_data(june_2025)

        expected = sum([
            3000, 3000, 4500, 5400, 2700, 10500, 1500
        ])
        assert vm.total_spent == pytest.approx(expected)


class TestUC3AlternativeFlows:
    """UC3 替代流程測試"""

    def test_alt_a_switch_to_last3months(self, seeded_db, june_2025):
        """替代 A：切換到近 3 個月（切換後目前只有 6 月有資料）"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.switch_period(Period.LAST_3_MONTHS, june_2025)

        assert vm.selected_period == Period.LAST_3_MONTHS
        assert vm.is_empty is False
        assert len(vm.category_rows) == 7

    def test_alt_a_switch_to_last6months(self, seeded_db, june_2025):
        """替代 A：切換到近 6 個月"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.switch_period(Period.LAST_6_MONTHS, june_2025)

        assert vm.selected_period == Period.LAST_6_MONTHS
        assert vm.is_empty is False

    def test_alt_a_switch_to_last12months(self, seeded_db, june_2025):
        """替代 A：切換到近 12 個月"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.switch_period(Period.LAST_12_MONTHS, june_2025)

        assert vm.selected_period == Period.LAST_12_MONTHS
        assert vm.is_empty is False

    def test_alt_a_all_periods_non_empty(self, seeded_db, june_2025):
        """所有週期切換都正常"""
        vm = BudgetOverviewViewModel(seeded_db)

        for period in Period:
            vm.switch_period(period, june_2025)
            assert vm.selected_period == period
            assert vm.is_empty is False


class TestUC3ExceptionFlows:
    """UC3 例外流程測試"""

    def test_e1_empty_no_transactions(self, dp, june_2025):
        """E1：無任何紀錄 → isEmpty=True"""
        vm = BudgetOverviewViewModel(dp)
        vm.load_data(june_2025)

        assert vm.is_empty is True
        assert len(vm.category_rows) == 0
        assert vm.total_spent == 0.0

    def test_e2_category_with_zero_spending(self, dp, june_2025):
        """E2：某分類花費為 0 → 實際比例 0%, 差異 -100%"""
        # 只記一筆：TITHE 3000，日期設在 2025-06
        dp.add_transaction(amount=3000, category=Category.TITHE,
                          created_at=datetime(2025, 6, 15, 10, 0, 0))

        vm = BudgetOverviewViewModel(dp)
        vm.load_data(june_2025)

        # 食行無花費 → 比例 0%, 差異為 -30%
        food_row = next(r for r in vm.category_rows if r.category == Category.FOOD_TRANSPORT)
        assert food_row.actual_ratio == 0.0
        assert food_row.difference < 0

    def test_e2_over_budget_flag(self, seeded_db, june_2025):
        """超支標記正確"""
        vm = BudgetOverviewViewModel(seeded_db)
        vm.load_data(june_2025)

        for row in vm.category_rows:
            if row.difference > 0.001:
                assert row.is_over_budget is True
            else:
                assert row.is_over_budget is False

    def test_no_budget_config_uses_defaults(self, dp, june_2025):
        """無預算設定時使用預設比例"""
        dp.add_transaction(amount=5000, category=Category.FOOD_TRANSPORT,
                          created_at=datetime(2025, 6, 15, 10, 0, 0))

        vm = BudgetOverviewViewModel(dp)
        vm.load_data(june_2025)

        assert vm.is_empty is False
        # 預設比例應存在
        for row in vm.category_rows:
            assert row.budget_ratio >= 0
