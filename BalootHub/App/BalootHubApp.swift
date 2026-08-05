import SwiftUI
import SwiftData

@main
struct BalootHubApp: App {
    let modelContainer = PersistenceController.makeContainer()
    @State private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appEnvironment)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar_SA"))
        }
        .modelContainer(modelContainer)
    }
}
