import XCTest
@testable import FaithfulSteward

/// PeriodCalculator 单元测试：验证 monthKey 格式化与自然月周期日期区间计算。
final class PeriodCalculatorTests: XCTestCase {

    // MARK: - 测试日期（固定参考点）

    /// 固定参考日期：2025-06-15 12:30:00（UTC+8 中午）
    private let referenceDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 15
        components.hour = 12
        components.minute = 30
        components.second = 0
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }()

    // MARK: - monthKey 测试

    func test_monthKey_returnsCorrectFormat() {
        let key = PeriodCalculator.monthKey(from: referenceDate)
        XCTAssertEqual(key, "2025-06")
    }

    func test_monthKey_january_returnsTwoDigitMonth() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.timeZone = TimeZone.current
        let janDate = Calendar.current.date(from: components)!
        let key = PeriodCalculator.monthKey(from: janDate)
        XCTAssertEqual(key, "2025-01")
    }

    func test_monthKey_december_returnsTwoDigitMonth() {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 1
        components.timeZone = TimeZone.current
        let decDate = Calendar.current.date(from: components)!
        let key = PeriodCalculator.monthKey(from: decDate)
        XCTAssertEqual(key, "2025-12")
    }

    func test_monthKey_differentYears_producesDifferentKeys() {
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 31
        components.timeZone = TimeZone.current
        let date2024 = Calendar.current.date(from: components)!

        let key2024 = PeriodCalculator.monthKey(from: date2024)
        let key2025 = PeriodCalculator.monthKey(from: referenceDate)
        XCTAssertEqual(key2024, "2024-12")
        XCTAssertEqual(key2025, "2025-06")
        XCTAssertNotEqual(key2024, key2025)
    }

    // MARK: - dateRange 测试（委托给 Period.dateRange）

    func test_dateRange_currentMonth_startsOnFirstDay() {
        let (start, end) = PeriodCalculator.dateRange(for: .currentMonth, now: referenceDate)

        // 起始日期应为当月 1 日 00:00:00
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start)
        XCTAssertEqual(startComponents.year, 2025)
        XCTAssertEqual(startComponents.month, 6)
        XCTAssertEqual(startComponents.day, 1)
        XCTAssertEqual(startComponents.hour, 0)
        XCTAssertEqual(startComponents.minute, 0)

        // 结束日期应为当天 23:59:59
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: end)
        XCTAssertEqual(endComponents.year, 2025)
        XCTAssertEqual(endComponents.month, 6)
        XCTAssertEqual(endComponents.day, 15)
        XCTAssertEqual(endComponents.hour, 23)
        XCTAssertEqual(endComponents.minute, 59)
    }

    func test_dateRange_last3Months_startsFourMonthsAgo() {
        // 2025-06 → 前推 2 个月 = 2025-04
        let (start, end) = PeriodCalculator.dateRange(for: .last3Months, now: referenceDate)

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(startComponents.year, 2025)
        XCTAssertEqual(startComponents.month, 4)
        XCTAssertEqual(startComponents.day, 1)
    }

    func test_dateRange_last6Months_startsSixMonthsAgo() {
        // 2025-06 → 前推 5 个月 = 2025-01
        let (start, end) = PeriodCalculator.dateRange(for: .last6Months, now: referenceDate)

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: start)
        XCTAssertEqual(startComponents.year, 2025)
        XCTAssertEqual(startComponents.month, 1)
    }

    func test_dateRange_last12Months_startsTwelveMonthsAgo() {
        // 2025-06 → 前推 11 个月 = 2024-07
        let (start, end) = PeriodCalculator.dateRange(for: .last12Months, now: referenceDate)

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: start)
        XCTAssertEqual(startComponents.year, 2024)
        XCTAssertEqual(startComponents.month, 7)
    }

    func test_dateRange_startIsBeforeEnd() {
        for period in Period.allCases {
            let (start, end) = PeriodCalculator.dateRange(for: period, now: referenceDate)
            XCTAssertLessThanOrEqual(start, end, "\(period.displayName): 起始日期应 ≤ 结束日期")
        }
    }

    func test_dateRange_startIsMidnight() {
        let calendar = Calendar.current
        for period in Period.allCases {
            let (start, _) = PeriodCalculator.dateRange(for: period, now: referenceDate)
            let hour = calendar.component(.hour, from: start)
            let minute = calendar.component(.minute, from: start)
            let second = calendar.component(.second, from: start)
            XCTAssertEqual(hour, 0, "\(period.displayName): 起始时数应为 0")
            XCTAssertEqual(minute, 0, "\(period.displayName): 起始分钟应为 0")
            XCTAssertEqual(second, 0, "\(period.displayName): 起始秒数应为 0")
        }
    }

    // MARK: - allMonthKeys 测试

    func test_allMonthKeys_currentMonth_returnsSingleKey() {
        let keys = PeriodCalculator.allMonthKeys(for: .currentMonth, now: referenceDate)
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys.first, "2025-06")
    }

    func test_allMonthKeys_last3Months_returnsThreeKeys() {
        // 2025-04, 2025-05, 2025-06
        let keys = PeriodCalculator.allMonthKeys(for: .last3Months, now: referenceDate)
        XCTAssertEqual(keys.count, 3)
        XCTAssertEqual(keys, ["2025-04", "2025-05", "2025-06"])
    }

    func test_allMonthKeys_last6Months_returnsSixKeys() {
        let keys = PeriodCalculator.allMonthKeys(for: .last6Months, now: referenceDate)
        XCTAssertEqual(keys.count, 6)
        XCTAssertEqual(keys, [
            "2025-01", "2025-02", "2025-03",
            "2025-04", "2025-05", "2025-06"
        ])
    }

    func test_allMonthKeys_last12Months_returnsTwelveKeys() {
        let keys = PeriodCalculator.allMonthKeys(for: .last12Months, now: referenceDate)
        XCTAssertEqual(keys.count, 12)
        // 2024-07 至 2025-06
        XCTAssertEqual(keys.first, "2024-07")
        XCTAssertEqual(keys.last, "2025-06")
    }

    func test_allMonthKeys_areChronological() {
        for period in Period.allCases {
            let keys = PeriodCalculator.allMonthKeys(for: period, now: referenceDate)
            // 验证由旧到新排列
            for i in 1..<keys.count {
                XCTAssertLessThan(keys[i - 1], keys[i],
                    "\(period.displayName): keys 应按时间顺序排列")
            }
        }
    }

    func test_allMonthKeys_noDuplicates() {
        for period in Period.allCases {
            let keys = PeriodCalculator.allMonthKeys(for: period, now: referenceDate)
            XCTAssertEqual(keys.count, Set(keys).count,
                "\(period.displayName): 不应有重复的 monthKey")
        }
    }

    // MARK: - currentMonthKey 测试

    func test_currentMonthKey_returnsCurrentMonth() {
        let key = PeriodCalculator.currentMonthKey(now: referenceDate)
        XCTAssertEqual(key, "2025-06")
    }

    // MARK: - startOfMonth 测试

    func test_startOfMonth_midMonth_returnsFirstDay() {
        let start = PeriodCalculator.startOfMonth(for: referenceDate)
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.day, 1)
    }

    func test_startOfMonth_firstDay_returnsFirstDay() {
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 1
        components.timeZone = TimeZone.current
        let firstDay = Calendar.current.date(from: components)!

        let start = PeriodCalculator.startOfMonth(for: firstDay)
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.day, 1)
    }

    func test_startOfMonth_yearBoundary_december() {
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 31
        components.timeZone = TimeZone.current
        let dec31 = Calendar.current.date(from: components)!

        let start = PeriodCalculator.startOfMonth(for: dec31)
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(comps.year, 2024)
        XCTAssertEqual(comps.month, 12)
        XCTAssertEqual(comps.day, 1)
    }

    // MARK: - Period Enum 属性测试

    func test_period_allCases_count() {
        XCTAssertEqual(Period.allCases.count, 4)
    }

    func test_period_monthCount_values() {
        XCTAssertEqual(Period.currentMonth.monthCount, 1)
        XCTAssertEqual(Period.last3Months.monthCount, 3)
        XCTAssertEqual(Period.last6Months.monthCount, 6)
        XCTAssertEqual(Period.last12Months.monthCount, 12)
    }

    func test_period_displayName_notEmpty() {
        for period in Period.allCases {
            XCTAssertFalse(period.displayName.isEmpty,
                "\(period.rawValue) 的 displayName 不应为空")
        }
    }
}
