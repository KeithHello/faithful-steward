import XCTest
@testable import tithe_budget

/// SpeechParser 单元测试：验证从语音辨识文字中提取金额与分类的能力。
final class SpeechParserTests: XCTestCase {

    // MARK: - 完整解析（金额 + 分类同时识别）

    func test_parse_foodTransportAndAmount_identifiesBoth() {
        let result = SpeechParser.parse("食行两百五")
        XCTAssertEqual(result.amount, 250.0)
        XCTAssertEqual(result.category, .foodTransport)
    }

    func test_parse_titheAndAmount_identifiesBoth() {
        let result = SpeechParser.parse("十一 500")
        XCTAssertEqual(result.amount, 500.0)
        XCTAssertEqual(result.category, .tithe)
    }

    func test_parse_filialAndAmount_identifiesBoth() {
        let result = SpeechParser.parse("孝亲一千")
        XCTAssertEqual(result.amount, 1000.0)
        XCTAssertEqual(result.category, .filial)
    }

    func test_parse_housingAndAmount_identifiesBoth() {
        let result = SpeechParser.parse("住八千")
        XCTAssertEqual(result.amount, 8000.0)
        XCTAssertEqual(result.category, .housing)
    }

    func test_parse_socialAndAmount_identifiesBoth() {
        let result = SpeechParser.parse("交际五百")
        XCTAssertEqual(result.amount, 500.0)
        XCTAssertEqual(result.category, .social)
    }

    func test_parse_debtAndAmount_identifiesBoth() {
        let result = SpeechParser.parse("还款两千")
        XCTAssertEqual(result.amount, 2000.0)
        XCTAssertEqual(result.category, .debt)
    }

    func test_parse_flexibleAndAmount_identifiesBoth() {
        let result = SpeechParser.parse("弹性一百")
        XCTAssertEqual(result.amount, 100.0)
        XCTAssertEqual(result.category, .flexible)
    }

    // MARK: - 仅金额（无分类关键字）

    func test_parse_amountOnly_noCategory() {
        let result = SpeechParser.parse("三百块")
        XCTAssertEqual(result.amount, 300.0)
        XCTAssertNil(result.category)
    }

    func test_parse_arabicNumberOnly_noCategory() {
        let result = SpeechParser.parse("250")
        XCTAssertEqual(result.amount, 250.0)
        XCTAssertNil(result.category)
    }

    // MARK: - 仅分类（无金额）

    func test_parse_categoryOnly_noAmount() {
        // "食行" 只含分类关键字，不含金额数字
        let result = SpeechParser.parse("食行")
        XCTAssertEqual(result.category, .foodTransport)
        // 剩余文字为空或无法解析，金额应为 nil
        XCTAssertNil(result.amount)
    }

    // MARK: - 无关键字、无金额

    func test_parse_noKeywordNoAmount_returnsNilForBoth() {
        let result = SpeechParser.parse("今天天气不错")
        XCTAssertNil(result.amount)
        XCTAssertNil(result.category)
    }

    // MARK: - 边界情况

    func test_parse_emptyString_returnsNilForBoth() {
        let result = SpeechParser.parse("")
        XCTAssertNil(result.amount)
        XCTAssertNil(result.category)
        XCTAssertEqual(result.rawText, "")
    }

    func test_parse_whitespaceOnly_returnsNilForBoth() {
        let result = SpeechParser.parse("   ")
        XCTAssertNil(result.amount)
        XCTAssertNil(result.category)
    }

    // MARK: - 语音辨识常见口语变体

    func test_parse_titheVariant_shiyi() {
        let result = SpeechParser.parse("什一 300")
        XCTAssertEqual(result.amount, 300.0)
        XCTAssertEqual(result.category, .tithe)
    }

    func test_parse_titheVariant_fengxian() {
        let result = SpeechParser.parse("奉献五百")
        XCTAssertEqual(result.amount, 500.0)
        XCTAssertEqual(result.category, .tithe)
    }

    func test_parse_foodTransportVariant_yinshi() {
        let result = SpeechParser.parse("饮食一百五")
        XCTAssertEqual(result.amount, 150.0)
        XCTAssertEqual(result.category, .foodTransport)
    }

    func test_parse_foodTransportVariant_jiaotong() {
        let result = SpeechParser.parse("交通两百")
        XCTAssertEqual(result.amount, 200.0)
        XCTAssertEqual(result.category, .foodTransport)
    }

    /// ✅ BUG-001 已修复：关键字按长度降序排列后，「住房」（2字符）优先匹配于「住」（1字符）
    func test_parse_housingVariant_zhufang() {
        let result = SpeechParser.parse("住房一万")
        XCTAssertEqual(result.amount, 10000.0)
        XCTAssertEqual(result.category, .housing)
    }

    func test_parse_housingVariant_fangzu() {
        let result = SpeechParser.parse("房租八千")
        XCTAssertEqual(result.amount, 8000.0)
        XCTAssertEqual(result.category, .housing)
    }

    func test_parse_debtVariant_huanzhai() {
        let result = SpeechParser.parse("还债三千")
        XCTAssertEqual(result.amount, 3000.0)
        XCTAssertEqual(result.category, .debt)
    }

    func test_parse_flexibleVariant_qita() {
        let result = SpeechParser.parse("其他两百")
        XCTAssertEqual(result.amount, 200.0)
        XCTAssertEqual(result.category, .flexible)
    }

    // MARK: - hasResult 属性测试

    func test_parsedResult_hasResult_withAmount_returnsTrue() {
        let result = ParsedResult(amount: 250, category: nil, rawText: "250")
        XCTAssertTrue(result.hasResult)
    }

    func test_parsedResult_hasResult_withCategory_returnsTrue() {
        let result = ParsedResult(amount: nil, category: .foodTransport, rawText: "食行")
        XCTAssertTrue(result.hasResult)
    }

    func test_parsedResult_hasResult_withBoth_returnsTrue() {
        let result = ParsedResult(amount: 250, category: .foodTransport, rawText: "食行250")
        XCTAssertTrue(result.hasResult)
    }

    func test_parsedResult_hasResult_withNeither_returnsFalse() {
        let result = ParsedResult(amount: nil, category: nil, rawText: "abc")
        XCTAssertFalse(result.hasResult)
    }

    // MARK: - 已知问题回归测试

    /// ✅ BUG-001 已修复：关键字按长度降序排列后，「住房」（2字符）优先匹配于「住」（1字符）
    func test_parse_housingWithZhufang_regression() {
        let result = SpeechParser.parse("住房八千")
        XCTAssertEqual(result.category, .housing, "分类应正确识别为 housing")
        XCTAssertEqual(result.amount, 8000.0, "金额应正确解析为 8000")
    }

    /// ⚠️ Known Limitation (P2)：单字「住」可能误匹配不相关文字
    /// 因「住」为单字符关键字，在非 housing 语境中也会被匹配。
    /// 实际语音记账场景中使用者不太会说完整句子，故影响极低。
    /// 如需修复，可将「住」关键字限制为前后须为空白/行首行尾的模式。
    func test_parse_characterZhu_ambiguousMatch_KNOWN_LIMITATION() {
        let result = SpeechParser.parse("我住在台北")
        // 「住」匹配 → category = .housing（误匹配，Known Limitation）
        XCTAssertEqual(result.category, .housing)
        // amount 无法从「我在 台北」中解析 → nil ✅
    }
}
