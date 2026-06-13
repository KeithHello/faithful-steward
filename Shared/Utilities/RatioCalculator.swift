import Foundation

/// 比例计算器：提供实际比例、预算比例、差异计算与滑杆重分配等纯函数。
struct RatioCalculator {

    /// 根据交易纪录计算各分类的实际花费比例
    /// - Parameter transactions: 交易纪录阵列
    /// - Returns: [Category: Double] 各分类实际比例（总和 = 1.0，无交易时回传全 0）
    static func calculateActualRatios(transactions: [TransactionEntity]) -> [Category: Double] {
        var categoryTotals: [Category: Double] = [:]
        var grandTotal: Double = 0

        for transaction in transactions {
            guard let category = Category(rawValue: transaction.categoryRaw ?? "") else { continue }
            categoryTotals[category, default: 0] += transaction.amount
            grandTotal += transaction.amount
        }

        // 若总金额为 0，回传全 0 比例
        guard grandTotal > 0 else {
            return Dictionary(uniqueKeysWithValues: Category.allCases.map { ($0, 0.0) })
        }

        var ratios: [Category: Double] = [:]
        for category in Category.allCases {
            let amount = categoryTotals[category] ?? 0
            ratios[category] = (amount / grandTotal).rounded(toPlaces: 4)
        }

        return ratios
    }

    /// 计算各分类的实际花费金额
    /// - Parameter transactions: 交易纪录阵列
    /// - Returns: [Category: Double] 各分类实际花费金额
    static func calculateActualAmounts(transactions: [TransactionEntity]) -> [Category: Double] {
        var amounts: [Category: Double] = [:]
        for transaction in transactions {
            guard let category = Category(rawValue: transaction.categoryRaw ?? "") else { continue }
            amounts[category, default: 0] += transaction.amount
        }
        // 确保所有分类都有值
        for category in Category.allCases {
            if amounts[category] == nil {
                amounts[category] = 0
            }
        }
        return amounts
    }

    /// 从 BudgetConfigEntity 读取预算比例
    /// - Parameter config: 预算设定实体
    /// - Returns: [Category: Double] 各分类预算比例
    static func calculateBudgetRatios(config: BudgetConfigEntity) -> [Category: Double] {
        return DataProvider.decodeRatiosFromJSON(config.ratiosJSON ?? "")
    }

    /// 计算各分类实际比例与预算比例的差异
    /// - Parameters:
    ///   - actual: 实际比例
    ///   - budget: 预算比例
    /// - Returns: [Category: Double] 各分类差异值（actual - budget）
    static func calculateDifference(actual: [Category: Double], budget: [Category: Double]) -> [Category: Double] {
        var differences: [Category: Double] = [:]
        for category in Category.allCases {
            let actualRatio = actual[category] ?? 0
            let budgetRatio = budget[category] ?? category.defaultRatio
            differences[category] = (actualRatio - budgetRatio).rounded(toPlaces: 4)
        }
        return differences
    }

    /// 验证比例总和是否等于 1.0（容忍度 ±0.001）
    /// - Parameter ratios: 比例字典
    /// - Returns: 总和 ≈ 1.0 则回传 true
    static func validateTotalRatio(ratios: [Category: Double]) -> Bool {
        let total = ratios.values.reduce(0, +)
        return abs(total - 1.0) < 0.001
    }

    /// 计算比例总和（供 UI 显示用）
    /// - Parameter ratios: 比例字典
    /// - Returns: 比例总和
    static func totalRatio(ratios: [Category: Double]) -> Double {
        return ratios.values.reduce(0, +).rounded(toPlaces: 4)
    }

    /// 滑杆比例重分配演算法（锁定总和 = 1.0 约束）
    ///
    /// 当某个分类的比例变动时，差额由其余分类按原比例等比分摊。
    ///
    /// - Parameters:
    ///   - ratios: 当前所有分类的比例字典
    ///   - changedCategory: 被拖动的分类
    ///   - newValue: 该分类的新比例值
    /// - Returns: 调整后的比例字典（总和 ≈ 1.0）
    static func redistributeRatios(
        ratios: [Category: Double],
        changedCategory: Category,
        newValue: Double
    ) -> [Category: Double] {
        var newRatios = ratios
        let clampedNewValue = max(0, min(1.0, newValue))
        let oldValue = ratios[changedCategory] ?? 0
        let delta = clampedNewValue - oldValue

        newRatios[changedCategory] = clampedNewValue

        // 获取其余分类及其比例
        let otherCategories = Category.allCases.filter { $0 != changedCategory }
        let otherTotal = otherCategories.reduce(0.0) { $0 + (ratios[$1] ?? 0) }

        if abs(otherTotal) < 0.0001 {
            // 若其余分类总和为 0，平均分配差额
            let equalShare = -delta / Double(otherCategories.count)
            for category in otherCategories {
                newRatios[category] = max(0, equalShare.rounded(toPlaces: 4))
            }
        } else {
            // 按等比分摊差额
            for category in otherCategories {
                let currentRatio = ratios[category] ?? 0
                let share = otherTotal > 0 ? currentRatio / otherTotal : 1.0 / Double(otherCategories.count)
                let adjusted = currentRatio - delta * share
                newRatios[category] = max(0, adjusted.rounded(toPlaces: 4))
            }
        }

        // 四舍五入到 4 位小数，移除浮点误差
        for category in Category.allCases {
            newRatios[category] = (newRatios[category] ?? 0).rounded(toPlaces: 4)
        }

        // 若总和仍有微小误差，用最大比例的分类吸收
        let currentTotal = newRatios.values.reduce(0, +)
        let error = 1.0 - currentTotal
        if abs(error) > 0.0001 && abs(error) < 0.01 {
            if let maxCategory = newRatios.max(by: { $0.value < $1.value })?.key {
                newRatios[maxCategory] = (newRatios[maxCategory]! + error).rounded(toPlaces: 4)
            }
        }

        return newRatios
    }
}
