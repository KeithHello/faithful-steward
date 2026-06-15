import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tithe_budget")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }
}

/// CoreData 預覽用（測試資料）
extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // 新增幾筆測試交易
        let sampleTransactions: [(Double, String)] = [
            (3000, "tithe"), (3000, "filial"), (4500, "social"),
            (5400, "housing"), (2700, "debt"), (10500, "foodTransport"), (1500, "flexible"),
        ]
        for (amount, rawCategory) in sampleTransactions {
            let txn = TransactionEntity(context: context)
            txn.id = UUID()
            txn.amount = amount
            txn.categoryRaw = rawCategory
            txn.inputMethodRaw = "text"
            txn.createdAt = Date()
            txn.updatedAt = Date()
        }

        try? controller.save()
        return controller
    }()
}
