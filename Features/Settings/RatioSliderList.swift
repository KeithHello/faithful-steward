import SwiftUI

/// 7 分类比例滑杆列表：每列显示分类名 + 百分比 + 滑杆。
/// 任一滑杆变动时透过 RatioCalculator.redistributeRatios 连锁更新所有滑杆位置。
struct RatioSliderList: View {
    /// 各分类比例
    let ratios: [Category: Double]
    /// 比例变更回调
    let onChange: (Category, Double) -> Void
    /// 比例总和
    let totalRatio: Double
    /// 总和是否有效
    let isTotalValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedString.ratioAdjustmentLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                ForEach(Category.allCases, id: \.rawValue) { category in
                    RatioSliderRow(
                        category: category,
                        ratio: ratios[category] ?? category.defaultRatio,
                        onRatioChange: { newValue in
                            onChange(category, newValue)
                        }
                    )
                }
            }

            // 总和提示
            ratioTotalIndicator
        }
    }

    // MARK: - 总和提示

    private var ratioTotalIndicator: some View {
        HStack {
            Text("\(LocalizedString.ratioTotalLabel)：\(Int((totalRatio * 100).rounded()))%")
                .font(.caption)
                .foregroundColor(isTotalValid ? .green : .red)
                .fontWeight(.medium)

            if !isTotalValid {
                Text(LocalizedString.ratioTotalInvalid)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// MARK: - 单列滑杆行

private struct RatioSliderRow: View {
    let category: Category
    let ratio: Double
    let onRatioChange: (Double) -> Void

    var body: some View {
        HStack(spacing: 10) {
            // 分类图标
            Image(systemName: category.iconName)
                .foregroundColor(category.color)
                .frame(width: 22)

            // 分类名称
            Text(category.displayName)
                .font(.caption)
                .frame(width: 32, alignment: .leading)

            // 滑杆
            Slider(
                value: Binding(
                    get: { ratio },
                    set: { onRatioChange($0) }
                ),
                in: 0...1.0,
                step: 0.01
            )
            .tint(category.color)

            // 百分比数字
            Text(ratio.formattedAsPercentage)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Preview

#Preview {
    RatioSliderList(
        ratios: Category.defaultRatios,
        onChange: { _, _ in },
        totalRatio: 1.0,
        isTotalValid: true
    )
    .padding()
}
