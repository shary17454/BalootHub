import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \GameCatalogItem.sortOrder) private var allItems: [GameCatalogItem]
    @Query(filter: #Predicate<ScoreSession> { $0.statusRaw == "active" }, sort: \ScoreSession.updatedAt, order: .reverse)
    private var activeSessions: [ScoreSession]

    @State private var searchText = ""
    @State private var refreshCoordinator = HomeRefreshCoordinator()
    @AppStorage(HomeRefreshCoordinator.lastRefreshDefaultsKey) private var lastRefreshTimestamp = 0.0

    private var lastActiveSession: ScoreSession? { activeSessions.first }
    private var lastRefreshDate: Date? {
        lastRefreshTimestamp > 0 ? Date(timeIntervalSince1970: lastRefreshTimestamp) : nil
    }

    private var searchResults: [GameCatalogItem] {
        CatalogSearch.apply(filter: .all, query: searchText, to: allItems)
    }

    private var homeSections: [CatalogPresentationSection] {
        CatalogPresentation.homeSections(from: allItems)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                refreshStatusCard

                QuickSearchField(text: $searchText)

                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResultsSection
                } else {
                    if let lastActiveSession {
                        continueSessionCard(lastActiveSession)
                    }

                    if allItems.isEmpty {
                        LoadingStateView(message: "جارِ تجهيز الكتالوج…")
                    } else {
                        workflowSection
                        appMapSection

                        ForEach(homeSections) { section in
                            catalogSection(section)
                        }

                        let favorites = allItems.filter(\.isFavorite)
                        if !favorites.isEmpty {
                            catalogSection(
                                CatalogPresentationSection(
                                    id: "favorites",
                                    title: "المفضلة".localized,
                                    detail: "العناصر التي اخترتها للوصول السريع.".localized,
                                    items: favorites
                                )
                            )
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
        .background(AppColor.background)
        .navigationTitle("البلوت")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    startRefresh()
                } label: {
                    Label("تحديث", systemImage: "arrow.clockwise")
                }
                .disabled(refreshCoordinator.isRefreshing)
                .accessibilityHint("يحدّث الكتالوج والخدمات المحلية ويعرض آخر وقت تحديث")
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            Image("BalootMajlisHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.08), .black.opacity(0.64)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("أهلًا بك في البلوت")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(.white)
                Text("لعبة البلوت بصنها وحكمها وأدواتها في مكان واحد")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(AppSpacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .appGlassCard(cornerRadius: AppRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("صورة مجلس بلوت مع أوراق لعب وقهوة عربية")
    }

    @ViewBuilder
    private var refreshStatusCard: some View {
        if refreshCoordinator.shouldShowStatus || lastRefreshDate != nil {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    Image(systemName: refreshCoordinator.statusIconName)
                        .foregroundStyle(refreshCoordinator.statusTint)
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(refreshCoordinator.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(refreshCoordinator.detail(lastRefreshDate: lastRefreshDate))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if refreshCoordinator.isRefreshing {
                        Text(refreshCoordinator.progressPercentage)
                            .font(AppTypography.caption)
                            .monospacedDigit()
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                if refreshCoordinator.isRefreshing {
                    ProgressView(value: refreshCoordinator.progress)
                        .tint(AppColor.accent)
                        .accessibilityLabel("تقدم التحديث")
                        .accessibilityValue(refreshCoordinator.progressPercentage)

                    if refreshCoordinator.isTakingLong {
                        Label("التحديث يستغرق وقتًا أطول من المعتاد…", systemImage: "hourglass")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.warning)
                    }
                } else if refreshCoordinator.canRetry {
                    Button {
                        startRefresh()
                    } label: {
                        Label("إعادة المحاولة", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(AppSpacing.md)
            .appGlassCard(cornerRadius: AppRadius.medium, tint: refreshCoordinator.statusTint)
            .accessibilityElement(children: .combine)
        }
    }

    private func continueSessionCard(_ session: ScoreSession) -> some View {
        Button {
            appEnvironment.openScorekeeperSession(id: session.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("متابعة آخر جلسة")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textOnPrimary.opacity(0.85))
                    Text("\(session.teamOneName) ضد \(session.teamTwoName)")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textOnPrimary)
                }
                Spacer()
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColor.textOnPrimary)
            }
            .padding(AppSpacing.md)
            .appInteractiveGlassCard(cornerRadius: AppRadius.large, tint: AppColor.primary)
        }
        .accessibilityLabel("متابعة آخر جلسة، \(session.teamOneName) ضد \(session.teamTwoName)")
    }

    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("اختر مسارك")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                Text("أربع بوابات تفصل اللعب، التسجيل، التدريب، ومكتبة القواعد.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            if horizontalSizeClass == .regular {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 230), spacing: AppSpacing.md)],
                    spacing: AppSpacing.md
                ) {
                    ForEach(CatalogPresentation.workflowActions) { action in
                        workflowActionButton(action)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(CatalogPresentation.workflowActions) { action in
                            workflowActionButton(action)
                                .frame(width: 230)
                        }
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }
            }
        }
    }

    private func workflowActionButton(_ action: CatalogWorkflowAction) -> some View {
        Button {
            if let route = action.route {
                appEnvironment.navigate(to: route, tab: action.tab)
            } else {
                appEnvironment.selectedTab = action.tab
            }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: action.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 34, height: 34)
                    .background(AppColor.accent.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(action.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(action.detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .appInteractiveGlassCard(cornerRadius: AppRadius.medium, tint: AppColor.accent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .accessibilityHint(action.detail)
    }

    private var appMapSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("كيف تستخدم التطبيق؟")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                Text("كل بطاقة في التطبيق توضح هل هي طاولة لعب، تدريب، أو مرجع قواعد.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 230), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                ForEach(CatalogPresentation.usageGuideItems) { item in
                    usageGuideCard(item)
                }
            }
        }
    }

    private func usageGuideCard(_ item: CatalogUsageGuideItem) -> some View {
        let tint = guideTint(for: item.tintToken)
        return HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: item.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.14), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Text(item.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .appGlassCard(cornerRadius: AppRadius.medium, tint: tint)
        .accessibilityElement(children: .combine)
    }

    private func guideTint(for token: String) -> Color {
        switch token {
        case "success": AppColor.success
        case "accent": AppColor.accent
        case "primary": AppColor.primary
        default: AppColor.textSecondary
        }
    }

    private func catalogSection(_ section: CatalogPresentationSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(section.title)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                Text(section.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            if section.items.isEmpty {
                Text("لا توجد عناصر بعد في هذا القسم.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            } else if horizontalSizeClass == .regular {
                // على الشاشات العريضة يملأ العرضُ شبكةً تلتف تلقائيًا. الشريط الأفقي
                // ببطاقات ثابتة العرض كان يترك فراغًا كبيرًا في قسم فيه بطاقة واحدة،
                // لأن 220 نقطة تملأ شاشة الآيفون ولا تملأ ربع شاشة iPad.
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220), spacing: AppSpacing.md)],
                    spacing: AppSpacing.md
                ) {
                    ForEach(section.items) { item in
                        catalogCard(item)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(section.items) { item in
                            catalogCard(item)
                                .frame(width: 220)
                        }
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }
            }
        }
    }

    private func catalogCard(_ item: GameCatalogItem) -> some View {
        Button {
            appEnvironment.openGameDetails(slug: item.slug, from: .home)
        } label: {
            GameCardView(item: item, onToggleFavorite: { toggleFavorite(item) })
        }
        .buttonStyle(.plain)
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("نتائج البحث")
                .font(AppTypography.title)
            if searchResults.isEmpty {
                EmptyStateView(systemImage: "magnifyingglass", title: "لا نتائج", message: "جرّب كلمة بحث أخرى مثل اسم اللعبة أو نوعها.")
            } else {
                ForEach(searchResults) { item in
                    Button {
                        appEnvironment.openGameDetails(slug: item.slug, from: .home)
                    } label: {
                        GameCardView(item: item, onToggleFavorite: { toggleFavorite(item) })
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggleFavorite(_ item: GameCatalogItem) {
        item.isFavorite.toggle()
        try? modelContext.save()
    }

    private func startRefresh() {
        Task {
            await refreshCoordinator.refresh(
                modelContext: modelContext,
                subscriptionStore: appEnvironment.subscriptionStore
            )
            lastRefreshTimestamp = refreshCoordinator.lastRefreshTimestamp
        }
    }
}

enum HomeRefreshStage: CaseIterable, Equatable, Sendable {
    case metadata
    case locations
    case times
    case services
    case localPreparation

    var title: String {
        switch self {
        case .metadata: "جلب الميتاداتا".localized
        case .locations: "جلب المواقع".localized
        case .times: "جلب الأوقات".localized
        case .services: "جلب الخدمات".localized
        case .localPreparation: "إعداد البيانات محليًا".localized
        }
    }

    var progress: Double {
        switch self {
        case .metadata: 0.18
        case .locations: 0.38
        case .times: 0.58
        case .services: 0.78
        case .localPreparation: 0.94
        }
    }
}

@MainActor
@Observable
final class HomeRefreshCoordinator {
    static let lastRefreshDefaultsKey = "BalootHubLastInternalRefreshTimestamp"

    private(set) var isRefreshing = false
    private(set) var progress = 0.0
    private(set) var currentStage: HomeRefreshStage?
    private(set) var statusMessage: String?
    private(set) var didFinishSuccessfully = false
    private(set) var isTakingLong = false
    private(set) var lastRefreshTimestamp = UserDefaults.standard.double(forKey: lastRefreshDefaultsKey)

    var shouldShowStatus: Bool {
        isRefreshing || statusMessage != nil
    }

    var canRetry: Bool {
        !isRefreshing && didFinishSuccessfully == false && statusMessage != nil
    }

    var title: String {
        if isRefreshing {
            return currentStage?.title ?? "جارِ التحديث".localized
        }
        if didFinishSuccessfully {
            return "تم التحديث".localized
        }
        if statusMessage != nil {
            return "تعذر التحديث".localized
        }
        return "جاهز للتحديث".localized
    }

    var progressPercentage: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var statusIconName: String {
        if isRefreshing { return "arrow.triangle.2.circlepath" }
        if didFinishSuccessfully { return "checkmark.circle.fill" }
        if statusMessage != nil { return "exclamationmark.triangle.fill" }
        return "clock.arrow.circlepath"
    }

    var statusTint: Color {
        if isRefreshing { return AppColor.accent }
        if didFinishSuccessfully { return AppColor.success }
        if statusMessage != nil { return AppColor.warning }
        return AppColor.textSecondary
    }

    func detail(lastRefreshDate: Date?) -> String {
        if let statusMessage, didFinishSuccessfully, let lastRefreshDate {
            return "\(statusMessage) آخر تحديث: \(lastRefreshDate.formatted(date: .abbreviated, time: .shortened))"
        }
        if let statusMessage {
            return statusMessage
        }
        if isRefreshing, let currentStage {
            return "المرحلة الحالية: \(currentStage.title)".localized
        }
        if let lastRefreshDate {
            return "آخر تحديث: \(lastRefreshDate.formatted(date: .abbreviated, time: .shortened))".localized
        }
        return "يضبط الكتالوج والخدمات المحلية ويحدّث حالة الاشتراكات.".localized
    }

    func refresh(
        modelContext: ModelContext,
        subscriptionStore: SubscriptionStore,
        stageDelayNanoseconds: UInt64 = 140_000_000
    ) async {
        guard !isRefreshing else { return }

        isRefreshing = true
        isTakingLong = false
        didFinishSuccessfully = false
        statusMessage = nil
        progress = 0.04

        let longRunningTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self?.isRefreshing == true {
                    self?.isTakingLong = true
                }
            }
        }

        do {
            for stage in HomeRefreshStage.allCases {
                currentStage = stage
                withAnimation(.easeInOut(duration: 0.22)) {
                    progress = stage.progress
                }
                try await run(stage, modelContext: modelContext, subscriptionStore: subscriptionStore)
                if stageDelayNanoseconds > 0 {
                    try await Task.sleep(nanoseconds: stageDelayNanoseconds)
                }
            }

            let timestamp = Date().timeIntervalSince1970
            UserDefaults.standard.set(timestamp, forKey: Self.lastRefreshDefaultsKey)
            lastRefreshTimestamp = timestamp
            withAnimation(.easeInOut(duration: 0.18)) {
                progress = 1
            }
            didFinishSuccessfully = true
            statusMessage = "اكتمل تحديث الكتالوج والخدمات المحلية.".localized
            AppLogger.refresh.info("اكتمل التحديث الداخلي بنجاح")
        } catch {
            modelContext.rollback()
            didFinishSuccessfully = false
            statusMessage = "لم يكتمل التحديث. تحقق من اتصال App Store أو جرّب لاحقًا.".localized
            AppLogger.refresh.error("فشل التحديث الداخلي: \(error.localizedDescription, privacy: .public)")
        }

        longRunningTask.cancel()
        currentStage = nil
        isTakingLong = false
        isRefreshing = false
    }

    private func run(
        _ stage: HomeRefreshStage,
        modelContext: ModelContext,
        subscriptionStore: SubscriptionStore
    ) async throws {
        switch stage {
        case .metadata:
            SettingsRepository.ensureSettingsExist(context: modelContext)
        case .locations:
            try CatalogSeeder.refresh(context: modelContext, saveImmediately: false)
        case .times:
            _ = Calendar.current.startOfDay(for: Date())
        case .services:
            await subscriptionStore.refreshEntitlements()
        case .localPreparation:
            try modelContext.save()
        }
    }
}

private struct QuickSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColor.textSecondary)
            TextField("ابحث عن لعبة أو أداة…", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.textSecondary)
                }
                .accessibilityLabel("مسح البحث")
            }
        }
        .padding(AppSpacing.sm)
        .appGlassCard(cornerRadius: AppRadius.medium)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
