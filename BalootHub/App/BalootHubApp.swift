import SwiftUI
import SwiftData

@main
struct BalootHubApp: App {
    let modelContainer = PersistenceController.makeContainer()
    @State private var appEnvironment = AppEnvironment()
    @State private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            // اللغة والاتجاه يُشتقّان تلقائيًا من لغة الجهاز (عربي أو إنجليزي)
            // بدل تثبيتهما، حتى يعمل التطبيق فعليًا بالإنجليزية عند من يختارها.
            RootTabView()
                .environment(appEnvironment)
                .environment(purchaseManager)
                .task { await purchaseManager.start() }
        }
        .modelContainer(modelContainer)
    }
}
