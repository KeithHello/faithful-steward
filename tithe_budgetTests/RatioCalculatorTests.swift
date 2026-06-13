import XCTest
import CoreData
@testable import FaithfulSteward

/// RatioCalculator 单元测试：验证比例计算、差异计算、重分配算法与总和验证。
final class RatioCalculatorTests: XCTestCase {

    // MARK: - 测试辅助：In-Memory CoreData Stack

    var testContainer: NSPersistentContainer!

    override func setUp() {
        super.setUp()
        testContainer = makeInMemoryContainer()
    }

    override func tearDown() {
        testContainer = nil
        super.tearDown()
    }

    /// 建立内存中的 NSPersistentContainer，用于建立 TransactionEntity / BudgetConfigEntity
    private func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "FaithfulSteward")
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Test CoreData stack failed: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }

    /// Helper：建立测试用 TransactionEntity
    private func makeTransaction(
        amount: Double,
        category: Category,
        context: NSManagedObjectContext
    ) -> TransactionEntity {
        let tx = TransactionEntity(context: context)
        tx.id = UUID()
        tx.amount = amount
        tx.categoryRaw = category.rawValue
        tx.createdAt = Date()
        tx.updatedAt = Date()
        return tx
    }

    /// Helper：建立测试用 BudgetConfigEntity
    private func makeBudgetConfig(
        monthKey: String,
        monthlyTotal: Double,
        ratios: [Category: Double],
        context: NSManagedObjectContext
    ) -> BudgetConfigEntity {
        let config = BudgetConfigEntity(context: context)
        config.id = UUID()
        config.monthKey = monthKey
        config.monthlyTotal = monthlyTotal
        config.updatedAt = Date()
        // Encode ratios to JSON
        var dict: [String: Double] = [:]
        for (cat, ratio) in ratios {
            dict[cat.rawValue] = ratio
        }
        config.ratiosJSON = (try? JSONEncoder().encode(dict)).flatMap {
            String(data: $0, encoding: .utf8)
        } ?? "{}"
        return config
    }

    // MARK: - validateTotalRatio 测试

    func test_validateTotalRatio_exactOne_returnsTrue() {
        let ratios: [Category: Double] = [
            .tithe: 0.10, .filial: 0.10, .social: 0.10,
            .housing: 0.20, .debt: 0.10, .foodTransport: 0.30,
            .flexible: 0.10
        ]
        XCTAssertTrue(RatioCalculator.validateTotalRatio(ratios: ratios))
    }

    func test_validateTotalRatio_withinTolerance_returnsTrue() {
        // 总和 = 1.0005，在 ±0.001 容忍范围内
        let ratios: [Category: Double] = [
            .tithe: 0.1005, .filial: 0.10, .social: 0.10,
            .housing: 0.20, .debt: 0.10, .foodTransport: 0.30,
            .flexible: 0.0995
        ]
        // 总和 = 0.1005+0.10+0.10+0.20+0.10+0.30+0.0995 = 1.0000
        XCTAssertTrue(RatioCalculator.validateTotalRatio(ratios: ratios))
    }

    func test_validateTotalRatio_outsideTolerance_returnsFalse() {
        // 总和 = 0.95
        let ratios: [Category: Double] = [
            .tithe: 0.05, .filial: 0.10, .social: 0.10,
            .housing: 0.20, .debt: 0.10, .foodTransport: 0.30,
            .flexible: 0.10
        ]
        XCTAssertFalse(RatioCalculator.validateTotalRatio(ratios: ratios))
    }

    func test_validateTotalRatio_emptyDictionary_returnsFalse() {
        let ratios: [Category: Double] = [:]
        // 总和 = 0，|0 - 1.0| = 1.0 > 0.001
        XCTAssertFalse(RatioCalculator.validateTotalRatio(ratios: ratios))
    }

    // MARK: - totalRatio 测试

    func test_totalRatio_defaultRatios_equalsOne() {
        let ratios = Category.defaultRatios
        XCTAssertEqual(RatioCalculator.totalRatio(ratios: ratios), 1.0, accuracy: 0.001)
    }

    func test_totalRatio_partialRatios_returnsCorrectSum() {
        let ratios: [Category: Double] = [.tithe: 0.5, .housing: 0.3]
        XCTAssertEqual(RatioCalculator.totalRatio(ratios: ratios), 0.8, accuracy: 0.001)
    }

    // MARK: - calculateDifference 测试

    func test_calculateDifference_allEqual_returnsZeros() {
        let defaults = Category.defaultRatios
        let differences = RatioCalculator.calculateDifference(actual: defaults, budget: defaults)
        for (_, diff) in differences {
            XCTAssertEqual(diff, 0.0, accuracy: 0.001)
        }
    }

    func test_calculateDifference_overBudget_returnsPositive() {
        let actual: [Category: Double] = [.tithe: 0.15, .foodTransport: 0.35]
        let budget: [Category: Double] = [.tithe: 0.10, .foodTransport: 0.30]
        let differences = RatioCalculator.calculateDifference(actual: actual, budget: budget)
        XCTAssertEqual(differences[.tithe]!, 0.05, accuracy: 0.001)
        XCTAssertEqual(differences[.foodTransport]!, 0.05, accuracy: 0.001)
    }

    func test_calculateDifference_underBudget_returnsNegative() {
        let actual: [Category: Double] = [.tithe: 0.05]
        let budget: [Category: Double] = [.tithe: 0.10]
        let differences = RatioCalculator.calculateDifference(actual: actual, budget: budget)
        XCTAssertEqual(differences[.tithe]!, -0.05, accuracy: 0.001)
    }

    func test_calculateDifference_missingCategories_usesFallback() {
        // 当 budget 缺少某分类时，应使用 defaultRatio
        let actual: [Category: Double] = [.tithe: 0.15]
        let budget: [Category: Double] = [:]  // 空 budget
        let differences = RatioCalculator.calculateDifference(actual: actual, budget: budget)
        // tithe 的 defaultRatio = 0.10，所以差异 = 0.15 - 0.10 = 0.05
        XCTAssertEqual(differences[.tithe]!, 0.05, accuracy: 0.001)
        // foodTransport 未在 actual 中，差异 = 0 - 0.30 = -0.30
        XCTAssertEqual(differences[.foodTransport]!, -0.30, accuracy: 0.001)
    }

    // MARK: - redistributeRatios 测试（核心算法）

    func test_redistributeRatios_increaseOne_othersDecreaseProportionally() {
        var ratios = Category.defaultRatios  // 总和 = 1.0
        // 将 foodTransport 从 0.30 调高到 0.35（+0.05）
        let newRatios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .foodTransport,
            newValue: 0.35
        )
        // foodTransport 应为 0.35
        XCTAssertEqual(newRatios[.foodTransport]!, 0.35, accuracy: 0.01)
        // 总和仍应 ≈ 1.0
        let total = newRatios.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.01)
        // 验证该分类确实被调整了
        XCTAssertEqual(newRatios[.foodTransport]!, 0.35, accuracy: 0.01)
    }

    func test_redistributeRatios_decreaseOne_othersIncreaseProportionally() {
        var ratios = Category.defaultRatios
        // 将 foodTransport 从 0.30 调低到 0.20（-0.10）
        let newRatios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .foodTransport,
            newValue: 0.20
        )
        // foodTransport 应为 0.20
        XCTAssertEqual(newRatios[.foodTransport]!, 0.20, accuracy: 0.01)
        // 总和仍应 ≈ 1.0
        let total = newRatios.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.01)
        // 其他分类总和应为 0.80（整体总和 1.0 - 0.20）
        let others = Category.allCases.filter { $0 != .foodTransport }
        let otherTotal = others.reduce(0.0) { $0 + (newRatios[$1] ?? 0) }
        XCTAssertEqual(otherTotal, 0.80, accuracy: 0.01)
    }

    func test_redistributeRatios_setToZero_othersAbsorbAll() {
        var ratios = Category.defaultRatios
        // 将 tithe 设为 0
        let newRatios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .tithe,
            newValue: 0.0
        )
        XCTAssertEqual(newRatios[.tithe]!, 0.0, accuracy: 0.001)
        let total = newRatios.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.01)
    }

    func test_redistributeRatios_setToOne_othersBecomeZero() {
        var ratios = Category.defaultRatios
        // 将 tithe 设为 1.0
        let newRatios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .tithe,
            newValue: 1.0
        )
        XCTAssertEqual(newRatios[.tithe]!, 1.0, accuracy: 0.01)
        let total = newRatios.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.01)
    }

    func test_redistributeRatios_noOtherTotal_averageSplit() {
        // 当其余分类总和为 0 时，差额平均分配
        var ratios: [Category: Double] = [:]
        for cat in Category.allCases {
            ratios[cat] = 0.0
        }
        ratios[.tithe] = 1.0  // 只有 tithe 有 100%

        // 将 tithe 调整为 0.5
        let newRatios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .tithe,
            newValue: 0.5
        )
        XCTAssertEqual(newRatios[.tithe]!, 0.5, accuracy: 0.01)
        // 其余 6 类均分 +0.5 → 每类 0.5/6 ≈ 0.0833
        let others = Category.allCases.filter { $0 != .tithe }
        for cat in others {
            XCTAssertEqual(newRatios[cat]!, 0.5 / 6.0, accuracy: 0.01)
        }
        let total = newRatios.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.01)
    }

    func test_redistributeRatios_clampedNewValue_outOfRange() {
        // 超过范围的值应被 clamp
        var ratios = Category.defaultRatios
        let newRatios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .tithe,
            newValue: 1.5  // > 1.0，应 clamp 到 1.0
        )
        XCTAssertEqual(newRatios[.tithe]!, 1.0, accuracy: 0.01)

        let newRatios2 = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .tithe,
            newValue: -0.5  // < 0，应 clamp 到 0
        )
        XCTAssertEqual(newRatios2[.tithe]!, 0.0, accuracy: 0.001)
    }

    func test_redistributeRatios_noExistingRatioForCategory() {
        // 当 ratios 字典中没有 changedCategory 时
        var ratios: [Category: Double] = [.housing: 0.5, .foodTransport: 0.5]
        let newRatios = RatioCalculator.redistributeRatios(
            ratios: ratios,
            changedCategory: .tithe,
            newValue: 0.1
        )
        // tithe 旧值为 0（不存在于字典），新值为 0.1
        // 差额 = 0.1 - 0 = 0.1
        // 其余（housing + foodTransport）按比例分摊 -0.1
        XCTAssertEqual(newRatios[.tithe]!, 0.1, accuracy: 0.01)
        let total = newRatios.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.01)
    }

    // MARK: - calculateActualRatios 测试（需 CoreData）

    func test_calculateActualRatios_noTransactions_returnsAllZeros() {
        let ratios = RatioCalculator.calculateActualRatios(transactions: [])
        // 所有分类比例应为 0
        for (_, ratio) in ratios {
            XCTAssertEqual(ratio, 0.0)
        }
        // 应包含所有 7 个分类
        XCTAssertEqual(ratios.count, Category.allCases.count)
    }

    func test_calculateActualRatios_singleTransaction_returnsFullRatio() {
        let ctx = testContainer.viewContext
        let tx = makeTransaction(amount: 100, category: .foodTransport, context: ctx)
        let ratios = RatioCalculator.calculateActualRatios(transactions: [tx])
        XCTAssertEqual(ratios[.foodTransport]!, 1.0, accuracy: 0.001)
        // 其他分类应为 0
        for cat in Category.allCases where cat != .foodTransport {
            XCTAssertEqual(ratios[cat]!, 0.0)
        }
    }

    func test_calculateActualRatios_multipleTransactions_proportionalRatios() {
        let ctx = testContainer.viewContext
        let tx1 = makeTransaction(amount: 100, category: .tithe, context: ctx)
        let tx2 = makeTransaction(amount: 400, category: .foodTransport, context: ctx)
        let tx3 = makeTransaction(amount: 500, category: .housing, context: ctx)
        // 总金额 = 1000
        let ratios = RatioCalculator.calculateActualRatios(transactions: [tx1, tx2, tx3])
        XCTAssertEqual(ratios[.tithe]!, 0.10, accuracy: 0.01)
        XCTAssertEqual(ratios[.foodTransport]!, 0.40, accuracy: 0.01)
        XCTAssertEqual(ratios[.housing]!, 0.50, accuracy: 0.01)
    }

    // MARK: - calculateActualAmounts 测试（需 CoreData）

    func test_calculateActualAmounts_noTransactions_returnsAllZeros() {
        let amounts = RatioCalculator.calculateActualAmounts(transactions: [])
        for (_, amount) in amounts {
            XCTAssertEqual(amount, 0.0)
        }
        XCTAssertEqual(amounts.count, Category.allCases.count)
    }

    func test_calculateActualAmounts_withTransactions_returnsCorrectAmounts() {
        let ctx = testContainer.viewContext
        let tx1 = makeTransaction(amount: 250, category: .foodTransport, context: ctx)
        let tx2 = makeTransaction(amount: 150, category: .foodTransport, context: ctx)
        let tx3 = makeTransaction(amount: 500, category: .housing, context: ctx)
        let amounts = RatioCalculator.calculateActualAmounts(transactions: [tx1, tx2, tx3])
        XCTAssertEqual(amounts[.foodTransport]!, 400.0)
        XCTAssertEqual(amounts[.housing]!, 500.0)
    }

    // MARK: - calculateBudgetRatios 测试（需 CoreData + DataProvider）

    func test_calculateBudgetRatios_validConfig_returnsDecodedRatios() {
        let ctx = testContainer.viewContext
        let dataProvider = DataProvider(context: ctx)
        let config = makeBudgetConfig(
            monthKey: "2025-06",
            monthlyTotal: 30000,
            ratios: Category.defaultRatios,
            context: ctx
        )
        let ratios = RatioCalculator.calculateBudgetRatios(config: config, dataProvider: dataProvider)
        XCTAssertEqual(ratios[.tithe]!, 0.10, accuracy: 0.001)
        XCTAssertEqual(ratios[.foodTransport]!, 0.30, accuracy: 0.001)
    }

    func test_calculateBudgetRatios_malformedJSON_fallsBackToDefaults() {
        let ctx = testContainer.viewContext
        let dataProvider = DataProvider(context: ctx)
        let config = BudgetConfigEntity(context: ctx)
        config.id = UUID()
        config.monthKey = "2025-06"
        config.monthlyTotal = 30000
        config.ratiosJSON = "not-valid-json"
        config.updatedAt = Date()
        let ratios = RatioCalculator.calculateBudgetRatios(config: config, dataProvider: dataProvider)
        // 应回退到 preset ratio
        XCTAssertEqual(ratios[.tithe]!, 0.10, accuracy: 0.001)
    }
}
