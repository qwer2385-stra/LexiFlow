import SwiftUI

/// LexiFlow 应用入口
@main
struct LexiFlowApp: App {

    // MARK: - App Delegate

    /// 集成 UIKit AppDelegate（处理推送通知）
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Persistence

    /// 共享的持久化控制器
    @StateObject private var persistenceController = PersistenceController.shared

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(persistenceController)
        }
    }
}
