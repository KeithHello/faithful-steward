import XCTest
import SwiftUI
@testable import FaithfulSteward

/// Category enum 单元测试：验证 7 大分类的预设比例、显示名称、颜色与图标设定。
final class CategoryTests: XCTestCase {

    // MARK: - allCases 测试

    func test_allCases_containsSevenCategories() {
        XCTAssertEqual(Category.allCases.count, 7, "应有 7 个预设分类")
    }

    func test_allCases_containsAllExpectedCases() {
        let expectedRawValues: Set<String> = [
            "tithe", "filial", "social", "housing",
            "debt", "foodTransport", "flexible"
        ]
        let actualRawValues = Set(Category.allCases.map { $0.rawValue })
        XCTAssertEqual(actualRawValues, expectedRawValues)
    }

    // MARK: - rawValue 测试

    func test_rawValue_tithe() {
        XCTAssertEqual(Category.tithe.rawValue, "tithe")
    }

    func test_rawValue_filial() {
        XCTAssertEqual(Category.filial.rawValue, "filial")
    }

    func test_rawValue_social() {
        XCTAssertEqual(Category.social.rawValue, "social")
    }

    func test_rawValue_housing() {
        XCTAssertEqual(Category.housing.rawValue, "housing")
    }

    func test_rawValue_debt() {
        XCTAssertEqual(Category.debt.rawValue, "debt")
    }

    func test_rawValue_foodTransport() {
        XCTAssertEqual(Category.foodTransport.rawValue, "foodTransport")
    }

    func test_rawValue_flexible() {
        XCTAssertEqual(Category.flexible.rawValue, "flexible")
    }

    func test_initFromRawValue_validValues() {
        XCTAssertEqual(Category(rawValue: "tithe"), .tithe)
        XCTAssertEqual(Category(rawValue: "filial"), .filial)
        XCTAssertEqual(Category(rawValue: "foodTransport"), .foodTransport)
    }

    func test_initFromRawValue_invalidValue_returnsNil() {
        XCTAssertNil(Category(rawValue: "invalid"))
        XCTAssertNil(Category(rawValue: ""))
        XCTAssertNil(Category(rawValue: "TITHE"))  // 大小写敏感
    }

    // MARK: - defaultRatio 测试

    func test_defaultRatio_sumEqualsOne() {
        let total = Category.allCases.reduce(0.0) { $0 + $1.defaultRatio }
        XCTAssertEqual(total, 1.0, accuracy: 0.0001, "7 大分类预设比例总和必须为 1.0")
    }

    func test_defaultRatio_individualValues() {
        XCTAssertEqual(Category.tithe.defaultRatio, 0.10, accuracy: 0.0001)
        XCTAssertEqual(Category.filial.defaultRatio, 0.10, accuracy: 0.0001)
        XCTAssertEqual(Category.social.defaultRatio, 0.10, accuracy: 0.0001)
        XCTAssertEqual(Category.housing.defaultRatio, 0.20, accuracy: 0.0001)
        XCTAssertEqual(Category.debt.defaultRatio, 0.10, accuracy: 0.0001)
        XCTAssertEqual(Category.foodTransport.defaultRatio, 0.30, accuracy: 0.0001)
        XCTAssertEqual(Category.flexible.defaultRatio, 0.10, accuracy: 0.0001)
    }

    func test_defaultRatio_noNegativeValues() {
        for category in Category.allCases {
            XCTAssertGreaterThanOrEqual(category.defaultRatio, 0.0,
                "\(category.rawValue) 预设比例不应为负数")
        }
    }

    // MARK: - displayName 测试

    func test_displayName_allCategories_haveNonEmptyName() {
        for category in Category.allCases {
            XCTAssertFalse(category.displayName.isEmpty,
                "\(category.rawValue) 应有繁体中文名称")
        }
    }

    func test_displayName_specificValues() {
        XCTAssertEqual(Category.tithe.displayName, "十一")
        XCTAssertEqual(Category.filial.displayName, "孝親")
        XCTAssertEqual(Category.social.displayName, "交際")
        XCTAssertEqual(Category.housing.displayName, "住")
        XCTAssertEqual(Category.debt.displayName, "還款")
        XCTAssertEqual(Category.foodTransport.displayName, "食行")
        XCTAssertEqual(Category.flexible.displayName, "彈性")
    }

    func test_displayName_allUnique() {
        let names = Category.allCases.map { $0.displayName }
        XCTAssertEqual(names.count, Set(names).count,
            "每个分类应有独一无二的显示名称")
    }

    // MARK: - color 测试

    func test_color_allCategories_haveColor() {
        for category in Category.allCases {
            // 仅验证 color 属性存在且可存取（Color 为 SwiftUI 型别，不需做值比对）
            _ = category.color
        }
    }

    func test_color_specificAssignments() {
        // 验证颜色指派与架构文件规范一致
        // indigo, pink, orange, blue, purple, green, gray
        // 因 SwiftUI Color 在测试中的可比性有限，这里仅验证不 crash
        let colors: [Color] = Category.allCases.map { $0.color }
        XCTAssertEqual(colors.count, 7)
    }

    // MARK: - iconName 测试

    func test_iconName_allCategories_haveNonEmptyIconName() {
        for category in Category.allCases {
            XCTAssertFalse(category.iconName.isEmpty,
                "\(category.rawValue) 应有 SF Symbols 图标名称")
        }
    }

    func test_iconName_startsWithValidSFSymbol() {
        // SF Symbols 名称应以小写字母开头，可含 '.' 和数字
        for category in Category.allCases {
            let icon = category.iconName
            // 有效的 SF Symbols 名称不以数字开头
            let firstChar = icon.first!
            XCTAssertTrue(firstChar.isLetter,
                "\(category.rawValue) 图标名称应以字母开头: \(icon)")
        }
    }

    func test_iconName_allUnique() {
        let icons = Category.allCases.map { $0.iconName }
        XCTAssertEqual(icons.count, Set(icons).count,
            "每个分类应有独一无二的 SF Symbols 名称")
    }

    // MARK: - defaultRatios 静态属性测试

    func test_defaultRatios_containsAllCategories() {
        let defaults = Category.defaultRatios
        XCTAssertEqual(defaults.count, 7)
        for category in Category.allCases {
            XCTAssertNotNil(defaults[category],
                "defaultRatios 应包含 \(category.rawValue)")
        }
    }

    func test_defaultRatios_valuesMatchDefaultRatio() {
        let defaults = Category.defaultRatios
        for category in Category.allCases {
            XCTAssertEqual(defaults[category], category.defaultRatio,
                "\(category.rawValue) 的 defaultRatios 值应与 defaultRatio 一致")
        }
    }

    func test_defaultRatios_sumEqualsOne() {
        let total = Category.defaultRatios.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
    }

    // MARK: - Codable 一致性测试

    func test_categoryCodable_roundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for category in Category.allCases {
            let data = try encoder.encode(category)
            let decoded = try decoder.decode(Category.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    // MARK: - CaseIterable 顺序测试

    func test_allCases_orderIsStable() {
        // 确认顺序稳定（在多次调⽤之间一致）
        let first = Category.allCases
        let second = Category.allCases
        XCTAssertEqual(first, second)
    }
}
