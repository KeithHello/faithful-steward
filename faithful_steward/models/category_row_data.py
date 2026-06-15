"""CategoryRowData — BudgetOverviewViewModel 使用的結構體"""

from dataclasses import dataclass
from .enums import Category


@dataclass
class CategoryRowData:
    """單一分類的預算對比資料行"""
    category: Category
    actual_ratio: float = 0.0
    budget_ratio: float = 0.0
    difference: float = 0.0
    actual_amount: float = 0.0
    budget_amount: float = 0.0

    @property
    def is_over_budget(self) -> bool:
        """實際比例是否超出預算"""
        return self.difference > 0.001

    @property
    def difference_pct(self) -> float:
        """差異百分比 (-1.0 ~ +1.0)"""
        return self.difference

    @property
    def display_name(self) -> str:
        return self.category.display_name

    @property
    def color_hex(self) -> str:
        return self.category.color_hex
