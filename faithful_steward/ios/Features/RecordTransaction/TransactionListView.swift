import SwiftUI

struct TransactionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.createdAt, ascending: false)],
        animation: .default
    ) private var transactions: FetchedResults<TransactionEntity>

    @State private var currentMonthOffset = 0
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month navigation
                monthNavBar

                if filteredTransactions.isEmpty {
                    Spacer()
                    EmptyStateView.noTransactions()
                    Spacer()
                } else {
                    List {
                        // Summary cards
                        summarySection
                            .listRowInsets(EdgeInsets())

                        // Transaction list
                        ForEach(filteredTransactions, id: \.id) { txn in
                            transactionRow(txn)
                        }
                        .onDelete(perform: deleteTransactions)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.surfaceBackground)
            .navigationTitle("明細")
        }
    }

    private var monthNavBar: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            .disabled(currentMonthOffset <= 0)

            Spacer()
            Text(monthKey(from: selectedDate))
                .font(.headline)
            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .background(Color.cardBackground)
    }

    private var summarySection: some View {
        let total = filteredTransactions.reduce(0) { $0 + $1.amount }
        let count = filteredTransactions.count
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
        let dailyAvg = total / Double(daysInMonth)

        return VStack(spacing: 8) {
            summaryCard(title: "總支出", value: total.currencyString)
            HStack {
                summaryCard(title: "筆數", value: "\(count) 筆")
                summaryCard(title: "日均", value: dailyAvg.currencyString)
            }
        }
        .padding()
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    private func transactionRow(_ txn: TransactionEntity) -> some View {
        let cat = Category(rawValue: txn.categoryRaw ?? "") ?? .flexible
        return HStack(spacing: 12) {
            Image(systemName: cat.iconName)
                .foregroundColor(cat.color)
                .frame(width: 36, height: 36)
                .background(cat.color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(cat.displayName)
                    .font(.subheadline)
                if let note = txn.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Text(txn.amount.currencyString)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }

    private var filteredTransactions: [TransactionEntity] {
        let (start, end) = monthRange(for: selectedDate)
        return transactions.filter {
            guard let date = $0.createdAt else { return false }
            return date >= start && date < end
        }
    }

    private func monthRange(for date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        return (start, end)
    }

    private func monthKey(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy 年 M 月"
        return fmt.string(from: date)
    }

    private func changeMonth(by offset: Int) {
        currentMonthOffset += offset
        selectedDate = Calendar.current.date(byAdding: .month, value: currentMonthOffset, to: Date()) ?? Date()
    }

    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let txn = filteredTransactions[index]
            viewContext.delete(txn)
        }
        try? PersistenceController.shared.save()
    }
}
