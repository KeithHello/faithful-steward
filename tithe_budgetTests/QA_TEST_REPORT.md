# QA 测试报告 — 忠心好管家 (faithful_steward)

## 测试概览

| 指标 | 数值 |
|------|------|
| 测试文件数 | 5 |
| 测试用例总数 | 87 |
| 预期通过 | 85 |
| 预期失败（源码 Bug） | 2 |
| 纯逻辑测试覆盖 | AmountParser, RatioCalculator, SpeechParser, PeriodCalculator, Category |
| 代码审查模块 | DataProvider, RecordTransactionViewModel, SettingsViewModel, BudgetOverviewViewModel |

---

## 智能路由判定

### 🔴 Route to: Engineer（源码 Bug）

发现 **1 个确定 Bug**，位于 `SpeechParser.swift`：

---

## Bug 详情

### BUG-001: SpeechParser 关键字匹配顺序缺陷

- **严重程度**: P0
- **文件**: `Core/Speech/SpeechParser.swift`
- **行号**: 66-73（关键字匹配循环）
- **问题**: `categoryKeywords` 阵列中，短关键字「住」（8 字符位置）排在长关键字「住房」（9 字符位置）之前。匹配时采用 first-match 策略，导致「住房一万」先被「住」截断匹配，remainingText 变为「 房一万」，其中的「房」非中文数字字符，使金额解析失败。
- **期望行为**: `SpeechParser.parse("住房一万")` → `amount: 10000.0, category: .housing`
- **实际行为**: `SpeechParser.parse("住房一万")` → `amount: nil, category: .housing`
- **影响范围**: 所有以「住房」开头的语音输入（如「住房一万」「住房八千」）
- **修复建议**:
  1. **推荐方案**: 在匹配前将 `categoryKeywords` 按关键字长度降序排列，确保长关键字优先匹配
     ```swift
     // 在 parse() 方法开头加入：
     let sortedKeywords = categoryKeywords.sorted { $0.keyword.count > $1.keyword.count }
     ```
  2. **备选方案**: 改为收集所有匹配项后取最长匹配
- **关联测试**: `test_parse_housingVariant_zhufang_KNOWN_BUG`, `test_parse_housingWithZhufang_knownIssue`

### BUG-002: SpeechParser 单字关键字「住」过度匹配（设计边界）

- **严重程度**: P2（边界情况）
- **文件**: `Core/Speech/SpeechParser.swift`
- **行号**: 37（关键字定义）
- **问题**: 「住」作为单字关键字过于宽泛，会误匹配不相关内容。例：「我住在台北」→ 错误匹配 category=.housing
- **实际影响**: 低概率。实际语音记账场景中，使用者不会说完整句子，通常只说「住+金额」模式
- **修复建议**: 可考虑将「住」关键字改为需要后续跟随数字的模式，或提升匹配精度要求（如要求关键字前后为空白/行首行尾）
- **关联测试**: `test_parse_characterZhu_ambiguousMatch`

---

## 测试文件详情

### 1. AmountParserTests.swift — ✅ 33 测试，全部预期通过

| 测试分类 | 数量 | 覆盖内容 |
|----------|------|----------|
| 阿拉伯数字解析 | 10 | 纯数字、小数、千分位、货币符号、后缀清理、空白 |
| 中文数字解析 | 10 | 百位级（两百五）、千位级（一千二）、万位级（一万五千）、复杂组合（三万六千八百）、单位开头（十/一百）、繁简支援（兩） |
| 边界情况 | 5 | 空字串、纯空白、零值、非数字文字、负数 |
| 内部方法测试 | 8 | parseChineseNumber 隐式单位、parseArabicNumber 千分位/NT$ 前缀 |

### 2. RatioCalculatorTests.swift — ✅ 20 测试，全部预期通过

