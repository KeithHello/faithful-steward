import SwiftUI

// MARK: - Toast 类型

/// Toast 横幅类型
enum ToastType {
    case success
    case error
    case warning

    var backgroundColor: Color {
        switch self {
        case .success: return Color.toastSuccess
        case .error: return Color.toastError
        case .warning: return Color.toastWarning
        }
    }

    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Toast 管理器（ObservableObject）

/// 全局 Toast 状态管理器，注入于 App 环境中供所有 View 使用。
class ToastManager: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var message: String = ""
    @Published var type: ToastType = .success

    private var dismissTask: DispatchWorkItem?

    /// 显示 Toast
    /// - Parameters:
    ///   - message: 提示文字
    ///   - type: Toast 类型
    ///   - duration: 显示秒数（预设 2 秒）
    func show(message: String, type: ToastType, duration: TimeInterval = 2.0) {
        dismissTask?.cancel()

        self.message = message
        self.type = type

        withAnimation(.easeInOut(duration: 0.3)) {
            self.isShowing = true
        }

        let task = DispatchWorkItem { [weak self] in
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.isShowing = false
            }
        }
        dismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }

    /// 隐藏 Toast
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = false
        }
    }
}

// MARK: - Toast 横幅 View

/// 顶部横幅视图：显示操作结果（成功/失败/警告），2 秒后自动消失。
struct ToastBannerView: View {
    @ObservedObject var toastManager: ToastManager

    var body: some View {
        VStack {
            if toastManager.isShowing {
                HStack(spacing: 10) {
                    Image(systemName: toastManager.type.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))

                    Text(toastManager.message)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Button {
                        toastManager.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(toastManager.type.backgroundColor)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: toastManager.isShowing)
    }
}

// MARK: - View Extension：便捷 Toast 调用

extension View {
    /// 为 View 加上 Toast 横幅覆盖层
    /// - Parameter toastManager: ToastManager 实例
    func toastOverlay(toastManager: ToastManager) -> some View {
        self.overlay(alignment: .top) {
            ToastBannerView(toastManager: toastManager)
        }
    }
}
