import SwiftUI

struct RatioSliderList: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分類比例分配")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(Category.allCases, id: \.self) { category in
                    ratioSliderRow(category)
                }
            }

            // Total summary bar
            HStack {
                Text("總和")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(viewModel.ratios.values.reduce(0, +) * 100))%")
                    .font(.headline)
                    .foregroundColor(viewModel.isValid ? .underBudgetGreen : .overBudgetRed)
            }
            .padding()
            .background(
                viewModel.isValid
                    ? Color.underBudgetGreen.opacity(0.05)
                    : Color.overBudgetRed.opacity(0.05)
            )
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    private func ratioSliderRow(_ category: Category) -> some View {
        let ratio = viewModel.ratios[category] ?? 0
        let pct = Int(ratio * 100)
        let amount = viewModel.monthlyTotal * ratio

        return VStack(spacing: 4) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                Text(category.shortName)
                    .font(.subheadline)
                Spacer()
                Text("\(pct)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(amount.currencyString)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Slider(
                value: Binding(
                    get: { ratio },
                    set: { viewModel.updateRatio(category: category, newValue: $0) }
                ),
                in: 0...1,
                step: 0.01
            )
            .tint(category.color)
        }
    }
}
