import SwiftUI

/// 7 大分類 enum — 不可刪除的預設分類
enum Category: String, CaseIterable, Codable {
    case tithe, filial, social, housing, debt, foodTransport, flexible

    var displayName: String {
        switch self {
        case .tithe: return "十一奉獻"
        case .filial: return "孝親費"
        case .social: return "交際費"
        case .housing: return "租房買房（住）"
        case .debt: return "還款存款保險投資"
        case .foodTransport: return "生活必需（食行）"
        case .flexible: return "彈性運用（衣通訊）"
        }
    }

    var shortName: String {
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

    var color: Color {
        switch self {
        case .tithe: return Color(hex: "#C47DA7")
        case .filial: return Color(hex: "#D4A057")
        case .social: return Color(hex: "#7DAEBF")
        case .housing: return Color(hex: "#8C7DC4")
        case .debt: return Color(hex: "#5B7FAD")
        case .foodTransport: return Color(hex: "#5B8C5A")
        case .flexible: return Color(hex: "#C47D6B")
        }
    }

    var iconName: String {
        switch self {
        case .tithe: return "cross.circle.fill"
        case .filial: return "heart.circle.fill"
        case .social: return "person.2.circle.fill"
        case .housing: return "house.circle.fill"
        case .debt: return "banknote.circle.fill"
        case .foodTransport: return "cart.circle.fill"
        case .flexible: return "ellipsis.circle.fill"
        }
    }

    static var defaultRatios: [Category: Double] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.defaultRatio) })
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static let brandPrimary = Color(hex: "#5B8C5A")
    static let brandSecondary = Color(hex: "#7DAEBF")
    static let surfaceBackground = Color(hex: "#FBFAF8")
    static let cardBackground = Color.white
    static let textPrimary = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#6B7280")
    static let overBudgetRed = Color(hex: "#DC2626")
    static let underBudgetGreen = Color(hex: "#16A34A")
}
