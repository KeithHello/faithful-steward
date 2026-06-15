"""Unit tests for PeriodCalculator."""

import pytest
from datetime import date
from faithful_steward.services.period_calculator import PeriodCalculator
from faithful_steward.models import Period


class TestPeriodCalculator:
    """週期計算器測試"""

    def test_month_key(self):
        assert PeriodCalculator.month_key(date(2025, 6, 15)) == "2025-06"
        assert PeriodCalculator.month_key(date(2025, 1, 1)) == "2025-01"
        assert PeriodCalculator.month_key(date(2025, 12, 31)) == "2025-12"

    def test_current_month_range(self):
        """本月：6月1日～6月15日"""
        now = date(2025, 6, 15)
        start, end = PeriodCalculator.date_range(Period.CURRENT_MONTH, now)
        assert start == date(2025, 6, 1)
        assert end == date(2025, 6, 15)

    def test_last3months_range(self):
        """近3月：4月1日～6月15日"""
        now = date(2025, 6, 15)
        start, end = PeriodCalculator.date_range(Period.LAST_3_MONTHS, now)
        assert start == date(2025, 4, 1)
        assert end == date(2025, 6, 15)

    def test_last6months_range(self):
        """近6月：1月1日～6月15日"""
        now = date(2025, 6, 15)
        start, end = PeriodCalculator.date_range(Period.LAST_6_MONTHS, now)
        assert start == date(2025, 1, 1)
        assert end == date(2025, 6, 15)

    def test_last12months_range(self):
        """近12月：去年7月1日～6月15日"""
        now = date(2025, 6, 15)
        start, end = PeriodCalculator.date_range(Period.LAST_12_MONTHS, now)
        assert start == date(2024, 7, 1)
        assert end == date(2025, 6, 15)

    def test_cross_year_range(self):
        """跨年度測試"""
        now = date(2025, 2, 15)
        start, end = PeriodCalculator.date_range(Period.LAST_6_MONTHS, now)
        assert start == date(2024, 9, 1)
        assert end == date(2025, 2, 15)

    def test_all_month_keys_current_month(self):
        now = date(2025, 6, 15)
        keys = PeriodCalculator.all_month_keys(Period.CURRENT_MONTH, now)
        assert keys == ["2025-06"]

    def test_all_month_keys_last3(self):
        now = date(2025, 6, 15)
        keys = PeriodCalculator.all_month_keys(Period.LAST_3_MONTHS, now)
        assert keys == ["2025-04", "2025-05", "2025-06"]

    def test_all_month_keys_last6(self):
        now = date(2025, 6, 15)
        keys = PeriodCalculator.all_month_keys(Period.LAST_6_MONTHS, now)
        assert keys == ["2025-01", "2025-02", "2025-03", "2025-04", "2025-05", "2025-06"]

    def test_all_month_keys_cross_year(self):
        now = date(2025, 2, 15)
        keys = PeriodCalculator.all_month_keys(Period.LAST_6_MONTHS, now)
        assert keys == [
            "2024-09", "2024-10", "2024-11", "2024-12",
            "2025-01", "2025-02",
        ]

    def test_first_day_of_month(self):
        assert PeriodCalculator.first_day_of_month(2025, 6) == date(2025, 6, 1)

    def test_last_day_of_month(self):
        assert PeriodCalculator.last_day_of_month(2025, 6) == date(2025, 6, 30)
        assert PeriodCalculator.last_day_of_month(2025, 2) == date(2025, 2, 28)
        assert PeriodCalculator.last_day_of_month(2024, 2) == date(2024, 2, 29)  # 閏年
