import SwiftUI

/// 7 大分类 LazyVGrid 选择器：3 列 × 3 行（最后一行仅一栏 =「弹性」）。
/// 选中格会有高亮边框与底色变化。
struct CategorySelector: View {
    /// 当前选中的分类
    @Binding var selectedCategory: Category?
    /// 选择回调
    let onSelect: ((Category) -> Void)?

    /// 3 列版面配置
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString.selectCategory)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Category.allCases, id: \.rawValue) { category in
                    CategoryCell(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            selectedCategory = category
                            onSelect?(category)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - 分类格元件

private struct CategoryCell: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : category.color)

                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(category.defaultRatio.formattedAsPercentage)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : category.color.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName) \(category.defaultRatio.formattedAsPercentage)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selected: Category? = nil
    CategorySelector(selectedCategory: $selected, onSelect: nil)
        .padding()
}
