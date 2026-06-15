import Foundation

enum Period: String, CaseIterable, Codable {
    case currentMonth, last3Months, last6Months, last12Months

    var displayName: String {
        switch self {
        case .currentMonth: return "本月"
        case .last3Months: return "近 3 個月"
        case .last6Months: return "近 6 個月"
        case .last12Months: return "近 12 個月"
        }
    }

    var monthCount: Int {
        switch self {
        case .currentMonth: return 1
        case .last3Months: return 3
        case .last6Months: return 6
        case .last12Months: return 12
        }
    }
}
