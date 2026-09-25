import SwiftUI
import SwiftData

@main
struct BalootHubApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer = Self.makeContainer()
    @State private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            // اللغة والاتجاه يُشتقّان تلقائيًا من لغة الجهاز (عربي أو إنجليزي)
            // بدل تثبيتهما، حتى يعمل التطبيق فعليًا بالإنجليزية عند من يختارها.
            VStack(spacing: 0) {
                if PersistenceController.isTemporary(modelContainer) {
                    Label("التخزين مؤقت: تعذر فتح بياناتك. لن تُحفظ تغييرات هذه الجلسة بعد الإغلاق.", systemImage: "exclamationmark.triangle.fill")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.warning.opacity(0.18))
                        .accessibilityIdentifier("temporaryStorageWarning")
                }
                RootTabView()
            }
                .environment(appEnvironment)
                .task { await appEnvironment.subscriptionStore.configure() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await appEnvironment.subscriptionStore.refreshEntitlements() }
                    }
                }
#if DEBUG
                .task { appEnvironment.applyDebugStartRouteIfNeeded() }
#endif
        }
        .modelContainer(modelContainer)
    }

    private static func makeContainer() -> ModelContainer {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-BalootHubTemporaryStore") {
            return PersistenceController.makePreviewContainer()
        }
#endif
        return PersistenceController.makeContainer()
    }
}
