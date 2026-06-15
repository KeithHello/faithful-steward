import SwiftUI

struct ConfirmDialog: ViewModifier {
    let isPresented: Bool
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: .constant(isPresented)) {
                Button(cancelLabel, role: .cancel) { onCancel?() }
                Button(confirmLabel, role: .none) { onConfirm() }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func confirmDialog(
        isPresented: Bool,
        title: String = "確認記帳",
        message: String,
        confirmLabel: String = "確認",
        cancelLabel: String = "取消",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(ConfirmDialog(
            isPresented: isPresented,
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            onConfirm: onConfirm,
            onCancel: onCancel
        ))
    }
}
