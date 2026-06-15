import Foundation

/// 比例計算：實際 vs 預算差異、總和校驗、滑桿重分配
final class RatioCalculator {

    static func calculateActualRatios(transactions: [TransactionEntity]) -> [Category: Double] {
        guard !transactions.isEmpty else { return Category.defaultRatios.mapValues { _ in 0.0 } }

        var totals: [Category: Double] = [:]
        for txn in transactions {
            guard let cat = Category(rawValue: txn.categoryRaw ?? "") else { continue }
            totals[cat, default: 0] += txn.amount
        }

        let grandTotal = totals.values.reduce(0, +)
        guard grandTotal > 0 else { return Category.defaultRatios.mapValues { _ in 0.0 } }

        return Category.allCases.reduce(into: [:]) { dict, cat in
            dict[cat] = (totals[cat] ?? 0) / grandTotal
        }
    }

    static func calculateActualAmounts(transactions: [TransactionEntity]) -> [Category: Double] {
        var totals: [Category: Double] = [:]
        for txn in transactions {
            guard let cat = Category(rawValue: txn.categoryRaw ?? "") else { continue }
            totals[cat, default: 0] += txn.amount
        }
        return totals
    }

    static func calculateDifference(actual: [Category: Double], budget: [Category: Double]) -> [Category: Double] {
        Category.allCases.reduce(into: [:]) { result, cat in
            result[cat] = (actual[cat] ?? 0) - (budget[cat] ?? 0)
        }
    }

    static func validateTotalRatio(_ ratios: [Category: Double]) -> Bool {
        abs(ratios.values.reduce(0, +) - 1.0) <= 0.001
    }

    static func redistributeRatios(
        _ ratios: [Category: Double],
        changedCategory: Category,
        newValue: Double
    ) -> [Category: Double] {
        guard (0...1).contains(newValue) else { return ratios }

        let oldValue = ratios[changedCategory] ?? 0
        let delta = newValue - oldValue
        guard abs(delta) > 0.0001 else { return ratios }

        let otherCats = Category.allCases.filter { $0 != changedCategory }
        let otherTotal = otherCats.reduce(0) { $0 + (ratios[$1] ?? 0) }

        var result = ratios
        result[changedCategory] = newValue

        if otherTotal == 0 {
            let share = max(0, -delta) / Double(otherCats.count)
            for cat in otherCats { result[cat] = share }
        } else {
            for cat in otherCats {
                let original = ratios[cat] ?? 0
                let weight = original / otherTotal
                result[cat] = max(0, original - delta * weight)
            }
        }

        // Normalize to ensure sum = 1.0
        let total = result.values.reduce(0, +)
        if total > 0 {
            for cat in Category.allCases { result[cat] = (result[cat] ?? 0) / total }
        }
        return result
    }
}
