"""BudgetOverviewViewModel — 總覽 ViewModel。

對應 iOS BudgetOverviewViewModel（Features/BudgetOverview/BudgetOverviewViewModel.swift）。
管理週期切換、交易聚合、比例計算、CategoryRowData 組裝。
"""

from datetime import date
from ..models import Category, Period, CategoryRowData, BudgetConfig
from ..storage import DataProvider
from ..services import RatioCalculator, PeriodCalculator


class BudgetOverviewViewModel:
    """
    總覽 ViewModel。
    管理 selectedPeriod / categoryRows / totalSpent / budgetTotal / isEmpty。
    """

    def __init__(self, data_provider: DataProvider):
        self._dp = data_provider
        self._rc = RatioCalculator()
        self._pc = PeriodCalculator()

        # Published state
        self.selected_period: Period = Period.CURRENT_MONTH
        self.category_rows: list[CategoryRowData] = []
        self.total_spent: float = 0.0
        self.budget_total: float = 0.0
        self.is_empty: bool = True

    def load_data(self, now: date | None = None):
        """
        載入當前週期的資料。

        Args:
            now: 當前日期（預設 today）
        """
        if now is None:
            now = date.today()

        # 1. 取得日期範圍
        start, end = self._pc.date_range(self.selected_period, now)

        # 2. 查詢交易
        transactions = self._dp.fetch_transactions(start, end)

        if not transactions:
            self.is_empty = True
            self.category_rows = []
            self.total_spent = 0.0
            self.budget_total = 0.0
            return

        self.is_empty = False

        # 3. 計算實際比例與金額
        actual_ratios = self._rc.calculate_actual_ratios(transactions)
        actual_amounts = self._rc.calculate_actual_amounts(transactions)
        self.total_spent = sum(actual_amounts.values())

        # 4. 取得該週期所有月份的預算設定並匯總
        month_keys = self._pc.all_month_keys(self.selected_period, now)
        budget_ratios_agg: dict[Category, float] = {cat: 0.0 for cat in Category}

        configs: list[BudgetConfig] = []
        for mk in month_keys:
            config = self._dp.fetch_budget_config(mk)
            if config:
                configs.append(config)

        if configs:
            # 取所有 config 的比例平均值（或最近一個月的）
            # 根據架構文檔：取最近一個月的 budget config 作為基準
            latest_config = configs[-1]  # month_key 升序，最後一個是最新的
            budget_ratios_agg = self._rc.calculate_budget_ratios(latest_config)
            self.budget_total = latest_config.monthly_total * len(month_keys)
        else:
            # 無設定 → 使用預設比例
            budget_ratios_agg = {cat: cat.default_ratio for cat in Category}
            self.budget_total = 0.0

        # 5. 計算差異
        differences = self._rc.calculate_difference(actual_ratios, budget_ratios_agg)

        # 6. 組裝 CategoryRowData
        self.category_rows = []
        for cat in Category:
            row = CategoryRowData(
                category=cat,
                actual_ratio=actual_ratios.get(cat, 0.0),
                budget_ratio=budget_ratios_agg.get(cat, 0.0),
                difference=differences.get(cat, 0.0),
                actual_amount=actual_amounts.get(cat, 0.0),
                budget_amount=self.budget_total * budget_ratios_agg.get(cat, 0.0),
            )
            self.category_rows.append(row)

    def switch_period(self, period: Period, now: date | None = None):
        """切換週期並重新載入"""
        self.selected_period = period
        self.load_data(now)
