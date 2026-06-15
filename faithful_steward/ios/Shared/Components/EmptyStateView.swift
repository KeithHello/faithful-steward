import SwiftUI

struct EmptyStateView: View {
    let message: String
    let iconName: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(.textSecondary.opacity(0.5))

            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension EmptyStateView {
    static func noTransactions() -> EmptyStateView {
        EmptyStateView(message: "暫無紀錄，開始記第一筆吧！", iconName: "tray")
    }

    static func noBudgetConfig() -> EmptyStateView {
        EmptyStateView(message: "尚未設定預算，請至設定頁設定", iconName: "gearshape")
    }
}
