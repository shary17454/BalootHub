import SwiftUI
import SwiftData
import BalootEngine

struct OtherCardGamePlayView: View {
    let slug: String

    nonisolated static let originalEngineSlugs: Set<String> = ["kout-bou-sitta", "trex", "hand", "solitaire-klondike", "freecell", "spider-solitaire"]

    @ViewBuilder var body: some View {
        switch slug {
        case "kout-bou-sitta": KoutOriginalPlayView()
        case "trex": TrexOriginalPlayView()
        case "hand": HandOriginalPlayView()
        case "solitaire-klondike": SolitaireOriginalPlayView(variant: .klondike)
        case "freecell": SolitaireOriginalPlayView(variant: .freecell)
        case "spider-solitaire": SolitaireOriginalPlayView(variant: .spider)
        default: LegacyOtherCardGamePlayView(slug: slug)
        }
    }
}

private struct LegacyOtherCardGamePlayView: View {
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

            DisclosureGroup("التفاصيل والقواعد") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label(state.rules.setupText.localized, systemImage: "rectangle.on.rectangle")
                    Label(state.rules.playText.localized, systemImage: "hand.point.up.left.fill")
                    Label(state.rules.scoringText.localized, systemImage: "number.circle.fill")
                }
                .padding(.top, AppSpacing.xs)
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
            Button {
                reset()
            } label: {
                Label("جولة جديدة", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if OtherCardGameEngine.canDraw(in: state) {
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

            if OtherCardGameEngine.canPass(in: state) {
                Button {
                    OtherCardGameEngine.passUser(in: &state)
                } label: {
                    Label("بس", systemImage: "arrow.forward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
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
                    .disabled(state.roundFinished || state.currentPlayerID != 0 || !legal.contains(card) || state.rules.mode == .blackjack || state.rules.mode == .war || state.rules.mode == .pokerShowdown)
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

private struct OriginalCardTile: View {
    let card: StandardCard
    var selected = false
    var faceUp = true

    var body: some View {
        VStack(spacing: 2) {
            if faceUp {
                Text(card.isJoker ? "J" : [1: "A", 11: "J", 12: "Q", 13: "K"][card.rank] ?? String(card.rank))
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(card.isJoker ? "★" : card.suit.symbol).font(.system(size: 27))
                Text(card.isJoker ? "J" : [1: "A", 11: "J", 12: "Q", 13: "K"][card.rank] ?? String(card.rank))
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .rotationEffect(.degrees(180)).frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Image(systemName: "suit.spade.fill").font(.title2).foregroundStyle(.white)
            }
        }
        .padding(6)
        .frame(width: 58, height: 84)
        .foregroundStyle(card.suit.isRed ? Color.red : Color.black)
        .background(faceUp ? Color.white : Color.indigo, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(selected ? AppColor.accent : Color.gray.opacity(0.5), lineWidth: selected ? 3 : 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(faceUp ? card.label : "ورقة مقلوبة".localized)
    }
}

private func originalPlayerName(_ seat: Int) -> String {
    seat == 0 ? "أنت".localized : String(format: "لاعب %lld".localized, seat + 1)
}

private struct OriginalCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct OriginalHandGrid: View {
    let cards: [StandardCard]
    var enabled: Set<Int> = []
    var selected: Set<Int> = []
    let action: (StandardCard) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 10) {
            ForEach(cards.sorted { ($0.suit.ordinal, $0.highRank, $0.id) < ($1.suit.ordinal, $1.highRank, $1.id) }) { card in
                Button { action(card) } label: {
                    OriginalCardTile(card: card, selected: selected.contains(card.id))
                        .opacity(enabled.contains(card.id) ? 1 : 0.8)
                }
                .buttonStyle(OriginalCardButtonStyle())
                .disabled(!enabled.contains(card.id))
                .accessibilityAddTraits(selected.contains(card.id) ? .isSelected : [])
            }
        }
    }
}

private struct OriginalSeats: View {
    let hands: [[StandardCard]]
    let scores: [Int]
    let turn: Int
    var teams = false

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
            ForEach(hands.indices, id: \.self) { seat in
                VStack(alignment: .leading, spacing: 4) {
                    Label(originalPlayerName(seat), systemImage: seat == turn ? "arrowtriangle.left.fill" : "person.fill")
                    Text(String(format: "%lld ورقة".localized, hands[seat].count)).font(.caption)
                    if teams {
                        Text(seat.isMultiple(of: 2) ? "فريقنا".localized : "الخصم".localized).font(.caption)
                    } else { Text(String(format: "%lld نقطة".localized, scores[seat])).monospacedDigit() }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(seat == turn ? AppColor.primary.opacity(0.18) : Color.clear)
            }
        }
    }
}

private struct OriginalPlayedCards: View {
    let cards: [StandardCard]
    var seats: [Int] = []
    var representedRanks: [Int] = []
    var body: some View {
        if !cards.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        VStack(spacing: 4) {
                            OriginalCardTile(card: card)
                            if card.isJoker && representedRanks.indices.contains(index) {
                                Text("= \([1: "A", 11: "J", 12: "Q", 13: "K", 14: "A"][representedRanks[index]] ?? String(representedRanks[index]))").font(.caption)
                            }
                            if seats.indices.contains(index) { Text(originalPlayerName(seats[index])).font(.caption) }
                        }
                    }
                }.padding(.vertical, 4)
            }
            .frame(minHeight: 92)
        }
    }
}

private struct KoutOriginalPlayView: View {
    @State private var game = KoutMatch(seed: UInt64.random(in: 1...UInt64.max))
    @State private var revision = 0
    @State private var failure: String?
    @Environment(\.scenePhase) private var scenePhase
    private var aiTurn: Bool { game.turn != 0 && [.bidding, .trump, .playing].contains(game.phase) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("فريقنا".localized + ": \(game.scores[0])")
                    Spacer()
                    Text("الخصم".localized + ": \(game.scores[1])")
                }.font(.headline)
                Text(String(format: "الجولة %lld".localized, game.round))
                OriginalSeats(hands: game.hands, scores: game.scores, turn: game.turn, teams: true)
                if game.bid > 0 {
                    Text(String(format: "العقد: %lld · %@".localized, game.bid, originalPlayerName(game.bidder)))
                }
                if let trump = game.trump {
                    Text("الحكم".localized + ": " + trump.arabicName.localized + " " + trump.symbol)
                    Text(String(format: "الأكلات: %lld - %lld".localized, game.tricksWon[0], game.tricksWon[1]))
                }
                if game.trick.isEmpty && !game.lastTrick.isEmpty { Text("الأكلة السابقة".localized).font(.caption) }
                OriginalPlayedCards(cards: game.trick.isEmpty ? game.lastTrick : game.trick.map(\.card), seats: game.trick.map(\.player))
                if aiTurn { ProgressView(originalPlayerName(game.turn)).frame(maxWidth: .infinity) }
                if game.turn == 0 {
                    if game.phase == .bidding {
                        Text("المزايدة".localized).font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 74))]) {
                            ForEach(game.legalBids, id: \.self) { bid in
                                Button(String(bid)) { act { try $0.offer(bid, player: 0) } }.buttonStyle(.borderedProminent)
                            }
                            Button("تمرير".localized) { act { try $0.offer(nil, player: 0) } }.buttonStyle(.bordered)
                        }
                    } else if game.phase == .trump {
                        Text("اختر الحكم".localized).font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 115))]) {
                            ForEach(BalootEngine.Suit.allCases) { suit in
                                Button(suit.arabicName.localized + " " + suit.symbol) { act { try $0.selectTrump(suit, player: 0) } }.buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                if game.phase == .roundEnd {
                    Button("الجولة التالية".localized) { act { try $0.nextRound() } }.buttonStyle(.borderedProminent)
                }
                if game.phase == .matchEnd {
                    Text("انتهت المباراة".localized).font(.headline)
                    Text("الفائز".localized + ": " + (game.scores[0] > game.scores[1] ? "فريقنا".localized : "الخصم".localized))
                    Button("مباراة جديدة".localized) { game = KoutMatch(seed: .random(in: 1...UInt64.max)); revision += 1 }.buttonStyle(.borderedProminent)
                }
                if let failure { Text(failure).foregroundStyle(AppColor.danger) }
                Text("يدك".localized).font(.headline)
                OriginalHandGrid(cards: game.hands[0], enabled: Set(game.legalCards(player: 0).map(\.id))) { card in act { try $0.play(card, player: 0) } }
            }.padding().adaptiveContentWidth()
        }
        .background(AppColor.background).navigationTitle("كوت بو ستة".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(revision)-\(scenePhase)") {
            guard aiTurn, scenePhase == .active else { return }
            do {
                try await Task.sleep(for: .milliseconds(450))
                let snapshot = game
                let next = try await Task.detached(priority: .userInitiated) { var next = snapshot; try next.stepAI(); return next }.value
                try Task.checkCancellation(); game = next; revision += 1
            } catch is CancellationError {} catch { failure = "تعذر تنفيذ الحركة".localized }
        }
    }

    private func act(_ action: (inout KoutMatch) throws -> Void) {
        do { try action(&game); failure = nil; revision += 1 }
        catch { failure = "هذه الحركة غير مسموحة".localized }
    }
}

