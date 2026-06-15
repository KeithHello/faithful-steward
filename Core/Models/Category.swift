import SwiftUI

/// 七大预算分类枚举，对应「什一奉献」理念的固定支出类别。
enum Category: String, CaseIterable, Codable {
    case tithe = "tithe"
    case filial = "filial"
    case social = "social"
    case housing = "housing"
    case debt = "debt"
    case foodTransport = "foodTransport"
    case flexible = "flexible"

    /// 繁体中文显示名称
    var displayName: String {
        switch self {
        case .tithe: return "十一"
        case .filial: return "孝親"
        case .social: return "交際"
        case .housing: return "住"
        case .debt: return "還款"
        case .foodTransport: return "食行"
        case .flexible: return "彈性"
        }
    }

    /// 预设预算比例（总和 = 1.0）
    var defaultRatio: Double {
        switch self {
        case .tithe: return 0.10
        case .filial: return 0.10
        case .social: return 0.10
        case .housing: return 0.20
        case .debt: return 0.10
        case .foodTransport: return 0.30
        case .flexible: return 0.10
        }
    }

    /// 分类代表颜色
    var color: Color {
        switch self {
        case .tithe: return .indigo
        case .filial: return .pink
        case .social: return .orange
        case .housing: return .blue
        case .debt: return .purple
        case .foodTransport: return .green
        case .flexible: return .gray
        }
    }

    /// SF Symbols 图标名称
    var iconName: String {
        switch self {
        case .tithe: return "hands.sparkles.fill"
        case .filial: return "heart.fill"
        case .social: return "person.2.fill"
        case .housing: return "house.fill"
        case .debt: return "creditcard.fill"
        case .foodTransport: return "takeoutbag.and.cup.and.straw.fill"
        case .flexible: return "ellipsis.circle.fill"
        }
    }

    /// 所有分类的预设比例字典
    static var defaultRatios: [Category: Double] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.defaultRatio) })
    }
}
