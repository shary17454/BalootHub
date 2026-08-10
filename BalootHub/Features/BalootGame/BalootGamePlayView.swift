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

    init(slug: String) {
        self.slug = slug
        // النمط يُشتق من عنصر الكتالوج، فيبدأ المحرك مقيّدًا بنمط اللعبة المفتوحة
        // بدل أن تفتح كل الألعاب نفس الجولة الحرة.
        _viewModel = State(initialValue: BalootGameViewModel(variant: BalootGameVariant(slug: slug)))
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
                    if viewModel.usesFullBidding {
                        fullBiddingPanel
                    } else {
                        biddingPanel
                    }
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

    private var biddingPanel: some View {
        VStack(spacing: AppSpacing.md) {
            if viewModel.isHumanTurn {
                // تعبير شرطي ⇒ `Text(String)` الذي لا يترجم تلقائيًا، بخلاف السلسلة
                // الحرفية داخل `Text`. لذا تُترجم كل حالة صراحةً.
                Text(viewModel.variant == .hokumOnly ? "اختر نوع الحكم".localized : "اختر نمط الجولة".localized)
                    .font(AppTypography.headline)
                // خمسة أزرار في صف واحد تتزاحم على الشاشات الضيقة وعند تكبير الخط،
                // فتتوزّع تلقائيًا على أكثر من سطر بدل قصّها.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.sm) { bidButtons }
                    VStack(spacing: AppSpacing.sm) {
                        if viewModel.variant.allowsSun { sunBidButton }
                        if viewModel.variant.allowsHokum {
                            HStack(spacing: AppSpacing.sm) { hokumBidButtons }
                        }
                    }
                }
            } else {
                LoadingStateView(message: "بقية اللاعبين يقررون نمط الجولة…")
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    @ViewBuilder
    private var bidButtons: some View {
        if viewModel.variant.allowsSun { sunBidButton }
        if viewModel.variant.allowsHokum { hokumBidButtons }
    }

    private var sunBidButton: some View {
        Button("صن") { viewModel.chooseMode(.sun, trumpSuit: nil) }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.accent)
    }

    @ViewBuilder
    private var hokumBidButtons: some View {
        ForEach(Suit.allCases) { suit in
            Button {
                viewModel.chooseMode(.hokum, trumpSuit: suit)
            } label: {
                Text("حكم \(suit.symbol)")
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.primary)
            // الرمز وحده لا يكفي قارئ الشاشة، فيُنطق اسم النوع كاملًا.
            .accessibilityLabel("\("حكم".localized) \(suit.spokenName)")
        }
    }

    // MARK: - دورة المزايدة الكاملة

    private var fullBiddingPanel: some View {
        VStack(spacing: AppSpacing.md) {
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

            if viewModel.isAwaitingHumanMultiplierDecision {
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

    private var biddingStageTitle: String {
        switch viewModel.biddingStage {
        case .firstRound: "الجولة الأولى: حكم على الورقة المكشوفة أو صن أو بس".localized
        case .secondRound: "جولة الأشكال: اختر أي لون للحكم أو صن أو بس".localized
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
                if let next = viewModel.nextAvailableMultiplier {
                    Button(next.arabicName) { viewModel.raiseMultiplier(to: next) }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColor.danger)
                }
                if viewModel.canLockMultiplier {
                    Button("قفل") { viewModel.lockMultiplier() }
                        .buttonStyle(.bordered)
                        .tint(AppColor.accent)
                }
                Button("بس") { viewModel.passMultiplier() }
                    .buttonStyle(.bordered)
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
            } else if viewModel.biddingStage == .voided {
                Text("مرّ الجميع في الجولتين — دورة ميتة بلا نقاط")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
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
