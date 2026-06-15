import SwiftUI

struct BudgetBarRow: View {
    let rowData: CategoryRowData
    let totalSpent: Double

    private var barWidth: CGFloat {
        guard totalSpent > 0 else { return 0 }
        return min(CGFloat(rowData.actualRatio), 1.0)
    }

    private var displayPercent: String {
        "\(Int(rowData.actualRatio * 100))%"
    }

    var body: some View {
        VStack(spacing: 4) {
            // Label row
            HStack {
                Image(systemName: rowData.category.iconName)
                    .foregroundColor(rowData.category.color)
                Text(rowData.displayName)
                    .font(.subheadline)
                Spacer()
                Text(rowData.actualAmount.currencyString)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(displayPercent)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if rowData.isOverBudget {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.overBudgetRed)
                }
            }

            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 20)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(rowData.isOverBudget ? Color.overBudgetRed : rowData.category.color)
                        .frame(width: max(geo.size.width * barWidth, 4), height: 20)
                }
            }
            .frame(height: 20)
        }
        .padding(.vertical, 6)
    }
}
