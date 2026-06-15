import SwiftUI

@main
struct TitheBudgetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentTabView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}

/// 主 TabView（記帳 / 明細 / 總覽 / 設定）
/// 對應 architecture 圖中的 App Entry → TabView
struct ContentTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordTransactionView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("記帳")
                }
                .tag(0)

            TransactionListView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("明細")
                }
                .tag(1)

            BudgetOverviewView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("總覽")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(3)
        }
        .tint(Color(.brandPrimary))
    }
}
