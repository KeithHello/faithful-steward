"""ParsedResult — SpeechParser 解析結果"""

from dataclasses import dataclass
from .enums import Category


@dataclass
class ParsedResult:
    """語音辨識解析結果"""
    amount: float | None = None
    category: Category | None = None
    raw_text: str = ""

    @property
    def has_amount(self) -> bool:
        return self.amount is not None and self.amount > 0

    @property
    def has_category(self) -> bool:
        return self.category is not None
