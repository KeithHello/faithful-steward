"""SQLite database layer — mirrors PersistenceController in iOS."""

import sqlite3
import os
from typing import Optional


class Database:
    """
    SQLite 資料庫管理 — 對應 iOS PersistenceController。
    提供 singleton 共享實例 + 測試用 in-memory 模式。
    """

    _instance: Optional["Database"] = None

    def __init__(self, db_path: str = ":memory:"):
        self.db_path = db_path
        self._conn: sqlite3.Connection | None = None

    @classmethod
    def shared(cls) -> "Database":
        """Singleton 實例（檔案持久化）"""
        if cls._instance is None:
            db_dir = os.path.join(os.path.dirname(__file__), "..", "data")
            os.makedirs(db_dir, exist_ok=True)
            cls._instance = cls(db_path=os.path.join(db_dir, "faithful_steward.db"))
            cls._instance.initialize()
        return cls._instance

    @classmethod
    def in_memory(cls) -> "Database":
        """測試用 in-memory 資料庫"""
        db = cls(db_path=":memory:")
        db.initialize()
        return db

    @property
    def conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(self.db_path)
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA foreign_keys = ON")
        return self._conn

    def initialize(self):
        """建立資料表（若不存在）"""
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS transactions (
                id TEXT PRIMARY KEY,
                amount REAL NOT NULL,
                category_raw TEXT NOT NULL,
                note TEXT,
                input_method_raw TEXT NOT NULL DEFAULT 'text',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS budget_configs (
                id TEXT PRIMARY KEY,
                month_key TEXT NOT NULL,
                monthly_total REAL NOT NULL,
                ratios_json TEXT NOT NULL DEFAULT '{}',
                updated_at TEXT NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_transactions_created_at
                ON transactions(created_at);

            CREATE INDEX IF NOT EXISTS idx_transactions_category
                ON transactions(category_raw);

            CREATE UNIQUE INDEX IF NOT EXISTS idx_budget_config_month_key
                ON budget_configs(month_key);
        """)
        self.conn.commit()

    def save(self):
        """手動 commit（CoreData save 對應）"""
        self.conn.commit()

    def close(self):
        if self._conn:
            self._conn.close()
            self._conn = None
