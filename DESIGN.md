# DESIGN.md — 忠心好管家（Faithful Steward）

> 設計系統令牌文檔 | 基於 Notion 定制版  
> 版本：v1.0 | 最後更新：2026-06-14

---

## 相關文檔

| 文檔 | 路徑 | 用途 |
|------|------|------|
| **開發總入口** | `DEVELOPMENT.md` | 架構對照 + SwiftUI 映射 + 實作指引 |
| **系統架構** | `architecture-tithe-budget.md` | 核心框架、資料結構、任務分解 |
| **UI 原型** | `prototype/index.html` | 可互動原型（iPhone 393×852） |
| **原型 README** | `prototype/README.md` | 原型結構 + CSS 層級 + JS 狀態說明 |

---

## §1 視覺主題（Visual Theme）

**定位**：Soft Warm × Modern Minimal 交匯點  
**一句話**：像管家一樣陪伴你的個人理財工具 — 溫暖但不甜膩，專業但不冰冷。

**核心原則**：
- 溫暖來自暖白底色 + 有生命感的綠色主調
- 專業來自絕對清晰的資訊層級 + 8px 網格紀律
- 可信賴來自狀態顏色（綠/紅）的即時語義反饋
- iOS 原生感來自系統級圓角曲線 + SF 字體家族

**拒絕**：冷灰色銀行報表、花俏遊戲化介面、過度裝飾

---

## §2 調色板（Color Palette）

### 2.1 主色（Primary）

| Token | 色值 | 用途 |
|-------|------|------|
| `--color-primary` | `#5B8C5A` | 主按鈕、Tab 選中態、主要強調 |
| `--color-primary-light` | `#E8F2E7` | 主色淺底、選中背景 |
| `--color-primary-dark` | `#3D6B3C` | 長按按壓態 |
| `--color-primary-disabled` | `#A8C8A7` | 主按鈕禁用態 |

**設計意圖**：舊銅綠 × 鼠尾草的混合色調，沉穩可靠有生命力，象徵「管家」的培育與責任。

### 2.2 暖灰階（Neutral — Warm-Tinted）

| Token | 色值 | OKLCh 近似 | 用途 |
|-------|------|-----------|------|
| `--color-bg` | `#FBFAF8` | L:0.98 | 頁面背景 |
| `--color-surface` | `#F5F3F0` | L:0.95 | 卡片/區塊背景 |
| `--color-surface-hover` | `#EEECE8` | L:0.93 | 卡片按壓態 |
| `--color-border` | `#E0DDD8` | L:0.88 | 分隔線、邊框 |
| `--color-border-strong` | `#C8C4BD` | L:0.80 | 強調邊框 |
| `--color-text-primary` | `#1D1B1A` | L:0.12 | 主要文字 |
| `--color-text-secondary` | `#5E5A56` | L:0.38 | 次要文字 |
| `--color-text-tertiary` | `#94908B` | L:0.58 | 輔助/佔位文字 |
| `--color-text-inverse` | `#FFFFFF` | — | 深色底反白字 |

### 2.3 語義色（Semantic）

| Token | 色值 | 用途 |
|-------|------|------|
| `--color-success` | `#4A9E5C` | 預算結餘、成功狀態 |
| `--color-success-light` | `#E6F4E9` | 結餘長條圖、成功 Toast 底 |
| `--color-danger` | `#D94A4A` | 預算超支、錯誤狀態 |
| `--color-danger-light` | `#FCE8E8` | 超支長條圖、錯誤 Toast 底 |
| `--color-warning` | `#E8A840` | 警告提示 |
| `--color-warning-light` | `#FDF3DF` | 警告 Toast 底 |
| `--color-info` | `#5B8CA8` | 資訊提示 |

### 2.4 7 大分類專屬色（Category Palette）

全部校準在 oklch 中等彩度（C:0.08–0.14）範圍內，和諧共存但保有足夠區分度。

| # | 分類 | 主色 | 淺底色 | 語義 |
|---|------|------|--------|------|
| 1 | 十一奉獻 | `#C47DA7` | `#F5E8F0` | 玫瑰粉 — 敬虔奉獻 |
| 2 | 孝親費 | `#D4A057` | `#F9F0E1` | 琥珀金 — 感恩回報 |
| 3 | 交際費 | `#7DAEBF` | `#E4F0F5` | 霧藍 — 開朗社交 |
| 4 | 租房買房(住) | `#8C7DC4` | `#EDE8F7` | 薰衣草紫 — 安穩歸屬 |
| 5 | 還款存款保險投資 | `#5B7FAD` | `#E4EBF5` | 鋼藍 — 穩健理財 |
| 6 | 生活必需(食行) | `#5B8C5A` | `#E8F2E7` | 鼠尾草綠 — 日常活力 |
| 7 | 彈性運用(衣通訊) | `#C47D6B` | `#F5EBE7` | 陶土橙 — 靈活自由 |

