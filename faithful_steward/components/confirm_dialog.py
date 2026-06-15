"""ConfirmDialog — 確認彈窗邏輯。

對應 iOS ConfirmDialog（Shared/Components/ConfirmDialog.swift）。
在 Python 中為純邏輯層，UI 由前端框架實現。
"""

from dataclasses import dataclass
from ..models import Category


@dataclass
class ConfirmDialog:
    """確認對話框的資料模型"""
    amount: float = 0.0
    category: Category | None = None
    title: str = "確認記帳"
    message: str = ""
    confirm_label: str = "確認"
    cancel_label: str = "取消"

    @classmethod
    def for_transaction(
        cls,
        amount: float,
        category: Category,
        confirm_label: str = "確認",
        cancel_label: str = "取消",
    ) -> "ConfirmDialog":
        """建立記帳確認對話框"""
        return cls(
            amount=amount,
            category=category,
            title="確認記帳",
            message=f"NT$ {amount:,.0f} → {category.display_name}",
            confirm_label=confirm_label,
            cancel_label=cancel_label,
        )
