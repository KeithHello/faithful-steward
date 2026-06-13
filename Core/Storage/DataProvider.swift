import CoreData
import Foundation

/// 统一资料存取层，封装所有 CoreData CRUD 操作。
/// 所有方法皆可能 throw Error，由上层 ViewModel catch 处理后转为 errorMessage。
class DataProvider {
    /// 使用的 CoreData context
    private let context: NSManagedObjectContext

    /// 初始化
    /// - Parameter context: NSManagedObjectContext，通常为 PersistenceController.shared.viewContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Transaction 查询

    /// 查询指定日期区间内的所有交易纪录
    /// - Parameters:
    ///   - startDate: 区间起始日期
    ///   - endDate: 区间结束日期
    /// - Returns: 交易纪录阵列（按 createdAt 降幂排列）
    func fetchTransactions(from startDate: Date, to endDate: Date) throws -> [TransactionEntity] {
        let request = TransactionEntity.fetchRequest() as NSFetchRequest<TransactionEntity>
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt <= %@",
            startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TransactionEntity.createdAt, ascending: false)
        ]
        return try context.fetch(request)
    }

    /// 查询指定日期区间内、指定分类的交易纪录
    /// - Parameters:
    ///   - category: 交易分类
    ///   - startDate: 区间起始日期
    ///   - endDate: 区间结束日期
    /// - Returns: 该分类的交易纪录阵列
    func fetchTransactions(forCategory category: Category, from startDate: Date, to endDate: Date) throws -> [TransactionEntity] {
        let request = TransactionEntity.fetchRequest() as NSFetchRequest<TransactionEntity>
        request.predicate = NSPredicate(
            format: "categoryRaw == %@ AND createdAt >= %@ AND createdAt <= %@",
            category.rawValue, startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TransactionEntity.createdAt, ascending: false)
        ]
        return try context.fetch(request)
    }

    // MARK: - Transaction 写入

    /// 新增一笔记账
    /// - Parameters:
    ///   - amount: 金额
    ///   - category: 分类
    ///   - note: 备注（可空）
    ///   - method: 输入方式
    /// - Returns: 新建立的 TransactionEntity
    @discardableResult
    func addTransaction(amount: Double, category: Category, note: String?, method: InputMethod) throws -> TransactionEntity {
        let transaction = TransactionEntity(context: context)
        transaction.id = UUID()
        transaction.amount = amount
        transaction.categoryRaw = category.rawValue
        transaction.note = note
        transaction.inputMethodRaw = method.rawValue
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        try context.save()
        return transaction
    }

    /// 更新既有交易纪录
    /// - Parameter transaction: 要更新的 TransactionEntity
    func updateTransaction(_ transaction: TransactionEntity) throws {
        transaction.updatedAt = Date()
        try context.save()
    }

    /// 删除交易纪录
    /// - Parameter transaction: 要删除的 TransactionEntity
    func deleteTransaction(_ transaction: TransactionEntity) throws {
        context.delete(transaction)
        try context.save()
    }

    // MARK: - BudgetConfig 查询

    /// 查询指定 monthKey 的预算设定
    /// - Parameter monthKey: 格式 "yyyy-MM"（如 "2025-06"）
    /// - Returns: 对应的 BudgetConfigEntity，若无则回传 nil
    func fetchBudgetConfig(forMonthKey monthKey: String) throws -> BudgetConfigEntity? {
        let request = BudgetConfigEntity.fetchRequest() as NSFetchRequest<BudgetConfigEntity>
        request.predicate = NSPredicate(format: "monthKey == %@", monthKey)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 查询最近一笔预算设定（按 updatedAt 降幂）
    /// - Returns: 最新的 BudgetConfigEntity，若无则回传 nil
    func fetchLatestBudgetConfig() throws -> BudgetConfigEntity? {
        let request = BudgetConfigEntity.fetchRequest() as NSFetchRequest<BudgetConfigEntity>
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \BudgetConfigEntity.updatedAt, ascending: false)
        ]
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 查询指定多个 monthKey 的所有预算设定
    /// - Parameter monthKeys: monthKey 阵列
    /// - Returns: 对应的 BudgetConfigEntity 阵列
    func fetchBudgetConfigs(forMonthKeys monthKeys: [String]) throws -> [BudgetConfigEntity] {
        let request = BudgetConfigEntity.fetchRequest() as NSFetchRequest<BudgetConfigEntity>
        request.predicate = NSPredicate(format: "monthKey IN %@", monthKeys)
        return try context.fetch(request)
    }

    // MARK: - BudgetConfig 写入

    /// 储存（新增或更新）月预算设定
    /// - Parameters:
    ///   - monthlyTotal: 月预算总额
    ///   - ratios: 各分类比例字典（总和须 = 1.0）
    ///   - monthKey: 格式 "yyyy-MM"
    /// - Returns: 储存后的 BudgetConfigEntity
    @discardableResult
    func saveBudgetConfig(monthlyTotal: Double, ratios: [Category: Double], forMonthKey monthKey: String) throws -> BudgetConfigEntity {
        // 查找是否已存在当月设定
        let existing = try fetchBudgetConfig(forMonthKey: monthKey)
        let config: BudgetConfigEntity

        if let existing = existing {
            config = existing
        } else {
            config = BudgetConfigEntity(context: context)
            config.id = UUID()
            config.monthKey = monthKey
        }

        config.monthlyTotal = monthlyTotal
        config.ratiosJSON = Self.encodeRatiosToJSON(ratios)
        config.updatedAt = Date()

        try context.save()
        return config
    }

    // MARK: - JSON 编解码辅助

    /// 将比例字典编码为 JSON 字串
    /// - Parameter ratios: [Category: Double] 字典
    /// - Returns: JSON 字串
    static func encodeRatiosToJSON(_ ratios: [Category: Double]) -> String {
        var dict: [String: Double] = [:]
        for (category, ratio) in ratios {
            dict[category.rawValue] = ratio
        }
        guard let data = try? JSONEncoder().encode(dict),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    /// 将 JSON 字串解码为比例字典
    /// - Parameter json: JSON 字串
    /// - Returns: [Category: Double] 字典，解码失败则回传预设比例
    static func decodeRatiosFromJSON(_ json: String) -> [Category: Double] {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return Category.defaultRatios
        }
        var result: [Category: Double] = [:]
        for (key, value) in dict {
            if let category = Category(rawValue: key) {
                result[category] = value
            }
        }
        // 若有分类缺失，补上预设值
        for category in Category.allCases {
            if result[category] == nil {
                result[category] = category.defaultRatio
            }
        }
        return result
    }
}
