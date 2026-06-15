"""
UC1: 文字記帳 — 完整測試。

PRD §3.3 Use Case 1:
- 主流程：輸入金額 → 選分類 → 確認彈窗 → 儲存 → 清空
- 替代流程 A：先選分類再輸入金額
- 替代流程 B：取消確認 → 回到編輯
- 例外流程 E1：無法辨識的文字 → 提示
- 例外流程 E2：未選分類就確認 → 按鈕不可用
- 例外流程 E3：金額為 0 或負數 → 提示
"""

import pytest
from faithful_steward.viewmodels import RecordTransactionViewModel
from faithful_steward.models import Category, InputMethod
from faithful_steward.storage import Database, DataProvider


class TestUC1MainFlow:
    """UC1 主流程測試"""

    def test_full_text_transaction_flow(self, dp):
        """主流程：輸入金額 250 → 選分類 食行 → 確認 → 儲存成功 → 清空"""
        vm = RecordTransactionViewModel(dp)

        # Step 1: 輸入金額
        vm.set_amount_text("250")
        assert vm.parsed_amount == 250.0
        assert vm.can_confirm is False  # 還沒選分類

        # Step 2: 選分類
        vm.select_category(Category.FOOD_TRANSPORT)
        assert vm.selected_category == Category.FOOD_TRANSPORT
        assert vm.can_confirm is True

        # Step 3: 提交
        txn = vm.submit_transaction()
        assert txn.amount == 250.0
        assert txn.category == Category.FOOD_TRANSPORT
        assert txn.input_method == InputMethod.TEXT

        # Step 4: 驗證輸入已清空
        assert vm.amount_text == ""
        assert vm.parsed_amount is None
        assert vm.selected_category is None
        assert vm.can_confirm is False

    def test_transaction_persisted_correctly(self, dp):
        """驗證資料正確寫入 DB"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("500")
        vm.select_category(Category.HOUSING)
        txn = vm.submit_transaction()

        # 從 DB 查回
        transactions = dp.fetch_all_transactions()
        assert len(transactions) == 1
        assert transactions[0].amount == 500.0
        assert transactions[0].category == Category.HOUSING
        assert transactions[0].id == txn.id


class TestUC1AlternativeFlows:
    """UC1 替代流程測試"""

    def test_alt_a_select_category_first(self, dp):
        """替代流程 A：先選分類再輸入金額"""
        vm = RecordTransactionViewModel(dp)

        vm.select_category(Category.FOOD_TRANSPORT)
        assert vm.can_confirm is False  # 還沒輸金額

        vm.set_amount_text("250")
        assert vm.can_confirm is True

        txn = vm.submit_transaction()
        assert txn.amount == 250.0
        assert txn.category == Category.FOOD_TRANSPORT

    def test_alt_b_cancel_does_not_save(self, dp):
        """替代流程 B：取消 → 不儲存（PV 層保留輸入，不呼叫 submit）"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("250")
        vm.select_category(Category.FOOD_TRANSPORT)

        # 不呼叫 submit → 不應有記錄
        transactions = dp.fetch_all_transactions()
        assert len(transactions) == 0

    def test_alt_b_clear_and_restart(self, dp):
        """替代流程 B：取消後清空重新輸入"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("250")
        vm.select_category(Category.FOOD_TRANSPORT)
        vm.clear_input()

        assert vm.amount_text == ""
        assert vm.selected_category is None
        assert vm.parsed_amount is None

        # 重新輸入
        vm.set_amount_text("100")
        vm.select_category(Category.TITHE)
        txn = vm.submit_transaction()
        assert txn.amount == 100.0
        assert txn.category == Category.TITHE


class TestUC1ExceptionFlows:
    """UC1 例外流程測試"""

    def test_e1_unrecognizable_text(self, dp):
        """E1：無法辨識的文字 → parsed_amount=None"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("吃晚餐")
        assert vm.parsed_amount is None
        assert vm.can_confirm is False

    def test_e1_non_numeric_text(self, dp):
        """E1：非數字文字 → 無法確認"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("hello")
        vm.select_category(Category.FOOD_TRANSPORT)
        assert vm.can_confirm is False

    def test_e2_no_category_cannot_confirm(self, dp):
        """E2：未選分類 → can_confirm=False, submit 拋錯"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("250")
        assert vm.can_confirm is False

        with pytest.raises(ValueError, match="請選擇分類"):
            vm.submit_transaction()

    def test_e3_zero_amount_cannot_confirm(self, dp):
        """E3：金額為 0 → can_confirm=False"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("0")
        vm.select_category(Category.FOOD_TRANSPORT)
        assert vm.can_confirm is False

    def test_e3_negative_amount_cannot_confirm(self, dp):
        """E3：金額為負數 → can_confirm=False"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("-100")
        vm.select_category(Category.FOOD_TRANSPORT)
        assert vm.can_confirm is False

    def test_e3_zero_amount_submit_raises(self, dp):
        """E3：提交 0 金額 → 拋錯"""
        vm = RecordTransactionViewModel(dp)
        vm.set_amount_text("0")
        vm.select_category(Category.FOOD_TRANSPORT)
        # parsed_amount=0 → can_confirm=False
        # 但即使強制 submit 也應拋錯
        vm.parsed_amount = 0.0
        with pytest.raises(ValueError, match="請輸入有效金額"):
            vm.submit_transaction()
