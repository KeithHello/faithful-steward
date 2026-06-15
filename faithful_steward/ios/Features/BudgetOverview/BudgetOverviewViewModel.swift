import Foundation
import CoreData
import Combine

/// CategoryRowData — 單一分類的預算對比資料行
struct CategoryRowData: Identifiable {
    let id = UUID()
    let category: Category
    let actualRatio: Double
    let budgetRatio: Double
    let difference: Double
    let actualAmount: Double
    let budgetAmount: Double

    var isOverBudget: Bool { difference > 0.001 }
    var displayName: String { category.displayName }
}

@MainActor
final class BudgetOverviewViewModel: ObservableObject {
    private let dataProvider: DataProvider

    @Published var selectedPeriod: Period = .currentMonth
    @Published var categoryRows: [CategoryRowData] = []
    @Published var totalSpent: Double = 0.0
    @Published var budgetTotal: Double = 0.0
    @Published var isEmpty: Bool = true

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    func loadData(now: Date = Date()) {
        let (start, end) = PeriodCalculator.dateRange(for: selectedPeriod, now: now)
        let transactions = dataProvider.fetchTransactions(from: start, to: end)

        guard !transactions.isEmpty else {
            isEmpty = true; categoryRows = []; totalSpent = 0.0; budgetTotal = 0.0
            return
        }

        isEmpty = false
        let actualRatios = RatioCalculator.calculateActualRatios(transactions: transactions)
        let actualAmounts = RatioCalculator.calculateActualAmounts(transactions: transactions)
        totalSpent = actualAmounts.values.reduce(0, +)

        // Get budget config
        let monthKeys = PeriodCalculator.allMonthKeys(for: selectedPeriod, now: now)
        var budgetRatios: [Category: Double] = Category.defaultRatios.mapValues { _ in 0.0 }
        var budgetTotalTemp: Double = 0.0

        for mk in monthKeys {
            if let config = dataProvider.fetchBudgetConfig(monthKey: mk) {
                if let data = config.ratiosJSON?.data(using: .utf8),
                   let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
                    for (key, val) in dict {
                        if let cat = Category(rawValue: key) { budgetRatios[cat] = val }
                    }
                }
                budgetTotalTemp += config.monthlyTotal
            }
        }

        // Fallback to defaults
        if budgetTotalTemp == 0 {
            budgetRatios = Category.defaultRatios
        } else {
            budgetTotal = budgetTotalTemp
        }

        let differences = RatioCalculator.calculateDifference(actual: actualRatios, budget: budgetRatios)
        categoryRows = Category.allCases.map { cat in
            CategoryRowData(
                category: cat,
                actualRatio: actualRatios[cat] ?? 0,
                budgetRatio: budgetRatios[cat] ?? 0,
                difference: differences[cat] ?? 0,
                actualAmount: actualAmounts[cat] ?? 0,
                budgetAmount: (budgetTotal > 0 ? budgetTotal : totalSpent) * (budgetRatios[cat] ?? 0)
            )
        }
    }

    func switchPeriod(_ period: Period, now: Date = Date()) {
        selectedPeriod = period
        loadData(now: now)
    }
}
