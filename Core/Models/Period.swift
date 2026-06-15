import Foundation

/// 预算检视周期：本月 / 近 3 个月 / 近 6 个月 / 近 12 个月。
/// 全部使用自然月计算。
enum Period: String, CaseIterable {
    case currentMonth = "currentMonth"
    case last3Months = "last3Months"
    case last6Months = "last6Months"
    case last12Months = "last12Months"

    /// 繁体中文显示名称
    var displayName: String {
        switch self {
        case .currentMonth: return "本月"
        case .last3Months: return "近 3 個月"
        case .last6Months: return "近 6 個月"
        case .last12Months: return "近 12 個月"
        }
    }

    /// 周期涵盖的月份数量
    var monthCount: Int {
        switch self {
        case .currentMonth: return 1
        case .last3Months: return 3
        case .last6Months: return 6
        case .last12Months: return 12
        }
    }

    /// 计算此周期对应的日期区间。
    /// - Parameter now: 参考日期（通常为 Date()）
    /// - Returns: (start: 区间起始日 00:00:00, end: 区间结束日，即今天 23:59:59)
    func dateRange(now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        // 结束日：今天 23:59:59
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now

        let startDate: Date
        switch self {
        case .currentMonth:
            // 本月 1 日 00:00:00
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .last3Months, .last6Months, .last12Months:
            // 往前推 (monthCount - 1) 个月的第 1 日
            let monthsAgo = monthCount - 1
            guard let targetMonth = calendar.date(byAdding: .month, value: -monthsAgo, to: now) else {
                startDate = now
                break
            }
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth)) ?? now
        }

        // 确保起始日为当天 00:00:00
        let startOfDay = calendar.startOfDay(for: startDate)
        return (start: startOfDay, end: endOfToday)
    }
}