### 2.5 顏色使用規則

- 分類色只用於**圖標**、**分類標籤**和**長條圖列**，不用於文字（無障礙考量）
- 文字色只用 `--color-text-primary` / `--color-text-secondary` / `--color-text-tertiary`
- 長條圖：綠色底 = 結餘（`--color-success-light`），紅色底 = 超支（`--color-danger-light`）
- 所有色值組合需通過 WCAG AA 對比度（≥4.5:1 文字，≥3:1 大文字）

---

## §3 排版（Typography）

### 3.1 字體棧

| 用途 | 字體 | 備註 |
|------|------|------|
| 繁體中文 | `'PingFang TC', 'Noto Sans TC', sans-serif` | iOS 原生 |
| 數字/金額 | `'SF Mono', 'Menlo', monospace` | 數字對齊 |
| 英文/拉丁 | `'Inter', -apple-system, sans-serif` | 標題/輔助 |

### 3.2 排版層級（iOS 風格 12 級）

| Token | 字級 | 字重 | 行高 | 用途 |
|-------|------|------|------|------|
| `--text-display` | 34px | 700 | 1.2 | 頁面大標題（總覽總金額） |
| `--text-title1` | 28px | 700 | 1.25 | Tab 頁面標題 |
| `--text-title2` | 22px | 600 | 1.3 | 區塊標題 |
| `--text-title3` | 20px | 600 | 1.35 | 卡片標題 |
| `--text-headline` | 17px | 600 | 1.4 | 分類主標題 |
| `--text-body` | 17px | 400 | 1.5 | 主要內文 |
| `--text-callout` | 16px | 400 | 1.5 | 輔助說明 |
| `--text-subhead` | 15px | 400 | 1.45 | 副標題 |
| `--text-footnote` | 13px | 400 | 1.4 | 腳註文字 |
| `--text-caption1` | 12px | 400 | 1.35 | 次要標籤 |
| `--text-caption2` | 11px | 400 | 1.3 | 最小文字 |
| `--text-amount` | 24px | 600 | 1.3 | 金額數字專用 |

---

## §4 組件樣式（Component Tokens）

### 4.1 按鈕（Button）

| Token | 值 |
|-------|---|
| `--btn-primary-bg` | `var(--color-primary)` |
| `--btn-primary-text` | `#FFFFFF` |
| `--btn-primary-radius` | `12px` |
| `--btn-primary-height` | `52px` |
| `--btn-primary-font` | `var(--text-headline)` |
| `--btn-secondary-bg` | `var(--color-surface)` |
| `--btn-secondary-text` | `var(--color-text-primary)` |
| `--btn-secondary-border` | `var(--color-border)` |
| `--btn-icon-size` | `44px` |
| `--btn-icon-radius` | `12px` |

### 4.2 分類方格（Category Grid）

| Token | 值 |
|-------|---|
| `--cat-grid-cols` | `3` |
| `--cat-grid-gap` | `12px` |
| `--cat-item-radius` | `16px` |
| `--cat-item-padding` | `16px 12px` |
| `--cat-item-icon-size` | `32px` |
| `--cat-item-selected-border` | `2px solid var(--color-primary)` |
| `--cat-item-selected-bg` | `var(--color-primary-light)` |

### 4.3 卡片（Card）

| Token | 值 |
|-------|---|
| `--card-radius` | `16px` |
| `--card-padding` | `20px` |
| `--card-bg` | `#FFFFFF` |
| `--card-shadow` | `var(--shadow-sm)` |
| `--card-border` | `1px solid var(--color-border)` |

### 4.4 輸入框（Input）

| Token | 值 |
|-------|---|
| `--input-height` | `56px` |
| `--input-radius` | `12px` |
| `--input-bg` | `#FFFFFF` |
| `--input-border` | `1.5px solid var(--color-border)` |
| `--input-border-focus` | `1.5px solid var(--color-primary)` |
| `--input-font` | `var(--text-amount)` |
| `--input-padding` | `0 16px` |

