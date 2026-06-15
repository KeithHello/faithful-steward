import SwiftUI

/// 周期下拉选择器：本月 / 近 3 个月 / 近 6 个月 / 近 12 个月。
struct PeriodPicker: View {
    /// 当前选中周期
    @Binding var selectedPeriod: Period
    /// 选择回调
    let onSelect: (Period) -> Void

    var body: some View {
        Menu {
            ForEach(Period.allCases, id: \.rawValue) { period in
                Button {
                    selectedPeriod = period
                    onSelect(period)
                } label: {
                    HStack {
                        Text(period.displayName)
                        if period == selectedPeriod {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(LocalizedString.periodLabel)
                    .foregroundColor(.secondary)

                Text(selectedPeriod.displayName)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .accessibilityLabel("\(LocalizedString.periodLabel)：\(selectedPeriod.displayName)")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var period: Period = .currentMonth
    PeriodPicker(selectedPeriod: $period, onSelect: { _ in })
        .padding()
}
