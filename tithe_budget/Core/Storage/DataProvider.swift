import Foundation
import CoreData

/// 統一資料存取層 — 封裝 CoreData CRUD
/// 對應 architecture 圖中的 DataProvider
final class DataProvider {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Transaction CRUD

    func addTransaction(amount: Double, category: Category, note: String? = nil, method: InputMethod = .text) throws -> TransactionEntity {
        let txn = TransactionEntity(context: context)
        txn.id = UUID()
        txn.amount = amount
        txn.categoryRaw = category.rawValue
        txn.note = note
        txn.inputMethodRaw = method.rawValue
        txn.createdAt = Date().standardized
        txn.updatedAt = txn.createdAt
        try context.save()
        return txn
    }

    func fetchTransactions(from startDate: Date, to endDate: Date, category: Category? = nil) -> [TransactionEntity] {
        let request = TransactionEntity.fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "createdAt >= %@ AND createdAt < %@", startDate as NSDate, endDate as NSDate)
        ]
        if let category = category {
            predicates.append(NSPredicate(format: "categoryRaw == %@", category.rawValue))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func deleteTransaction(_ txn: TransactionEntity) throws {
        context.delete(txn)
        try context.save()
    }

    // MARK: - BudgetConfig CRUD

    func fetchBudgetConfig(monthKey: String) -> BudgetConfigEntity? {
        let request = BudgetConfigEntity.fetchRequest()
        request.predicate = NSPredicate(format: "monthKey == %@", monthKey)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func fetchLatestBudgetConfig() -> BudgetConfigEntity? {
        let request = BudgetConfigEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "monthKey", ascending: false)]
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func saveBudgetConfig(monthlyTotal: Double, ratios: [Category: Double], monthKey: String) throws -> BudgetConfigEntity {
        let config = fetchBudgetConfig(monthKey: monthKey) ?? BudgetConfigEntity(context: context)
        config.id = config.id ?? UUID()
        config.monthKey = monthKey
        config.monthlyTotal = monthlyTotal

        let data = try JSONEncoder().encode(ratios.mapKeys { $0.rawValue })
        config.ratiosJSON = String(data: data, encoding: .utf8) ?? "{}"
        config.updatedAt = Date()
        try context.save()
        return config
    }
}

extension Dictionary {
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
}

extension Date {
    /// 標準化：秒數歸零（僅記錄到分鐘精度）
    var standardized: Date {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return cal.date(from: components) ?? self
    }
}
