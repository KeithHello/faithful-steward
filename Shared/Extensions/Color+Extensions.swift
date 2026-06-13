import SwiftUI

// MARK: - Color 扩展：分类颜色与预算状态颜色

extension Color {
    /// 根据是否为超预算状态回传对应颜色
    /// - Parameter isOverBudget: 是否超出预算
    /// - Returns: 超出预算回传红色，未超出回传绿色
    static func budgetBarColor(isOverBudget: Bool) -> Color {
        isOverBudget ? .red : .green
    }

    /// 超预算警示背景色
    static let overBudgetBackground = Color.red.opacity(0.12)

    /// 符合预算背景色
    static let withinBudgetBackground = Color.green.opacity(0.12)

    /// 总和有效（=100%）绿色
    static let ratioValid = Color.green

    /// 总和无效（≠100%）红色
    static let ratioInvalid = Color.red

    /// Toast 横幅背景色
    static let toastSuccess = Color.green.opacity(0.9)
    static let toastError = Color.red.opacity(0.9)
    static let toastWarning = Color.orange.opacity(0.9)
}
