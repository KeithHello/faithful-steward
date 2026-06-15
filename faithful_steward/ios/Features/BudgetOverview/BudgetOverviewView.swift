import SwiftUI

struct BudgetOverviewView: View {
    @StateObject private var viewModel = BudgetOverviewViewModel(
        dataProvider: DataProvider(context: PersistenceController.shared.viewContext)
    )

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                PeriodPicker(selectedPeriod: $viewModel.selectedPeriod) { period in
                    viewModel.switchPeriod(period)
                }
                .padding()

                if viewModel.isEmpty {
                    Spacer()
                    EmptyStateView.noTransactions()
                    Spacer()
                } else {
                    BudgetBarChart(viewModel: viewModel)
                }
            }
            .background(Color.surfaceBackground)
            .navigationTitle("總覽")
            .onAppear { viewModel.loadData() }
        }
    }
}
