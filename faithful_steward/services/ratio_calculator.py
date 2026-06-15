"""RatioCalculator — 比例計算：實際 vs 預算差異、總和校驗、滑桿重分配。

對應 iOS RatioCalculator（Shared/Utilities/RatioCalculator.swift）。
"""

from ..models import Transaction, BudgetConfig, Category


class RatioCalculator:
    """預算比例計算器（純函數）"""

    @staticmethod
    def calculate_actual_ratios(
        transactions: list[Transaction],
    ) -> dict[Category, float]:
        """
        計算各分類實際花費佔總花費的比例。

        Args:
            transactions: 交易紀錄列表

        Returns:
            dict[Category, float]: 各分類比例（0.0 ~ 1.0）
        """
        if not transactions:
            return {cat: 0.0 for cat in Category}

        # 各分類總額
        totals: dict[Category, float] = {cat: 0.0 for cat in Category}
        for txn in transactions:
            if txn.category is not None:
                totals[txn.category] += txn.amount

        grand_total = sum(totals.values())
        if grand_total == 0:
            return {cat: 0.0 for cat in Category}

        return {cat: amt / grand_total for cat, amt in totals.items()}

    @staticmethod
    def calculate_actual_amounts(
        transactions: list[Transaction],
    ) -> dict[Category, float]:
        """計算各分類實際花費金額"""
        totals: dict[Category, float] = {cat: 0.0 for cat in Category}
        for txn in transactions:
            if txn.category is not None:
                totals[txn.category] += txn.amount
        return totals

    @staticmethod
    def calculate_budget_ratios(
        config: BudgetConfig,
    ) -> dict[Category, float]:
        """從 BudgetConfig 讀取預算比例"""
        return dict(config.ratios)

    @staticmethod
    def calculate_difference(
        actual: dict[Category, float],
        budget: dict[Category, float],
    ) -> dict[Category, float]:
        """
        計算實際比例與預算比例的差異。

        Returns:
            dict[Category, float]: 差異值 (actual - budget)
                正值 = 超支，負值 = 結餘
        """
        return {
            cat: actual.get(cat, 0.0) - budget.get(cat, 0.0)
            for cat in Category
        }

    @staticmethod
    def validate_total_ratio(ratios: dict[Category, float]) -> bool:
        """
        驗證比例總和是否為 1.0（容忍 ±0.001）。

        Args:
            ratios: 各分類比例字典

        Returns:
            bool: 總和是否等於 100%
        """
        total = sum(ratios.values())
        return abs(total - 1.0) <= 0.001

    @staticmethod
    def redistribute_ratios(
        ratios: dict[Category, float],
        changed_category: Category,
        new_value: float,
    ) -> dict[Category, float]:
        """
        當某分類比例變動時，將差額由其餘 N-1 類按原比例等比分攤。

        演算法（來自架構文檔）：
        1. 計算差額 = new_value - old_value
        2. 從其餘分類按原比例吸收差額
        3. 保證總和 = 1.0

        Args:
            ratios: 當前各分類比例（總和 = 1.0）
            changed_category: 被調整的分類
            new_value: 新的比例值（0.0 ~ 1.0）

        Returns:
            dict[Category, float]: 新的比例字典（總和 = 1.0）
        """
        if new_value < 0 or new_value > 1:
            raise ValueError(f"比例值必須在 0~1 之間，收到 {new_value}")

        old_value = ratios.get(changed_category, 0.0)
        delta = new_value - old_value

        # 若無變動，直接回傳
        if abs(delta) < 0.0001:
            return dict(ratios)

        # 其餘分類（排除被調整的分類）
        other_cats = [cat for cat in Category if cat != changed_category]
        other_total = sum(ratios.get(cat, 0.0) for cat in other_cats)

        result = dict(ratios)
        result[changed_category] = new_value

        if other_total == 0:
            # 其餘分類均為 0，無法分攤 → 均分差額
            if len(other_cats) > 0:
                share = -delta / len(other_cats)
                for cat in other_cats:
                    result[cat] = max(0.0, min(1.0, share))
        else:
            # 按原比例等比分攤差額
            for cat in other_cats:
                original = ratios.get(cat, 0.0)
                # 該分類原佔其餘的比例
                weight = original / other_total if other_total > 0 else 0
                result[cat] = max(0.0, original - delta * weight)

        # 正規化確保總和 = 1.0
        total = sum(result.values())
        if total > 0:
            result = {cat: val / total for cat, val in result.items()}

        return result
