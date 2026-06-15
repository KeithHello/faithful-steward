import SwiftUI

struct RecordTransactionView: View {
    @StateObject private var viewModel = RecordTransactionViewModel(
        dataProvider: DataProvider(context: PersistenceController.shared.viewContext)
    )
    @State private var showConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 金額輸入
                    amountInputSection

                    // 語音按鈕
                    VoiceInputButton(viewModel: viewModel)

                    // 分類選擇
                    CategorySelector(selectedCategory: $viewModel.selectedCategory) { cat in
                        viewModel.selectCategory(cat)
                    }

                    // 錯誤提示
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding()
            }
            .background(Color.surfaceBackground)
            .navigationTitle("記帳")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    confirmButton
                }
            }
            .alert("確認記帳", isPresented: $showConfirm) {
                Button("取消", role: .cancel) {}
                Button("確認") { submit() }
            } message: {
                if let amount = viewModel.parsedAmount, let cat = viewModel.selectedCategory {
                    Text("NT$ \(Int(amount)) → \(cat.displayName)")
                }
            }
            .overlay(alignment: .top) {
                if viewModel.shouldShowToast {
                    toastBanner
                }
            }
        }
    }

    private var amountInputSection: some View {
        VStack(spacing: 4) {
            Text("金額")
                .font(.caption)
                .foregroundColor(.textSecondary)
            TextField("輸入金額", text: $viewModel.amountText)
                .keyboardType(.decimalPad)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    private var confirmButton: some View {
        Button(action: { showConfirm = true }) {
            Text("確認記帳")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canConfirm ? Color.brandPrimary : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!viewModel.canConfirm)
        .padding(.horizontal)
    }

    private func submit() {
        try? viewModel.submitTransaction()
        showConfirm = false
    }

    private var errorBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(viewModel.errorMessage ?? "")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.errorRed)
        .cornerRadius(8)
    }

    private var toastBanner: some View {
        ToastBanner(message: viewModel.toastMessage, type: .success, duration: 2.0)
            .padding(.top, 50)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    viewModel.shouldShowToast = false
                }
            }
    }
}