private struct TrexOriginalPlayView: View {
    @State private var game = TrexMatch(seed: UInt64.random(in: 1...UInt64.max))
    @State private var revision = 0
    @State private var failure: String?
    @Environment(\.scenePhase) private var scenePhase
    private var aiTurn: Bool { !game.roundFinished && !game.matchFinished && (game.contract == nil ? game.kingdomOwner != 0 : game.turn != 0) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(String(format: "المملكة %lld · %@".localized, min(4, game.kingdomsCompleted + 1), originalPlayerName(game.kingdomOwner))).font(.headline)
                OriginalSeats(hands: game.hands, scores: game.scores, turn: game.turn)
                if let contract = game.contract { Text(contract.title.localized).font(.title2.bold()) }
                if game.contract == .trex {
                    ForEach(BalootEngine.Suit.allCases) { suit in
                        HStack {
                            Text(suit.symbol).foregroundStyle(suit.isRed ? .red : AppColor.textPrimary)
                            Text(game.layout[suit, default: []].sorted().map { [11: "J", 12: "Q", 13: "K", 14: "A"][$0] ?? String($0) }.joined(separator: " · "))
                                .fixedSize(horizontal: false, vertical: true)
                        }.frame(minHeight: 32)
                    }
                } else {
                    if game.trick.isEmpty && !game.lastTrick.isEmpty { Text("الأكلة السابقة".localized).font(.caption) }
                    OriginalPlayedCards(cards: game.trick.isEmpty ? game.lastTrick : game.trick.map(\.card), seats: game.trick.map(\.player))
                }
                if game.contract == nil && game.kingdomOwner == 0 && !game.matchFinished {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))]) {
                        ForEach(game.availableContracts, id: \.self) { contract in
                            Button(contract.title.localized) { act { try $0.choose(contract, player: 0) } }.buttonStyle(.borderedProminent)
                        }
                    }
                }
                if aiTurn { ProgressView(originalPlayerName(game.turn)).frame(maxWidth: .infinity) }
                if game.contract == .trex && game.turn == 0 && !game.roundFinished && game.legalCards(player: 0).isEmpty {
                    Button("تمرير".localized) { act { try $0.pass(player: 0) } }.buttonStyle(.bordered)
                }
                if game.canRequestRedeal(player: 0) {
                    Button("إعادة التوزيع".localized) { act { try $0.requestRedeal(player: 0) } }.buttonStyle(.bordered)
                }
                if game.roundFinished && !game.matchFinished {
                    Text("انتهت الجولة".localized).font(.headline)
                    Button("الجولة التالية".localized) { act { try $0.nextRound() } }.buttonStyle(.borderedProminent)
                }
                if game.matchFinished {
                    Text("انتهت المباراة".localized).font(.headline)
                    Text("الفائز".localized + ": " + game.scores.indices.filter { game.scores[$0] == game.scores.max() }.map(originalPlayerName).joined(separator: "، "))
                    Button("مباراة جديدة".localized) { game = TrexMatch(seed: .random(in: 1...UInt64.max)); revision += 1 }.buttonStyle(.borderedProminent)
                }
                if let failure { Text(failure).foregroundStyle(AppColor.danger) }
                Text("يدك".localized).font(.headline)
                OriginalHandGrid(cards: game.hands[0], enabled: Set(game.legalCards(player: 0).map(\.id))) { card in act { try $0.play(card, player: 0) } }
            }.padding().adaptiveContentWidth()
        }
        .background(AppColor.background).navigationTitle("تركس".localized).navigationBarTitleDisplayMode(.inline)
        .task(id: "\(revision)-\(scenePhase)") {
            guard aiTurn, scenePhase == .active else { return }
            do {
                try await Task.sleep(for: .milliseconds(450))
                let snapshot = game
                let next = try await Task.detached(priority: .userInitiated) { var next = snapshot; try next.stepAI(); return next }.value
                try Task.checkCancellation(); game = next; revision += 1
            } catch is CancellationError {} catch { failure = "تعذر تنفيذ الحركة".localized }
        }
    }

    private func act(_ action: (inout TrexMatch) throws -> Void) {
        do { try action(&game); failure = nil; revision += 1 }
        catch { failure = "هذه الحركة غير مسموحة".localized }
    }
}

