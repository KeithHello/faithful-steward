import SwiftUI

/// 忠心好管家 App 进入点。
/// 使用 TabView 组织三个主要功能页面：记账 / 总览 / 设定。
@main
struct tithe_budgetApp: App {
    private let persistenceController = PersistenceController.shared
    @StateObject private var toastManager = ToastManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(toastManager)
                .toastOverlay(toastManager: toastManager)
        }
    }
}

// MARK: - ContentView（TabView）

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1: 记账
            RecordTransactionView()
                .tabItem {
                    Label(LocalizedString.tabRecord, systemImage: "plus.circle.fill")
                }

            // Tab 2: 总览
            BudgetOverviewView()
                .tabItem {
                    Label(LocalizedString.tabOverview, systemImage: "chart.bar.fill")
                }

            // Tab 3: 设定
            SettingsView()
                .tabItem {
                    Label(LocalizedString.tabSettings, systemImage: "gearshape.fill")
                }
        }
    }
}
