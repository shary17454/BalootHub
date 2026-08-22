import SwiftUI
import SwiftData

@main
struct BalootHubApp: App {
    let modelContainer = PersistenceController.makeContainer()
    @State private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            // اللغة والاتجاه يُشتقّان تلقائيًا من لغة الجهاز (عربي أو إنجليزي)
            // بدل تثبيتهما، حتى يعمل التطبيق فعليًا بالإنجليزية عند من يختارها.
            RootTabView()
                .environment(appEnvironment)
#if DEBUG
                .task { appEnvironment.applyDebugStartRouteIfNeeded() }
#endif
        }
        .modelContainer(modelContainer)
    }
}
