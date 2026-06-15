"""EmptyStateView — 空資料狀態。

對應 iOS EmptyStateView（Shared/Components/EmptyStateView.swift）。
"""

from dataclasses import dataclass


@dataclass
class EmptyStateView:
    """空資料狀態的資料模型"""
    message: str = "暫無紀錄，開始記第一筆吧！"
    icon: str = "📋"

    @classmethod
    def no_transactions(cls) -> "EmptyStateView":
        return cls(
            message="暫無紀錄，開始記第一筆吧！",
            icon="📋",
        )

    @classmethod
    def no_budget_config(cls) -> "EmptyStateView":
        return cls(
            message="尚未設定預算，請至設定頁設定",
            icon="⚙️",
        )
