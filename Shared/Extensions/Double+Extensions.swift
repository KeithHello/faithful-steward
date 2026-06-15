import Foundation

// MARK: - Double 金额格式化扩展

extension Double {
    /// 格式化为 NT$ 货币显示（含千分位）
    /// 例：30000.0 → "NT$ 30,000"
    var formattedAsCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.currencySymbol = "NT$ "
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "NT$ 0"
    }

    /// 格式化为百分比显示
    /// 例：0.35 → "35%"
    var formattedAsPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "0%"
    }

    /// 格式化为带正负号的差异百分比
    /// 例：+0.05 → "+5%"，-0.03 → "-3%"
    var formattedAsDifference: String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(Int((self * 100).rounded()))%"
    }

    /// 四舍五入到指定小数位
    /// - Parameter places: 小数位数
    /// - Returns: 四舍五入后的 Double
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
