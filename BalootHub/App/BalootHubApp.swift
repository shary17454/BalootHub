import SwiftUI
import SwiftData

@main
struct BalootHubApp: App {
    private let persistence = PersistenceController.makeBootstrap()
    @State private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            // اللغة والاتجاه يُشتقّان تلقائيًا من لغة الجهاز (عربي أو إنجليزي)
            // بدل تثبيتهما، حتى يعمل التطبيق فعليًا بالإنجليزية عند من يختارها.
            RootTabView()
                .environment(appEnvironment)
                .task {
                    appEnvironment.persistenceWarning = persistence.warningMessage
                    await appEnvironment.subscriptionStore.configure()
                }
#if DEBUG
                .task { appEnvironment.applyDebugStartRouteIfNeeded() }
#endif
        }
        .modelContainer(persistence.container)
    }
}
