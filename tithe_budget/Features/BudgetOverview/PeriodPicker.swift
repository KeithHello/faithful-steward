import SwiftUI

struct PeriodPicker: View {
    @Binding var selectedPeriod: Period
    let onSelect: (Period) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Period.allCases, id: \.self) { period in
                    Button(action: { onSelect(period) }) {
                        Text(period.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedPeriod == period ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedPeriod == period ? Color.brandPrimary : Color.cardBackground)
                            .foregroundColor(selectedPeriod == period ? .white : .textPrimary)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}
