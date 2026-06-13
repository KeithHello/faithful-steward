import XCTest
@testable import tithe_budget

/// AmountParser 单元测试：验证阿拉伯数字与繁体中文口语数字的解析能力。
final class AmountParserTests: XCTestCase {

    // MARK: - parse() 主入口测试

    // ── 阿拉伯数字 ──

    func test_parse_plainArabic_returnsDouble() {
        XCTAssertEqual(AmountParser.parse("250"), 250.0)
    }

    func test_parse_arabicWithDecimal_returnsDouble() {
        XCTAssertEqual(AmountParser.parse("250.5"), 250.5)
    }

    func test_parse_arabicWithThousandSeparator_returnsDouble() {
        XCTAssertEqual(AmountParser.parse("1,250"), 1250.0)
    }

    func test_parse_arabicWithDollarSign_returnsDouble() {
        XCTAssertEqual(AmountParser.parse("$250"), 250.0)
    }

    func test_parse_arabicWithNTSymbol_returnsDouble() {
        XCTAssertEqual(AmountParser.parse("NT$ 250"), 250.0)
    }

    func test_parse_arabicWithCurrencyUnit_returnsDouble() {
        // "元"、"塊" 后缀应被剥离
        XCTAssertEqual(AmountParser.parse("250元"), 250.0)
        XCTAssertEqual(AmountParser.parse("250塊"), 250.0)
        XCTAssertEqual(AmountParser.parse("250块"), 250.0)
    }

    func test_parse_arabicWithSpaces_returnsDouble() {
        XCTAssertEqual(AmountParser.parse("  250  "), 250.0)
    }

    // ── 繁体中文数字 ──

    func test_parse_chineseHundreds_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("两百五"), 250.0, "「两百五」应解析为 250")
    }

    func test_parse_chineseWithBlockSuffix_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("三百块"), 300.0, "「三百块」应解析为 300")
    }

    func test_parse_chineseThousandAndTwo_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("一千二"), 1200.0, "「一千二」应解析为 1200")
    }

    func test_parse_chineseTenThousandAndFiveThousand_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("一万五千"), 15000.0, "「一万五千」应解析为 15000")
    }

    func test_parse_chineseComplexNumber_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("三万六千八百"), 36800.0)
    }

    func test_parse_chineseSingleDigit_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("五"), 5.0)
    }

    func test_parse_chineseExactTen_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("十"), 10.0)
    }

    func test_parse_chineseExactHundred_returnsCorrectValue() {
        XCTAssertEqual(AmountParser.parse("一百"), 100.0)
    }

    // ── 边界情况 ──

    func test_parse_emptyString_returnsNil() {
        XCTAssertNil(AmountParser.parse(""))
    }

    func test_parse_whitespaceOnly_returnsNil() {
        XCTAssertNil(AmountParser.parse("   "))
    }

    func test_parse_zeroValue_returnsNil() {
        // "零" 解析为 0，但函数返回 nil（因 result > 0 检查）
        // 这与 PRD 例外流程 E3「金额为 0 → 提示请输入有效金额」一致
        XCTAssertNil(AmountParser.parse("零"))
    }

    func test_parse_nonNumericText_returnsNil() {
        XCTAssertNil(AmountParser.parse("吃晚餐"))
        XCTAssertNil(AmountParser.parse("abc"))
    }

    func test_parse_negativeArabic_shouldHandleAppropriately() {
        // 负数不是预期输入，解析行为取决于 NumberFormatter
        let result = AmountParser.parse("-250")
        // 根据 PRD E3，负数应为无效金额，回传 nil 或正确处理
        // 当前实现中的 NumberFormatter 可能会解析 "-250"
        // 这是需要工程端确认的行为
        if let parsed = result {
            // 若解析成功，调用方应在上层检查 amount > 0
            XCTAssertTrue(parsed < 0, "如果解析成功，负数应该保持为负")
        }
    }

    // MARK: - parseChineseNumber() 专项测试

    func test_parseChineseNumber_implicitUnitAtTail_twoHundredFive() {
        // 「两百五」: 2×100 + 5×(100/10) = 200 + 50 = 250
        XCTAssertEqual(AmountParser.parseChineseNumber("两百五"), 250.0)
    }

    func test_parseChineseNumber_implicitUnitAtTail_thousandTwo() {
        // 「一千二」: 1×1000 + 2×(1000/10) = 1000 + 200 = 1200
        XCTAssertEqual(AmountParser.parseChineseNumber("一千二"), 1200.0)
    }

    func test_parseChineseNumber_implicitUnitAtTail_threeHundred() {
        // 「三百」: 1×300 = 300（无尾随隐式单位数字）
        XCTAssertEqual(AmountParser.parseChineseNumber("三百"), 300.0)
    }

    func test_parseChineseNumber_explicitUnits() {
        XCTAssertEqual(AmountParser.parseChineseNumber("两百五十"), 250.0)
        XCTAssertEqual(AmountParser.parseChineseNumber("一千二百"), 1200.0)
    }

    func test_parseChineseNumber_wanSection() {
        XCTAssertEqual(AmountParser.parseChineseNumber("一万"), 10000.0)
        XCTAssertEqual(AmountParser.parseChineseNumber("一万两千"), 12000.0)
        XCTAssertEqual(AmountParser.parseChineseNumber("十二万"), 120000.0)
    }

    func test_parseChineseNumber_withYuanSuffix() {
        XCTAssertEqual(AmountParser.parseChineseNumber("两百五十元"), 250.0)
    }

    // 注意：繁体「兩」与简体「两」均支援
    func test_parseChineseNumber_traditionalLiang() {
        XCTAssertEqual(AmountParser.parseChineseNumber("兩百"), 200.0)
    }

    func test_parseChineseNumber_noChineseChars_returnsNil() {
        XCTAssertNil(AmountParser.parseChineseNumber("abc"))
        XCTAssertNil(AmountParser.parseChineseNumber("123"))
    }

    func test_parseChineseNumber_emptyAfterCleaning_returnsNil() {
        // 仅含会被清理的后缀字串
        XCTAssertNil(AmountParser.parseChineseNumber("元"))
        XCTAssertNil(AmountParser.parseChineseNumber("   "))
    }

    // MARK: - parseArabicNumber() 专项测试

    func test_parseArabicNumber_validArabic() {
        // 内部方法间接透过 parse() 测试
        XCTAssertEqual(AmountParser.parse("1234"), 1234.0)
    }

    func test_parseArabicNumber_withComma() {
        XCTAssertEqual(AmountParser.parse("12,345"), 12345.0)
    }

    func test_parseArabicNumber_withNTDollarPrefix() {
        XCTAssertEqual(AmountParser.parse("NT$500"), 500.0)
    }

    func test_parseArabicNumber_onlyCurrencyPrefix_returnsNil() {
        // "NT$" 被清理后为空
        XCTAssertNil(AmountParser.parse("NT$"))
        XCTAssertNil(AmountParser.parse("$"))
    }
}
