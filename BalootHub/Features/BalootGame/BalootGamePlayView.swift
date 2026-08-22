import SwiftUI
import SwiftData
import BalootEngine

struct BalootGamePlayView: View {
    let slug: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var appEnvironment
    @State private var viewModel: BalootGameViewModel
    @State private var isPresentingStopConfirm = false
    @State private var isPresentingRules = false
    @State private var isPresentingReplay = false
    @State private var celebration: CelebrationKind?
    @Namespace private var cardNamespace
    @Query private var settingsList: [AppSettings]

    /// المظهر المختار للطاولة. يُقرأ من الإعدادات مباشرة بلا فحص فتح لأن الحفظ نفسه
    /// لا يقبل نمطًا مقفولًا (انظر ``AppearanceCatalog/apply(entry:to:)``).
    private var appearance: TableAppearance {
        AppearanceCatalog.resolveTrusted(settingsList.first?.appearanceSelection ?? .standard)
    }

    /// لون النص المقروء فوق لبس الطاولة.
    ///
    /// ألوان النظام (`textSecondary` وأخواتها) مصمَّمة لخلفية فاتحة. بعد أن صار سطح
    /// الطاولة لبسًا ملوّنًا داكنًا، صارت تلك الألوان باهتة فوقه إلى حد يصعب قراءته —
    /// وهو ما ظهر فور تشغيل التطبيق فعليًا على المحاكي ولم يظهر في أي اختبار.
    private var onFeltColor: Color { appearance.felt.contentColor }

    private var onFeltSecondaryColor: Color { appearance.felt.contentColor.opacity(0.75) }

    /// هل تُعرض مؤثرات المشاريع والكبوت؟ إطفاء الحركة من إعدادات النظام يلغيها دائمًا.
    private var showsCelebrations: Bool {
        !reduceMotion && (settingsList.first?.celebrationEffectsEnabled ?? true)
    }

    init(slug: String) {
        self.slug = slug
        // البلوت لعبة واحدة: الصن والحكم يحددهما مسار المزايدة داخل نفس الطاولة.
        // روابط الكتالوج القديمة للصن/الحكم تُفتح كتجربة بلوت كاملة للتوافق فقط.
        _viewModel = State(initialValue: BalootGameViewModel(variant: BalootGameVariant(slug: slug), rules: HouseRulesStore.currentRules()))
    }

    var body: some View {
        gameContent
    }

