import Foundation

final class AmountParser {
    static func parse(_ text: String) -> Double? {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let text = text.trimmingCharacters(in: .whitespaces)

        // Try Arabic number first
        if let arabic = parseArabic(text) { return arabic }
        // Try Chinese number
        return parseChineseNumber(text)
    }

    private static func parseArabic(_ text: String) -> Double? {
        // Match floating point numbers (including negative)
        guard let match = text.firstMatch(of: /-?\d+(?:\.\d+)?/) else { return nil }
        return Double(match.output).flatMap { $0 }
    }

    private static let cnDigits: [Character: Int] = [
        "零": 0, "一": 1, "二": 2, "兩": 2, "三": 3, "四": 4,
        "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
        "十": 10, "百": 100, "千": 1000,
    ]
    private static let unitKeywords: [Character] = ["元", "塊", "圆"]

    private static func parseChineseNumber(_ text: String) -> Double? {
        var cleaned = text
        for ch in unitKeywords { cleaned = cleaned.replacingOccurrences(of: String(ch), with: "") }

        // Extract Chinese number sequence
        let cnPattern = try! Regex("[零一二兩三四五六七八九十百千萬]+")
        guard let match = cleaned.firstMatch(of: cnPattern) else { return nil }
        let cnStr = String(match.output)

        // Handle 萬
        if cnStr.contains("萬") {
            let parts = cnStr.components(separatedBy: "萬")
            let pre = cnToInt(parts[0]) ?? 1
            var post = 0
            if parts.count > 1, !parts[1].isEmpty {
                post = cnToInt(parts[1]) ?? 0
                if parts[1].count == 1, let d = cnDigits[parts[1].first!], d < 10 {
                    post *= 1000  // omit-unit after 萬
                }
            }
            return Double(pre * 10000 + post)
        }

        if let val = cnToInt(cnStr) { return Double(val) }
        return nil
    }

    private static func cnToInt(_ str: String) -> Int? {
        guard !str.isEmpty else { return 0 }
        let chars = Array(str)
        var result = 0
        var current = 0
        var i = 0

        while i < chars.count {
            guard let digit = cnDigits[chars[i]] else { i += 1; continue }

            if digit >= 10 { // unit
                if current == 0 { current = 1 }
                current *= digit

                // Omit-unit pattern: last char is a digit after unit
                if i + 1 == chars.count - 1 {
                    let nextChar = chars[i + 1]
                    if let nextDigit = cnDigits[nextChar], nextDigit < 10 {
                        result += current
                        result += nextDigit * (digit / 10)
                        return result
                    }
                }
                result += current
                current = 0
            } else {
                current = digit
            }
            i += 1
        }
        result += current
        return result
    }
}