### 4.5 滑桿（Slider）

| Token | 值 |
|-------|---|
| `--slider-track-height` | `6px` |
| `--slider-track-radius` | `3px` |
| `--slider-track-bg` | `var(--color-border)` |
| `--slider-track-fill` | `var(--color-primary)` |
| `--slider-thumb-size` | `24px` |
| `--slider-thumb-shadow` | `var(--shadow-sm)` |
| `--slider-row-height` | `56px` |

### 4.6 長條圖（Bar Chart）

| Token | 值 |
|-------|---|
| `--bar-height` | `40px` |
| `--bar-radius` | `8px` |
| `--bar-gap` | `8px` |
| `--bar-budget-color` | `var(--color-success-light)` |
| `--bar-over-color` | `var(--color-danger-light)` |
| `--bar-transition` | `width 0.6s var(--ease-out)` |

### 4.7 ToastBanner

| Token | 值 |
|-------|---|
| `--toast-radius` | `12px` |
| `--toast-padding` | `14px 20px` |
| `--toast-max-width` | `343px` |
| `--toast-top` | `16px` |

### 4.8 TabBar

| Token | 值 |
|-------|---|
| `--tabbar-height` | `84px` |
| `--tabbar-bg` | `rgba(251, 250, 248, 0.85)` |
| `--tabbar-blur` | `blur(20px)` |
| `--tab-icon-size` | `24px` |
| `--tab-label-font` | `var(--text-caption2)` |

### 4.9 ConfirmDialog

| Token | 值 |
|-------|---|
| `--dialog-radius` | `20px` |
| `--dialog-padding` | `24px` |
| `--dialog-bg` | `#FFFFFF` |
| `--dialog-overlay` | `rgba(0, 0, 0, 0.4)` |
| `--dialog-max-width` | `320px` |

---

## §5 佈局與間距（Layout & Spacing）

### 5.1 8px 網格系統

| Token | 值 | 用途 |
|-------|---|------|
| `--space-xs` | `4px` | 圖標與文字間的緊湊間距 |
| `--space-sm` | `8px` | 元素內間距 |
| `--space-md` | `16px` | 組件間距 |
| `--space-lg` | `24px` | 區塊間距 |
| `--space-xl` | `32px` | 頁面大區塊間距 |
| `--space-2xl` | `48px` | 頁面級分隔 |

### 5.2 螢幕基準

| Token | 值 |
|-------|---|
| `--viewport-width` | `393px` |
| `--viewport-height` | `852px` |
| `--safe-area-top` | `54px` |
| `--safe-area-bottom` | `34px` |
| `--content-padding-x` | `20px` |

### 5.3 圓角體系

| Token | 值 | 用途 |
|-------|---|------|
| `--radius-xs` | `6px` | 標籤、徽章 |
| `--radius-sm` | `8px` | 長條圖、小型元件 |
| `--radius-md` | `12px` | 按鈕、輸入框、滑桿 |
| `--radius-lg` | `16px` | 卡片、分類方格 |
| `--radius-xl` | `20px` | 對話框、浮層 |
| `--radius-full` | `9999px` | 藥丸形、圓形元件 |

---

## §6 深度與陰影（Depth & Shadows）

### 6.1 陰影層級

| Token | 值 | 用途 |
|-------|---|------|
| `--shadow-xs` | `0 1px 2px rgba(0,0,0,0.04)` | 微浮起、卡片預設 |
| `--shadow-sm` | `0 2px 8px rgba(0,0,0,0.06)` | 滑桿 thumb、浮動按鈕 |
| `--shadow-md` | `0 4px 16px rgba(0,0,0,0.08)` | Toast、下拉選單 |
| `--shadow-lg` | `0 8px 32px rgba(0,0,0,0.12)` | 對話框、覆蓋層 |

### 6.2 Z-Index 體系

| Token | 值 | 用途 |
|-------|---|------|
| `--z-base` | `0` | 內容層 |
| `--z-dropdown` | `100` | 周期下拉 |
| `--z-sticky` | `200` | TabBar |
| `--z-toast` | `300` | ToastBanner |
| `--z-overlay` | `400` | 對話框遮罩 |
| `--z-dialog` | `500` | ConfirmDialog |
| `--z-tooltip` | `600` | 分類提示 Tooltip |

---

## §7 動效（Animation）

### 7.1 Easing Tokens

