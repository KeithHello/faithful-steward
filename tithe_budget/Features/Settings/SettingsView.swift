import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel(
        dataProvider: DataProvider(context: PersistenceController.shared.viewContext)
    )

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Unsaved changes badge
                    if viewModel.hasUnsavedChanges {
                        HStack {
                            Circle()
                                .fill(Color.warningYellow)
                                .frame(width: 8, height: 8)
                            Text("有未儲存的更改")
                                .font(.caption)
                                .foregroundColor(.warningYellow)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    BudgetTotalEditor(viewModel: viewModel)

                    RatioSliderList(viewModel: viewModel)

                    // Error message
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.errorRed)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.errorRed)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Save button
                    Button(action: { try? viewModel.saveConfig() }) {
                        Text("儲存設定")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                viewModel.hasUnsavedChanges && viewModel.isValid
                                    ? Color.brandPrimary : Color.gray.opacity(0.5)
                            )
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.hasUnsavedChanges || !viewModel.isValid)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.surfaceBackground)
            .navigationTitle("設定")
            .onAppear { viewModel.loadConfig() }
            .overlay(alignment: .top) {
                if viewModel.shouldShowToast {
                    ToastBanner(message: viewModel.toastMessage, type: .success, duration: 2.0)
                        .padding(.top, 50)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                viewModel.shouldShowToast = false
                            }
                        }
                }
            }
        }
    }
}
