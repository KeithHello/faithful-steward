# Faithful Steward — Python 實作總覽

> 基於 `DEVELOPMENT.md`、`architecture-tithe-budget.md`、`DESIGN.md`、`prd-tithe-budget.md` 四份文檔開發
> 開發日期：2026-06-14

---

## 檔案結構

```
faithful_steward/
├── __init__.py
├── models/                          # 資料模型層
│   ├── enums.py                     # Category(7類)/InputMethod/Period/ToastType
│   ├── transaction.py               # Transaction (dataclass)
│   ├── budget_config.py             # BudgetConfig (dataclass)
│   ├── parsed_result.py             # ParsedResult
│   └── category_row_data.py         # CategoryRowData
├── storage/                         # 持久化層 (SQLite ← CoreData)
│   ├── database.py                  # Database (SQLite wrapper, singleton + in-memory)
│   └── data_provider.py             # DataProvider (完整 CRUD)
├── services/                        # 工具層 (純函數)
│   ├── amount_parser.py             # 金額解析（阿拉伯+繁中口語，含省略單位模式）
│   ├── speech_parser.py             # 語音解析（關鍵字匹配+金額提取）
│   ├── ratio_calculator.py          # 比例計算+滑桿重分配
│   └── period_calculator.py         # 自然月週期計算
├── components/                      # 共用元件（邏輯層）
│   ├── confirm_dialog.py            # 確認彈窗
│   ├── toast_banner.py              # Toast 提示
│   └── empty_state.py               # 空狀態
├── viewmodels/                      # MVVM ViewModel 層
│   ├── record_transaction_vm.py     # 記帳 ViewModel (UC1+UC2)
│   ├── budget_overview_vm.py        # 總覽 ViewModel (UC3)
│   └── settings_vm.py               # 設定 ViewModel (UC4)
└── tests/                           # 149 個測試，100% 通過
    ├── conftest.py                  # Fixtures: db, dp, seeded_db, june_2025
    ├── test_amount_parser.py        # 22 tests (阿拉伯+繁中口語)
    ├── test_speech_parser.py        # 16 tests (關鍵字匹配+解析)
    ├── test_ratio_calculator.py     # 12 tests (比例+重分配)
    ├── test_period_calculator.py    # 12 tests (週期+monthKey)
    ├── test_data_provider.py        # 18 tests (CRUD 整合)
    ├── test_models.py               # 22 tests (enum+dataclass)
    ├── test_uc1_text_transaction.py # 12 tests (主流程+替代+例外)
    ├── test_uc2_voice_transaction.py# 12 tests (主流程+替代+例外)
    ├── test_uc3_budget_comparison.py# 15 tests (主流程+週期切換+例外)
    └── test_uc4_settings.py         # 14 tests (主流程+滑桿+例外+持久化)
```

---

## 架構對照

| iOS (SwiftUI) | Python 實作 | 說明 |
|---|---|---|
| SwiftUI Views | (前端層，待 UI 框架實作) | ViewModels 可直接接入任何 Python web 框架 |
| CoreData | SQLite (`database.py`) | in-memory 測試 / file 持久化 |
| DataProvider | `data_provider.py` | 完整 CRUD，接口一致 |
| SpeechRecognizer | (不可用，由前端處理) | `SpeechParser` 邏輯層保留 |
| AmountParser | `amount_parser.py` | 支援「兩百五」→250 等口語模式 |
| RatioCalculator | `ratio_calculator.py` | 比例計算 + 滑桿重分配 |
| PeriodCalculator | `period_calculator.py` | 自然月日期範圍 |
| MVVM ViewModels | `viewmodels/` | 三層 ViewModel，狀態管理完整 |

---

## 核心技術決策

1. **中文數字解析**：採用狀態機處理省略單位模式（「兩百五」=250、「一千二」=1200），覆蓋口語化表達
2. **SQLite 日期查詢**：使用 `< next_day`（而非 `<= to_date`）確保同日 timestamp 被包含
3. **比例重分配**：滑桿調整後，其餘 N-1 類按原比例等比分攤，保證總和=100%
4. **語音解析策略**：先剝離分類關鍵字，再從剩餘文字提取金額，避免「十一」被誤解析為 11

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
