# tithe_budget iOS App — SwiftUI 重建完成

> 基於 architecture-tithe-budget.md 的完整文件清單重建
> 開發日期：2026-06-15

---

## 專案結構（31 個檔案）

```
tithe_budget/
├── tithe_budgetApp.swift                    # App 進入點 + TabView（4 Tab）
│
├── Core/
│   ├── Models/
│   │   ├── Category.swift                   # 7 大分類 enum + 預設比例 + 顯示名稱 + SF Symbols
│   │   ├── InputMethod.swift                # 輸入方式 enum（text / voice）
│   │   └── Period.swift                     # 檢視週期 enum（本月/近3/近6/近12月）
│   │
│   ├── Storage/
│   │   ├── PersistenceController.swift      # CoreData NSPersistentContainer 管理 + preview 支援
│   │   └── DataProvider.swift               # 統一 CRUD：addTransaction / fetch / delete / budgetConfig
│   │
│   └── Speech/
│       ├── SpeechRecognizer.swift           # SFSpeechRecognizer 封裝（async permissions + streaming）
│       └── SpeechParser.swift               # 關鍵字匹配分類 → 剩餘文字提取金額
│
├── Features/
│   ├── RecordTransaction/                   # 記帳 Tab
│   │   ├── RecordTransactionView.swift
│   │   ├── RecordTransactionViewModel.swift
│   │   ├── VoiceInputButton.swift
│   │   ├── CategorySelector.swift
│   │   └── TransactionListView.swift        # 明細 Tab（新增）
│   │
│   ├── BudgetOverview/                      # 總覽 Tab
│   │   ├── BudgetOverviewView.swift
│   │   ├── BudgetOverviewViewModel.swift
│   │   ├── PeriodPicker.swift
│   │   ├── BudgetBarChart.swift
│   │   └── BudgetBarRow.swift
│   │
│   └── Settings/                            # 設定 Tab
│       ├── SettingsView.swift
│       ├── SettingsViewModel.swift
│       ├── BudgetTotalEditor.swift
│       └── RatioSliderList.swift
│
├── Shared/
│   ├── Utilities/
│   │   ├── AmountParser.swift               # 金額解析（阿拉伯 + 繁中口語數字）
│   │   ├── RatioCalculator.swift            # 比例計算 + 滑桿重分配（總和=100%）
│   │   └── PeriodCalculator.swift           # 自然月週期計算
│   │
│   ├── Components/
│   │   ├── ConfirmDialog.swift              # .alert 封裝
│   │   ├── ToastBanner.swift                # 頂部自動消失提示橫幅
│   │   └── EmptyStateView.swift             # 空狀態佔位
│   │
│   └── Extensions/
│       ├── Decimal+Extensions.swift         # Double/Decimal 貨幣與百分比格式化
│       ├── Color+Extensions.swift           # 7 分類色 + 語意色
│       └── String+Localization.swift        # 繁中字串常數
│
└── Resources/
    └── tithe_budget.xcdatamodeld/           # CoreData 模型（TransactionEntity + BudgetConfigEntity）
```

## 架構對照

| 架構圖層級 | 檔案 | 用途 |
|---|---|---|
| App Entry | `tithe_budgetApp.swift` | `@main` + TabView 4 Tab |
| ViewModel | 3 個 `*ViewModel.swift` | MVVM 狀態管理、業務邏輯 |
| DataProvider | `DataProvider.swift` | CoreData CRUD (
| PersistenceController | `PersistenceController.swift` | NSPersistentContainer |
| 純函數服務 | 3 個 `Shared/Utilities/*.swift` | AmountParser, RatioCalculator, PeriodCalculator |
| 語音 | `SpeechRecognizer.swift` + `SpeechParser.swift` | 語音辨識 + 解析 |
| 共用 UI | 3 個 `Components/*.swift` | ConfirmDialog, ToastBanner, EmptyStateView |
| 擴充 | 3 個 `Extensions/*.swift` | Decimal, Color, String |

## 如何在 Xcode 使用

1. 在 Xcode 選擇 **File → New → Project → iOS → App**
2. 填寫：
   - Product Name: `tithe_budget`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - 勾選 **Core Data**
3. 將產出的 31 個 .swift 檔案依目錄結構拖入專案
4. 取代 Xcode 自動產生的 CoreData 模型檔（用 `contents` 覆蓋）
5. Build 即可

> **注意**：此為純 SwiftUI 原始碼，無法在 Windows 編譯。需在 macOS + Xcode 環境中開啟。
