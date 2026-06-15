import SwiftUI

struct BudgetTotalEditor: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("月預算總額")
                .font(.headline)

            HStack {
                Text("NT$")
                    .foregroundColor(.textSecondary)
                TextField("30000", text: $viewModel.monthlyTotalText)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .fontWeight(.bold)
                    .onChange(of: viewModel.monthlyTotalText) { _, newValue in
                        viewModel.setMonthlyTotal(newValue)
                    }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)

            if viewModel.monthlyTotal > 0 {
                Text("各分類預算將自動依比例計算")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal)
    }
}
