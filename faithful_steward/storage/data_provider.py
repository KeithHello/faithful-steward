"""DataProvider — unified CRUD interface over SQLite, mirrors iOS DataProvider."""

from datetime import datetime, date, timedelta
from typing import Optional
from ..models import Transaction, BudgetConfig, Category, InputMethod
from .database import Database


class DataProviderError(Exception):
    """DataProvider 操作異常"""
    pass


class DataProvider:
    """
    統一資料存取層 — 封裝 SQLite CRUD。
    對應 iOS DataProvider（CoreData 版）。
    """

    def __init__(self, database: Database):
        self._db = database

    # ── Transaction CRUD ──

    def add_transaction(
        self,
        amount: float,
        category: Category,
        note: str | None = None,
        method: InputMethod = InputMethod.TEXT,
        created_at: datetime | None = None,
    ) -> Transaction:
        """新增一筆記帳紀錄"""
        if amount <= 0:
            raise DataProviderError("金額必須大於 0")

        if created_at is None:
            created_at = datetime.now()

        txn = Transaction(
            amount=amount,
            category=category,
            note=note,
            input_method=method,
            created_at=created_at,
            updated_at=created_at,
        )

        self._db.conn.execute(
            """INSERT INTO transactions (id, amount, category_raw, note, input_method_raw, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                str(txn.id),
                txn.amount,
                txn.category_raw,
                txn.note,
                txn.input_method.value,
                txn.created_at.isoformat(),
                txn.updated_at.isoformat(),
            ),
        )
        self._db.save()
        return txn

    def fetch_transactions(
        self,
        from_date: date,
        to_date: date,
        category: Category | None = None,
    ) -> list[Transaction]:
        """查詢指定日期範圍的交易紀錄（可選分類篩選）"""
        # 使用 < next_day 而非 <= to_date，因為 created_at 是完整 timestamp
        next_day = (to_date + timedelta(days=1)).isoformat()
        if category:
            rows = self._db.conn.execute(
                """SELECT * FROM transactions
                   WHERE created_at >= ? AND created_at < ?
                   AND category_raw = ?
                   ORDER BY created_at DESC""",
                (from_date.isoformat(), next_day, category.value),
            ).fetchall()
        else:
            rows = self._db.conn.execute(
                """SELECT * FROM transactions
                   WHERE created_at >= ? AND created_at < ?
                   ORDER BY created_at DESC""",
                (from_date.isoformat(), next_day),
            ).fetchall()

        return [Transaction.from_dict(dict(row)) for row in rows]

    def fetch_all_transactions(self) -> list[Transaction]:
        """查詢全部交易紀錄"""
        rows = self._db.conn.execute(
            "SELECT * FROM transactions ORDER BY created_at DESC"
        ).fetchall()
        return [Transaction.from_dict(dict(row)) for row in rows]

    def update_transaction(self, txn: Transaction) -> Transaction:
        """更新一筆交易"""
        txn.updated_at = datetime.now()
        self._db.conn.execute(
            """UPDATE transactions
               SET amount=?, category_raw=?, note=?, input_method_raw=?, updated_at=?
               WHERE id=?""",
            (
                txn.amount,
                txn.category_raw,
                txn.note,
                txn.input_method.value,
                txn.updated_at.isoformat(),
                str(txn.id),
            ),
        )
        self._db.save()
        return txn

    def delete_transaction(self, txn_id: str) -> bool:
        """刪除一筆交易"""
        cursor = self._db.conn.execute(
            "DELETE FROM transactions WHERE id=?", (txn_id,)
        )
        self._db.save()
        return cursor.rowcount > 0

    # ── BudgetConfig CRUD ──

    def fetch_budget_config(self, month_key: str) -> BudgetConfig | None:
        """查詢指定月份的預算設定"""
        row = self._db.conn.execute(
            "SELECT * FROM budget_configs WHERE month_key=?",
            (month_key,),
        ).fetchone()

        if row is None:
            return None
        return BudgetConfig.from_dict(dict(row))

    def fetch_latest_budget_config(self) -> BudgetConfig | None:
        """查詢最新的預算設定（按 month_key 降序）"""
        row = self._db.conn.execute(
            "SELECT * FROM budget_configs ORDER BY month_key DESC LIMIT 1"
        ).fetchone()

        if row is None:
            return None
        return BudgetConfig.from_dict(dict(row))

    def save_budget_config(
        self,
        monthly_total: float,
        ratios: dict[Category, float],
        month_key: str,
    ) -> BudgetConfig:
        """儲存或更新預算設定（month_key 唯一）"""
        if monthly_total <= 0:
            raise DataProviderError("月預算總額必須大於 0")

        # 檢查總和
        total = sum(ratios.values())
        if abs(total - 1.0) > 0.001:
            raise DataProviderError(f"比例總和必須為 100%，目前為 {total * 100:.1f}%")

        existing = self.fetch_budget_config(month_key)

        if existing:
            # 更新現有
            existing.monthly_total = monthly_total
            existing.ratios = ratios
            existing.updated_at = datetime.now()

            self._db.conn.execute(
                """UPDATE budget_configs
                   SET monthly_total=?, ratios_json=?, updated_at=?
                   WHERE month_key=?""",
                (
                    existing.monthly_total,
                    existing.ratios_json,
                    existing.updated_at.isoformat(),
                    month_key,
                ),
            )
            self._db.save()
            return existing
        else:
            # 新建
            config = BudgetConfig(
                month_key=month_key,
                monthly_total=monthly_total,
                ratios=ratios,
            )

            self._db.conn.execute(
                """INSERT INTO budget_configs (id, month_key, monthly_total, ratios_json, updated_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (
                    str(config.id),
                    config.month_key,
                    config.monthly_total,
                    config.ratios_json,
                    config.updated_at.isoformat(),
                ),
            )
            self._db.save()
            return config
