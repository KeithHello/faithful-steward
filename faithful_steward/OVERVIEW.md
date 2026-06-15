# Faithful Steward — 專案總覽

> 基於 `DEVELOPMENT.md`、`architecture-tithe-budget.md`、`DESIGN.md`、`prd-tithe-budget.md` 四份文檔開發
> 最後更新：2026-06-15

---

## 專案結構

```
faithful_steward/
├── ios/                                 # iOS SwiftUI App（31 個檔案）
│   ├── faithful_stewardApp.swift        # App 進入點 + 4 Tab
│   ├── Core/Models/                     # Category / InputMethod / Period
│   ├── Core/Storage/                    # PersistenceController + DataProvider
│   ├── Core/Speech/                     # SpeechRecognizer + SpeechParser
│   ├── Features/RecordTransaction/      # 記帳 + 明細 Tab
│   ├── Features/BudgetOverview/         # 總覽 Tab
│   ├── Features/Settings/               # 設定 Tab
│   ├── Shared/                          # Utilities / Components / Extensions
│   └── Resources/                       # CoreData 模型定義
│
├── models/                              # Python 資料模型層
│   ├── enums.py                         # Category(7類) / InputMethod / Period
│   ├── transaction.py                   # Transaction (dataclass)
│   ├── budget_config.py                 # BudgetConfig (dataclass)
│   ├── parsed_result.py                 # ParsedResult
│   └── category_row_data.py             # CategoryRowData
│
├── storage/                             # 持久化層 (SQLite ← CoreData)
│   ├── database.py                      # Database (singleton + in-memory)
│   └── data_provider.py                 # DataProvider (完整 CRUD)
│
├── services/                            # 工具層 (純函數)
│   ├── amount_parser.py                 # 金額解析（阿拉伯 + 繁中口語）
│   ├── speech_parser.py                 # 語音解析（關鍵字匹配 + 金額提取）
│   ├── ratio_calculator.py              # 比例計算 + 滑桿重分配（總和=100%）
│   └── period_calculator.py             # 自然月週期計算
│
├── components/                          # 共用元件（邏輯層）
│   ├── confirm_dialog.py                # 確認彈窗
│   ├── toast_banner.py                  # Toast 提示
│   └── empty_state.py                   # 空狀態
│
├── viewmodels/                          # MVVM ViewModel 層
│   ├── record_transaction_vm.py         # 記帳 ViewModel (UC1+UC2)
│   ├── budget_overview_vm.py            # 總覽 ViewModel (UC3)
│   └── settings_vm.py                   # 設定 ViewModel (UC4)
│
└── tests/                               # 149 個測試，100% 通過
    ├── conftest.py
    ├── amount_parser_test.py            # 22 tests
    ├── speech_parser_test.py            # 16 tests
    ├── ratio_calculator_test.py         # 12 tests
    ├── period_calculator_test.py        # 12 tests
    ├── data_provider_test.py            # 18 tests
    ├── models_test.py                   # 22 tests
    ├── uc1_text_transaction_test.py     # 12 tests（主流程 + 替代 + 例外）
    ├── uc2_voice_transaction_test.py    # 12 tests（主流程 + 替代 + 例外）
    ├── uc3_budget_comparison_test.py    # 15 tests（主流程 + 週期切換 + 例外）
    └── uc4_settings_test.py             # 14 tests（主流程 + 滑桿 + 例外 + 持久化）
```

---

## 測試覆蓋

| Use Case | 測試數 | 覆蓋點 |
|---|---|---|
| UC1 文字記帳 | 12 | 主流程 / Alt A/B / E1/E2/E3 |
| UC2 語音記帳 | 12 | 主流程 / Alt A/B / E1/E2 / 覆寫 |
| UC3 預算對比 | 15 | 主流程 / 4 週期切換 / E1/E2 / 預設值 |
| UC4 設定 | 14 | 主流程 / 滑桿 / E1/E2 / 持久化 |
| 工具層 | 62 | AmountParser / SpeechParser / RatioCalculator / PeriodCalculator / DataProvider |
| 模型層 | 22 | Category / Period / Transaction / BudgetConfig / ParsedResult / CategoryRowData |
| **總計** | **149** | **100% 通過** |

---

## 核心技術決策

1. **中文數字解析**：狀態機處理省略單位模式（「兩百五」=250、「一千二」=1200）
2. **SQLite 日期查詢**：使用 `< next_day`（而非 `<= to_date`）確保同日 timestamp 被包含
3. **比例重分配**：滑桿調整後，其餘 N-1 類按原比例等比分攤，保證總和=100%
4. **語音解析策略**：先剝離分類關鍵字，再從剩餘文字提取金額

## 如何在 Xcode 使用

1. Xcode → **File → New → Project → iOS → App**
2. Product Name: `faithful_steward`，勾選 Core Data
3. 將 `ios/` 下所有 .swift 檔案依目錄結構拖入專案
4. 用 `ios/Resources/` 的 CoreData 模型覆蓋 Xcode 自動產生的
5. Build + Run
