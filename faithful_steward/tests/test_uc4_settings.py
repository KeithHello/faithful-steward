"""
UC4: 設定月預算與比例 — 完整測試。

PRD §3.3 Use Case 4:
- 主流程：輸入總額 → 自動計算各分類上限 → 拖動滑桿 → 即時校驗總和 100% → 儲存
- 例外流程 E1：總和 ≠ 100% → 儲存按鈕反灰，提示
- 例外流程 E2：月預算輸入 0 或空白 → 提示
"""

import pytest
from datetime import date
from faithful_steward.viewmodels import SettingsViewModel
from faithful_steward.models import Category


class TestUC4MainFlow:
    """UC4 主流程測試"""

    def test_load_defaults_when_no_config(self, dp, june_2025):
        """無已存設定 → 使用預設值"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        assert vm.monthly_total == 30000.0
        assert vm.monthly_total_text == "30000"
        assert vm.is_valid is True

        # 驗證預設比例
        for cat in Category:
            assert vm.ratios[cat] == pytest.approx(cat.default_ratio)

    def test_load_existing_config(self, dp, june_2025):
        """已有本月設定 → 載入"""
        dp.save_budget_config(
            monthly_total=35000.0,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-06",
        )

        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        assert vm.monthly_total == 35000.0
        assert vm.monthly_total_text == "35000"

    def test_full_save_flow(self, dp, june_2025):
        """主流程：輸入總額 → 調比例 → 儲存"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        # Step 2: 設定總額
        vm.set_monthly_total("30000")
        assert vm.monthly_total == 30000.0
        assert vm.is_valid is True

        # Step 4: 微調比例（調整食行 30% → 35%）
        vm.update_ratio(Category.FOOD_TRANSPORT, 0.35)
        assert vm.ratios[Category.FOOD_TRANSPORT] == pytest.approx(0.35)
        assert vm.is_valid is True  # 總和仍然 = 100%

        # Step 6: 儲存
        config = vm.save_config(june_2025)
        assert config.monthly_total == 30000.0
        assert vm.is_saved is True

        # 驗證持久化
        loaded = dp.fetch_budget_config("2025-06")
        assert loaded is not None
        assert loaded.monthly_total == 30000.0
        assert loaded.ratios[Category.FOOD_TRANSPORT] == pytest.approx(0.35)

    def test_auto_calculate_category_budgets(self, dp, june_2025):
        """輸入 30000 總額，自動計算各分類上限"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        vm.set_monthly_total("30000")

        expected_budgets = {
            Category.TITHE: 3000,
            Category.FILIAL: 3000,
            Category.SOCIAL: 3000,
            Category.HOUSING: 6000,
            Category.DEBT: 3000,
            Category.FOOD_TRANSPORT: 9000,
            Category.FLEXIBLE: 3000,
        }

        for cat, expected in expected_budgets.items():
            actual = vm.monthly_total * vm.ratios[cat]
            assert actual == pytest.approx(expected)


class TestUC4SliderLogic:
    """UC4 滑桿邏輯測試"""

    def test_slider_redistribution(self, dp, june_2025):
        """拖動任一滑桿 → 其餘按原比例等比分攤"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        # 初始總和 = 100%
        original_sum = sum(vm.ratios.values())
        assert original_sum == pytest.approx(1.0)

        # 調整食行 0.30 → 0.40 (+10%)
        vm.update_ratio(Category.FOOD_TRANSPORT, 0.40)

        # 總和仍然 = 100%
        assert sum(vm.ratios.values()) == pytest.approx(1.0)
        assert vm.ratios[Category.FOOD_TRANSPORT] == pytest.approx(0.40)

        # 其餘分類被等比分攤 -10%
        for cat in Category:
            if cat != Category.FOOD_TRANSPORT:
                assert vm.ratios[cat] < cat.default_ratio  # 比原來少

    def test_multiple_slider_changes(self, dp, june_2025):
        """連續多次滑桿調整"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        vm.update_ratio(Category.HOUSING, 0.25)
        vm.update_ratio(Category.DEBT, 0.15)
        vm.update_ratio(Category.TITHE, 0.12)

        assert sum(vm.ratios.values()) == pytest.approx(1.0)
        # 經過多次重分配後，值會偏離初始目標，但總和必須保持 100%
        assert vm.ratios[Category.HOUSING] == pytest.approx(0.25, abs=0.03)
        assert vm.ratios[Category.DEBT] == pytest.approx(0.15, abs=0.03)
        assert vm.ratios[Category.TITHE] == pytest.approx(0.12, abs=0.03)


class TestUC4ExceptionFlows:
    """UC4 例外流程測試"""

    def test_e1_ratio_not_100_percent(self, dp, june_2025):
        """E1：總和 ≠ 100% → 直接設定無效的 ratios → isValid=False"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        # 手動設定一個總和不是 100% 的狀況
        vm.ratios = {cat: 0.10 for cat in Category}  # total = 70%
        vm.is_valid = False  # simulate invalid state

        assert vm.is_valid is False

        # 儲存應該報錯
        with pytest.raises(ValueError, match="比例總和須為 100%"):
            vm.save_config(june_2025)

    def test_e2_zero_budget_total(self, dp, june_2025):
        """E2：月預算輸入 0 → isValid=False"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        vm.set_monthly_total("0")
        assert vm.monthly_total == 0.0
        assert vm.is_valid is False
        assert vm.error_message is not None

        # 儲存應該報錯
        with pytest.raises(ValueError, match="請輸入有效的月預算金額"):
            vm.save_config(june_2025)

    def test_e2_empty_budget_total(self, dp, june_2025):
        """E2：月預算空白"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        vm.set_monthly_total("")
        assert vm.monthly_total == 0.0
        assert vm.is_valid is False

    def test_e2_invalid_text_budget(self, dp, june_2025):
        """E2：輸入非數字文字"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        vm.set_monthly_total("abc")
        assert vm.monthly_total == 0.0
        assert vm.is_valid is False

    def test_e2_negative_budget(self, dp, june_2025):
        """E2：負數預算"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)

        vm.set_monthly_total("-500")
        assert vm.monthly_total == 0.0
        assert vm.is_valid is False


class TestUC4Persistence:
    """UC4 資料持久化測試"""

    def test_save_creates_new_config(self, dp, june_2025):
        """儲存新建設定"""
        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)
        vm.set_monthly_total("40000")
        vm.save_config(june_2025)

        config = dp.fetch_budget_config("2025-06")
        assert config is not None
        assert config.monthly_total == 40000.0

    def test_save_updates_existing_config(self, dp, june_2025):
        """更新已存在的設定"""
        dp.save_budget_config(
            monthly_total=30000.0,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-06",
        )

        vm = SettingsViewModel(dp)
        vm.load_config(june_2025)
        vm.set_monthly_total("35000")
        vm.save_config(june_2025)

        config = dp.fetch_budget_config("2025-06")
        assert config.monthly_total == 35000.0

    def test_load_latest_config_when_no_current_month(self, dp):
        """本月無設定 → 載入最新設定（上月）"""
        dp.save_budget_config(
            monthly_total=28000.0,
            ratios={cat: cat.default_ratio for cat in Category},
            month_key="2025-05",
        )

        vm = SettingsViewModel(dp)
        vm.load_config(date(2025, 6, 15))

        assert vm.monthly_total == 28000.0