private struct HandOriginalPlayView: View {
    @State private var game = HandMatch(seed: UInt64.random(in: 1...UInt64.max))
    @State private var selected: Set<Int> = []
    @State private var batches: [HandMatch.Meld] = []
    @State private var revision = 0
    @State private var failure: String?
    @Environment(\.scenePhase) private var scenePhase
    private var arranging: Bool { game.turn == 0 && game.phase == .arrange }
    private var selectedCards: [StandardCard] { game.hands[0].filter { selected.contains($0.id) } }
    private var reserved: Set<Int> { Set(batches.flatMap(\.cards).map(\.id)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(String(format: "الجولة %lld من 5".localized, game.round)).font(.headline)
                OriginalSeats(hands: game.hands, scores: game.scores, turn: game.turn)
                HStack(alignment: .top, spacing: 18) {
                    VStack {
                        Text("المخزون".localized)
                        Button { act { try $0.draw(fromDiscard: false, player: 0) } } label: {
                            VStack { Image(systemName: "rectangle.stack.fill").font(.largeTitle); Text("\(game.stock.count)") }.frame(width: 70, height: 84)
                        }.buttonStyle(.bordered).disabled(game.turn != 0 || game.phase != .draw)
                    }
                    VStack {
                        Text("المكشوف".localized)
                        if let card = game.discardPile.last {
                            Button { act { try $0.draw(fromDiscard: true, player: 0) } } label: { OriginalCardTile(card: card) }
                                .buttonStyle(.plain).disabled(game.turn != 0 || game.phase != .draw)
                        }
                    }
                }.frame(maxWidth: .infinity)
                if game.turn != 0 && (game.phase == .draw || game.phase == .arrange) {
                    ProgressView(originalPlayerName(game.turn)).frame(maxWidth: .infinity)
                }
                if arranging {
                    Text(game.mustDiscardFirst ? "البادي يرمي ورقة دون سحب أو إنزال".localized : game.opened[0] ? "دورك: إنزال أو تركيب ثم رمي".localized : "الإنزال الأول: 51 نقطة على الأقل".localized).font(.headline)
                    OriginalHandGrid(cards: game.hands[0], enabled: Set(game.hands[0].map(\.id)).subtracting(reserved), selected: selected) { card in
                        if !selected.insert(card.id).inserted { selected.remove(card.id) }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))]) {
                        Button("إضافة مجموعة".localized) {
                            guard let meld = HandMatch.validate(selectedCards, preferredKind: .set) else { failure = "حدد مجموعة أو تسلسلا صحيحا من 3 أوراق فأكثر".localized; return }
                            batches.append(meld); selected = []; failure = nil
                        }.buttonStyle(.bordered).disabled(selected.count < 3 || game.mustDiscardFirst)
                        Menu("إضافة تسلسل".localized) {
                            ForEach(Array(HandMatch.validMelds(selectedCards).filter { $0.kind == .run }.enumerated()), id: \.offset) { _, meld in
                                Button(meld.representedRanks.map { [1: "A", 11: "J", 12: "Q", 13: "K", 14: "A"][$0] ?? String($0) }.joined(separator: " - ")) {
                                    batches.append(meld); selected = []; failure = nil
                                }
                            }
                        }.buttonStyle(.bordered).disabled(game.mustDiscardFirst || !HandMatch.validMelds(selectedCards).contains { $0.kind == .run })
                        Button("اقتراح إنزال".localized) {
                            batches = game.suggestedMelds(player: 0).compactMap { HandMatch.validate($0) }; selected = []
                            failure = batches.isEmpty ? "لا يوجد إنزال صالح حاليا".localized : nil
                        }.buttonStyle(.bordered).disabled(game.mustDiscardFirst)
                        Button("رمي الورقة".localized) {
                            if let card = selectedCards.first { act { try $0.discard(card, player: 0) } }
                        }.buttonStyle(.borderedProminent).disabled(selected.count != 1 || !batches.isEmpty)
                    }
                    if !batches.isEmpty {
                        Text(String(format: "الإنزال: %lld نقطة".localized, batches.map(\.points).reduce(0, +)))
                        ForEach(batches.indices, id: \.self) { index in OriginalPlayedCards(cards: batches[index].cards, representedRanks: batches[index].representedRanks) }
                        HStack {
                            Button("تأكيد الإنزال".localized) { let pending = batches; act { try $0.layMelds(pending, player: 0) } }.buttonStyle(.borderedProminent)
                            Button("إلغاء".localized) { batches = []; selected = [] }.buttonStyle(.bordered)
                        }
                    }
                } else {
                    OriginalHandGrid(cards: game.hands[0]) { _ in }
                }
                if let failure { Text(failure).foregroundStyle(AppColor.danger).fixedSize(horizontal: false, vertical: true) }
                if game.phase == .roundEnd || game.phase == .matchEnd {
                    Text(game.phase == .matchEnd ? "انتهت المباراة".localized : "انتهت الجولة".localized).font(.headline)
                    if game.phase == .matchEnd {
                        Text("الفائز".localized + ": " + game.scores.indices.filter { game.scores[$0] == game.scores.min() }.map(originalPlayerName).joined(separator: "، "))
                    } else if let winner = game.winner { Text("الفائز".localized + ": " + originalPlayerName(winner)) }
                    if game.fullHand { Text("هاند كامل: نقاط مضاعفة".localized) }
                    if game.phase == .roundEnd {
                        Button("الجولة التالية".localized) { act { try $0.nextRound() } }.buttonStyle(.borderedProminent)
                    } else {
                        Button("مباراة جديدة".localized) { game = HandMatch(seed: .random(in: 1...UInt64.max)); revision += 1 }.buttonStyle(.borderedProminent)
                    }
                }
                if !game.melds.isEmpty { Text("المجموعات المنزلة".localized).font(.headline) }
                ForEach(game.melds) { meld in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(originalPlayerName(meld.owner)).font(.caption)
                        OriginalPlayedCards(cards: meld.cards, representedRanks: meld.representedRanks)
                        if arranging && game.opened[0] {
                            HStack {
                                Button("تركيب".localized) {
                                    if let card = selectedCards.first { act { try $0.layOff(card, onto: meld.id, player: 0) } }
                                }.buttonStyle(.bordered).disabled(selected.count != 1 || !batches.isEmpty)
                                if meld.cards.contains(where: \.isJoker) {
                                    Button("استبدال الجوكر".localized) {
                                        let cards = selectedCards; act { try $0.replaceJoker(in: meld.id, using: cards, player: 0) }
                                    }.buttonStyle(.bordered).disabled(selected.isEmpty || !batches.isEmpty)
                                }
                            }
                        }
                        Divider()
                    }
                }
            }.padding().adaptiveContentWidth()
        }
        .background(AppColor.background).navigationTitle("هاند".localized).navigationBarTitleDisplayMode(.inline)
        .task(id: "\(revision)-\(scenePhase)") {
            guard game.turn != 0, scenePhase == .active, game.phase == .draw || game.phase == .arrange else { return }
            do {
                try await Task.sleep(for: .milliseconds(450))
                let snapshot = game
                let next = try await Task.detached(priority: .userInitiated) { var next = snapshot; try next.stepAI(); return next }.value
                try Task.checkCancellation(); game = next; revision += 1
            } catch is CancellationError {} catch { failure = "تعذر تنفيذ الحركة".localized }
        }
    }

    private func act(_ action: (inout HandMatch) throws -> Void) {
        do { try action(&game); failure = nil; selected = []; batches = []; revision += 1 }
        catch { failure = "حركة غير صالحة: تحقق من حد الإنزال واحتفظ بورقة للرمي، واستخدم المكشوف المسحوب في مجموعة جديدة".localized }
    }
}

