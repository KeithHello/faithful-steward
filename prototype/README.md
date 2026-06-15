# Prototype README — 忠心好管家 UI 原型

> 互動式 HTML/CSS 原型 | iPhone 393×852 模擬
> 版本：v8 | 2026-06-14

---

## 使用方法

### 瀏覽器直接打開
```
file:///E:/develop/self-dev/workbuddy/financial-management/prototype/index.html
```

### 設計系統文件
- `../DESIGN.md` — 完整設計令牌（色彩/排版/動效/佈局）
- `../DEVELOPMENT.md` — 開發總入口（架構對照 + SwiftUI 映射）
- `../architecture-tithe-budget.md` — 系統架構 + 任務分解

---

## 原型結構

```
index.html
├── <style>     # 設計令牌 + 所有 CSS
├── <body>
│   ├── #app                    # iPhone 外框
│   ├── .dynamic-island          # 瀏海
│   ├── #toast                   # Toast 提示層（z-index:3000）
│   ├── #fabRecordWrap           # 記帳 FAB（z-index:1400）
│   ├── #fabSaveWrap             # 儲存 FAB（z-index:1400）
│   ├── #confirmDialog           # 確認記帳彈窗（z-index:2500）
│   ├── #fixedDialog             # 固定支出編輯器（z-index:2500）
│   ├── .content                # 主內容區（可滾動）
│   │   ├── #tab-record         # Tab 1: 記帳
│   │   ├── #tab-detail         # Tab 2: 明細
│   │   ├── #tab-overview       # Tab 3: 總覽
│   │   └── #tab-settings       # Tab 4: 設定
│   └── .tabbar.inne            # 底部導航欄（z-index:1500）
└── <script>                     # 所有 JS 邏輯
```

---

## 四個 Tab 詳情

### Tab 1: 記帳（Record）
- 檔案對應：`Features/RecordTransaction/`
- 功能：Hero 金額顯示 → 語音按鈕（長按 pulse） → 文字輸入 → 7 類方格選擇 → FAB 確認
- 狀態：`state.amount`, `state.selectedCat`, `state.isRec`
- 模擬數據：`mockRes[]`（5 組語音辨識結果）

### Tab 2: 明細（Detail）
- 檔案對應：新功能（`Features/Detail/`）
- 功能：◀▶ 月導航 → Hero Card（總支出+趨勢+統計Pill） → 日期分組交易列表
- 狀態：`detailYear`, `detailMonth`
- 模擬數據：`mockTransactions`（2026-04/05/06 三個月）

### Tab 3: 總覽（Overview）
- 檔案對應：`Features/BudgetOverview/`
- 功能：周期選擇 → Bento 摘要卡 → 相對比例長條圖+圖例
- 關鍵計算：每條 `width = actual / categoryBudget × 100%`

### Tab 4: 設定（Settings）
- 檔案對應：`Features/Settings/`
- 功能：月預算輸入 → 固定支出 CRUD（分類關聯） → 比例滑桿 → 智慧儲存 FAB
- 狀態：`sliderRatios`, `fixedExpenses`, `hasUnsavedChanges`

---

## CSS 層級體系

| z-index | 元件 | 說明 |
|---------|------|------|
| 3000 | Toast | 最高，不可被遮擋 |
| 2500 | Dialog Overlay | 確認彈窗 + 固定支出編輯器 |
| 2000 | Dynamic Island | 瀏海 |
| 1500 | TabBar | 底部毛玻璃導航 |
| 1400 | FAB Wrap | 浮動確認/儲存按鈕 |
| 100 | Tooltip | 分類提示 |
| 0 | Content | 主內容區 |

---

## 設計令牌使用

所有 CSS 變數定義於 `:root`，命名與 `DESIGN.md` §9 一致。SwiftUI 開發時可直接從 `DESIGN.md` 提取等價值。

關鍵變數速查：
```css
--color-accent: #5B8C5A       /* 管家綠 */
--color-bg: #F8F8F7            /* 暖白背景 */
--color-surface: #FFFFFF        /* 卡片表面 */
--color-text: #1A1A18           /* 主要文字 */
--ease: cubic-bezier(0.32, 0.72, 0, 1)  /* spring 動畫 */
```
