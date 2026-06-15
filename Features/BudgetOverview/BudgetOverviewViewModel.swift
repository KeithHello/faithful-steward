import Foundation
import Combine

/// 单列类别行资料：用于 BudgetBarRow 渲染
struct CategoryRowData: Identifiable {
    /// 分类
    let category: Category
    /// 实际花费比例
    let actualRatio: Double
    /// 预算比例
    let budgetRatio: Double
    /// 差异值（actual - budget）
    let difference: Double
    /// 实际花费金额
    let actualAmount: Double
    /// 预算金额
    let budgetAmount: Double
    /// 是否超出预算
    var isOverBudget: Bool {
        difference > 0.001
    }

    var id: String { category.rawValue }
}

/// 预算总览 ViewModel：负责周期聚合、比例计算与 CategoryRowData 组装。
@MainActor
class BudgetOverviewViewModel: ObservableObject {
    // MARK: - 依赖

    private let dataProvider: DataProvider

    // MARK: - 发布属性

    /// 当前选中的检视周期
    @Published var selectedPeriod: Period = .currentMonth

    /// 各分类的资料行
    @Published var categoryRows: [CategoryRowData] = []

    /// 周期内总花费
    @Published var totalSpent: Double = 0

    /// 周期预算总额（多个月加总）
    @Published var budgetTotal: Double = 0

    /// 周期内是否有任何纪录
    @Published var isEmpty: Bool = true

    /// 错误讯息
    @Published var errorMessage: String? = nil

    // MARK: - 初始化

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    // MARK: - 资料载入

    /// 根据当前周期载入资料并计算
    func loadData() {
        do {
            let range = PeriodCalculator.dateRange(for: selectedPeriod)

            // 1. 查询交易纪录
            let transactions = try dataProvider.fetchTransactions(from: range.start, to: range.end)

            guard !transactions.isEmpty else {
                isEmpty = true
                categoryRows = buildEmptyRows()
                totalSpent = 0
                budgetTotal = 0
                return
            }

            isEmpty = false
            totalSpent = transactions.reduce(0) { $0 + $1.amount }

            // 2. 计算实际比例与金额
            let actualRatios = RatioCalculator.calculateActualRatios(transactions: transactions)
            let actualAmounts = RatioCalculator.calculateActualAmounts(transactions: transactions)

            // 3. 取得周期内所有 monthKey
            let monthKeys = PeriodCalculator.allMonthKeys(for: selectedPeriod)

            // 4. 查询对应月份预算设定
            let budgetConfigs = try dataProvider.fetchBudgetConfigs(forMonthKeys: monthKeys)

            // 5. 汇总预算
            let (totalBudget, budgetRatios, budgetAmounts) = aggregateBudgets(
                configs: budgetConfigs,
                monthKeys: monthKeys,
                actualAmounts: actualAmounts
            )
            self.budgetTotal = totalBudget

            // 6. 计算差异
            let differences = RatioCalculator.calculateDifference(actual: actualRatios, budget: budgetRatios)

            // 7. 组装 CategoryRowData
            categoryRows = Category.allCases.map { category in
                CategoryRowData(
                    category: category,
                    actualRatio: actualRatios[category] ?? 0,
                    budgetRatio: budgetRatios[category] ?? category.defaultRatio,
                    difference: differences[category] ?? 0,
                    actualAmount: actualAmounts[category] ?? 0,
                    budgetAmount: budgetAmounts[category] ?? 0
                )
            }

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            isEmpty = true
            categoryRows = buildEmptyRows()
        }
    }

    /// 切换检视周期
    func switchPeriod(_ period: Period) {
        selectedPeriod = period
        loadData()
    }

    // MARK: - Private

    /// 汇总多个月预算设定
    /// - Returns: (总预算额, 加权平均预算比例, 各分类预算金额)
    private func aggregateBudgets(
        configs: [BudgetConfigEntity],
        monthKeys: [String],
        actualAmounts: [Category: Double]
    ) -> (total: Double, ratios: [Category: Double], amounts: [Category: Double]) {
        // 若无任何预算设定，使用预设值
        guard !configs.isEmpty else {
            let defaultBudget = 30000.0 * Double(monthKeys.count)
            let defaultRatios = Category.defaultRatios
            var defaultAmounts: [Category: Double] = [:]
            for (cat, ratio) in defaultRatios {
                defaultAmounts[cat] = defaultBudget * ratio
            }
            return (defaultBudget, defaultRatios, defaultAmounts)
        }

        // 加总所有月份的 monthlyTotal
        let totalBudget = configs.reduce(0.0) { $0 + $1.monthlyTotal }

        // 按月总额加权平均比例
        var weightedRatios: [Category: Double] = [:]
        for config in configs {
            let ratios = DataProvider.decodeRatiosFromJSON(config.ratiosJSON ?? "")
            let weight = totalBudget > 0 ? config.monthlyTotal / totalBudget : 0
            for (category, ratio) in ratios {
                weightedRatios[category, default: 0] += ratio * weight
            }
        }

        // 确保所有分类都有值
        for category in Category.allCases {
            if weightedRatios[category] == nil {
                weightedRatios[category] = category.defaultRatio
            }
        }

        // 计算各分类预算金额
        var budgetAmounts: [Category: Double] = [:]
        for (category, ratio) in weightedRatios {
            budgetAmounts[category] = totalBudget * ratio
        }

        return (totalBudget, weightedRatios, budgetAmounts)
    }

    /// 建立空资料行（所有值为 0，用于无资料时的显示）
    private func buildEmptyRows() -> [CategoryRowData] {
        Category.allCases.map { category in
            CategoryRowData(
                category: category,
                actualRatio: 0,
                budgetRatio: category.defaultRatio,
                difference: 0,
                actualAmount: 0,
                budgetAmount: 0
            )
        }
    }
}
