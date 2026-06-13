import Foundation
import Combine

/// 设定 ViewModel：管理月预算总额、7 大分类比例滑杆调整、储存验证。
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - 依赖

    private let dataProvider: DataProvider

    // MARK: - 发布属性

    /// 月预算总额输入文字
    @Published var monthlyTotalText: String = ""

    /// 各分类比例
    @Published var ratios: [Category: Double] = [:]

    /// 设定是否有效（总额 > 0 且比例总和 = 100%）
    @Published var isValid: Bool = false

    /// 是否已成功储存
    @Published var isSaved: Bool = false

    /// 错误讯息
    @Published var errorMessage: String? = nil

    /// 比例总和
    var ratioTotal: Double {
        RatioCalculator.totalRatio(ratios: ratios)
    }

    /// 比例总和是否为 100%
    var isRatioValid: Bool {
        RatioCalculator.validateTotalRatio(ratios: ratios)
    }

    /// 预算总额是否有效
    var isBudgetValid: Bool {
        guard let total = parsedMonthlyTotal else { return false }
        return total > 0
    }

    /// 解析月预算总额
    var parsedMonthlyTotal: Double? {
        AmountParser.parse(monthlyTotalText)
    }

    // MARK: - 初始化

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        // 初始化为预设比例
        self.ratios = Category.defaultRatios
    }

    // MARK: - 载入

    /// 载入最新预算设定（若无则使用预设值）
    func loadConfig() {
        do {
            if let config = try dataProvider.fetchLatestBudgetConfig() {
                monthlyTotalText = String(format: "%.0f", config.monthlyTotal)
                ratios = DataProvider.decodeRatiosFromJSON(config.ratiosJSON ?? "")
            } else {
                // 使用预设值
                monthlyTotalText = LocalizedString.defaultMonthlyBudget
                ratios = Category.defaultRatios
            }
            validate()
        } catch {
            errorMessage = error.localizedDescription
            monthlyTotalText = LocalizedString.defaultMonthlyBudget
            ratios = Category.defaultRatios
            validate()
        }
    }

    // MARK: - 比例调整

    /// 更新某个分类的比例（其余分类自动重分配）
    /// - Parameters:
    ///   - category: 被调整的分类
    ///   - value: 新比例值（0~1 范围）
    func updateRatio(for category: Category, to value: Double) {
        let clampedValue = max(0, min(1.0, value))
        ratios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: category,
            newValue: clampedValue
        )
        validate()
    }

    // MARK: - 储存

    /// 储存设定
    func saveConfig() throws {
        guard let total = parsedMonthlyTotal, total > 0 else {
            errorMessage = LocalizedString.invalidBudgetAmount
            isValid = false
            throw SettingsError.invalidBudgetAmount
        }

        guard isRatioValid else {
            errorMessage = LocalizedString.ratioTotalInvalid
            isValid = false
            throw SettingsError.ratioTotalInvalid
        }

        let monthKey = PeriodCalculator.currentMonthKey()
        try dataProvider.saveBudgetConfig(
            monthlyTotal: total,
            ratios: ratios,
            forMonthKey: monthKey
        )

        isSaved = true
        errorMessage = nil
    }

    // MARK: - Private

    private func validate() {
        isValid = isBudgetValid && isRatioValid
        errorMessage = nil
        isSaved = false
    }
}

// MARK: - 错误类型

enum SettingsError: LocalizedError {
    case invalidBudgetAmount
    case ratioTotalInvalid

    var errorDescription: String? {
        switch self {
        case .invalidBudgetAmount:
            return LocalizedString.invalidBudgetAmount
        case .ratioTotalInvalid:
            return LocalizedString.ratioTotalInvalid
        }
    }
}
