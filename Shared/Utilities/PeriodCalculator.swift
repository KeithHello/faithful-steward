import Foundation

/// 自然月周期计算器：提供日期区间计算、monthKey 格式化等功能。
struct PeriodCalculator {

    /// 计算指定周期的日期区间。
    /// - Parameters:
    ///   - period: 检视周期
    ///   - now: 参考日期
    /// - Returns: (start: Date, end: Date)
    static func dateRange(for period: Period, now: Date = Date()) -> (start: Date, end: Date) {
        return period.dateRange(now: now)
    }

    /// 从 Date 产生 monthKey。
    /// 格式："yyyy-MM"（如 "2025-06"）
    /// - Parameter date: 日期
    /// - Returns: monthKey 字串
    static func monthKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        return formatter.string(from: date)
    }

    /// 产生指定周期涵盖的所有 monthKey。
    /// 例：本月 → ["2025-06"]，近3月 → ["2025-04", "2025-05", "2025-06"]
    /// - Parameters:
    ///   - period: 检视周期
    ///   - now: 参考日期
    /// - Returns: monthKey 字串阵列（由旧到新排列）
    static func allMonthKeys(for period: Period, now: Date = Date()) -> [String] {
        let calendar = Calendar.current
        let range = period.dateRange(now: now)
        var keys: [String] = []

        // 从起始月开始，逐月递增直到当前月
        var currentDate = range.start
        while currentDate <= range.end {
            keys.append(monthKey(from: currentDate))
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) else { break }
            currentDate = nextMonth
        }

        return keys
    }

    /// 取得当前月的 monthKey
    /// - Parameter now: 参考日期
    /// - Returns: monthKey 字串
    static func currentMonthKey(now: Date = Date()) -> String {
        return monthKey(from: now)
    }

    /// 计算给定日期所属月份的第一天 00:00:00
    /// - Parameter date: 日期
    /// - Returns: 当月第一天
    static func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
