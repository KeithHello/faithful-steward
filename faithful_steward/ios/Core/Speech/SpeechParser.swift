import Foundation

/// 語音辨識結果
struct ParsedResult {
    let amount: Double?
    let category: Category?
    let rawText: String

    var hasAmount: Bool { amount != nil && amount! > 0 }
    var hasCategory: Bool { category != nil }
}

/// 從語音辨識文字中提取金額與分類
final class SpeechParser {

    private static let categoryKeywords: [(String, Category)] = [
        ("十一", .tithe), ("孝親", .filial), ("交際", .social),
        ("住", .housing), ("還款", .debt), ("食行", .foodTransport),
        ("彈性", .flexible),
    ]

    static func parse(_ text: String) -> ParsedResult {
        var result = ParsedResult(amount: nil, category: nil, rawText: text)
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return result }

        var remaining = text

        // Step 1: 匹配分類關鍵字
        for (keyword, category) in categoryKeywords {
            if text.contains(keyword) {
                result = ParsedResult(amount: nil, category: category, rawText: text)
                remaining = text.replacingOccurrences(of: keyword, with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Step 2: 從剩餘文字提取金額
        if !remaining.isEmpty {
            result = ParsedResult(amount: AmountParser.parse(remaining), category: result.category, rawText: text)
        } else if result.category == nil {
            // 無分類時才嘗試從原始文字提取金額
            result = ParsedResult(amount: AmountParser.parse(text), category: nil, rawText: text)
        }

        return result
    }
}
