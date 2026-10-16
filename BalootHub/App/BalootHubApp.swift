import SwiftUI
import SwiftData

@main
struct BalootHubApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer = Self.makeContainer()
    @State private var appEnvironment = AppEnvironment()
    @State private var hasEnteredApp = ProcessInfo.processInfo.arguments.contains("-BalootHubStartRoute")

    var body: some Scene {
        WindowGroup {
            // اللغة والاتجاه يُشتقّان تلقائيًا من لغة الجهاز (عربي أو إنجليزي)
            // بدل تثبيتهما، حتى يعمل التطبيق فعليًا بالإنجليزية عند من يختارها.
            Group {
                if hasEnteredApp {
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
                } else {
                    BalootWelcomeView { hasEnteredApp = true }
                }
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

/// تبقى الصورة الأصلية كما هي، وتوضع مساحة الضغط والتوهج فوق زرها المرسوم.
private struct BalootWelcomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowDegrees = 0.0

    let onStart: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 592, geometry.size.height / 1280)
            let imageTop = (geometry.size.height - 1280 * scale) / 2

            ZStack {
                Color.black

                Image("BalootWelcome")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .accessibilityHidden(true)

                Button(action: onStart) {
                    Color.clear
                        .contentShape(RoundedRectangle(cornerRadius: 23 * scale))
                        .overlay {
                            if !reduceMotion {
                                RoundedRectangle(cornerRadius: 23 * scale)
                                    .stroke(
                                        AngularGradient(
                                            stops: [
                                                .init(color: .clear, location: 0),
                                                .init(color: .clear, location: 0.65),
                                                .init(color: Color(red: 1, green: 0.98, blue: 0.78), location: 0.81),
                                                .init(color: .clear, location: 0.95),
                                                .init(color: .clear, location: 1)
                                            ],
                                            center: .center,
                                            startAngle: .degrees(glowDegrees),
                                            endAngle: .degrees(glowDegrees + 360)
                                        ),
                                        lineWidth: 3 * scale
                                    )
                                    .padding(2 * scale)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ابدأ")
                .accessibilityHint("يفتح تطبيق البلوت")
                .accessibilityIdentifier("welcomeStartButton")
                .frame(width: 512 * scale, height: 102 * scale)
                .position(x: geometry.size.width / 2, y: imageTop + 1120 * scale)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                glowDegrees = 360
            }
        }
    }
}