    private var gameContent: some View {
        ZStack {
            table

            tableLayout
                .padding(AppSpacing.md)
                // على iPad كانت العناصر تتناثر إلى الزوايا لأن `Spacer` يوزّع فراغًا
                // هائلًا؛ تحديد العرض يُبقي الطاولة مقروءة ويترك اللبس يملأ الخلفية.
                .adaptiveContentWidth(AppLayout.wideContentWidth)
                .adaptiveContentHeight()
        }
        .background(AppColor.background)
        .overlay {
            if let celebration {
                // ‏`id` ضروري: مؤثران متتاليان (مشروع ثم كبوت) لهما نفس نوع الواجهة،
                // فبلا تغيير الهوية لا تُعاد `task` وتبقى مدة المؤثر الأول سارية على الثاني.
                CelebrationOverlay(kind: celebration) { self.celebration = nil }
                    .id(celebration.id)
            }
        }
        .onAppear { syncFeedbackSettings() }
        .onChange(of: viewModel.pendingFeedback) { _, _ in consumeFeedback() }
        .navigationTitle("طاولة اللعب")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    tableModeMenu
                    aiProfileMenu
                    Button {
                        isPresentingRules = true
                    } label: {
                        Image(systemName: "book.fill")
                    }
                    .accessibilityLabel("عرض القواعد")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .destructive) {
                    isPresentingStopConfirm = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityLabel("إنهاء الجولة")
            }
        }
        .sheet(isPresented: $isPresentingRules) {
            NavigationStack { RulesView(slug: slug) }
        }
        .sheet(isPresented: $isPresentingReplay) {
            NavigationStack {
                RoundReplayView(
                    initialState: viewModel.currentRoundReplayInitialState,
                    actions: viewModel.state.actionHistory
                )
            }
        }
        .confirmationDialog("هل تريد إنهاء هذه الجولة والخروج؟", isPresented: $isPresentingStopConfirm, titleVisibility: .visible) {
            Button("إنهاء والخروج", role: .destructive) { dismiss() }
            Button("متابعة اللعب", role: .cancel) {}
        }
        .onAppear {
            if viewModel.onRoundFinished == nil {
                let context = modelContext
                viewModel.onRoundFinished = { finishedState in
                    Self.persistProjectDeclarations(from: finishedState, into: context)
                }
            }
            if viewModel.state.phase == .setup {
                viewModel.deal()
            }
        }
        .alert("تنبيه", isPresented: errorAlertBinding, actions: {
            Button("حسنًا") {}
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }

    private var tableModeMenu: some View {
        Menu {
            ForEach(BalootTableMode.allCases) { mode in
                Button {
                    viewModel.setTableMode(mode)
                } label: {
                    Label(mode.title, systemImage: mode.systemImage)
                }
            }
        } label: {
            Image(systemName: viewModel.tableMode.systemImage)
        }
        .accessibilityLabel("نمط اللاعبين")
    }

    private var aiProfileMenu: some View {
        Menu {
            ForEach(AIProfile.roster) { profile in
                Button {
                    viewModel.setAIProfile(profile)
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text(profile.displayName.localized)
                            Text("\(profile.levelTitle.localized) · \(profile.personalityTitle.localized)")
                        }
                    } icon: {
                        Image(systemName: profile.avatarSystemName)
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.selectedAIProfile.avatarSystemName)
        }
        .disabled(viewModel.tableMode == .localHumans)
        .accessibilityLabel("اختيار الخصم الآلي")
    }

    /// تخطيط الطاولة.
    ///
    /// عند مقاسات خط الوصولية يصير المحتوى أطول من الشاشة، فتُدفع أزرار المزايدة
    /// خارجها بلا أي وسيلة للوصول إليها — أي أن اللاعب لا يستطيع المزايدة أصلًا.
    /// لذلك يتحوّل التخطيط عندها إلى تمرير رأسي كامل بلا `Spacer`، ويبقى التوزيع
    /// الثابت على المقاسات العادية حيث يتّسع كل شيء.
    @ViewBuilder
    private var tableLayout: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    topBar
                    centerPanel
                    trickArea
                    humanHandArea
                }
            }
        } else if horizontalSizeClass == .regular {
            seatedTableLayout
        } else {
            VStack {
                topBar
                Spacer()
                centerPanel
                Spacer()
                trickArea
                Spacer()
                humanHandArea
            }
        }
    }

    /// تخطيط الشاشات الواسعة: المقاعد الأربعة موزّعة حول الطاولة.
    ///
    /// على الآيفون لا يتّسع العرض إلا لمقعد واحد أعلى الشاشة، فبقي التخطيط الضيّق
    /// كما هو. أما على iPad فكان ذلك التخطيط يُمدّ رأسيًا ويترك الطاولة شبه فارغة
    /// بينما ثلاثة لاعبين لا يظهرون أصلًا — وهو ما بدا واضحًا في أول لقطة فعلية.
    ///
    /// ترتيب المقاعد يتبع تسلسل الأدوار: أنت أسفل، ثم غرب، ثم شمال، ثم شرق. في
    /// الاتجاه من اليمين لليسار يضع `HStack` «غرب» على اليمين، فتتبع العين تسلسل
    /// الدور بشكل طبيعي.
    private var seatedTableLayout: some View {
        VStack(spacing: AppSpacing.md) {
            tableStatusBar

            seatView(.north)

            HStack(alignment: .center, spacing: AppSpacing.md) {
                seatView(.west)
                Spacer(minLength: AppSpacing.sm)
                VStack(spacing: AppSpacing.md) {
                    centerPanel
                    trickArea
                }
                Spacer(minLength: AppSpacing.sm)
                seatView(.east)
            }

            humanHandArea
        }
    }

    private func seatView(_ seat: SeatPosition) -> some View {
        SeatIndicator(
            name: playerName(seat),
            seatIndex: seat.rawValue,
            isCurrentTurn: isCurrentSeat(seat),
            cardCount: cardCount(seat),
            avatarStyle: appearance.avatar,
            theme: appearance.theme,
            contentColor: onFeltColor
        )
    }

    /// شريط حالة الجولة (النمط · الأكلات · شارة صن/حكم) بلا مقعد.
    private var tableStatusBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label(viewModel.tableMode.title, systemImage: viewModel.tableMode.systemImage)
                    .font(AppTypography.caption)
                    .foregroundStyle(onFeltSecondaryColor)
                if viewModel.tableMode == .versusAI {
                    Text(viewModel.selectedAIProfileTitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(onFeltSecondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            Spacer()
            VStack(spacing: 2) {
                Text("الأكلات")
                    .font(AppTypography.caption)
                    .foregroundStyle(onFeltSecondaryColor)
                Text("\(trickCount(for: .south)) - \(trickCount(for: .west))")
                    .font(AppTypography.headline)
                    .foregroundStyle(onFeltColor)
            }
            Spacer()
            if let mode = viewModel.state.mode {
                StatusBadge(mode.arabicName, systemImage: mode == .hokum ? "crown.fill" : "sun.max.fill", tint: AppColor.accent)
            }
        }
    }

    /// لوحة المرحلة الحالية (مزايدة · إعلان مشاريع · نتيجة).
    ///
    /// التمرير عند مقاسات الوصولية تتكفّل به ``tableLayout``.
    @ViewBuilder
    private var centerPanel: some View {
        let hasPanel = viewModel.state.phase == .bidding
            || viewModel.state.phase == .declaring
            || viewModel.state.phase == .finished
        if hasPanel {
            switch viewModel.state.phase {
            case .bidding: fullBiddingPanel
            case .declaring: declarationPanel
            case .finished: resultPanel
            default: EmptyView()
            }
        }
    }

    private var table: some View {
        ZStack {
            // الخلفية تتجاوز الحواف الآمنة بنفسها، أما سطح الطاولة فيبقى داخلها
            // بهامش صغير حتى يظهر النمط المختار للخلفية حول الطاولة لا خلفها فقط.
            TableBackdrop(style: appearance.backdrop, theme: appearance.theme)
            TableFeltSurface(style: appearance.felt)
                .padding(AppSpacing.xs)
        }
    }

    private var topBar: some View {
        HStack {
            SeatIndicator(
                name: playerName(.north),
                seatIndex: 1,
                isCurrentTurn: isCurrentSeat(.north),
                cardCount: cardCount(.north),
                avatarStyle: appearance.avatar,
                theme: appearance.theme,
                contentColor: onFeltColor
            )
            Spacer()
            VStack {
                Label(viewModel.tableMode.title, systemImage: viewModel.tableMode.systemImage)
                    .font(AppTypography.caption)
                    .foregroundStyle(onFeltSecondaryColor)
                if viewModel.tableMode == .versusAI {
                    Text(viewModel.selectedAIProfileTitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(onFeltSecondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text("الأكلات")
                    .font(AppTypography.caption)
                    .foregroundStyle(onFeltSecondaryColor)
                Text("\(trickCount(for: .south)) - \(trickCount(for: .west))")
                    .font(AppTypography.headline)
                    .foregroundStyle(onFeltColor)
            }
            Spacer()
            if let mode = viewModel.state.mode {
                StatusBadge(mode.arabicName, systemImage: mode == .hokum ? "crown.fill" : "sun.max.fill", tint: AppColor.accent)
            }
        }
    }

    // MARK: - دورة المزايدة الكاملة

    private var fullBiddingPanel: some View {
        VStack(spacing: AppSpacing.md) {
            if viewModel.tableMode == .versusAI {
                aiProfileSummaryCard
            }

            if let upCard = viewModel.upCard {
                VStack(spacing: AppSpacing.xxs) {
                    Text("الورقة المكشوفة")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    PlayingCardFaceView(card: upCard, style: appearance.cardFace)
                }
            }

            Text(biddingStageTitle)
                .font(AppTypography.headline)
                .multilineTextAlignment(.center)
                // بدونه يُقصّ سطر التعليمات على عرض الآيفون («…حكم على الورقة المكشوفة أو ص»)
                // لأن التخطيط الرأسي يقترح ارتفاعًا لا يتسع لسطرين.
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.currentMultiplier != .none {
                StatusBadge(viewModel.currentMultiplier.arabicName, systemImage: "flame.fill", tint: AppColor.danger)
            }

            if viewModel.requiresLocalHandoffConfirmation {
                localHandoffCard
            } else if viewModel.isShowingHumanMultiplierControls {
                multiplierButtons
            } else if viewModel.canCurrentHumanAct && !viewModel.legalBidsForHuman.isEmpty {
                bidOptionButtons
            } else {
                LoadingStateView(message: "بقية اللاعبين يزايدون…")
            }

            if !viewModel.bidHistory.isEmpty {
                bidHistoryStrip
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var aiProfileSummaryCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: viewModel.selectedAIProfile.avatarSystemName)
                .font(.title3)
                .foregroundStyle(AppColor.primary)
                .frame(width: 32, height: 32)
                .background(AppColor.primary.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(viewModel.selectedAIProfileTitle)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(viewModel.selectedAIProfileDetail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text(opponentRosterSummary)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: AppSpacing.xs) {
                    profilePill(viewModel.selectedAIProfileRiskText)
                    profilePill(viewModel.selectedAIProfileModePreferenceText)
                    profilePill(viewModel.selectedAIProfileMultiplierText)
                }
                profilePill(viewModel.selectedAIProfileAnalysisText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var opponentRosterSummary: String {
        let names = viewModel.aiOpponentProfiles.map { $0.displayName.localized }
        guard !names.isEmpty else { return "" }
        return "\("الخصوم".localized): \(names.joined(separator: " · "))"
    }

    private func profilePill(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 3)
            .background(AppColor.surfaceElevated, in: Capsule())
            .foregroundStyle(AppColor.textSecondary)
    }

    private var biddingStageTitle: String {
        switch viewModel.biddingStage {
        case .firstRound: "الجولة الأولى: حكم على الورقة المكشوفة أو صن أو بس".localized
        case .secondRound: "جولة الأشكال: اختر حكمًا بلون غير المكشوف أو صن أو بس".localized
        case .doubling: "جولة المضاعفة".localized
        case .completed, .voided: "انتهت المزايدة".localized
        }
    }

    @ViewBuilder
    private var bidOptionButtons: some View {
        // الخيارات تصل إلى ستة في جولة الأشكال، فتُلفّ تلقائيًا بدل أن تتزاحم.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.sm) { bidOptions }
            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) { bidOptions }
            }
        }
    }

    @ViewBuilder
    private var bidOptions: some View {
        ForEach(Array(viewModel.legalBidsForHuman.enumerated()), id: \.offset) { _, bid in
            Button {
                viewModel.placeBid(bid)
            } label: {
                Text(bidLabel(bid))
            }
            .buttonStyle(.borderedProminent)
            .tint(bidTint(bid))
            .accessibilityLabel(bidAccessibilityLabel(bid))
        }
    }

    private func bidLabel(_ bid: Bid) -> String {
        switch bid {
        case .pass: "بس".localized
        case .sun: "صن".localized
        case .hokum(let suit): "\("حكم".localized) \(suit.symbol)"
        }
    }

    private func bidAccessibilityLabel(_ bid: Bid) -> String {
        switch bid {
        case .pass: "بس، تمرير الدور".localized
        case .sun: "شراء صن".localized
        case .hokum(let suit): "\("شراء حكم".localized) \(suit.spokenName)"
        }
    }

    private func bidTint(_ bid: Bid) -> Color {
        switch bid {
        case .pass: AppColor.textSecondary
        case .sun: AppColor.accent
        case .hokum: AppColor.primary
        }
    }

    @ViewBuilder
    private var multiplierButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            if let declarerName = viewModel.declarerName {
                Text("المشتري: \(declarerName)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            HStack(spacing: AppSpacing.sm) {
                if viewModel.isAwaitingHumanMultiplierDecision, let next = viewModel.nextAvailableMultiplier {
                    Button(next.arabicName) { viewModel.raiseMultiplier(to: next) }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColor.danger)
                }
                if viewModel.canLockMultiplier {
                    Button("قفل") { viewModel.lockMultiplier() }
                        .buttonStyle(.bordered)
                        .tint(AppColor.accent)
                }
                if viewModel.isAwaitingHumanMultiplierDecision {
                    Button("بس") { viewModel.passMultiplier() }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private var bidHistoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(Array(viewModel.bidHistory.enumerated()), id: \.offset) { _, entry in
                    Text("\(entry.playerName): \(bidLabel(entry.bid))")
                        .font(.caption2)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(AppColor.surfaceElevated, in: Capsule())
                }
            }
        }
        .accessibilityLabel("سجل المزايدة")
    }

    // MARK: - إعلان المشاريع

    private var declarationPanel: some View {
        VStack(spacing: AppSpacing.md) {
            Text("إعلان المشاريع").font(AppTypography.headline)

            if viewModel.requiresLocalHandoffConfirmation {
                localHandoffCard
            } else if viewModel.isAwaitingHumanDeclaration && viewModel.canCurrentHumanAct {
                let projects = viewModel.declarableProjectsForHuman
                if projects.isEmpty {
                    Text("لا يوجد مشروع في يدك")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                    Button("متابعة") { viewModel.skipDeclaration() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColor.primary)
                } else {
                    ForEach(projects) { project in
                        HStack {
                            Text(project.kind.arabicName)
                            Spacer()
                            Text(project.cards.map(\.displayLabel).joined(separator: " "))
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                            Text("\(project.points)")
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColor.success)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    HStack(spacing: AppSpacing.sm) {
                        Button("أعلن الكل") { viewModel.declareProjects(projects) }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColor.success)
                        Button("لا أعلن") { viewModel.skipDeclaration() }
                            .buttonStyle(.bordered)
                    }
                }
            } else {
                LoadingStateView(message: "بقية اللاعبين يعلنون مشاريعهم…")
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var resultPanel: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("انتهت الجولة").font(AppTypography.headline)
            if let result = viewModel.state.lastRoundResult {
                ForEach(viewModel.state.teams) { team in
                    HStack {
                        Text(team.name)
                        Spacer()
                        Text("\(result.teamPoints[team.id] ?? 0)")
                            .font(AppTypography.headline)
                    }
                }
                if let winnerID = result.winningTeamID, let winner = viewModel.state.teams.first(where: { $0.id == winnerID }) {
                    Text("الفريق الفائز بالجولة: \(winner.name)")
                        .foregroundStyle(AppColor.success)
                        .font(AppTypography.subheadline)
                }
                if result.multiplier != .none {
                    StatusBadge(result.multiplier.arabicName, systemImage: "flame.fill", tint: AppColor.danger)
                }
                if let kabootID = result.kabootTeamID,
                   let team = viewModel.state.teams.first(where: { $0.id == kabootID }) {
                    Label("كبوت لصالح \(team.name)", systemImage: "sparkles")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.accent)
                }
                if result.didDeclarerFail {
                    Label("طاح المشتري: كل النقاط للخصم", systemImage: "exclamationmark.triangle.fill")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.danger)
                }
                if !result.awardedProjects.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("المشاريع المحتسَبة")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        ForEach(result.awardedProjects) { project in
                            HStack {
                                Text(viewModel.state.player(id: project.playerID)?.name ?? "")
                                Text(project.kind.arabicName)
                                Spacer()
                                Text("\(project.points)")
                            }
                            .font(AppTypography.caption)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                if let report = viewModel.roundAnalysisReport {
                    roundAnalysisCard(report)
                } else if viewModel.tableMode == .versusAI {
                    LoadingStateView(message: "جارٍ تحليل قراراتك…")
                }
            } else if viewModel.biddingStage == .voided {
                Text("مرّ الجميع في الجولتين — دورة ميتة بلا نقاط")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if viewModel.canReplayCurrentRound {
                Button {
                    isPresentingReplay = true
                } label: {
                    Label("إعادة الجولة", systemImage: "play.rectangle.fill")
                }
                .buttonStyle(.bordered)
            }
            Button("جولة جديدة") {
                viewModel.startNextRound()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.primary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func roundAnalysisCard(_ report: RoundAnalysisReport) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label("تحليل أدائك", systemImage: "chart.bar.xaxis")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)
                Spacer()
                Text("\(report.scoreOutOf100) / 100")
                    .font(AppTypography.headline)
                    .foregroundStyle(scoreTint(report.scoreOutOf100))
            }

            VStack(spacing: AppSpacing.xs) {
                if let focus = report.primaryReviewFocus {
                    analysisRow(
                        icon: reviewPriorityIcon(focus.priority),
                        title: "أولوية المراجعة".localized,
                        value: reviewPriorityValue(focus)
                    )
                }
                if let bidding = report.biddingDecisions.first {
                    analysisRow(
                        icon: bidding.matchedRecommendation ? "hand.thumbsup.fill" : "exclamationmark.bubble.fill",
                        title: "قرار المزايدة".localized,
                        value: biddingAnalysisValue(bidding)
                    )
                }
                if report.needsBiddingReview {
                    analysisRow(
                        icon: "magnifyingglass.circle.fill",
                        title: "مراجعة المزايدة".localized,
                        value: "\(report.biddingMistakeCount) · \(report.biddingLostPoints) \("نقطة".localized)"
                    )
                }
                if let missedProject = report.projectOpportunities.first(where: { !$0.capturedAllProjects }) {
                    analysisRow(
                        icon: "sparkles",
                        title: "فرصة مشروع".localized,
                        value: "\(missedProject.estimatedLostPoints) \("نقطة".localized)"
                    )
                }
                if report.needsProjectReview {
                    analysisRow(
                        icon: "sparkles.rectangle.stack.fill",
                        title: "مراجعة المشاريع".localized,
                        value: "\(report.projectMistakeCount) · \(report.projectLostPoints) \("نقطة".localized)"
                    )
                }
                if let multiplier = report.multiplierDecisions.first(where: { !$0.matchedRecommendation }) {
                    analysisRow(
                        icon: "flame.fill",
                        title: "قرار المضاعفة".localized,
                        value: multiplierAnalysisValue(multiplier)
                    )
                }
                if report.needsMultiplierReview {
                    analysisRow(
                        icon: "flame.circle.fill",
                        title: "مراجعة المضاعفة".localized,
                        value: "\(report.multiplierMistakeCount) · \(report.multiplierLostPoints) \("نقطة".localized)"
                    )
                }
                if let best = report.bestDecision {
                    analysisRow(
                        icon: "checkmark.seal.fill",
                        title: "أفضل قرار",
                        value: "\(best.playedCard.displayLabel) في الأكلة \(best.trickNumber)"
                    )
                }
                if let worst = report.worstDecision {
                    analysisRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "أسوأ قرار",
                        value: worstDecisionAnalysisValue(worst)
                    )
                }
                analysisRow(
                    icon: "minus.circle.fill",
                    title: "نقاط ضائعة تقديريًا",
                    value: "\(report.totalEstimatedLostPoints)"
                )
                if let recommendation = report.practiceRecommendation {
                    analysisRow(
                        icon: "target",
                        title: "خطة تدريب".localized,
                        value: recommendation.title.localized
                    )
                    analysisRow(
                        icon: "brain.head.profile",
                        title: "مستوى التدريب".localized,
                        value: "\(difficultyTitle(recommendation.difficulty)) · \(recommendation.suggestedScenarioCount) \("مواقف".localized)"
                    )
                    Button {
                        appEnvironment.openPracticeRecommendation(
                            recommendation,
                            from: appEnvironment.selectedTab
                        )
                    } label: {
                        Label("ابدأ التدريب المقترح".localized, systemImage: "brain.head.profile")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColor.primary)
                    .accessibilityHint("يفتح مدرب وش تلعب؟ بنفس صعوبة وبذرة خطة التدريب.".localized)
                }
            }

            ForEach(report.tips.prefix(2), id: \.self) { tip in
                Text(tip)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func reviewPriorityIcon(_ priority: RoundReviewPriority) -> String {
        switch priority {
        case .bidding:
            return "hand.raised.fill"
        case .projects:
            return "sparkles.rectangle.stack.fill"
        case .multipliers:
            return "flame.circle.fill"
        case .play:
            return "suit.club.fill"
        case .none:
            return "checkmark.seal.fill"
        }
    }

    private func reviewPriorityValue(_ focus: RoundReviewFocus) -> String {
        let title = switch focus.priority {
        case .bidding:
            "ابدأ بالمزايدة".localized
        case .projects:
            "ابدأ بالمشاريع".localized
        case .multipliers:
            "ابدأ بالمضاعفات".localized
        case .play:
            "ابدأ باللعب".localized
        case .none:
            "لا توجد أولوية".localized
        }
        return "\(title) · \(focus.estimatedLostPoints) \("نقطة".localized)"
    }

    private func difficultyTitle(_ difficulty: WhatToPlayDifficulty) -> String {
        switch difficulty {
        case .easy:
            return "سهل".localized
        case .medium:
            return "متوسط".localized
        case .hard:
            return "صعب".localized
        case .expert:
            return "خبير".localized
        }
    }

    private func biddingAnalysisValue(_ decision: RoundBiddingDecisionAnalysis) -> String {
        let bid = bidAnalysisLabel(decision.bid)
        guard !decision.matchedRecommendation else { return bid }
        let comparison = "\(bid) \("بدل".localized) \(bidAnalysisLabel(decision.recommendedBid))"
        guard let selected = decision.selectedBidMargin,
              let recommended = decision.recommendedBidMargin else { return comparison }
        return "\(comparison) · \("الهامش".localized): \(recommended - selected)"
    }

    private func multiplierAnalysisValue(_ decision: RoundMultiplierDecisionAnalysis) -> String {
        let selected = multiplierActionLabel(decision.selectedAction)
        guard !decision.matchedRecommendation else { return selected }
        return "\(selected) \("بدل".localized) \(multiplierActionLabel(decision.recommendedAction))"
    }

    private func worstDecisionAnalysisValue(_ decision: RoundDecisionAnalysis) -> String {
        let base = "\(decision.playedCard.displayLabel) \("بدل".localized) \(decision.recommendedCard.displayLabel)"
        guard decision.estimatedProjectedLostPoints > decision.estimatedImmediateLostPoints else { return base }
        return "\(base) · \("أفضل نتيجة محاكاة".localized)"
    }

    private func multiplierActionLabel(_ action: LegalMultiplierAction) -> String {
        switch action {
        case .pass:
            return "بس".localized
        case .raise(let level):
            return level.arabicName.localized
        case .lock:
            return "قفل".localized
        }
    }

    private func bidAnalysisLabel(_ bid: Bid) -> String {
        switch bid {
        case .pass:
            return "بس".localized
        case .sun:
            return "صن".localized
        case .hokum(let suit):
            return "\("حكم".localized) \(suit.symbol)"
        }
    }

    private func analysisRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: icon)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func scoreTint(_ score: Int) -> Color {
        if score >= 85 { return AppColor.success }
        if score >= 60 { return AppColor.accent }
        return AppColor.danger
    }

    private var trickArea: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                if !viewModel.trickOnTable.isEmpty {
                    ForEach(viewModel.trickOnTable) { played in
                        PlayingCardFaceView(card: played.card, style: appearance.cardFace)
                            .matchedGeometryEffect(id: played.card.id, in: cardNamespace)
                            .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
                            // بلا اسم اللاعب يسمع مستخدم VoiceOver أربع أوراق بلا
                            // معرفة من لعب أيًّا منها — وهي المعلومة التي تُبنى عليها
                            // قراءة الأكلة كلها.
                            .accessibilityLabel(trickCardAccessibilityLabel(played))
                    }
                } else if viewModel.state.phase == .playing {
                    Text("بانتظار أول ورقة في الأكلة")
                        .font(AppTypography.caption)
                        .foregroundStyle(onFeltSecondaryColor)
                }
            }
            // إظهار من فاز بالأكلة بعد حسمها، وإلا اختفت الأوراق دون تفسير.
            if let winner = viewModel.lastTrickWinnerName {
                Label("فاز بالأكلة: \(winner)", systemImage: "checkmark.seal.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.success)
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.standard(reduceMotion: reduceMotion), value: viewModel.trickOnTable.count)
        .animation(AppAnimation.standard(reduceMotion: reduceMotion), value: viewModel.lastTrickWinnerName)
        .frame(minHeight: 110)
        .opacity(viewModel.isShowingResolvedTrick ? 0.75 : 1)
    }

    private var humanHandArea: some View {
        VStack(spacing: AppSpacing.xs) {
            if viewModel.state.phase == .playing {
                Text(turnStatusText)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(viewModel.isHumanTurn ? AppColor.success : onFeltSecondaryColor)
            }
            if viewModel.requiresLocalHandoffConfirmation && viewModel.state.phase == .playing {
                localHandoffCard
            }
            // اليد ثماني أوراق كحد أقصى وتتّسع كاملةً على شاشة عريضة، فتُعرض
            // متوسّطة بلا تمرير. الشريط الأفقي على الآيفون يبقى لأن العرض لا يكفي،
            // وهو في الاتجاه من اليمين لليسار يبدأ من اليمين فيبدو مزاحًا على iPad.
            if horizontalSizeClass == .regular {
                handCards
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    handCards
                }
            }
        }
    }

    /// أوراق يد اللاعب. مشتركة بين الشريط الأفقي على الآيفون والصف المتوسّط على iPad.
    private var handCards: some View {
        // تُحسب مرة واحدة لكل إعادة رسم بدل مرة لكل ورقة.
        let legalCards = viewModel.legalCardIDsForHuman
        let canAct = viewModel.canCurrentHumanAct
        return HStack(spacing: AppSpacing.xs) {
            ForEach(viewModel.visibleHumanHand) { card in
                let isPlayable = canAct && legalCards.contains(card)
                PlayingCardFaceView(card: card, style: appearance.cardFace, isHighlighted: isPlayable)
                    .matchedGeometryEffect(id: card.id, in: cardNamespace)
                    .opacity(isPlayable ? 1 : 0.4)
                    .onTapGesture {
                        // الضغط على ورقة ممنوعة يشرح السبب بدل أن يُتجاهل بصمت.
                        if isPlayable {
                            viewModel.play(card)
                        } else if canAct {
                            viewModel.explainIllegalMove(card)
                        }
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(isPlayable ? "اضغط للعب هذه الورقة" : "لا يمكن لعب هذه الورقة الآن، اضغط لمعرفة السبب")
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .animation(AppAnimation.spring(reduceMotion: reduceMotion), value: viewModel.visibleHumanHand.count)
    }

    private var localHandoffCard: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "hand.raised.fill")
                .font(.title2)
                .foregroundStyle(AppColor.primary)
            Text("\("سلّم الجهاز إلى".localized) \(viewModel.currentTurnPlayerName)")
                .font(AppTypography.headline)
                .multilineTextAlignment(.center)
            Text("اضغط جاهز عندما يكون الجهاز مع اللاعب الحالي فقط.".localized)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                viewModel.revealLocalHumanHand()
            } label: {
                Label("جاهز".localized, systemImage: "eye.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.primary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
    }

    private var turnStatusText: String {
        if viewModel.tableMode == .localHumans {
            return "\("الدور الآن".localized): \(viewModel.currentTurnPlayerName)"
        }
        return viewModel.isHumanTurn ? "دورك الآن".localized : "بانتظار بقية اللاعبين".localized
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.clearError() } })
    }

    /// يمرّر تفضيلات الصوت والاهتزاز لمشغّل ردود الفعل قبل أول حدث في الطاولة.
    private func syncFeedbackSettings() {
        FeedbackPlayer.shared.sync(
            soundEnabled: settingsList.first?.soundEnabled ?? true,
            hapticsEnabled: settingsList.first?.hapticsEnabled ?? true
        )
    }

    /// يشغّل صوت/اهتزاز آخر حدث ويعرض مؤثره البصري إن استحق.
    private func consumeFeedback() {
        guard let signal = viewModel.consumeFeedback() else { return }
        FeedbackPlayer.shared.play(signal.event)
        guard showsCelebrations, let kind = signal.celebration else { return }
        celebration = kind
    }

    /// وصف ورقة على الطاولة لـVoiceOver: اسم اللاعب ثم الورقة.
    private func trickCardAccessibilityLabel(_ played: PlayedCard) -> String {
        let name = viewModel.state.player(id: played.playerID)?.name
        guard let name, !name.isEmpty else { return played.card.accessibilityName }
        return "\(name)، \(played.card.accessibilityName)"
    }

    private func playerName(_ seat: SeatPosition) -> String {
        viewModel.state.player(at: seat)?.name ?? ""
    }

    private func isCurrentSeat(_ seat: SeatPosition) -> Bool {
        viewModel.state.player(at: seat)?.id == viewModel.state.currentTurnPlayerID
    }

    private func cardCount(_ seat: SeatPosition) -> Int {
        guard let player = viewModel.state.player(at: seat) else { return 0 }
        return viewModel.state.hands[player.id]?.count ?? 0
    }

    private func trickCount(for seat: SeatPosition) -> Int {
        guard let teamID = viewModel.state.player(at: seat)?.teamID else { return 0 }
        return viewModel.state.completedTricks.count { trick in
            guard let winnerID = trick.winnerPlayerID else { return false }
            return viewModel.state.player(id: winnerID)?.teamID == teamID
        }
    }

    /// يحفظ مشاريع اللاعب البشري المُعلَنة في هذه الجولة كسجلات إحصائية دائمة،
    /// تغذّي تفصيل المشاريع حسب النوع في ``PlayerStatsView``.
    private static func persistProjectDeclarations(from finishedState: GameState, into modelContext: ModelContext) {
        guard let humanID = finishedState.players.first(where: { $0.kind == .human })?.id else { return }
        let declared = finishedState.declaredProjects.filter { $0.playerID == humanID }
        guard !declared.isEmpty else { return }

        let awardedIDs = Set(finishedState.awardedProjects.map(\.id))
        for project in declared {
            modelContext.insert(ProjectDeclarationRecord(
                kind: project.kind,
                points: project.points,
                wasAwarded: awardedIDs.contains(project.id)
            ))
        }
        try? modelContext.save()
    }
}

private struct SeatIndicator: View {
    let name: String
    let seatIndex: Int
    let isCurrentTurn: Bool
    let cardCount: Int
    var avatarStyle: AvatarStyle = .person
    var theme: TableThemeStyle = .baloot
    /// لون النص فوق لبس الطاولة؛ ألوان النظام الرمادية تختفي على الجوخ الداكن.
    var contentColor: Color = AppColor.textPrimary

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            SeatAvatarView(
                name: name,
                seatIndex: seatIndex,
                style: avatarStyle,
                theme: theme,
                isCurrentTurn: isCurrentTurn
            )
            Text(name).font(AppTypography.caption).foregroundStyle(contentColor)
            Text("\(cardCount) أوراق").font(.caption2).foregroundStyle(contentColor.opacity(0.75))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name)\(isCurrentTurn ? "، دوره الآن" : "")")
    }
}

#Preview {
    NavigationStack {
        BalootGamePlayView(slug: "baloot-classic")
    }
}
