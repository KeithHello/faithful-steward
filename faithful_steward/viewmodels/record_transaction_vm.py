"""RecordTransactionViewModel — 記帳 ViewModel。

對應 iOS RecordTransactionViewModel（Features/RecordTransaction/RecordTransactionViewModel.swift）。
管理文字輸入、語音辨識、分類選擇、驗證、提交。
"""

from typing import Optional
from ..models import Category, InputMethod, Transaction, ParsedResult
from ..storage import DataProvider
from ..services import AmountParser, SpeechParser


class RecordTransactionViewModel:
    """
    記帳 ViewModel。
    管理 amountText / parsedAmount / selectedCategory / isRecording / canConfirm。
    """

    def __init__(self, data_provider: DataProvider):
        self._dp = data_provider
        self._amount_parser = AmountParser()
        self._speech_parser = SpeechParser()

        # Published state (in SwiftUI these would be @Published)
        self.amount_text: str = ""
        self.parsed_amount: float | None = None
        self.selected_category: Category | None = None
        self.is_recording: bool = False
        self.voice_result_text: str = ""
        self.error_message: str | None = None
        self.last_submitted_txn: Transaction | None = None

    @property
    def can_confirm(self) -> bool:
        """確認按鈕是否可用：金額 > 0 且分類已選"""
        return (
            self.parsed_amount is not None
            and self.parsed_amount > 0
            and self.selected_category is not None
        )

    def set_amount_text(self, text: str):
        """更新金額文字並自動解析"""
        self.amount_text = text
        self.error_message = None
        self.parsed_amount = AmountParser.parse(text)

    def select_category(self, category: Category):
        """選擇分類"""
        self.selected_category = category
        self.error_message = None

    def process_voice_result(self, text: str):
        """
        處理語音辨識結果（UC2 主流程）。
        呼叫 SpeechParser 解析文字，自動填入金額與分類。
        """
        self.voice_result_text = text
        self.error_message = None

        result = SpeechParser.parse(text)

        if result.has_amount:
            self.parsed_amount = result.amount
            self.amount_text = str(int(result.amount))

        if result.has_category:
            self.selected_category = result.category

        # 例外：無金額 → 提示
        if not result.has_amount and not result.has_category:
            self.error_message = "未偵測到金額與分類，請手動輸入"

        if not result.has_amount and result.has_category:
            # 只有分類沒有金額 → 金額欄保持空白
            pass

    def submit_transaction(self, note: str | None = None) -> Transaction:
        """
        提交記帳（UC1/UC2 確認步驟）。
        驗證 → DataProvider.addTransaction → 清空輸入。

        Raises:
            ValueError: 驗證失敗時拋出
        """
        # 驗證
        if self.parsed_amount is None or self.parsed_amount <= 0:
            raise ValueError("請輸入有效金額")

        if self.selected_category is None:
            raise ValueError("請選擇分類")

        # 寫入
        txn = self._dp.add_transaction(
            amount=self.parsed_amount,
            category=self.selected_category,
            note=note,
            method=InputMethod.VOICE if self.is_recording or self.voice_result_text else InputMethod.TEXT,
        )

        self.last_submitted_txn = txn
        self.clear_input()
        return txn

    def clear_input(self):
        """清空所有輸入狀態"""
        self.amount_text = ""
        self.parsed_amount = None
        self.selected_category = None
        self.is_recording = False
        self.voice_result_text = ""
        self.error_message = None
