import CoreData

/// CoreData NSPersistentContainer 管理器，提供单例 shared 实例与 preview 支援。
class PersistenceController {
    /// 共享单例
    static let shared = PersistenceController()

    /// NSPersistentContainer 实例
    let container: NSPersistentContainer

    /// 主线程 NSManagedObjectContext，供 SwiftUI @Environment 注入使用
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// 初始化 PersistenceController
    /// - Parameter inMemory: 若为 true，使用 /dev/null 作为储存位置（供 Preview / 测试用）
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tithe_budget")
        // TODO: 正式发布时可将 CoreData store name 改为 "faithful_steward"

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // 启用轻量级迁移
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                // MVP 阶段若迁移失败，直接重建资料库
                if error.domain == NSCocoaErrorDomain &&
                   (error.code == NSPersistentStoreIncompatibleVersionHashError ||
                    error.code == NSMigrationMissingSourceModelError) {
                    self?.recreateStore()
                    return
                }
                fatalError("CoreData 载入失败: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// 储存 main context 的变更
    func save() throws {
        let context = container.viewContext
        guard context.hasChanges else { return }
        try context.save()
    }

    /// 删除旧资料库并重新载入（MVP 阶段无 Migration 策略）
    private func recreateStore() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        // 删除旧 store 档案
        let fileManager = FileManager.default
        let storeDir = storeURL.deletingLastPathComponent()
        let storeName = storeURL.deletingPathExtension().lastPathComponent
        let fileURLs: [String] = ["", "-wal", "-shm"].compactMap { suffix in
            let url = storeDir.appendingPathComponent("\(storeName)\(suffix).sqlite")
            return fileManager.fileExists(atPath: url.path) ? url.path : nil
        }
        for path in fileURLs {
            try? fileManager.removeItem(atPath: path)
        }
        // 重新载入
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 重建失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview 支援

extension PersistenceController {
    /// 供 SwiftUI Preview 使用的内存型 PersistenceController
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.viewContext

        // 插入一笔范例交易
        let sampleTransaction = TransactionEntity(context: context)
        sampleTransaction.id = UUID()
        sampleTransaction.amount = 250.0
        sampleTransaction.categoryRaw = Category.foodTransport.rawValue
        sampleTransaction.note = "午餐"
        sampleTransaction.inputMethodRaw = InputMethod.text.rawValue
        sampleTransaction.createdAt = Date()
        sampleTransaction.updatedAt = Date()

        // 插入一笔范例预算设定
        let sampleBudget = BudgetConfigEntity(context: context)
        sampleBudget.id = UUID()
        sampleBudget.monthKey = "2025-06"
        sampleBudget.monthlyTotal = 30000.0
        sampleBudget.ratiosJSON = "{\"tithe\":0.10,\"filial\":0.10,\"social\":0.10,\"housing\":0.20,\"debt\":0.10,\"foodTransport\":0.30,\"flexible\":0.10}"
        sampleBudget.updatedAt = Date()

        try? context.save()
        return controller
    }()
}
