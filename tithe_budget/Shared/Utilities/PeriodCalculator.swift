import Foundation

/// 自然月週期計算器
final class PeriodCalculator {
    static func dateRange(for period: Period, now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = now

        switch period {
        case .currentMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, end)
        case .last3Months, .last6Months, .last12Months:
            let monthsBack = period.monthCount - 1
            let start = calendar.date(byAdding: .month, value: -monthsBack, to: now)!
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: start))!
            return (startOfMonth, end)
        }
    }

    static func monthKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func allMonthKeys(for period: Period, now: Date = Date()) -> [String] {
        let (start, end) = dateRange(for: period, now: now)
        var keys: [String] = []
        var current = start
        let calendar = Calendar.current

        while current <= end {
            keys.append(monthKey(from: current))
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }
        return keys
    }
}
