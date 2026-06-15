import SwiftUI

/// 月预算总额输入栏：数字键盘输入 + 即时格式化显示。
struct BudgetTotalEditor: View {
    /// 输入文字
    @Binding var text: String
    /// 解析后的金额（用于即时显示格式化结果）
    let parsedAmount: Double?
    /// 金额变更回调
    let onCommit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedString.monthlyBudgetLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text(LocalizedString.currencyPrefix)
                    .font(.title3)
                    .foregroundColor(.primary)

                TextField("0", text: $text)
                    .font(.title3)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onChange(of: text) { _, _ in
                        onCommit()
                    }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1.5)
            )

            // 即时格式化预览
            if let amount = parsedAmount, amount > 0 {
                Text("≈ \(amount.formattedAsCurrency)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            } else if !text.isEmpty {
                Text(LocalizedString.invalidBudgetAmount)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var text = "30000"
    BudgetTotalEditor(
        text: $text,
        parsedAmount: 30000,
        onCommit: {}
    )
    .padding()
}
