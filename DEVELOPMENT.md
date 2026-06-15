# DEVELOPMENT.md — 忠心好管家開發總覽

> 主開發文檔 | 將系統架構、設計令牌與 UI 原型串接為可執行的開發規範
> 版本：v1.0 | 2026-06-14

---

## 文檔地圖

```
financial-management/
├── DEVELOPMENT.md              ← 本文件：開發總入口
├── architecture-tithe-budget.md ← 系統架構 + 任務分解
├── DESIGN.md                   ← 設計令牌（色彩/排版/動效）
├── prd-tithe-budget.md          ← 產品需求文檔
├── prototype/
│   └── index.html              ← UI 原型（可互動）
└── tithe_budget/               ← SwiftUI Xcode 專案
```

---

## 快速開始（給 Agent）

### Step 1：理解系統

閱讀 `architecture-tithe-budget.md`，重點關注：
- §1.2 框架選型（SwiftUI + CoreData + MVVM）
- §3 資料結構（TransactionEntity / BudgetConfigEntity / Category enum）
- §7 任務列表（T01-T05，按依賴順序排列）

### Step 2：理解視覺

閱讀 `DESIGN.md`，重點關注：
- §2 調色板（主色 #5B8C5A、暖灰階、7 分類專屬色）
- §3 排版（字體棧、12 級層級）
- §5 佈局間距（8px 網格、圓角體系）
- §9 CSS 變數速查（可直接移植到 SwiftUI）

### Step 3：理解互動

打開 `prototype/index.html` 在瀏覽器中體驗：
- Tab 1 記帳：金額輸入 + 語音模擬 + 7 類方格選擇 + FAB 確認
- Tab 2 明細：按月檢視 + Hero Card + 交易列表
- Tab 3 總覽：Bento 摘要 + 周期切換 + 相對比例長條圖
- Tab 4 設定：月預算 + 固定支出 + 比例滑桿 + 智慧儲存

### Step 4：開發對照

| 原型區塊 | 對應架構檔案 | SwiftUI 實作指引 |
|---------|-------------|-----------------|
| Tab 1 記帳 | `Features/RecordTransaction/` | RecordTransactionView + VoiceInputButton + CategorySelector |
| Tab 2 明細 | 新增功能（架構文檔待更新） | 需新建 DetailView + TransactionList |
| Tab 3 總覽 | `Features/BudgetOverview/` | BudgetOverviewView + BudgetBarChart |
| Tab 4 設定 | `Features/Settings/` | SettingsView + BudgetTotalEditor + RatioSliderList |
| FAB 按鈕 | Shared/Components/ | 使用 `.overlay` + `@State` 條件顯示 |
| Toast | `Shared/Components/ToastBanner.swift` | 頂部 overlay + 2 秒自動消失 |
| Dialog | `Shared/Components/ConfirmDialog.swift` | `.alert` / `.sheet` 封裝 |
| TabBar | `tithe_budgetApp.swift` | TabView + `.tabItem` |

---

## 設計令牌 → SwiftUI 映射

### 色彩

```swift
// Color+Extensions.swift
extension Color {
    static let accent = Color(hex: "#5B8C5A")
    static let accentSoft = Color(hex: "#EDF5EC")
    static let bg = Color(hex: "#F8F8F7")
    static let surface = Color(hex: "#FFFFFF")
    static let textPrimary = Color(hex: "#1A1A18")
    static let textSecondary = Color(hex: "#5C5B58")
    static let textTertiary = Color(hex: "#94928E")
    static let success = Color(hex: "#4A9E5C")
    static let danger = Color(hex: "#D94A4A")

    // 7 大分類色
    static let catTithe = Color(hex: "#C47DA7")
    static let catFilial = Color(hex: "#D4A057")
    static let catSocial = Color(hex: "#7DAEBF")
    static let catHousing = Color(hex: "#8C7DC4")
    static let catDebt = Color(hex: "#5B7FAD")
    static let catFood = Color(hex: "#5B8C5A")
    static let catFlexible = Color(hex: "#C47D6B")
}
```

### 排版

```swift
// SwiftUI Font extensions
extension Font {
    static let displayLarge = .system(size: 42, weight: .black, design: .default)
    static let displayMedium = .system(size: 34, weight: .bold)
    static let title1 = .system(size: 28, weight: .bold)
    static let headline = .system(size: 17, weight: .semibold)
    static let body = .system(size: 17, weight: .regular)
    static let caption = .system(size: 12, weight: .regular)
    static let amount = .system(size: 24, weight: .semibold, design: .monospaced)
}
```

### 圓角 & 間距

```swift
// 圓角
let cardRadius: CGFloat = 22    // --r-lg
let btnRadius: CGFloat = 9999   // --r-full (capsule)
let itemRadius: CGFloat = 16    // --r-md

// 間距（8px 網格）
let spaceSM: CGFloat = 8
let spaceMD: CGFloat = 16
let spaceLG: CGFloat = 24
```

### 動效

```swift
// 使用 spring 動畫對應 CSS cubic-bezier(0.32, 0.72, 0, 1)
.animation(.interpolatingSpring(stiffness: 170, damping: 20), value: someState)

// 等價於 CSS --ease
.animation(.spring(response: 0.5, dampingFraction: 0.75), value: someState)
```

---

## 資料流對照

