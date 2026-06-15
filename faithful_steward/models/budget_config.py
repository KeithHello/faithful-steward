"""BudgetConfig data model — mirrors CoreData BudgetConfigEntity."""

from dataclasses import dataclass, field
from datetime import datetime
from uuid import UUID, uuid4
from .enums import Category
import json


@dataclass
class BudgetConfig:
    """預算設定"""

    id: UUID = field(default_factory=uuid4)
    month_key: str = ""  # "yyyy-MM"
    monthly_total: float = 0.0
    ratios: dict[Category, float] = field(default_factory=dict)
    updated_at: datetime = field(default_factory=datetime.now)

    @property
    def ratios_json(self) -> str:
        """CoreData 相容：ratios 存為 JSON 字串"""
        data = {cat.value: ratio for cat, ratio in self.ratios.items()}
        return json.dumps(data)

    @classmethod
    def from_dict(cls, data: dict) -> "BudgetConfig":
        """從資料庫 row dict 重建"""
        ratios_raw = data.get("ratios_json", "{}")
        if isinstance(ratios_raw, str):
            ratios_dict = json.loads(ratios_raw)
        else:
            ratios_dict = ratios_raw

        ratios = {Category.from_raw(k): float(v) for k, v in ratios_dict.items()}

        return cls(
            id=UUID(data["id"]) if isinstance(data["id"], str) else data["id"],
            month_key=data.get("month_key", ""),
            monthly_total=float(data.get("monthly_total", 0)),
            ratios=ratios,
            updated_at=datetime.fromisoformat(data["updated_at"]) if isinstance(data["updated_at"], str) else data["updated_at"],
        )

    def to_dict(self) -> dict:
        """轉為資料庫 row dict"""
        return {
            "id": str(self.id),
            "month_key": self.month_key,
            "monthly_total": self.monthly_total,
            "ratios_json": self.ratios_json,
            "updated_at": self.updated_at.isoformat(),
        }

    @classmethod
    def create_default(cls, month_key: str, monthly_total: float = 30000.0) -> "BudgetConfig":
        """建立預設預算設定（使用 Category.default_ratio）"""
        ratios = {cat: cat.default_ratio for cat in Category}
        return cls(
            month_key=month_key,
            monthly_total=monthly_total,
            ratios=ratios,
        )

    def get_budget_amount(self, category: Category) -> float:
        """計算特定分類的預算金額上限"""
        ratio = self.ratios.get(category, 0.0)
        return self.monthly_total * ratio
