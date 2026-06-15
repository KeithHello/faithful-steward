import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    private let dataProvider: DataProvider

    @Published var monthlyTotalText = ""
    @Published var monthlyTotal: Double = 30000.0
    @Published var ratios: [Category: Double] = Category.defaultRatios
    @Published var isValid = true
    @Published var isSaved = false
    @Published var errorMessage: String?
    @Published var shouldShowToast = false
    @Published var toastMessage = ""
    @Published var hasUnsavedChanges = false
    private var savedRatios: [Category: Double] = [:]
    private var savedTotal: Double = 0.0

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    func loadConfig(now: Date = Date()) {
        let monthKey = PeriodCalculator.monthKey(from: now)
        var config = dataProvider.fetchBudgetConfig(monthKey: monthKey)
        if config == nil { config = dataProvider.fetchLatestBudgetConfig() }

        if let config = config {
            monthlyTotal = config.monthlyTotal
            monthlyTotalText = String(Int(config.monthlyTotal))
            if let data = config.ratiosJSON?.data(using: .utf8),
               let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
                ratios = Category.allCases.reduce(into: [:]) { result, cat in
                    if let val = dict[cat.rawValue] { result[cat] = val }
                    else { result[cat] = cat.defaultRatio }
                }
            }
        } else {
            monthlyTotal = 30000.0
            monthlyTotalText = "30000"
            ratios = Category.defaultRatios
        }

        savedRatios = ratios
        savedTotal = monthlyTotal
        isSaved = false
        hasUnsavedChanges = false
        isValid = RatioCalculator.validateTotalRatio(ratios)
        errorMessage = nil
    }

    func setMonthlyTotal(_ text: String) {
        monthlyTotalText = text
        errorMessage = nil
        if let value = Double(text), value > 0 {
            monthlyTotal = value
            isValid = RatioCalculator.validateTotalRatio(ratios)
            hasUnsavedChanges = monthlyTotal != savedTotal || ratios != savedRatios
        } else {
            monthlyTotal = 0.0
            isValid = false
            errorMessage = "請輸入有效的月預算金額"
        }
    }

    func updateRatio(category: Category, newValue: Double) {
        errorMessage = nil
        ratios = RatioCalculator.redistributeRatios(ratios, changedCategory: category, newValue: newValue)
        isValid = RatioCalculator.validateTotalRatio(ratios)
        if !isValid { errorMessage = "比例總和須為 100%" }
        hasUnsavedChanges = monthlyTotal != savedTotal || ratios != savedRatios
    }

    func saveConfig(now: Date = Date()) throws {
        guard monthlyTotal > 0 else { throw ValidationError.invalidAmount }
        guard isValid else { throw ValidationError.invalidRatios }

        let monthKey = PeriodCalculator.monthKey(from: now)
        try dataProvider.saveBudgetConfig(monthlyTotal: monthlyTotal, ratios: ratios, monthKey: monthKey)

        savedRatios = ratios
        savedTotal = monthlyTotal
        isSaved = true
        hasUnsavedChanges = false
        errorMessage = nil
        toastMessage = "設定已儲存"
        shouldShowToast = true
    }
}
