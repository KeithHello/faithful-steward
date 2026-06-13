import Foundation

/// 金额解析器：支援阿拉伯数字与繁体中文口语数字的解析。
/// 例："250" → 250, "两百五" → 250, "一千二" → 1200, "三百块" → 300
struct AmountParser {

    /// 解析文字中的金额数字
    /// - Parameter text: 输入文字（可为纯数字或繁中口语）
    /// - Returns: 解析后的 Double，无法解析则回传 nil
    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 先尝试阿拉伯数字
        if let number = parseArabicNumber(trimmed) {
            return number
        }

        // 再尝试繁体中文数字
        if let number = parseChineseNumber(trimmed) {
            return number
        }

        return nil
    }

    // MARK: - 阿拉伯数字解析

    /// 解析纯阿拉伯数字（含小数）
    /// 支援格式："250", "250.5", "1,250" 等
    private static func parseArabicNumber(_ text: String) -> Double? {
        // 移除逗号、空白与常见后缀
        var cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "塊", with: "")
            .replacingOccurrences(of: "块", with: "")
            .replacingOccurrences(of: "NT$", with: "")
            .replacingOccurrences(of: "nt$", with: "")
            .replacingOccurrences(of: "NT", with: "")
            .replacingOccurrences(of: "$", with: "")

        // 若清理后为空，回传 nil
        guard !cleaned.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let number = formatter.number(from: cleaned) {
            return number.doubleValue
        }

        return nil
    }

    // MARK: - 繁体中文数字解析

    /// 解析繁体中文口语数字
    /// 支援范围：1 ~ 999,999（百万以下）
    static func parseChineseNumber(_ text: String) -> Double? {
        var cleaned = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "塊", with: "")
            .replacingOccurrences(of: "块", with: "")
            .replacingOccurrences(of: "錢", with: "")
            .replacingOccurrences(of: "钱", with: "")

        guard !cleaned.isEmpty else { return nil }

        // 中文数字对应表（包含繁简）
        let chineseDigits: [Character: Double] = [
            "零": 0, "〇": 0,
            "一": 1, "壹": 1,
            "二": 2, "兩": 2, "两": 2, "貳": 2,
            "三": 3, "參": 3, "叁": 3,
            "四": 4, "肆": 4,
            "五": 5, "伍": 5,
            "六": 6, "陸": 6,
            "七": 7, "柒": 7,
            "八": 8, "捌": 8,
            "九": 9, "玖": 9,
        ]

        let chineseUnits: [Character: Double] = [
            "十": 10, "拾": 10,
            "百": 100, "佰": 100,
            "千": 1000, "仟": 1000,
            "萬": 10000, "万": 10000,
        ]

        let chars = Array(cleaned)

        // 检查是否包含中文数字字符
        let hasChineseDigit = chars.contains { chineseDigits[$0] != nil }
        let hasChineseUnit = chars.contains { chineseUnits[$0] != nil }
        guard hasChineseDigit || hasChineseUnit else { return nil }

        // 解析算法：处理「万」分段 + 隐式单位（如「两百五」=250，非205）
        var result: Double = 0
        var currentNumber: Double = 0
        var sectionNumber: Double = 0  // 当前 < 10000 的段落
        var lastUnitValue: Double = 1  // 上一個单位的值，用于处理隐式单位

        for char in chars {
            if let digit = chineseDigits[char] {
                currentNumber = digit
                // 不重设 lastUnitValue，保留单位上下文
            } else if char == "十" || char == "拾" {
                if currentNumber == 0 { currentNumber = 1 }
                currentNumber *= 10
                sectionNumber += currentNumber
                currentNumber = 0
                lastUnitValue = 10
            } else if char == "百" || char == "佰" {
                if currentNumber == 0 { currentNumber = 1 }
                currentNumber *= 100
                sectionNumber += currentNumber
                currentNumber = 0
                lastUnitValue = 100
            } else if char == "千" || char == "仟" {
                if currentNumber == 0 { currentNumber = 1 }
                currentNumber *= 1000
                sectionNumber += currentNumber
                currentNumber = 0
                lastUnitValue = 1000
            } else if char == "萬" || char == "万" {
                if currentNumber > 0 { sectionNumber += currentNumber }
                if sectionNumber == 0 { sectionNumber = 1 }
                result += sectionNumber * 10000
                sectionNumber = 0
                currentNumber = 0
                lastUnitValue = 10000
            } else {
                // 非中文数字字符，跳出
                return nil
            }
        }

        // 处理尾部隐式单位：
        // 例：「两百五」→ lastUnitValue=100, currentNumber=5 → 5×(100/10)=50
        // 例：「一千二」→ lastUnitValue=1000, currentNumber=2 → 2×(1000/10)=200
        if currentNumber > 0 && lastUnitValue >= 10 {
            currentNumber *= (lastUnitValue / 10.0)
        }
        if currentNumber > 0 { sectionNumber += currentNumber }
        result += sectionNumber

        return result > 0 ? result : nil
    }
}
