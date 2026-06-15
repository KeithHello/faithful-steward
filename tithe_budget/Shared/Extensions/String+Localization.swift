import Foundation

extension String {
    /// 繁體中文本地化擴充
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    static let emptyStateTransactions = "暫無紀錄，開始記第一筆吧！"
    static let emptyStateBudget = "尚未設定預算，請至設定頁設定"
    static let toastSuccess = "記帳成功"
    static let toastSaved = "設定已儲存"
    static let toastError = "操作失敗，請重試"
    static let confirmTitle = "確認記帳"
    static let confirmCancel = "取消"
    static let confirmSubmit = "確認"
    static let permissionDenied = "請至設定開啟麥克風權限"
}
