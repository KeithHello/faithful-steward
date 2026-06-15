"""AmountParser — 文字→金額數字解析，支援繁中口語數字。

對應 iOS AmountParser（Shared/Utilities/AmountParser.swift）。
"""

import re
from typing import Optional


class AmountParser:
    """從文字中提取金額數字，支援阿拉伯數字與繁體中文口語數字"""

    # 中文數字映射
    _CN_DIGITS: dict[str, int] = {
        "零": 0, "一": 1, "二": 2, "兩": 2, "三": 3, "四": 4,
        "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
        "十": 10, "百": 100, "千": 1000,
    }

    # 金額單位關鍵字
    _UNIT_KEYWORDS = ["元", "塊", "块", "圓", "蚊"]

    @classmethod
    def parse(cls, text: str) -> float | None:
        """
        從文字中提取金額數字。
        優先嘗試阿拉伯數字，再嘗試繁體中文口語數字。

        Examples:
            "250" → 250.0
            "食行 250" → 250.0
            "兩百五" → 250.0
            "三百塊" → 300.0
            "一千二" → 1200.0
            "吃晚餐" → None
        """
        if not text or not text.strip():
            return None

        text = text.strip()

        # 1. 嘗試阿拉伯數字（含小數點）
        arabic_result = cls._parse_arabic(text)
        if arabic_result is not None:
            return arabic_result

        # 2. 嘗試繁體中文口語數字
        chinese_result = cls._parse_chinese_number(text)
        return chinese_result

    @classmethod
    def _parse_arabic(cls, text: str) -> float | None:
        """從文字中提取阿拉伯數字（含小數點與負號，如 250, 12.5, -100）"""
        # 匹配數字（含小數點與可選負號），排除純日期格式
        matches = re.findall(r'-?\d+(?:\.\d+)?', text)
        if not matches:
            return None

        # 過濾掉看起來像日期的（四位數年份）
        for m in matches:
            # 跳過四位數整數（可能是年份）
            if re.match(r'^-?\d{4}$', m):
                continue
            try:
                return float(m)
            except ValueError:
                continue
        return None

    @classmethod
    def _parse_chinese_number(cls, text: str) -> float | None:
        """
        解析繁體中文口語數字。

        支援格式：
        - "兩百五" → 250
        - "三百塊" → 300
        - "一千二" → 1200
        - "十" → 10
        - "一百" → 100
        - "五百三" → 530
        - "兩千三百" → 2300
        - "一萬二" → 12000
        """
        # 移除金額單位關鍵字
        cleaned = text
        for kw in cls._UNIT_KEYWORDS:
            cleaned = cleaned.replace(kw, "")

        # 嘗試匹配純中文數字序列
        cn_pattern = re.compile(r'[零一二兩三四五六七八九十百千萬]+')
        match = cn_pattern.search(cleaned)
        if not match:
            return None

        cn_str = match.group()

        # 處理「萬」
        if "萬" in cn_str:
            parts = cn_str.split("萬", 1)
            pre = cls._cn_to_int(parts[0]) if parts[0] else 1
            post_str = parts[1] if len(parts) > 1 and parts[1] else ""
            if post_str:
                post = cls._cn_to_int(post_str)
                # 省略單位：萬後只有一個數字 → ×1000
                if len(post_str) == 1 and cls._CN_DIGITS.get(post_str[0], 10) < 10:
                    post = post * 1000
            else:
                post = 0
            return float(pre * 10000 + post)

        return float(cls._cn_to_int(cn_str))

    @classmethod
    def _cn_to_int(cls, cn_str: str) -> int:
        """
        將中文數字字串轉為整數。

        支援省略單位模式（口語常見）：
        - "兩百五" = 250 (「五」後省略「十」，即 5×10)
        - "一千二" = 1200 (「二」後省略「百」，即 2×100)
        - "兩千三百" = 2300 (正常模式)
        """
        if not cn_str:
            return 0

        UNIT_VALUES: dict[str, int] = {"十": 10, "百": 100, "千": 1000}

        result = 0
        current_num = 0

        for i, char in enumerate(cn_str):
            digit = cls._CN_DIGITS.get(char)
            if digit is None:
                continue

            if char in UNIT_VALUES:
                unit_val = UNIT_VALUES[char]
                if current_num == 0:
                    current_num = 1
                current_num *= unit_val

                # 省略單位模式：若後面是最後一個字元且為數字
                # 例："兩百五" → 「五」是最後一字 × 10
                last_idx = len(cn_str) - 1
                if i + 1 == last_idx:
                    next_char = cn_str[last_idx]
                    next_digit = cls._CN_DIGITS.get(next_char)
                    if next_digit is not None and next_digit < 10:
                        result += current_num
                        result += next_digit * (unit_val // 10)
                        return result

                result += current_num
                current_num = 0
            else:
                current_num = digit

        result += current_num
        return result
