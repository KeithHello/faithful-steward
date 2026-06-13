import SwiftUI

/// 预算总览 Tab 主视图：显示周期选择器与横向长条比例对比图。
/// 处理 UC3（检视预算比例对比）的所有流程。
struct BudgetOverviewView: View {
    @StateObject private var viewModel: BudgetOverviewViewModel
    @EnvironmentObject private var toastManager: ToastManager

    init() {
        let context = PersistenceController.shared.viewContext
        let dataProvider = DataProvider(context: context)
        _viewModel = StateObject(wrappedValue: BudgetOverviewViewModel(dataProvider: dataProvider))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 周期选择器
                PeriodPicker(
                    selectedPeriod: $viewModel.selectedPeriod,
                    onSelect: { period in
                        viewModel.switchPeriod(period)
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

                if viewModel.isEmpty {
                    // 空资料状态
                    EmptyStateView()
                } else {
                    // 长条图
                    ScrollView {
                        BudgetBarChart(
                            rows: viewModel.categoryRows,
                            totalSpent: viewModel.totalSpent,
                            budgetTotal: viewModel.budgetTotal
                        )
                        .padding()
                    }
                }

                // 错误提示
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
            }
            .navigationTitle(LocalizedString.tabOverview)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - 错误横幅

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
}

// MARK: - Preview

#Preview {
    BudgetOverviewView()
        .environmentObject(ToastManager())
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
