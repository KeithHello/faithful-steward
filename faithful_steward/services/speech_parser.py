"""SpeechParser — 從語音辨識文字中提取金額與分類。

對應 iOS SpeechParser（Core/Speech/SpeechParser.swift）。
"""

from typing import Optional
from ..models import Category, ParsedResult
from .amount_parser import AmountParser


class SpeechParser:
    """
    從 SFSpeechRecognizer 回傳文字中提取金額 + 分類。
    策略：先匹配 Category 關鍵字，再從剩餘文字提取金額。
    """

    # 分類關鍵字映射（簡短名稱 → Category）
    _CATEGORY_KEYWORDS: dict[str, Category] = {
        cat.short_name: cat for cat in Category
    }

    @classmethod
    def parse(cls, text: str) -> ParsedResult:
        """
        解析語音辨識文字。

        Args:
            text: SFSpeechRecognizer 回傳的辨識文字

        Returns:
            ParsedResult: 包含 amount (float|None) 與 category (Category|None)

        Examples:
            "食行兩百五" → ParsedResult(amount=250, category=FOOD_TRANSPORT)
            "三百塊" → ParsedResult(amount=300, category=None)
            "十一" → ParsedResult(amount=None, category=TITHE)
        """
        result = ParsedResult(raw_text=text)

        if not text or not text.strip():
            return result

        text = text.strip()

        # Step 1: 匹配分類關鍵字
        remaining = text
        for keyword, category in cls._CATEGORY_KEYWORDS.items():
            if keyword in text:
                result.category = category
                remaining = text.replace(keyword, "", 1).strip()
                break

        # Step 2: 從剩餘文字提取金額
        if remaining:
            amount = AmountParser.parse(remaining)
            if amount is not None:
                result.amount = amount
        elif not result.has_category:
            # 只有當沒有匹配到分類時，才從原始文字提取金額
            # 避免分類關鍵字中包含數字（如「十一」）被誤解析為金額
            amount = AmountParser.parse(text)
            if amount is not None:
                result.amount = amount

        return result

    @classmethod
    def match_category(cls, text: str) -> Category | None:
        """僅匹配分類關鍵字（不回傳金額）"""
        for keyword, category in cls._CATEGORY_KEYWORDS.items():
            if keyword in text:
                return category
        return None