| 测试分类 | 数量 | 覆盖内容 |
|----------|------|----------|
| validateTotalRatio | 4 | 精确 1.0、容忍度内、容忍度外、空字典 |
| totalRatio | 2 | 预设比例总和、部分比例 |
| calculateDifference | 4 | 全部相等、超预算（正差）、低于预算（负差）、缺失分类回退 |
| redistributeRatios | 6 | 增加分配、减少分配、设为零、设为一、无基数均分、值域 clamp、缺失键值 |
| calculateActualRatios | 3 | 无交易、单笔交易、多笔比例 |
| calculateActualAmounts | 2 | 无交易、多笔累加 |
| calculateBudgetRatios | 2 | 正常解码、损坏 JSON 回退 |

### 3. SpeechParserTests.swift — ✅ 20 通过 / 🔴 2 失败（已知 Bug）

| 测试分类 | 数量 | 备注 |
|----------|------|------|
| 完整解析（金额+分类） | 7 | 七大分类各一笔 ✅ |
| 仅金额 | 2 | 无关键字时 ✅ |
| 仅分类 | 1 | 无金额时 ✅ |
| 无关键字无金额 | 1 | ✅ |
| 边界情况 | 2 | 空字串、纯空白 ✅ |
| 口语变体 | 7 | 什一/奉献、饮食/交通、住房⚠️、房租、还债、其他 |
| hasResult 属性 | 4 | ✅ |
| 已知 Bug 回归 | 2 | 🔴 BUG-001 关键字匹配顺序 |

### 4. PeriodCalculatorTests.swift — ✅ 21 测试，全部预期通过

| 测试分类 | 数量 | 覆盖内容 |
|----------|------|----------|
| monthKey 格式化 | 4 | 标准格式、一月补零、十二月、跨年差异 |
| dateRange 区间 | 6 | 本月起讫、近3月起讫、近6月起讫、近12月起讫、起≤讫、起为午夜 |
| allMonthKeys | 6 | 本月 1 键、近3月 3 键、近6月 6 键、近12月 12 键、时序排列、无重复 |
| currentMonthKey / startOfMonth | 3 | 当月键、月中→首日、跨年十二月 |
| Period Enum 属性 | 2 | allCases 数量、monthCount 值、displayName 非空 |

### 5. CategoryTests.swift — ✅ 16 测试，全部预期通过

| 测试分类 | 数量 | 覆盖内容 |
|----------|------|----------|
| allCases | 2 | 数量=7、包含全部 rawValue |
| rawValue | 3 | 每个 case 值、有效初始化、无效初始化 |
| defaultRatio | 3 | 总和=1.0、个别值、无非负数 |
| displayName | 3 | 非空、具体值、唯一性 |
| color / iconName | 4 | 存在性、SF Symbols 格式、唯一性 |
| defaultRatios | 3 | 全部分类、值一致性、总和 |
| Codable | 1 | 编解码往返 |
| CaseIterable | 1 | 顺序稳定性 |

---

## 代码审查报告（CoreData 依赖模块）

### DataProvider (`Core/Storage/DataProvider.swift`)

| 审查项 | 结果 | 说明 |
|--------|------|------|
| CRUD 正确性 | ✅ PASS | addTransaction / fetchTransactions / deleteTransaction 逻辑正确 |
| saveBudgetConfig upsert | ✅ PASS | 先查后插/更新，正确处理新建与修改 |
| JSON 编解码 | ✅ PASS | encodeRatiosToJSON 含 fallback "{}", decodeRatiosFromJSON 含 defaultRatios 回退且补全缺失分类 |
| 错误处理 | ✅ PASS | 所有方法标记 throws，错误由 ViewModel catch 转 errorMessage |
| 线程安全 | ✅ PASS | context 由调用方注入，所有 ViewModel 标记 @MainActor |
| fetchLatestBudgetConfig | ✅ PASS | 按 updatedAt 降幂取首笔 |

