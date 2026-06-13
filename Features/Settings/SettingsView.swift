import SwiftUI

/// 设定 Tab 主视图：月预算总额输入 + 分类比例滑杆调整 + 储存。
/// 处理 UC4（设定月预算与比例）的所有流程。
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var toastManager: ToastManager

    init() {
        let context = PersistenceController.shared.viewContext
        let dataProvider = DataProvider(context: context)
        _viewModel = StateObject(wrappedValue: SettingsViewModel(dataProvider: dataProvider))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: 月预算总额
                    BudgetTotalEditor(
                        text: $viewModel.monthlyTotalText,
                        parsedAmount: viewModel.parsedMonthlyTotal,
                        onCommit: {
                            viewModel.isSaved = false
                        }
                    )

                    // MARK: 分类比例滑杆
                    RatioSliderList(
                        ratios: viewModel.ratios,
                        onChange: { category, value in
                            viewModel.updateRatio(for: category, to: value)
                        },
                        totalRatio: viewModel.ratioTotal,
                        isTotalValid: viewModel.isRatioValid
                    )

                    // MARK: 错误提示
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    // MARK: 储存按钮
                    saveButton
                }
                .padding()
            }
            .navigationTitle(LocalizedString.tabSettings)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadConfig()
        }
        .onChange(of: viewModel.isSaved) { _, newValue in
            if newValue {
                toastManager.show(message: LocalizedString.settingsSaved, type: .success)
            }
        }
    }

    // MARK: - 储存按钮

    private var saveButton: some View {
        Button {
            do {
                try viewModel.saveConfig()
            } catch {
                toastManager.show(message: error.localizedDescription, type: .error)
            }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down.fill")
                Text(LocalizedString.saveSettings)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.isValid ? Color.blue : Color.gray)
            )
        }
        .disabled(!viewModel.isValid)
        .padding(.top, 8)
    }

    // MARK: - 错误横幅

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
    SettingsView()
        .environmentObject(ToastManager())
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
