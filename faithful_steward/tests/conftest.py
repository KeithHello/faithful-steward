"""Shared test fixtures for Faithful Steward tests."""

import sys
import os
import pytest

# Add financial-management directory to path (parent of faithful_steward package)
_project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)

from datetime import date, datetime
from faithful_steward.storage import Database, DataProvider
from faithful_steward.models import Category, InputMethod, Period, Transaction, BudgetConfig
from faithful_steward.services import AmountParser, SpeechParser, RatioCalculator, PeriodCalculator


@pytest.fixture
def db():
    """In-memory SQLite database for tests."""
    database = Database.in_memory()
    yield database
    database.close()


@pytest.fixture
def dp(db):
    """DataProvider backed by in-memory database."""
    return DataProvider(db)


@pytest.fixture
def seeded_db(dp):
    """
    預先填充資料的 DataProvider：
    - 本月預算設定：NT$ 30,000，預設比例
    - 數筆交易紀錄
    """
    # 本月預算
    dp.save_budget_config(
        monthly_total=30000.0,
        ratios={cat: cat.default_ratio for cat in Category},
        month_key="2025-06",
    )

    # 交易紀錄（模擬真實使用場景，日期設在 2025-06-15）
    txn_date = datetime(2025, 6, 15, 10, 0, 0)
    transactions = [
        (3000, Category.TITHE),     # 十一 10%
        (3000, Category.FILIAL),    # 孝親 10%
        (4500, Category.SOCIAL),    # 交際 15% ⚠超支
        (5400, Category.HOUSING),   # 住 18%
        (2700, Category.DEBT),      # 還款 9%
        (10500, Category.FOOD_TRANSPORT),  # 食行 35% ⚠超支
        (1500, Category.FLEXIBLE),  # 彈性 5%
    ]

    for amount, cat in transactions:
        dp.add_transaction(amount=amount, category=cat, created_at=txn_date)

    return dp


@pytest.fixture
def june_2025():
    """基準日期：2025-06-15"""
    return date(2025, 6, 15)


@pytest.fixture
def amount_parser():
    return AmountParser()


@pytest.fixture
def speech_parser():
    return SpeechParser()


@pytest.fixture
def ratio_calculator():
    return RatioCalculator()


@pytest.fixture
def period_calculator():
    return PeriodCalculator()