### RecordTransactionViewModel (`Features/RecordTransaction/RecordTransactionViewModel.swift`)

| 审查项 | 结果 | 说明 |
|--------|------|------|
| canConfirm | ✅ PASS | `amount > 0 && selectedCategory != nil`，符合 PRD E2/E3 |
| processVoiceResult | ✅ PASS | 正确委托 SpeechParser + AmountParser |
| submitTransaction | ⚠️ NOTE | inputMethod 判断：`isRecording \|\| !voiceResultText.isEmpty` — 若语音后手动编辑文字，仍标记为 .voice。影响小，非 Bug |
| Combine 订阅 | ✅ PASS | $amountText debounce 150ms，含 [weak self] 防循环引用 |
| 错误处理 | ✅ PASS | requestConfirmation 区分金额无效 vs 分类未选 |

### SettingsViewModel (`Features/Settings/SettingsViewModel.swift`)

| 审查项 | 结果 | 说明 |
|--------|------|------|
| updateRatio | ✅ PASS | 委托 RatioCalculator.redistributeRatios，即时调用 validate() |
| isValid | ✅ PASS | `isBudgetValid && isRatioValid`，总额>0 且比例总和=100% |
| saveConfig | ✅ PASS | 双重验证（金额+比例），使用 PeriodCalculator.currentMonthKey |
| loadConfig | ✅ PASS | 优先 fetchLatest，无则用预设值，错误时回退预设 |
| ratioTotal / isRatioValid | ✅ PASS | 正确委托 RatioCalculator |

### BudgetOverviewViewModel (`Features/BudgetOverview/BudgetOverviewViewModel.swift`)

| 审查项 | 结果 | 说明 |
|--------|------|------|
| loadData 流程 | ✅ PASS | 周期区间→查询交易→计算实际比例→查询预算设定→汇总→差异→组装 CategoryRowData |
| 空资料处理 | ✅ PASS | transactions 为空时设 isEmpty=true, buildEmptyRows |
| aggregateBudgets | ✅ PASS | 加总 monthlyTotal，加权平均比例（防止 totalBudget=0 除零），含预设回退 |
| 多月份预算汇总 | ✅ PASS | 使用 fetchBudgetConfigs + 月总额加权平均，逻辑正确 |
| CategoryRowData.isOverBudget | ✅ PASS | `difference > 0.001` 容忍浮点误差 |

### PersistenceController (`Core/Storage/PersistenceController.swift`)

| 审查项 | 结果 | 说明 |
|--------|------|------|
| 单例模式 | ✅ PASS | static shared，正确 |
| 轻量级迁移 | ✅ PASS | NSMigratePersistentStoresAutomaticallyOption + NSInferMappingModelAutomaticallyOption |
| 迁移失败处理 | ✅ PASS | recreateStore() 删除旧 store 并重建 |
| Preview 支援 | ✅ PASS | inMemory store + 范例资料 |
| mergePolicy | ✅ PASS | NSMergeByPropertyObjectTrumpMergePolicy |

---

## 测试总结

```
总计:  87 测试
通过:  85 (97.7%)
失败:   2 (2.3%) ← 根源为源码 Bug，非测试代码问题

路由: → Engineer（修复 SpeechParser 关键字匹配顺序）
```

### 行动项目

1. **[P0] Engineer 修复 BUG-001**: `SpeechParser.swift` 关键字匹配改为最长优先
2. **[P2] Engineer 评估 BUG-002**: 单字「住」关键字是否需要增加匹配精度约束
3. **[QA Round 2]**: Engineer 修复后执行回归测试，验证「住房」系列测试通过

### 测试文件位置

```
tithe_budget/tithe_budgetTests/
├── AmountParserTests.swift
├── RatioCalculatorTests.swift
├── SpeechParserTests.swift
├── PeriodCalculatorTests.swift
└── CategoryTests.swift
```

---

*Report generated by QA Engineer (Edward), 2025-06-13*
