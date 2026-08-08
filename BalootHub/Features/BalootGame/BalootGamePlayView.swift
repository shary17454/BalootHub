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
                    biddingPanel
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
                                if isPlayable { viewModel.play(card) }
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint(isPlayable ? "اضغط للعب هذه الورقة" : "لا يمكن لعب هذه الورقة الآن")
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
