"""
UC2: 語音記帳 — 完整測試。

PRD §3.3 Use Case 2:
- 主流程：長按 → 收音 → 說話 → 鬆手 → 辨識 → 自動填入金額+分類 → 確認 → 儲存
- 替代流程 A：只說金額（無分類）→ 只填金額，手動選分類
- 替代流程 B：說分類+金額（如「十一兩百」）→ 自動填入
- 例外流程 E1：辨識失敗 → 提示重試
- 例外流程 E2：無金額 → 切換手動模式
"""

import pytest
from faithful_steward.viewmodels import RecordTransactionViewModel
from faithful_steward.models import Category, InputMethod


class TestUC2MainFlow:
    """UC2 主流程測試"""

    def test_full_voice_flow_with_category_and_amount(self, dp):
        """主流程：說「食行兩百五」→ 自動填入金額=250 + 分類=食行 → 確認 → 儲存"""
        vm = RecordTransactionViewModel(dp)

        # Step 1-4: 語音辨識模擬（process_voice_result）
        vm.process_voice_result("食行兩百五")

        assert vm.parsed_amount == 250.0
        assert vm.selected_category == Category.FOOD_TRANSPORT
        assert vm.voice_result_text == "食行兩百五"
        assert vm.can_confirm is True

        # Step 5: 確認提交
        txn = vm.submit_transaction()
        assert txn.amount == 250.0
        assert txn.category == Category.FOOD_TRANSPORT
        assert txn.input_method == InputMethod.VOICE

        # Step 6: 清空
        assert vm.amount_text == ""
        assert vm.selected_category is None

    def test_voice_transaction_persisted(self, dp):
        """語音記帳資料正確寫入"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("住兩千")
        txn = vm.submit_transaction()

        transactions = dp.fetch_all_transactions()
        assert len(transactions) == 1
        assert transactions[0].amount == 2000.0
        assert transactions[0].category == Category.HOUSING
        assert transactions[0].input_method == InputMethod.VOICE


class TestUC2AlternativeFlows:
    """UC2 替代流程測試"""

    def test_alt_a_amount_only_no_category(self, dp):
        """替代 A：只說「三百塊」→ 只填金額，分類手動選"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("三百塊")

        assert vm.parsed_amount == 300.0
        assert vm.selected_category is None
        assert vm.can_confirm is False  # 還沒選分類

        # 手動選分類
        vm.select_category(Category.FOOD_TRANSPORT)
        assert vm.can_confirm is True

        txn = vm.submit_transaction()
        assert txn.amount == 300.0
        assert txn.category == Category.FOOD_TRANSPORT

    def test_alt_b_category_amount_keyword(self, dp):
        """替代 B：「十一兩百」→ 自動填入十一 + 200"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("十一兩百")

        assert vm.parsed_amount == 200.0
        assert vm.selected_category == Category.TITHE
        assert vm.can_confirm is True

    def test_alt_b_another_keyword(self, dp):
        """替代 B：「交際一千二」→ 交際 + 1200"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("交際一千二")

        assert vm.parsed_amount == 1200.0
        assert vm.selected_category == Category.SOCIAL

    def test_alt_b_with_unit(self, dp):
        """替代 B：「還款五百塊」→ 還款 + 500"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("還款五百塊")

        assert vm.parsed_amount == 500.0
        assert vm.selected_category == Category.DEBT


class TestUC2ExceptionFlows:
    """UC2 例外流程測試"""

    def test_e1_unrecognized_speech(self, dp):
        """E1：無法辨識 → error_message 設定"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("今天天氣很好")

        assert vm.parsed_amount is None
        assert vm.selected_category is None
        assert vm.error_message is not None
        assert "未偵測到" in vm.error_message

    def test_e1_empty_text(self, dp):
        """E1：空辨識結果"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("")

        assert vm.parsed_amount is None
        assert vm.selected_category is None

    def test_e2_no_amount_only_category(self, dp):
        """E2：只有分類沒有金額 → 手動輸入金額"""
        vm = RecordTransactionViewModel(dp)
        vm.process_voice_result("食行")

        assert vm.selected_category == Category.FOOD_TRANSPORT
        assert vm.parsed_amount is None
        assert vm.can_confirm is False

        # 手動輸入金額
        vm.set_amount_text("150")
        assert vm.can_confirm is True

        txn = vm.submit_transaction()
        assert txn.amount == 150.0
        assert txn.category == Category.FOOD_TRANSPORT

    def test_voice_result_overwrites_previous(self, dp):
        """連續兩次語音辨識，第二次覆蓋第一次"""
        vm = RecordTransactionViewModel(dp)

        vm.process_voice_result("食行兩百五")
        assert vm.selected_category == Category.FOOD_TRANSPORT
        assert vm.parsed_amount == 250.0

        vm.process_voice_result("交際一千")
        assert vm.selected_category == Category.SOCIAL
        assert vm.parsed_amount == 1000.0
