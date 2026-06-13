import Foundation

/// 语音辨识解析结果
struct ParsedResult {
    /// 解析出的金额（可能为 nil）
    let amount: Double?
    /// 解析出的分类（可能为 nil）
    let category: Category?
    /// 原始辨识文字
    let rawText: String

    /// 是否至少解析出金额或分类之一
    var hasResult: Bool {
        amount != nil || category != nil
    }
}

/// 语音辨识文字解析器：从 SFSpeechRecognizer 回传的纯文字中分离分类关键字与金额。
///
/// 解析流程：
/// 1. 先匹配 Category 关键字（如「食行」「十一」等）
/// 2. 从剩余文字呼叫 AmountParser 提取金额
/// 3. 回传 ParsedResult
struct SpeechParser {

    /// 分类关键字映射表：口语 → Category
    /// 包含常见口语变体，确保高匹配率
    private static let categoryKeywords: [(keyword: String, category: Category)] = [
        ("十一", .tithe),
        ("什一", .tithe),
        ("奉獻", .tithe),
        ("奉献", .tithe),
        ("孝親", .filial),
        ("孝亲", .filial),
        ("交際", .social),
        ("交际", .social),
        ("住", .housing),
        ("住房", .housing),
        ("房租", .housing),
        ("還款", .debt),
        ("还款", .debt),
        ("還債", .debt),
        ("还债", .debt),
        ("食行", .foodTransport),
        ("飲食", .foodTransport),
        ("饮食", .foodTransport),
        ("交通", .foodTransport),
        ("彈性", .flexible),
        ("弹性", .flexible),
        ("其他", .flexible),
    ]

    /// 解析语音辨识文字
    /// - Parameter text: SFSpeechRecognizer 回传的识别文字
    /// - Returns: ParsedResult 包含解析出的金额与分类
    static func parse(_ text: String) -> ParsedResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedResult(amount: nil, category: nil, rawText: trimmed)
        }

        // 1. 优先匹配分类关键字（按长度降序排列，确保长关键字优先）
        var matchedCategory: Category? = nil
        var remainingText = trimmed

        let sortedKeywords = categoryKeywords.sorted { $0.keyword.count > $1.keyword.count }

        for (keyword, category) in sortedKeywords {
            if trimmed.contains(keyword) {
                matchedCategory = category
                // 从文字中移除已匹配的分类关键字
                remainingText = remainingText.replacingOccurrences(of: keyword, with: " ")
                break
            }
        }

        // 2. 从剩余文字提取金额
        // 优先尝试完整剩余文字，再尝试逐个词
        var parsedAmount = AmountParser.parse(remainingText)

        if parsedAmount == nil {
            // 若整体解析失败，尝试用空格分割后逐一解析
            let tokens = remainingText.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            for token in tokens {
                if let amount = AmountParser.parse(token) {
                    parsedAmount = amount
                    break
                }
            }
        }

        return ParsedResult(
            amount: parsedAmount,
            category: matchedCategory,
            rawText: trimmed
        )
    }
}
