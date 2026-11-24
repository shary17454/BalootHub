import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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

    private var favorites: [GameCatalogItem] { allItems.filter(\.isFavorite) }
    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if !isSearching {
                    header
                    workflowSection

                    if let lastActiveSession {
                        continueSessionCard(lastActiveSession)
                    }
                }

                QuickSearchField(text: $searchText)

                if isSearching {
                    searchResultsSection
                } else if allItems.isEmpty {
                    LoadingStateView(message: "جارِ تجهيز المكتبة…")
                } else if !favorites.isEmpty {
                    favoritesSection
                }

                refreshStatusCard
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
                .accessibilityHidden(true)
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.08), .black.opacity(0.64)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("مجلس البلوت")
                    .font(AppTypography.title)
                    .foregroundStyle(.white)
            }
            .padding(AppSpacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .appGlassCard(cornerRadius: AppRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
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
                        .environment(\.layoutDirection, .leftToRight)
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
            appEnvironment.openTabRoot(.scorekeeper)
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
            if let primary = CatalogPresentation.workflowActions.first {
                workflowActionButton(primary, isPrimary: true)
            }

            LazyVGrid(
                columns: AppLayout.columns(2, for: dynamicTypeSize, spacing: AppSpacing.sm),
                alignment: .leading,
                spacing: AppSpacing.sm
            ) {
                ForEach(CatalogPresentation.workflowActions.dropFirst()) { action in
                    workflowActionButton(action)
                }
            }
        }
    }

    private func workflowActionButton(_ action: CatalogWorkflowAction, isPrimary: Bool = false) -> some View {
        Button {
            if let route = action.route {
                appEnvironment.navigate(to: route, tab: action.tab)
            } else {
                appEnvironment.openTabRoot(action.tab)
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(action.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(isPrimary ? AppColor.textOnPrimary : AppColor.textPrimary)
                    Text(action.detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(isPrimary ? AppColor.textOnPrimary.opacity(0.85) : AppColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: action.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isPrimary ? AppColor.textOnPrimary : AppColor.accent)
                    .accessibilityHidden(true)
            }
            .labelStyle(.titleAndIcon)
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(
                isPrimary ? AppColor.primary : Color.clear,
                in: RoundedRectangle(cornerRadius: AppRadius.medium)
            )
            .appInteractiveGlassCard(cornerRadius: AppRadius.medium, tint: isPrimary ? nil : AppColor.accent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .accessibilityHint(action.detail)
        .accessibilityIdentifier("homeAction.\(action.id)")
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("المفضلة")
                .font(AppTypography.title)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: AppLayout.columns(2, for: dynamicTypeSize, spacing: AppSpacing.sm),
                spacing: AppSpacing.sm
            ) {
                ForEach(favorites) { item in
                    catalogCard(item)
                }
            }
        }
    }

    private func catalogCard(_ item: GameCatalogItem) -> some View {
        GameCardView(
            item: item,
            onOpenDetails: { appEnvironment.openGameDetails(slug: item.slug, from: .home) },
            onStartPlaying: item.isPlayable ? { startPlaying(item) } : nil,
            onToggleFavorite: { toggleFavorite(item) }
        )
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("نتائج البحث")
                .font(AppTypography.title)
            if searchResults.isEmpty {
                EmptyStateView(systemImage: "magnifyingglass", title: "لا نتائج", message: "جرّب كلمة بحث أخرى مثل اسم اللعبة أو نوعها.")
            } else {
                ForEach(searchResults) { item in
                    catalogCard(item)
                }
            }
        }
    }

    private func toggleFavorite(_ item: GameCatalogItem) {
        item.isFavorite.toggle()
        try? modelContext.save()
    }

    private func startPlaying(_ item: GameCatalogItem) {
        if item.category == .otherCardGame {
            appEnvironment.navigate(to: .otherCardGamePlay(slug: item.slug), tab: .home)
        } else {
            appEnvironment.navigate(to: .balootGamePlay(slug: item.slug), tab: .home)
        }
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