| Token | cubic-bezier | 用途 |
|-------|-------------|------|
| `--ease-out` | `cubic-bezier(0.16, 1, 0.3, 1)` | 彈出、展開 |
| `--ease-in` | `cubic-bezier(0.7, 0, 0.84, 0)` | 收起、消失 |
| `--ease-in-out` | `cubic-bezier(0.65, 0, 0.35, 1)` | 滑桿拖動、連續動畫 |
| `--ease-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | 彈性過度動畫 |

### 7.2 動效定義

| 動效 | 屬性 | 時長 | Easing |
|------|------|------|--------|
| 語音按鈕 pulse | `scale(1→1.15), opacity(1→0.6)` | 1.2s 循環 | `--ease-in-out` |
| 長條圖 transition | `width` | 0.6s | `--ease-out` |
| 滑桿聯動 | `left` / `width` | 0.2s | `--ease-in-out` |
| Toast 滑入 | `translateY(-20→0), opacity(0→1)` | 0.4s | `--ease-out` |
| Toast 滑出 | `translateY(0→-20), opacity(1→0)` | 0.3s | `--ease-in` |
| 對話框出現 | `scale(0.9→1), opacity(0→1)` | 0.3s | `--ease-spring` |
| 對話框消失 | `scale(1→0.95), opacity(1→0)` | 0.2s | `--ease-in` |
| 分類選中 | `border-color, background-color` | 0.15s | `--ease-out` |

---

## §8 注意事項（Do's & Don'ts）

### 8.1 禁止事項（DON'T）

1. ❌ 不要使用純黑 `#000000` 或純白 `#FFFFFF` 作為主要表面色
2. ❌ 不要將分類色用於文字 — 文字只用暖中性色
3. ❌ 不要使用 `box-shadow` 模擬邊框 — 用 `border`
4. ❌ 不要在一個畫面中使用超過 3 個不同的圓角值
5. ❌ 不要讓任何文字小於 11px
6. ❌ 不要跳過 WCAG AA 對比度檢查
7. ❌ 不要使用超過 300ms 的過渡動畫（非彈出類）
8. ❌ 不要在長條圖中使用純紅色或純綠色 — 使用淺底變體

### 8.2 推薦事項（DO）

1. ✅ 優先使用 `--color-bg` / `--color-surface` / `--color-text-*` tokens
2. ✅ 長條圖標籤放在條外，而非條內（無障礙）
3. ✅ 分類方格保持 3 列對齊，第 3 行只有 1 個時置左
4. ✅ ToastBanner 固定頂部，2 秒自動消失
5. ✅ 滑桿值即時顯示百分比，總和 ≠ 100% 時紅色提示
6. ✅ 空資料狀態統一使用 EmptyStateView（圖示 + 引導文字）
7. ✅ 所有互動元素至少 44×44px 觸控區域
8. ✅ 繁體中文全部使用全形標點
9. ✅ 金額數字使用 `--text-amount` + 等寬數字字體
10. ✅ TabBar 使用毛玻璃背景（iOS 風格）

---

## §9 Agent 生成指南（Agent Generation Guide）

### 9.1 完整 CSS 變數速查

