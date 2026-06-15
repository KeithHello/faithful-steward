import SwiftUI

/// 空资料状态占位视图。
/// 当指定周期内无任何交易纪录时显示，提示使用者开始记账。
struct EmptyStateView: View {
    /// 提示讯息
    let message: String
    /// SF Symbol 图示名称
    let iconName: String
    /// 图示颜色
    let iconColor: Color

    /// 初始化
    /// - Parameters:
    ///   - message: 提示文字
    ///   - iconName: SF Symbol 名称（预设为 tray）
    ///   - iconColor: 图示颜色（预设为 secondary）
    init(
        message: String = LocalizedString.emptyStateMessage,
        iconName: String = "tray",
        iconColor: Color = .secondary
    ) {
        self.message = message
        self.iconName = iconName
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 56))
                .foregroundColor(iconColor)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView()
}