```
原型（JS 模擬）             →  SwiftUI 實作
──────────────────────────────────────────────
mockTransactions[monthKey]  →  DataProvider.fetchTransactions(from:to:)
state.amount / state.cat    →  RecordTransactionViewModel.amountText / selectedCategory
sliderRatios[]              →  SettingsViewModel.ratios
fixedExpenses[]             →  新增 FixedExpenseEntity (CoreData) 或 BudgetConfigEntity 擴展
barDataMap                  →  BudgetOverviewViewModel.categoryRows
renderDetail()              →  DetailViewModel + TransactionListView
```

---

## 新增功能規格（原型已實作，架構文檔待更新）

### Feature: 明細（Tab 2）
- **檔案位置**：`Features/Detail/`（需新建）
- **ViewModel**：`DetailViewModel` — 管理 monthKey、交易列表、月摘要統計
- **View**：`DetailView` — 月導航 + Hero Card + 日期分組列表
- **資料源**：`DataProvider.fetchTransactions(from:to:)`

### Feature: FAB 浮動按鈕
- **共用元件**：`Shared/Components/FloatingActionButton.swift`
- **實作**：使用 `.overlay(alignment: .bottom)` + `@State showFab` + `.animation(.spring())`

### Feature: 智慧儲存
- **邏輯**：`SettingsViewModel` 內部追蹤 `hasUnsavedChanges`
- **計算**：比對當前值與 `originalSettings`（budgetTotal / ratios / fixedExpenses）
- **UI**：`unsavedBadge` + `fabSaveWrap` 條件顯示

### Feature: 固定支出
- **資料模型**：`FixedExpenseEntity`（id, catId, name, amount, createdAt）
- **關聯**：`catId` 映射到 `Category` enum
- **UI**：`FixedExpenseList` + `FixedExpenseEditor`（分類選擇器）

---

## 開發優先級

| 優先級 | 任務 ID | 說明 | 原型對應 |
|--------|---------|------|---------|
| P0 | T01 | 專案基礎設施 | 全體 |
| P0 | T02 | 共用工具層 | Toast / Dialog |
| P0 | T03 | 記帳功能 | Tab 1 |
| P1 | T04 | 總覽功能 | Tab 3 |
| P1 | T05 | 設定功能 | Tab 4 |
| P1 | NEW | 明細功能 | Tab 2 |
| P1 | NEW | FAB + 智慧儲存 | 共用 |

---

## 檔案清單（含新增）

```
tithe_budget/
├── tithe_budgetApp.swift                    # TabView (4 tabs)
├── Core/
│   ├── Models/
│   │   ├── Category.swift                   # 7 大分類 enum
│   │   ├── InputMethod.swift
│   │   ├── Period.swift
│   │   └── MonthKey.swift                  # NEW: yyyy-MM 格式
│   ├── Storage/
│   │   ├── PersistenceController.swift
│   │   └── DataProvider.swift
│   └── Speech/
│       ├── SpeechRecognizer.swift
│       └── SpeechParser.swift
├── Features/
│   ├── RecordTransaction/                   # Tab 1
│   │   ├── RecordTransactionView.swift
│   │   ├── RecordTransactionViewModel.swift
│   │   ├── VoiceInputButton.swift
│   │   └── CategorySelector.swift
│   ├── Detail/                              # NEW: Tab 2
│   │   ├── DetailView.swift
│   │   ├── DetailViewModel.swift
│   │   └── TransactionRow.swift
│   ├── BudgetOverview/                      # Tab 3
│   │   ├── BudgetOverviewView.swift
│   │   ├── BudgetOverviewViewModel.swift
│   │   ├── PeriodPicker.swift
│   │   ├── BudgetBarChart.swift
│   │   └── BudgetBarRow.swift
│   └── Settings/                            # Tab 4
│       ├── SettingsView.swift
│       ├── SettingsViewModel.swift
│       ├── BudgetTotalEditor.swift
│       ├── RatioSliderList.swift
│       └── FixedExpenseList.swift           # NEW
├── Shared/
│   ├── Utilities/
│   │   ├── AmountParser.swift
│   │   ├── RatioCalculator.swift
│   │   └── PeriodCalculator.swift
│   ├── Components/
│   │   ├── ConfirmDialog.swift
│   │   ├── ToastBanner.swift
│   │   ├── EmptyStateView.swift
│   │   └── FloatingActionButton.swift       # NEW
│   └── Extensions/
│       ├── Decimal+Extensions.swift
│       ├── Color+Extensions.swift
│       └── String+Localization.swift
└── Resources/
    └── tithe_budget.xcdatamodeld/
```

---

## 原型互動行為 → 開發驗收標準

| 行為 | 原型 demo | SwiftUI 驗收 |
|------|----------|-------------|
| 輸入金額後 FAB 彈出 | ✅ | 金額 > 0 且分類已選時 FAB 出現 |
| 語音按鈕長按 pulse 動畫 | ✅ | `.onLongPressGesture` + 紅色 scale 動畫 |
| 分類選中發光 | ✅ | `.overlay(RoundedRectangle.stroke(accent))` |
| 明細月切換 | ✅ | ◀ ▶ 按鈕，上限鎖定當前月 |
| 長條圖 0.8s 過渡 | ✅ | `.animation(.spring(), value: barWidth)` |
| 滑桿拖動即時聯動 | ✅ | `@Binding` + `RatioCalculator.redistributeRatios` |
| 設定有未儲存 → FAB 出現 | ✅ | `@Published hasUnsavedChanges` + ZStack overlay |
| Toast 2 秒後滑出 | ✅ | `.transition(.move(edge: .top))` + `DispatchQueue.main.asyncAfter` |