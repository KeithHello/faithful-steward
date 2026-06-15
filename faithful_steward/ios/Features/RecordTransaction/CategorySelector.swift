import SwiftUI

struct CategorySelector: View {
    @Binding var selectedCategory: Category?
    let onSelect: (Category) -> Void

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分類")
                .font(.caption)
                .foregroundColor(.textSecondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Category.allCases, id: \.self) { category in
                    categoryCell(category)
                }
            }
        }
    }

    private func categoryCell(_ category: Category) -> some View {
        let isSelected = selectedCategory == category
        return Button(action: { onSelect(category) }) {
            VStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.title3)
                Text(category.shortName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color.opacity(0.15) : Color.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
            .cornerRadius(10)
            .foregroundColor(isSelected ? category.color : .textPrimary)
        }
    }
}