private struct SolitaireOriginalPlayView: View {
    let variant: SolitaireGame.Variant
    @State private var game: SolitaireGame
    @State private var history: [SolitaireGame] = []
    @State private var source: SolitaireGame.Pile?
    @State private var count = 1
    @State private var hintedDestination: SolitaireGame.Pile?
    @State private var failure: String?

    init(variant: SolitaireGame.Variant) {
        self.variant = variant
        _game = State(initialValue: SolitaireGame(variant: variant, seed: .random(in: 1...UInt64.max)))
    }

    private var title: String {
        switch variant { case .klondike: "كلوندايك".localized; case .freecell: "فري سيل".localized; case .spider: "سبايدر سوليتير".localized }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 22) {
                    Button { if let previous = history.popLast() { game = previous; clear() } } label: { Image(systemName: "arrow.uturn.backward") }
                        .disabled(history.isEmpty).accessibilityLabel("تراجع".localized)
                    Button {
                        if let hint = game.hint { source = hint.source; count = hint.count; hintedDestination = hint.destination; failure = nil }
                        else { failure = "لا توجد نقلة متاحة؛ افحص المخزون أو تراجع".localized }
                    } label: { Image(systemName: "lightbulb") }.accessibilityLabel("تلميح".localized)
                    Spacer()
                    Text(String(format: "الحركات: %lld".localized, game.moves)).monospacedDigit()
                }.font(.title3).buttonStyle(.bordered)
                if variant == .spider {
                    Picker("عدد الأنواع".localized, selection: Binding(get: { game.spiderSuitCount }, set: { suits in
                        history.append(game); game = SolitaireGame(variant: variant, seed: .random(in: 1...UInt64.max), spiderSuitCount: suits); clear()
                    })) {
                        Text("♠").tag(1)
                        Text("♠ ♥").tag(2)
                        Text("♠ ♥ ♣ ♦").tag(4)
                    }.pickerStyle(.segmented)
                } else if variant == .klondike {
                    Picker("عدد أوراق السحب".localized, selection: Binding(get: { game.drawCount }, set: { drawCount in
                        history.append(game); game = SolitaireGame(variant: variant, seed: .random(in: 1...UInt64.max), drawCount: drawCount); clear()
                    })) {
                        Text("1").tag(1)
                        Text("3").tag(3)
                    }.pickerStyle(.segmented)
                }
                if variant == .spider { Text(String(format: "السلاسل المكتملة: %lld من 8".localized, game.completed.count)) }
                if variant == .freecell {
                    Text("الخلايا الحرة".localized).font(.headline)
                    HStack(spacing: 8) { ForEach(0..<4, id: \.self) { index in slot(.cell(index), card: game.cells[index]) } }
                        .environment(\.layoutDirection, .leftToRight)
                }
                if variant != .spider {
                    Text("الأساسات".localized).font(.headline)
                    HStack(spacing: 8) { ForEach(0..<4, id: \.self) { index in slot(.foundation(index), card: game.foundations[index].last) } }
                        .environment(\.layoutDirection, .leftToRight)
                }
                if variant != .freecell {
                    HStack(spacing: 16) {
                        Button { act { try $0.draw() } } label: {
                            VStack { Image(systemName: "rectangle.stack.fill"); Text("\(game.stock.count)") }.frame(width: 58, height: 84)
                        }.buttonStyle(.bordered).accessibilityLabel("سحب من المخزون".localized)
                        if variant == .klondike { slot(.waste, card: game.waste.last) }
                    }
                }
                if let failure { Text(failure).foregroundStyle(AppColor.danger).fixedSize(horizontal: false, vertical: true) }
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(game.columns.indices, id: \.self) { index in
                            VStack(spacing: 3) {
                                Button { destination(.tableau(index)) } label: {
                                    Image(systemName: "arrow.down.to.line").frame(width: 58, height: 44)
                                }.buttonStyle(.plain)
                                    .background(AppColor.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                                    .accessibilityLabel(String(format: "عمود %lld".localized, index + 1))
                                    .tint(hintedDestination == .tableau(index) ? AppColor.accent : AppColor.primary)
                                if game.columns[index].isEmpty { slot(.tableau(index), card: nil) }
                                ForEach(Array(game.columns[index].enumerated()), id: \.element.value.id) { offset, card in
                                    Button {
                                        if source != nil && source != .tableau(index) { destination(.tableau(index)) }
                                        else if card.faceUp {
                                            let amount = game.columns[index].count - offset
                                            if game.movableCards(from: .tableau(index), count: amount) != nil {
                                                source = .tableau(index); count = amount; hintedDestination = nil
                                            } else { failure = "هذه السلسلة غير قابلة للنقل".localized }
                                        }
                                    } label: {
                                        if offset == game.columns[index].count - 1 {
                                            OriginalCardTile(card: card.value, selected: source == .tableau(index), faceUp: card.faceUp)
                                        } else {
                                            Text(card.faceUp ? card.value.label : "◆")
                                                .font(.system(size: 15, weight: .semibold, design: .serif))
                                                .foregroundStyle(card.faceUp ? (card.value.suit.isRed ? Color.red : Color.black) : Color.white)
                                                .frame(width: 58, height: 30)
                                                .background(card.faceUp ? Color.white : Color.indigo, in: RoundedRectangle(cornerRadius: 4))
                                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(source == .tableau(index) && offset >= game.columns[index].count - count ? AppColor.accent : .clear, lineWidth: 2))
                                        }
                                    }.buttonStyle(.plain)
                                    .accessibilityLabel(card.faceUp ? card.value.label : "ورقة مقلوبة".localized)
                                }
                            }
                        }
                    }.padding(.vertical, 4).environment(\.layoutDirection, .leftToRight)
                }
                if source != nil { Button("إلغاء التحديد".localized) { clear() }.buttonStyle(.bordered) }
                if game.won { Text("فزت!".localized).font(.title2.bold()) }
                Button("مباراة جديدة".localized) {
                    history.append(game); game = SolitaireGame(variant: variant, seed: .random(in: 1...UInt64.max), spiderSuitCount: game.spiderSuitCount, drawCount: game.drawCount); clear()
                }.buttonStyle(.bordered)
            }.padding().adaptiveContentWidth()
        }
        .background(AppColor.background).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }

    private func slot(_ pile: SolitaireGame.Pile, card: StandardCard?) -> some View {
        Button {
            if source != nil { destination(pile) }
            else if game.movableCards(from: pile) != nil { source = pile; count = 1 }
        } label: {
            if let card { OriginalCardTile(card: card, selected: source == pile || hintedDestination == pile) }
            else {
                Image(systemName: "plus").frame(width: 58, height: 84)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(hintedDestination == pile ? AppColor.accent : .gray))
            }
        }.buttonStyle(.plain)
        .accessibilityLabel(slotLabel(pile) + (card.map { ": " + $0.label } ?? ""))
    }

    private func slotLabel(_ pile: SolitaireGame.Pile) -> String {
        switch pile {
        case .tableau(let index): String(format: "عمود %lld".localized, index + 1)
        case .cell(let index): "الخلايا الحرة".localized + " \(index + 1)"
        case .foundation(let index): "الأساسات".localized + " \(index + 1)"
        case .waste: "المكشوف".localized
        }
    }

    private func destination(_ pile: SolitaireGame.Pile) {
        guard let source else { return }
        act { try $0.move(from: source, count: count, to: pile) }
    }

    private func clear() { source = nil; count = 1; hintedDestination = nil; failure = nil }

    private func act(_ action: (inout SolitaireGame) throws -> Void) {
        let previous = game
        do {
            try action(&game); history.append(previous)
            if history.count > 100 { history.removeFirst() }
            clear()
        } catch { failure = "هذه الحركة غير مسموحة".localized }
    }
}

#Preview {
    NavigationStack {
        OtherCardGamePlayView(slug: "tarneeb")
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
