import SwiftUI

/// 单列横向长条图行：显示分类 icon + 分类名 + 长条（实际比例宽）+ 百分比 + 差异标记。
/// 绿色 = 未超预算，红色 = 超出预算并标注 ⚠。
struct BudgetBarRow: View {
    /// 该行资料
    let rowData: CategoryRowData

    /// 所有行中的最大比例值（用于计算长条相对宽度）
    let maxRatio: Double

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                // 分类图标
                Image(systemName: rowData.category.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(rowData.category.color)
                    .frame(width: 24)

                // 分类名称
                Text(rowData.category.displayName)
                    .font(.subheadline)
                    .frame(width: 40, alignment: .leading)

                // 长条图
                barSection

                // 实际比例百分比
                Text(rowData.actualRatio.formattedAsPercentage)
                    .font(.caption)
                    .frame(width: 36, alignment: .trailing)
                    .foregroundColor(.primary)

                // 差异标记
                Text(rowData.difference.formattedAsDifference)
                    .font(.caption)
                    .foregroundColor(rowData.isOverBudget ? .red : .green)
                    .frame(width: 44, alignment: .trailing)

                // 超预算警告
                if rowData.isOverBudget {
                    Text(LocalizedString.overBudgetWarning)
                        .font(.caption)
                }
            }

            // 金额明细行
            HStack {
                Spacer().frame(width: 72)
                Text("\(rowData.actualAmount.formattedAsCurrency) / \(rowData.budgetAmount.formattedAsCurrency)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 长条部分

    private var barSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景（预算比例参考线）
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 20)

                // 实际比例长条
                let barWidth = maxRatio > 0
                    ? (rowData.actualRatio / maxRatio) * geometry.size.width
                    : 0

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        rowData.isOverBudget
                            ? Color.red.opacity(0.7)
                            : Color.green.opacity(0.7)
                    )
                    .frame(width: max(barWidth, 4), height: 20)

                // 预算比例标记（竖线）
                let budgetMarkerX = maxRatio > 0
                    ? (rowData.budgetRatio / maxRatio) * geometry.size.width
                    : 0

                Rectangle()
                    .fill(Color.primary.opacity(0.3))
                    .frame(width: 2, height: 24)
                    .offset(x: budgetMarkerX - 1, y: -2)
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Preview

#Preview {
    let sample = CategoryRowData(
        category: .foodTransport,
        actualRatio: 0.35,
        budgetRatio: 0.30,
        difference: 0.05,
        actualAmount: 10500,
        budgetAmount: 9000
    )

    BudgetBarRow(rowData: sample, maxRatio: 0.40)
        .padding()
}
