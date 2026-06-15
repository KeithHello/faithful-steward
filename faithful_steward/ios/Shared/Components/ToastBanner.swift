import SwiftUI

enum ToastType {
    case success, error, warning

    var color: Color {
        switch self {
        case .success: return .successGreen
        case .error: return .errorRed
        case .warning: return .warningYellow
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

struct ToastBanner: View {
    let message: String
    let type: ToastType
    let duration: TimeInterval

    @State private var isShowing = true

    var body: some View {
        if isShowing {
            HStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .foregroundColor(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(type.color)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation { isShowing = false }
                }
            }
        }
    }
}

extension View {
    func toast(message: String, type: ToastType = .success, duration: TimeInterval = 2.0) -> some View {
        overlay(alignment: .top) {
            ToastBanner(message: message, type: type, duration: duration)
                .padding(.top, 50)
        }
    }
}
