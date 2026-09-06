import SwiftUI
import SwiftData

struct OtherCardGamePlayView: View {
    let slug: String

    @Query private var items: [GameCatalogItem]
    @State private var state: OtherCardGameTableState
    @State private var seed: UInt64 = 7_341

    init(slug: String) {
        self.slug = slug
        let predicate = #Predicate<GameCatalogItem> { $0.slug == slug }
        _items = Query(filter: predicate)
        _state = State(initialValue: OtherCardGameEngine.newGame(slug: slug, title: slug))
    }

    private var title: String {
        items.first?.displayTitle ?? state.rules.title
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                tableHeader
                playersGrid
                playArea
                controls
                userHand
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
        .background(AppColor.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if state.rules.title == slug {
                reset()
            }
        }
    }

    private var tableHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Label("لعبة قابلة للعب", systemImage: "play.circle.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)
                Spacer()
                Text(state.roundFinished ? "انتهت الجولة".localized : "قيد اللعب".localized)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(state.roundFinished ? AppColor.success : AppColor.accent)
            }

            Text(state.rules.goalText.localized)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Label(state.rules.setupText.localized, systemImage: "rectangle.on.rectangle")
                Label(state.rules.playText.localized, systemImage: "hand.point.up.left.fill")
                Label(state.rules.scoringText.localized, systemImage: "number.circle.fill")
            }
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

            if let trump = state.trumpSuit {
                Label("الحكم: \(trump.title)", systemImage: trump.symbolName)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var playersGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            ForEach(state.players) { player in
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(player.name.localized)
                            .font(AppTypography.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(player.score)")
                            .font(AppTypography.headline)
                            .monospacedDigit()
                    }
                    Text("\(player.hand.count) ورقة".localized)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(AppSpacing.sm)
                .background(player.id == state.currentPlayerID ? AppColor.primary.opacity(0.18) : AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.small))
            }
        }
    }

    private var playArea: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(state.message.localized)
                .font(AppTypography.body.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if state.rules.mode == .matchingDiscard, let top = state.discardPile.last {
                VStack(spacing: AppSpacing.xs) {
                    Text("الورقة المفتوحة".localized)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    otherCardView(top, highlighted: true)
                }
                .frame(maxWidth: .infinity)
            } else if !state.currentTrick.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: AppSpacing.sm) {
                    ForEach(Array(state.currentTrick.enumerated()), id: \.offset) { _, play in
                        VStack(spacing: AppSpacing.xs) {
                            Text(state.players[play.playerID].name.localized)
                                .font(AppTypography.caption)
                            otherCardView(play.card, highlighted: play.playerID == 0)
                        }
                    }
                }
            } else if state.rules.mode == .blackjack {
                blackjackHands
            } else if state.rules.mode == .pokerShowdown {
                pokerShowdownArea
            } else if state.rules.mode == .solitaireFoundation {
                foundationArea
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var blackjackHands: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            blackjackHand(title: "يدك", cards: state.players[0].hand)
            blackjackHand(title: "الموزع", cards: state.players[1].hand)
        }
    }

    private func blackjackHand(title: String, cards: [OtherCardGameCard]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title.localized)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(cards) { card in
                        otherCardView(card, highlighted: false)
                    }
                }
            }
        }
    }

    private var pokerShowdownArea: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("أوراق الوسط".localized)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(state.communityCards) { card in
                        otherCardView(card, highlighted: false)
                    }
                }
            }
            blackjackHand(title: "يدك", cards: state.players[0].hand)
        }
    }

    private var foundationArea: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: AppSpacing.sm) {
            ForEach(OtherCardGameCard.Suit.allCases, id: \.self) { suit in
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: suit.symbolName)
                        .font(.title3)
                    Text(state.foundations[suit]?.title ?? "A")
                        .font(AppTypography.caption.weight(.semibold))
                }
                .foregroundStyle(suit.isRed ? AppColor.danger : AppColor.textPrimary)
                .frame(width: 66, height: 72)
                .background(AppColor.background, in: RoundedRectangle(cornerRadius: AppRadius.small))
            }
        }
    }

    private var controls: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                reset()
            } label: {
                Label("جولة جديدة", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if state.rules.mode == .matchingDiscard || state.rules.mode == .blackjack {
                Button {
                    OtherCardGameEngine.drawForUser(in: &state)
                } label: {
                    Label("اسحب", systemImage: "square.stack.3d.down.forward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.roundFinished)
                .controlSize(.large)
            }

            if state.rules.mode == .blackjack {
                Button {
                    OtherCardGameEngine.standUser(in: &state)
                } label: {
                    Label("توقف", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.roundFinished)
                .controlSize(.large)
            }

            if state.rules.mode == .war {
                Button {
                    OtherCardGameEngine.playUserCard(state.players[0].hand.first ?? OtherCardGameCard(suit: .spade, rank: .two), in: &state)
                } label: {
                    Label("اكشف", systemImage: "rectangle.portrait.on.rectangle.portrait")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.roundFinished || state.players[0].hand.isEmpty)
                .controlSize(.large)
            }

            if state.rules.mode == .pokerShowdown {
                Button {
                    OtherCardGameEngine.playUserCard(state.players[0].hand.first ?? OtherCardGameCard(suit: .spade, rank: .two), in: &state)
                } label: {
                    Label("اكشف", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.roundFinished)
                .controlSize(.large)
            }
        }
    }

    private var userHand: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("أوراقك".localized)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)

            let legal = Set(state.legalCardsForUser)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: AppSpacing.xs)], spacing: AppSpacing.xs) {
                ForEach(state.players[0].hand) { card in
                    Button {
                        OtherCardGameEngine.playUserCard(card, in: &state)
                    } label: {
                        otherCardView(card, highlighted: legal.contains(card))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.roundFinished || state.rules.mode == .blackjack || state.rules.mode == .war || state.rules.mode == .pokerShowdown)
                    .opacity(legal.isEmpty || legal.contains(card) ? 1 : 0.45)
                    .accessibilityHint(legal.contains(card) ? "ورقة قانونية الآن".localized : "ليست من الخيارات القانونية الآن".localized)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func otherCardView(_ card: OtherCardGameCard, highlighted: Bool) -> some View {
        VStack(spacing: 4) {
            Text(card.rank.title)
                .font(.system(.headline, design: .rounded).weight(.bold))
            Image(systemName: card.suit.symbolName)
                .font(.title3)
            Text(card.suit.title)
                .font(.caption2)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(card.suit.isRed ? AppColor.danger : AppColor.textPrimary)
        .frame(width: 58, height: 82)
        .background(AppColor.background, in: RoundedRectangle(cornerRadius: AppRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.small)
                .stroke(highlighted ? AppColor.accent : AppColor.textSecondary.opacity(0.35), lineWidth: highlighted ? 2 : 1)
        )
        .accessibilityLabel("\(card.rank.title) \(card.suit.title)")
    }

    private func reset() {
        seed += 1
        state = OtherCardGameEngine.newGame(slug: slug, title: title, seed: seed)
    }
}

#Preview {
    NavigationStack {
        OtherCardGamePlayView(slug: "tarneeb")
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
