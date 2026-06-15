"""Transaction data model — mirrors CoreData TransactionEntity."""

from dataclasses import dataclass, field
from datetime import datetime
from uuid import UUID, uuid4
from .enums import Category, InputMethod


@dataclass
class Transaction:
    """記帳紀錄"""

    id: UUID = field(default_factory=uuid4)
    amount: float = 0.0
    category: Category | None = None
    note: str | None = None
    input_method: InputMethod = InputMethod.TEXT
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)

    @property
    def category_raw(self) -> str | None:
        """CoreData 相容：儲存為 rawValue 字串"""
        return self.category.value if self.category else None

    @classmethod
    def from_dict(cls, data: dict) -> "Transaction":
        """從資料庫 row dict 重建"""
        return cls(
            id=UUID(data["id"]) if isinstance(data["id"], str) else data["id"],
            amount=float(data["amount"]),
            category=Category.from_raw(data["category_raw"]) if data.get("category_raw") else None,
            note=data.get("note"),
            input_method=InputMethod(data["input_method_raw"]) if data.get("input_method_raw") else InputMethod.TEXT,
            created_at=datetime.fromisoformat(data["created_at"]) if isinstance(data["created_at"], str) else data["created_at"],
            updated_at=datetime.fromisoformat(data["updated_at"]) if isinstance(data["updated_at"], str) else data["updated_at"],
        )

    def to_dict(self) -> dict:
        """轉為資料庫 row dict"""
        return {
            "id": str(self.id),
            "amount": self.amount,
            "category_raw": self.category_raw,
            "note": self.note,
            "input_method_raw": self.input_method.value,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }
