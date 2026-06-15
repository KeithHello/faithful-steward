import SwiftUI

struct BudgetBarChart: View {
    @ObservedObject var viewModel: BudgetOverviewViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Legend
                HStack(spacing: 16) {
                    legendItem("預算內", color: .underBudgetGreen)
                    legendItem("超支", color: .overBudgetRed)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Total summary
                totalSummary

                // Bar rows
                VStack(spacing: 6) {
                    ForEach(viewModel.categoryRows) { row in
                        BudgetBarRow(rowData: row, totalSpent: viewModel.totalSpent)
                    }
                }
                .padding()
            }
        }
    }

    private func legendItem(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
    }

    private var totalSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("總花費")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(viewModel.totalSpent.currencyString)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("預算")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(viewModel.budgetTotal.currencyString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.totalSpent > viewModel.budgetTotal ? .overBudgetRed : .underBudgetGreen)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}
