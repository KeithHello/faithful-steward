import Foundation

/// 繁体中文 UI 字串常数。
/// 所有使用者可见文字均集中于此，便于维护与潜在的多语系扩展。
enum LocalizedString {
    // MARK: - Tab 标签
    static let tabRecord = "記帳"
    static let tabOverview = "總覽"
    static let tabSettings = "設定"

    // MARK: - 记帳頁面
    static let amountPlaceholder = "輸入金額"
    static let selectCategory = "選擇分類"
    static let confirmRecord = "確認記帳"
    static let recordingHint = "按住說話，放開完成"
    static let recording = "錄音中…"
    static let amountParsingFailed = "請輸入金額數字"
    static let categoryNotSelected = "請選擇分類"
    static let amountMustBePositive = "請輸入有效金額"
    static let recordSuccess = "記帳成功"
    static let confirmTitle = "確認記帳"
    static let confirmMessage = "NT$ %@ → %@"
    static let confirm = "確認"
    static let cancel = "取消"
    static let voiceResultHint = "語音辨識結果：%@"

    // MARK: - 语音辨识
    static let speechNoResult = "請再說一次"
    static let speechNoAmount = "未偵測到金額，請手動輸入"
    static let speechPermissionDenied = "請至設定開啟麥克風權限"
    static let speechNotAvailable = "語音辨識目前無法使用"

    // MARK: - 预算总览
    static let periodLabel = "週期"
    static let totalSpent = "總花費"
    static let budgetTotal = "預算總額"
    static let emptyStateMessage = "暫無紀錄，開始記第一筆吧！"
    static let overBudgetWarning = "⚠"

    // MARK: - 设定
    static let monthlyBudgetLabel = "月預算總額"
    static let ratioAdjustmentLabel = "分類比例調整"
    static let ratioTotalLabel = "合計"
    static let ratioTotalInvalid = "比例總和須為 100%"
    static let ratioTotalValid = "比例總和 = 100%"
    static let saveSettings = "儲存"
    static let settingsSaved = "設定已儲存"
    static let invalidBudgetAmount = "請輸入有效的月預算金額"
    static let defaultMonthlyBudget = "30000"

    // MARK: - 金额格式化
    static let currencyPrefix = "NT$ "

    // MARK: - 通用
    static let appTitle = "忠心好管家"
    static let loading = "載入中…"
}
