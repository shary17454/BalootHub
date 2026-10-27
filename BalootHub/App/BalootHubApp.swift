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
            let fold = activeFold(in: geometry)
            let usesAdaptivePresentation = geometry.size.width > geometry.size.height || fold != nil
            let foregroundFrame = WelcomeLayout.foregroundFrame(in: geometry.size, avoiding: fold)

            ZStack {
                Color.black

                if usesAdaptivePresentation {
                    Image("BalootWelcome")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .overlay(.black.opacity(0.55))
                        .accessibilityHidden(true)

                    VStack(spacing: 16) {
                        Spacer(minLength: 12)
                        Text("البلوت")
                            .font(.system(size: 52, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                        Text("صن ولا حكم؟")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color(red: 1, green: 0.83, blue: 0.49))
                        Spacer(minLength: 12)
                        Button(action: onStart) {
                            Text("ابدأ")
                                .font(.title2.bold())
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(Color(red: 0.96, green: 0.76, blue: 0.38), in: RoundedRectangle(cornerRadius: 18))
                                .overlay {
                                    if reduceMotion {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(.white.opacity(0.5), lineWidth: 2)
                                    } else {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(glowGradient, lineWidth: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("ابدأ")
                        .accessibilityHint("يفتح تطبيق البلوت")
                        .accessibilityIdentifier("welcomeStartButton")
                    }
                    .padding(24)
                    .frame(width: foregroundFrame.width, height: foregroundFrame.height)
                    .position(x: foregroundFrame.midX, y: foregroundFrame.midY)
                } else {
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
                                            glowGradient,
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
                    .frame(width: 512 * scale, height: max(44, 102 * scale))
                    .position(x: geometry.size.width / 2, y: imageTop + 1120 * scale)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                glowDegrees = 360
            }
        }
    }

    private func activeFold(in geometry: GeometryProxy) -> CGRect? {
        if #available(iOS 27.1, *) {
            return geometry.reservedRegions(kind: .division).first(where: \.isActive)?.frame
        }
        return nil
    }

    private var glowGradient: AngularGradient {
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
        )
    }
}

enum WelcomeLayout {
    /// يبقي زر البداية والنص في جهة واحدة من المفصل عند طي الشاشة الداخلية.
    static func foregroundFrame(in size: CGSize, avoiding fold: CGRect?) -> CGRect {
        let full = CGRect(origin: .zero, size: size)
        guard let fold, fold.intersects(full) else { return full }
        if fold.height > fold.width {
            let left = CGRect(x: 0, y: 0, width: max(0, fold.minX), height: size.height)
            let right = CGRect(x: min(size.width, fold.maxX), y: 0,
                               width: max(0, size.width - fold.maxX), height: size.height)
            return right.width >= 280 ? right : (left.width >= 280 ? left : full)
        }
        let top = CGRect(x: 0, y: 0, width: size.width, height: max(0, fold.minY))
        let bottom = CGRect(x: 0, y: min(size.height, fold.maxY),
                            width: size.width, height: max(0, size.height - fold.maxY))
        return bottom.height >= 220 ? bottom : (top.height >= 220 ? top : full)
    }
}
