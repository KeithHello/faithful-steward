"""Integration tests for DataProvider — CRUD operations."""

import pytest
from datetime import date
from faithful_steward.models import Category, InputMethod, BudgetConfig
from faithful_steward.storage import DataProvider, Database
from faithful_steward.storage.data_provider import DataProviderError


class TestDataProviderTransactions:
    """交易 CRUD 測試"""

    def test_add_transaction(self, dp):
        txn = dp.add_transaction(amount=250, category=Category.FOOD_TRANSPORT)
        assert txn.amount == 250.0
        assert txn.category == Category.FOOD_TRANSPORT
        assert txn.input_method == InputMethod.TEXT
        assert txn.id is not None

    def test_add_transaction_with_voice_method(self, dp):
        txn = dp.add_transaction(
            amount=500, category=Category.HOUSING, method=InputMethod.VOICE
        )
        assert txn.input_method == InputMethod.VOICE

    def test_add_transaction_with_note(self, dp):
        txn = dp.add_transaction(
            amount=300, category=Category.SOCIAL, note="聚餐"
        )
        assert txn.note == "聚餐"

    def test_add_transaction_zero_amount_raises(self, dp):
        with pytest.raises(DataProviderError, match="金額必須大於 0"):
            dp.add_transaction(amount=0, category=Category.TITHE)

    def test_add_transaction_negative_amount_raises(self, dp):
        with pytest.raises(DataProviderError, match="金額必須大於 0"):
            dp.add_transaction(amount=-100, category=Category.TITHE)

    def test_fetch_all_transactions(self, dp):
        dp.add_transaction(amount=100, category=Category.TITHE)
        dp.add_transaction(amount=200, category=Category.HOUSING)
        dp.add_transaction(amount=300, category=Category.FOOD_TRANSPORT)

        all_txns = dp.fetch_all_transactions()
        assert len(all_txns) == 3

    def test_fetch_transactions_by_date_range(self, dp):
        today = date.today()
        month_start = date(today.year, today.month, 1)
        dp.add_transaction(amount=100, category=Category.TITHE)
        dp.add_transaction(amount=200, category=Category.HOUSING)

        txns = dp.fetch_transactions(
            from_date=month_start,
            to_date=today,
        )
        assert len(txns) == 2

    def test_fetch_transactions_out_of_range(self, dp):
        dp.add_transaction(amount=100, category=Category.TITHE)

        txns = dp.fetch_transactions(
            from_date=date(2020, 1, 1),
            to_date=date(2020, 12, 31),
        )
        assert len(txns) == 0

    def test_fetch_transactions_by_category(self, dp):
        today = date.today()
        year_start = date(today.year, 1, 1)
        dp.add_transaction(amount=100, category=Category.TITHE)
        dp.add_transaction(amount=200, category=Category.HOUSING)
        dp.add_transaction(amount=300, category=Category.TITHE)

        tithe_txns = dp.fetch_transactions(
            from_date=year_start,
            to_date=today,
            category=Category.TITHE,
        )
        assert len(tithe_txns) == 2
        assert all(t.category == Category.TITHE for t in tithe_txns)
        assert sum(t.amount for t in tithe_txns) == 400.0

    def test_delete_transaction(self, dp):
        txn = dp.add_transaction(amount=100, category=Category.TITHE)
        assert len(dp.fetch_all_transactions()) == 1

        success = dp.delete_transaction(str(txn.id))
        assert success is True
        assert len(dp.fetch_all_transactions()) == 0

    def test_delete_nonexistent_transaction(self, dp):
        success = dp.delete_transaction("non-existent-id")
        assert success is False

    def test_update_transaction(self, dp):
        txn = dp.add_transaction(amount=100, category=Category.TITHE)
        txn.amount = 200
        txn.category = Category.HOUSING
        dp.update_transaction(txn)

        updated = dp.fetch_all_transactions()[0]
        assert updated.amount == 200.0
        assert updated.category == Category.HOUSING


class TestDataProviderBudgetConfigs:
    """預算設定 CRUD 測試"""

    def test_save_budget_config(self, dp):
        config = dp.save_budget_config(
            monthly_total=30000,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-06",
        )
        assert config.monthly_total == 30000.0
        assert config.month_key == "2025-06"

    def test_fetch_budget_config(self, dp):
        dp.save_budget_config(
            monthly_total=30000,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-06",
        )

        config = dp.fetch_budget_config("2025-06")
        assert config is not None
        assert config.monthly_total == 30000.0

    def test_fetch_budget_config_nonexistent(self, dp):
        config = dp.fetch_budget_config("2099-01")
        assert config is None

    def test_fetch_latest_budget_config(self, dp):
        dp.save_budget_config(
            monthly_total=28000,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-05",
        )
        dp.save_budget_config(
            monthly_total=30000,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-06",
        )

        latest = dp.fetch_latest_budget_config()
        assert latest is not None
        assert latest.monthly_total == 30000.0
        assert latest.month_key == "2025-06"

    def test_save_budget_config_updates_existing(self, dp):
        dp.save_budget_config(
            monthly_total=30000,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-06",
        )

        dp.save_budget_config(
            monthly_total=35000,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-06",
        )

        config = dp.fetch_budget_config("2025-06")
        assert config.monthly_total == 35000.0

    def test_save_budget_config_zero_total_raises(self, dp):
        with pytest.raises(DataProviderError, match="月預算總額必須大於 0"):
            dp.save_budget_config(
                monthly_total=0,
                ratios={cat: cat.default_ratio for cat in Category},
                month_key="2025-06",
            )

    def test_save_budget_config_invalid_ratios_raises(self, dp):
        with pytest.raises(DataProviderError, match="比例總和必須為 100%"):
            dp.save_budget_config(
                monthly_total=30000,
                ratios={cat: 0.05 for cat in Category},  # 35% total
                month_key="2025-06",
            )
