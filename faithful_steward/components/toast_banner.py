"""ToastBanner — 操作結果提示。

對應 iOS ToastBanner（Shared/Components/ToastBanner.swift）。
支援 success / error / warning / info 四種樣式。
"""

from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime


class ToastType(Enum):
    SUCCESS = "success"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"


@dataclass
class ToastBanner:
    """Toast 提示的資料模型"""
    message: str
    type: ToastType = ToastType.SUCCESS
    duration_seconds: float = 2.0
    created_at: datetime = field(default_factory=datetime.now)

    @classmethod
    def success(cls, message: str) -> "ToastBanner":
        return cls(message=message, type=ToastType.SUCCESS)

    @classmethod
    def error(cls, message: str) -> "ToastBanner":
        return cls(message=message, type=ToastType.ERROR)

    @classmethod
    def warning(cls, message: str) -> "ToastBanner":
        return cls(message=message, type=ToastType.WARNING)

    @classmethod
    def info(cls, message: str) -> "ToastBanner":
        return cls(message=message, type=ToastType.INFO)
