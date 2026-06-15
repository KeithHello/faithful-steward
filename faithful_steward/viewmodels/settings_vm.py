"""SettingsViewModel — 設定 ViewModel。

對應 iOS SettingsViewModel（Features/Settings/SettingsViewModel.swift）。
管理月預算總額、比例滑桿、總和驗證、儲存。
"""

from datetime import date
from ..models import Category, BudgetConfig
from ..storage import DataProvider
from ..services import RatioCalculator, PeriodCalculator


class SettingsViewModel:
    """
    設定 ViewModel。
    管理 monthlyTotalText / ratios / isValid / isSaved。
    """

    def __init__(self, data_provider: DataProvider):
        self._dp = data_provider
        self._rc = RatioCalculator()
        self._pc = PeriodCalculator()

        # Published state
        self.monthly_total_text: str = ""
        self.monthly_total: float = 0.0
        self.ratios: dict[Category, float] = {cat: cat.default_ratio for cat in Category}
        self.is_valid: bool = True
        self.is_saved: bool = False
        self.error_message: str | None = None

    def load_config(self, now: date | None = None):
        """
        載入設定。

        優先：本月已有設定 → 顯示
        否則：沿用最新設定 → 若無則用預設值
        """
        if now is None:
            now = date.today()

        month_key = self._pc.month_key(now)

        # 查本月設定
        config = self._dp.fetch_budget_config(month_key)

        if config is None:
            # 查最新設定
            config = self._dp.fetch_latest_budget_config()

        if config:
            self.monthly_total = config.monthly_total
            self.monthly_total_text = str(int(config.monthly_total))
            self.ratios = dict(config.ratios)
        else:
            # 使用預設值
            self.monthly_total = 30000.0
            self.monthly_total_text = "30000"
            self.ratios = {cat: cat.default_ratio for cat in Category}

        self.is_saved = False
        self.is_valid = self._rc.validate_total_ratio(self.ratios)
        self.error_message = None

    def set_monthly_total(self, text: str):
        """設定月預算總額文字"""
        self.monthly_total_text = text
        self.error_message = None

        try:
            value = float(text)
            if value <= 0:
                self.monthly_total = 0.0
                self.is_valid = False
                self.error_message = "請輸入有效的月預算金額"
                return
            self.monthly_total = value
        except ValueError:
            self.monthly_total = 0.0
            self.is_valid = False
            self.error_message = "請輸入有效的月預算金額"
            return

        self.is_valid = self._rc.validate_total_ratio(self.ratios)

    def update_ratio(self, category: Category, new_value: float):
        """
        更新某一分類的比例，自動重分配其餘分類。
        對應 RatioSliderList 滑桿拖動行為。
        """
        self.error_message = None
        self.ratios = self._rc.redistribute_ratios(
            self.ratios, category, new_value
        )
        self.is_valid = self._rc.validate_total_ratio(self.ratios)

        if not self.is_valid:
            self.error_message = "比例總和須為 100%"

    def save_config(self, now: date | None = None) -> BudgetConfig:
        """
        儲存設定（UC4 步驟 6）。

        Raises:
            ValueError: 驗證失敗時拋出
        """
        if now is None:
            now = date.today()

        # 驗證
        if self.monthly_total <= 0:
            raise ValueError("請輸入有效的月預算金額")

        if not self._rc.validate_total_ratio(self.ratios):
            raise ValueError("比例總和須為 100%")

        month_key = self._pc.month_key(now)

        config = self._dp.save_budget_config(
            monthly_total=self.monthly_total,
            ratios=self.ratios,
            month_key=month_key,
        )

        self.is_saved = True
        self.error_message = None
        return config
