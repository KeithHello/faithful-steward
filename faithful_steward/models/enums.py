"""Core enums for Faithful Steward — mirrors Swift Category/InputMethod/Period enums."""

from enum import Enum
from typing import Tuple
from datetime import date, timedelta
from calendar import monthrange


class Category(Enum):
    """7 大分類 enum — 不可刪除的預設分類"""

    TITHE = "tithe"
    FILIAL = "filial"
    SOCIAL = "social"
    HOUSING = "housing"
    DEBT = "debt"
    FOOD_TRANSPORT = "foodTransport"
    FLEXIBLE = "flexible"

    @property
    def display_name(self) -> str:
        """繁體中文顯示名稱"""
        names = {
            Category.TITHE: "十一奉獻",
            Category.FILIAL: "孝親費",
            Category.SOCIAL: "交際費",
            Category.HOUSING: "租房買房（住）",
            Category.DEBT: "還款存款保險投資",
            Category.FOOD_TRANSPORT: "生活必需（食行）",
            Category.FLEXIBLE: "彈性運用（衣通訊）",
        }
        return names[self]

    @property
    def short_name(self) -> str:
        """簡短名稱（語音關鍵字匹配用）"""
        names = {
            Category.TITHE: "十一",
            Category.FILIAL: "孝親",
            Category.SOCIAL: "交際",
            Category.HOUSING: "住",
            Category.DEBT: "還款",
            Category.FOOD_TRANSPORT: "食行",
            Category.FLEXIBLE: "彈性",
        }
        return names[self]

    @property
    def default_ratio(self) -> float:
        """預設比例"""
        ratios = {
            Category.TITHE: 0.10,
            Category.FILIAL: 0.10,
            Category.SOCIAL: 0.10,
            Category.HOUSING: 0.20,
            Category.DEBT: 0.10,
            Category.FOOD_TRANSPORT: 0.30,
            Category.FLEXIBLE: 0.10,
        }
        return ratios[self]

    @property
    def color_hex(self) -> str:
        """分類專屬顏色 (from DESIGN.md §2.4)"""
        colors = {
            Category.TITHE: "#C47DA7",
            Category.FILIAL: "#D4A057",
            Category.SOCIAL: "#7DAEBF",
            Category.HOUSING: "#8C7DC4",
            Category.DEBT: "#5B7FAD",
            Category.FOOD_TRANSPORT: "#5B8C5A",
            Category.FLEXIBLE: "#C47D6B",
        }
        return colors[self]

    @property
    def color_light_hex(self) -> str:
        """分類淺底色"""
        colors = {
            Category.TITHE: "#F5E8F0",
            Category.FILIAL: "#F9F0E1",
            Category.SOCIAL: "#E4F0F5",
            Category.HOUSING: "#EDE8F7",
            Category.DEBT: "#E4EBF5",
            Category.FOOD_TRANSPORT: "#E8F2E7",
            Category.FLEXIBLE: "#F5EBE7",
        }
        return colors[self]

    @classmethod
    def from_short_name(cls, text: str) -> "Category | None":
        """從簡短名稱反查分類（語音辨識用）"""
        for cat in cls:
            if cat.short_name == text:
                return cat
        return None

    @classmethod
    def from_raw(cls, raw: str) -> "Category":
        """從 rawValue 字串反查"""
        for cat in cls:
            if cat.value == raw:
                return cat
        raise ValueError(f"Unknown category raw value: {raw}")


class InputMethod(Enum):
    """輸入方式"""
    TEXT = "text"
    VOICE = "voice"


class Period(Enum):
    """檢視週期"""
    CURRENT_MONTH = "currentMonth"
    LAST_3_MONTHS = "last3Months"
    LAST_6_MONTHS = "last6Months"
    LAST_12_MONTHS = "last12Months"

    @property
    def display_name(self) -> str:
        names = {
            Period.CURRENT_MONTH: "本月",
            Period.LAST_3_MONTHS: "近 3 個月",
            Period.LAST_6_MONTHS: "近 6 個月",
            Period.LAST_12_MONTHS: "近 12 個月",
        }
        return names[self]

    @property
    def month_count(self) -> int:
        counts = {
            Period.CURRENT_MONTH: 1,
            Period.LAST_3_MONTHS: 3,
            Period.LAST_6_MONTHS: 6,
            Period.LAST_12_MONTHS: 12,
        }
        return counts[self]

    def date_range(self, now: date) -> Tuple[date, date]:
        """
        計算週期起訖日期。
        本月：當月1日～今天
        近N月：往前推(N-1)個月的1日～今天
        """
        if self == Period.CURRENT_MONTH:
            start = date(now.year, now.month, 1)
            return (start, now)

        # 往前推 month_count-1 個月
        total_months = now.year * 12 + (now.month - 1)
        start_total = total_months - (self.month_count - 1)
        start_year = start_total // 12
        start_month = (start_total % 12) + 1
        start = date(start_year, start_month, 1)
        return (start, now)


class ToastType(Enum):
    """Toast 提示類型"""
    SUCCESS = "success"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
