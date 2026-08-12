import SwiftUI
import BalootEngine

struct BalootGamePlayView: View {
    let slug: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var viewModel: BalootGameViewModel
    @State private var isPresentingStopConfirm = false
    @State private var isPresentingRules = false
    @State private var isPresentingReplay = false

    init(slug: String) {
        self.slug = slug
        // البلوت لعبة واحدة: الصن والحكم يحددهما مسار المزايدة داخل نفس الطاولة.
        // روابط الكتالوج القديمة للصن/الحكم تُفتح كتجربة بلوت كاملة للتوافق فقط.
        _viewModel = State(initialValue: BalootGameViewModel(variant: BalootGameVariant(slug: slug), rules: HouseRulesStore.currentRules()))
    }

    var body: some View {
        Group {
            if purchaseManager.isFullGameUnlocked {
                gameContent
            } else {
                PaywallView()
                    .navigationTitle("طاولة اللعب")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var gameContent: some View {
        ZStack {
            table

            VStack {
                topBar
                Spacer()
                if viewModel.state.phase == .bidding {
                    fullBiddingPanel
                } else if viewModel.state.phase == .declaring {
                    declarationPanel
                } else if viewModel.state.phase == .finished {
                    resultPanel
                }
                Spacer()
                trickArea
                Spacer()
                humanHandArea
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
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

    private var table: some View {
        RoundedRectangle(cornerRadius: AppRadius.large)
            .fill(RadialGradient(colors: [AppColor.primary.opacity(0.35), AppColor.primary.opacity(0.12)], center: .center, startRadius: 10, endRadius: 400))
            .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            SeatIndicator(name: playerName(.north), isCurrentTurn: isCurrentSeat(.north), cardCount: cardCount(.north))
            Spacer()
            VStack {
                Label(viewModel.tableMode.title, systemImage: viewModel.tableMode.systemImage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                if viewModel.tableMode == .versusAI {
                    Text(viewModel.selectedAIProfileTitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text("الأكلات")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Text("\(trickCount(for: .south)) - \(trickCount(for: .west))")
                    .font(AppTypography.headline)
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
                    CardView(card: upCard)
                }
            }

            Text(biddingStageTitle)
                .font(AppTypography.headline)
                .multilineTextAlignment(.center)

            if viewModel.currentMultiplier != .none {
                StatusBadge(viewModel.currentMultiplier.arabicName, systemImage: "flame.fill", tint: AppColor.danger)
            }

            if viewModel.isShowingHumanMultiplierControls {
                multiplierButtons
            } else if viewModel.isHumanTurn && !viewModel.legalBidsForHuman.isEmpty {
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

            if viewModel.isAwaitingHumanDeclaration {
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
                viewModel.startNewMatch()
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
                if let bidding = report.biddingDecisions.first {
                    analysisRow(
                        icon: bidding.matchedRecommendation ? "hand.thumbsup.fill" : "exclamationmark.bubble.fill",
                        title: "قرار المزايدة".localized,
                        value: biddingAnalysisValue(bidding)
                    )
                }
                if let missedProject = report.projectOpportunities.first(where: { !$0.capturedAllProjects }) {
                    analysisRow(
                        icon: "sparkles",
                        title: "فرصة مشروع".localized,
                        value: "\(missedProject.estimatedLostPoints) \("نقطة".localized)"
                    )
                }
                if let multiplier = report.multiplierDecisions.first(where: { !$0.matchedRecommendation }) {
                    analysisRow(
                        icon: "flame.fill",
                        title: "قرار المضاعفة".localized,
                        value: multiplierAnalysisValue(multiplier)
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
                        value: "\(worst.playedCard.displayLabel) بدل \(worst.bestCard.displayLabel)"
                    )
                }
                analysisRow(
                    icon: "minus.circle.fill",
                    title: "نقاط ضائعة تقديريًا",
                    value: "\(report.totalEstimatedLostPoints)"
                )
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

    private func biddingAnalysisValue(_ decision: RoundBiddingDecisionAnalysis) -> String {
        let bid = bidAnalysisLabel(decision.bid)
        guard !decision.matchedRecommendation else { return bid }
        return "\(bid) \("بدل".localized) \(bidAnalysisLabel(decision.recommendedBid))"
    }

    private func multiplierAnalysisValue(_ decision: RoundMultiplierDecisionAnalysis) -> String {
        let selected = multiplierActionLabel(decision.selectedAction)
        guard !decision.matchedRecommendation else { return selected }
        return "\(selected) \("بدل".localized) \(multiplierActionLabel(decision.recommendedAction))"
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
                        CardView(card: played.card)
                            .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
                    }
                } else if viewModel.state.phase == .playing {
                    Text("بانتظار أول ورقة في الأكلة")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
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
                    .foregroundStyle(viewModel.isHumanTurn ? AppColor.success : AppColor.textSecondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                // تُحسب مرة واحدة لكل إعادة رسم بدل مرة لكل ورقة.
                let legalCards = viewModel.legalCardIDsForHuman
                let isHumanTurn = viewModel.isHumanTurn
                HStack(spacing: AppSpacing.xs) {
                    ForEach(viewModel.humanHand) { card in
                        let isPlayable = isHumanTurn && legalCards.contains(card)
                        CardView(card: card)
                            .opacity(isPlayable ? 1 : 0.4)
                            .onTapGesture {
                                // الضغط على ورقة ممنوعة يشرح السبب بدل أن يُتجاهل بصمت.
                                if isPlayable {
                                    viewModel.play(card)
                                } else if isHumanTurn {
                                    viewModel.explainIllegalMove(card)
                                }
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint(isPlayable ? "اضغط للعب هذه الورقة" : "لا يمكن لعب هذه الورقة الآن، اضغط لمعرفة السبب")
                    }
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
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
}

private struct SeatIndicator: View {
    let name: String
    let isCurrentTurn: Bool
    let cardCount: Int

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            ZStack {
                Circle().fill(isCurrentTurn ? AppColor.primary : AppColor.surface).frame(width: 44, height: 44)
                Image(systemName: "person.fill")
                    .foregroundStyle(isCurrentTurn ? .white : AppColor.textSecondary)
            }
            Text(name).font(AppTypography.caption)
            Text("\(cardCount) أوراق").font(.caption2).foregroundStyle(AppColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name)\(isCurrentTurn ? "، دوره الآن" : "")")
    }
}

private struct CardView: View {
    let card: PlayingCard

    /// الإطار الثابت كان يقصّ النص عند تكبير الخط، فيتمدّد الآن مع Dynamic Type
    /// انطلاقًا من نفس المقاس الأصلي عند الحجم القياسي.
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 46
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 64

    private var isRed: Bool { card.suit.isRed }

    var body: some View {
        VStack(spacing: 2) {
            Text(card.rank.shortLabel)
                .font(.system(.body, design: .rounded).weight(.bold))
            Image(systemName: symbolName)
                .font(.caption)
        }
        .foregroundStyle(isRed ? AppColor.danger : AppColor.textPrimary)
        .minimumScaleFactor(0.6)
        .frame(width: cardWidth, height: cardHeight)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.small))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.small).stroke(AppColor.border, lineWidth: 1))
        .accessibilityLabel(card.accessibilityName)
    }

    private var symbolName: String {
        switch card.suit {
        case .hearts: "suit.heart.fill"
        case .diamonds: "suit.diamond.fill"
        case .clubs: "suit.club.fill"
        case .spades: "suit.spade.fill"
        }
    }
}

#Preview {
    NavigationStack {
        BalootGamePlayView(slug: "baloot-classic")
    }
}
