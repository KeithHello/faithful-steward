import SwiftUI

/// 记账 Tab 主视图：组装文字输入栏、语音按钮、分类选择器与确认按钮。
/// 处理 UC1（文字记账）与 UC2（语音记账）的所有流程。
struct RecordTransactionView: View {
    @StateObject private var viewModel: RecordTransactionViewModel
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.managedObjectContext) private var viewContext

    init() {
        let context = PersistenceController.shared.viewContext
        let dataProvider = DataProvider(context: context)
        _viewModel = StateObject(wrappedValue: RecordTransactionViewModel(dataProvider: dataProvider))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: 金额输入区域
                    amountInputSection

                    // MARK: 语音按钮
                    VoiceInputButton(
                        isRecording: viewModel.isRecording,
                        onStartRecording: { viewModel.startRecording() },
                        onStopRecording: { viewModel.stopRecording() }
                    )

                    // MARK: 语音辨识结果
                    if !viewModel.voiceResultText.isEmpty {
                        voiceResultBanner
                    }

                    // MARK: 分类选择器
                    CategorySelector(
                        selectedCategory: $viewModel.selectedCategory,
                        onSelect: { _ in viewModel.errorMessage = nil }
                    )

                    // MARK: 确认按钮
                    confirmButton

                    // MARK: 错误提示
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedString.tabRecord)
            .navigationBarTitleDisplayMode(.large)
            // 确认弹窗
            .alert(LocalizedString.confirmTitle, isPresented: $viewModel.showConfirmation) {
                Button(LocalizedString.cancel, role: .cancel) {
                    // 保留输入状态，不做额外操作
                }
                Button(LocalizedString.confirm) {
                    viewModel.submitTransaction()
                }
            } message: {
                Text(String(format: LocalizedString.confirmMessage,
                      (viewModel.parsedAmount ?? 0).formattedAsCurrency,
                      viewModel.selectedCategory?.displayName ?? ""))
            }
            // 记账成功 Toast
            .onChange(of: viewModel.showSuccess) { _, newValue in
                if newValue {
                    toastManager.show(message: LocalizedString.recordSuccess, type: .success)
                    viewModel.showSuccess = false
                }
            }
        }
    }

    // MARK: - 金额输入区域

    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedString.currencyPrefix)
                    .font(.title2)
                    .foregroundColor(.secondary)

                TextField(LocalizedString.amountPlaceholder, text: $viewModel.amountText)
                    .font(.title2)
                    .keyboardType(.decimalPad)
                    .onSubmit {
                        viewModel.onTextSubmit()
                    }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )

            // 即时解析金额预览
            if let amount = viewModel.parsedAmount {
                Text(amount.formattedAsCurrency)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - 语音辨识结果横幅

    private var voiceResultBanner: some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundColor(.blue)
            Text(String(format: LocalizedString.voiceResultHint, viewModel.voiceResultText))
                .font(.subheadline)
                .foregroundColor(.blue)
            Spacer()
            Button {
                viewModel.voiceResultText = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.08))
        )
    }

    // MARK: - 确认按钮

    private var confirmButton: some View {
        Button {
            viewModel.requestConfirmation()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(LocalizedString.confirmRecord)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.canConfirm ? Color.blue : Color.gray)
            )
        }
        .disabled(!viewModel.canConfirm)
        .padding(.top, 8)
    }

    // MARK: - 错误提示

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    RecordTransactionView()
        .environmentObject(ToastManager())
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