```css
:root {
  /* ── 主色 ── */
  --color-primary: #5B8C5A;
  --color-primary-light: #E8F2E7;
  --color-primary-dark: #3D6B3C;

  /* ── 暖灰階（背景+表面） ── */
  --color-bg: #FBFAF8;
  --color-surface: #F5F3F0;
  --color-surface-hover: #EEECE8;
  --color-border: #E0DDD8;
  --color-border-strong: #C8C4BD;

  /* ── 暖灰階（文字） ── */
  --color-text-primary: #1D1B1A;
  --color-text-secondary: #5E5A56;
  --color-text-tertiary: #94908B;
  --color-text-inverse: #FFFFFF;

  /* ── 語義色 ── */
  --color-success: #4A9E5C;
  --color-success-light: #E6F4E9;
  --color-danger: #D94A4A;
  --color-danger-light: #FCE8E8;
  --color-warning: #E8A840;
  --color-warning-light: #FDF3DF;

  /* ── 7 大分類色 ── */
  --cat-tithe: #C47DA7;
  --cat-tithe-light: #F5E8F0;
  --cat-filial: #D4A057;
  --cat-filial-light: #F9F0E1;
  --cat-social: #7DAEBF;
  --cat-social-light: #E4F0F5;
  --cat-housing: #8C7DC4;
  --cat-housing-light: #EDE8F7;
  --cat-debt: #5B7FAD;
  --cat-debt-light: #E4EBF5;
  --cat-food: #5B8C5A;
  --cat-food-light: #E8F2E7;
  --cat-flexible: #C47D6B;
  --cat-flexible-light: #F5EBE7;

  /* ── 字體 ── */
  --font-cn: 'PingFang TC', 'Noto Sans TC', sans-serif;
  --font-en: 'Inter', -apple-system, sans-serif;
  --font-mono: 'SF Mono', 'Menlo', monospace;

  /* ── 字級 ── */
  --text-display: 700 34px/1.2 var(--font-cn);
  --text-title1: 700 28px/1.25 var(--font-cn);
  --text-title2: 600 22px/1.3 var(--font-cn);
  --text-headline: 600 17px/1.4 var(--font-cn);
  --text-body: 400 17px/1.5 var(--font-cn);
  --text-callout: 400 16px/1.5 var(--font-cn);
  --text-footnote: 400 13px/1.4 var(--font-cn);
  --text-caption1: 400 12px/1.35 var(--font-cn);
  --text-caption2: 400 11px/1.3 var(--font-cn);
  --text-amount: 600 24px/1.3 var(--font-mono);

  /* ── 間距 ── */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;
  --space-2xl: 48px;

  /* ── 圓角 ── */
  --radius-xs: 6px;
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-xl: 20px;
  --radius-full: 9999px;

  /* ── 陰影 ── */
  --shadow-xs: 0 1px 2px rgba(0,0,0,0.04);
  --shadow-sm: 0 2px 8px rgba(0,0,0,0.06);
  --shadow-md: 0 4px 16px rgba(0,0,0,0.08);
  --shadow-lg: 0 8px 32px rgba(0,0,0,0.12);

  /* ── 動效 ── */
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in: cubic-bezier(0.7, 0, 0.84, 0);
  --ease-in-out: cubic-bezier(0.65, 0, 0.35, 1);
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);

  /* ── 視口 ── */
  --viewport-width: 393px;
  --viewport-height: 852px;
  --safe-top: 54px;
  --safe-bottom: 34px;
  --content-px: 20px;
}
```

### 9.2 畫面結構圖

```
┌─────────────────────────────┐ ← 393px
│      Safe Area Top (54px)   │
├─────────────────────────────┤
│          Tab Content         │
│  ┌───────────────────────┐  │
│  │   Tab 1: 記帳         │  │
│  │   - 金額輸入欄        │  │
│  │   - 語音按鈕          │  │
│  │   - 7類方格選擇器     │  │
│  │   - 確認記帳按鈕      │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │   Tab 2: 總覽         │  │
│  │   - 周期下拉          │  │
│  │   - 總金額摘要卡      │  │
│  │   - 7條長條圖         │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │   Tab 3: 設定         │  │
│  │   - 月預算總額輸入    │  │
│  │   - 7類比例滑桿       │  │
│  │   - 儲存按鈕          │  │
│  └───────────────────────┘  │
├─────────────────────────────┤
│   TabBar (84px,毛玻璃)      │
│   記帳  │  總覽  │  設定    │
├─────────────────────────────┤
│    Safe Area Bottom (34px)  │
└─────────────────────────────┘
```

### 9.3 原型生成要點

1. **單頁 3 螢幕切換**：使用 JavaScript 實現 Tab 切換（無路由）
2. **所有文字繁體中文**：分類名、提示語、按鈕標籤
3. **分類提示 Tooltip**：每個分類方格 hover/長按時顯示副標說明
4. **語音按鈕動畫**：CSS keyframes pulse（scale + opacity 循環）
5. **滑桿聯動邏輯**：JavaScript 處理總和=100% 約束，即時重算
6. **長條圖動畫**：CSS transition width，數據載入後觸發
7. **Toast 自動消失**：setTimeout 2 秒後滑出
8. **空資料狀態**：無交易記錄時顯示 EmptyStateView
9. **對話框**：模擬 ConfirmDialog 彈出/關閉
10. **響應式**：以 393×852 為基準，居中顯示在桌面上

### 9.4 檔案結構

```
prototype/
├── index.html          # 單頁原型（3 個 Tab）
├── styles.css          # 引用 DESIGN.md 變數
└── scripts.js          # 互動邏輯（Tab/滑桿/語音動畫/Toast）
```

---

*文件由彩格調（Design System Expert）在 71 套設計系統中匹配生成，主理人編排彙整。*
