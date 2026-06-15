"""PeriodCalculator — 自然月週期起訖日期計算 + monthKey 格式化。

對應 iOS PeriodCalculator（Shared/Utilities/PeriodCalculator.swift）。
"""

from datetime import date
from calendar import monthrange
from ..models import Period


class PeriodCalculator:
    """自然月週期計算器"""

    @staticmethod
    def date_range(period: Period, now: date) -> tuple[date, date]:
        """
        計算週期起訖日期。

        - 本月：當月1日～今天
        - 近N月：往前推(N-1)個月的1日～今天
        """
        return period.date_range(now)

    @staticmethod
    def month_key(from_date: date) -> str:
        """
        從日期產生 monthKey（yyyy-MM 格式）。

        Example:
            date(2025, 6, 15) → "2025-06"
        """
        return from_date.strftime("%Y-%m")

    @staticmethod
    def all_month_keys(period: Period, now: date) -> list[str]:
        """
        取得該週期內的所有 monthKey。

        Example:
            Period.LAST_3_MONTHS on 2025-06-15 → ["2025-04", "2025-05", "2025-06"]
        """
        start, end = period.date_range(now)
        keys = []
        current = date(start.year, start.month, 1)

        while current <= end:
            keys.append(current.strftime("%Y-%m"))
            # 下個月
            if current.month == 12:
                current = date(current.year + 1, 1, 1)
            else:
                current = date(current.year, current.month + 1, 1)

        return keys

    @staticmethod
    def first_day_of_month(year: int, month: int) -> date:
        """取得該月第一天"""
        return date(year, month, 1)

    @staticmethod
    def last_day_of_month(year: int, month: int) -> date:
        """取得該月最後一天"""
        _, last_day = monthrange(year, month)
        return date(year, month, last_day)
