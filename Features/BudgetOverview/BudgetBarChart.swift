import SwiftUI

/// 横向长条图容器：纵向排列 7 个 BudgetBarRow，底部显示总花费与预算总额摘要。
struct BudgetBarChart: View {
    /// 各分类资料行
    let rows: [CategoryRowData]
    /// 总花费
    let totalSpent: Double
    /// 预算总额
    let budgetTotal: Double

    /// 计算最大比例值（用于长条图宽度参照）
    private var maxDisplayRatio: Double {
        let maxRatio = rows.map { max($0.actualRatio, $0.budgetRatio) }.max() ?? 1.0
        return max(maxRatio, 0.01) // 避免除以 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // 长条图各行
            VStack(spacing: 8) {
                ForEach(rows) { row in
                    BudgetBarRow(rowData: row, maxRatio: maxDisplayRatio)
                }
            }
            .padding(.vertical, 8)

            Divider()
                .padding(.vertical, 8)

            // 底部摘要
            summarySection
        }
    }

    // MARK: - 摘要区域

    private var summarySection: some View {
        VStack(spacing: 6) {
            HStack {
                Text(LocalizedString.totalSpent)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(totalSpent.formattedAsCurrency)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if budgetTotal > 0 {
                    let ratio = totalSpent / budgetTotal
                    Text("（\(ratio.formattedAsPercentage)）")
                        .font(.caption)
                        .foregroundColor(totalSpent > budgetTotal ? .red : .green)
                }
            }

            HStack {
                Text(LocalizedString.budgetTotal)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(budgetTotal.formattedAsCurrency)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview

#Preview {
    let sampleRows = Category.allCases.map { category in
        CategoryRowData(
            category: category,
            actualRatio: category.defaultRatio + Double.random(in: -0.05...0.05),
            budgetRatio: category.defaultRatio,
            difference: Double.random(in: -0.05...0.05),
            actualAmount: Double.random(in: 2000...10000),
            budgetAmount: 30000 * category.defaultRatio
        )
    }

    ScrollView {
        BudgetBarChart(
            rows: sampleRows,
            totalSpent: 28500,
            budgetTotal: 30000
        )
        .padding()
    }
}
