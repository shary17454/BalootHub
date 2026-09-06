import Foundation

struct OtherCardGameCard: Identifiable, Hashable, Comparable {
    enum Suit: String, CaseIterable {
        case spade
        case diamond
        case heart
        case club

        var title: String {
            switch self {
            case .spade: "سبيت"
            case .diamond: "ديمن"
            case .heart: "هاص"
            case .club: "شريا"
            }
        }

        var symbolName: String {
            switch self {
            case .spade: "suit.spade.fill"
            case .diamond: "suit.diamond.fill"
            case .heart: "suit.heart.fill"
            case .club: "suit.club.fill"
            }
        }

        var isRed: Bool { self == .diamond || self == .heart }
    }

    enum Rank: Int, CaseIterable, Comparable {
        case two = 2
        case three = 3
        case four = 4
        case five = 5
        case six = 6
        case seven = 7
        case eight = 8
        case nine = 9
        case ten = 10
        case jack = 11
        case queen = 12
        case king = 13
        case ace = 14

        static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var title: String {
            switch self {
            case .jack: "J"
            case .queen: "Q"
            case .king: "K"
            case .ace: "A"
            default: String(rawValue)
            }
        }
    }

    let suit: Suit
    let rank: Rank

    var id: String { "\(suit.rawValue)-\(rank.rawValue)" }

    static func < (lhs: OtherCardGameCard, rhs: OtherCardGameCard) -> Bool {
        if lhs.suit.rawValue == rhs.suit.rawValue {
            return lhs.rank < rhs.rank
        }
        return lhs.suit.rawValue < rhs.suit.rawValue
    }
}

struct OtherCardGameRules: Equatable {
    enum Mode: Equatable {
        case trickTaking
        case avoidPenalty
        case matchingDiscard
        case blackjack
        case war
    }

    let slug: String
    let title: String
    let mode: Mode
    let playerCount: Int
    let cardsPerPlayer: Int
    let allowsTrump: Bool
    let penaltySuit: OtherCardGameCard.Suit?

    var goalText: String {
        switch mode {
        case .trickTaking:
            allowsTrump ? "اكسب أكبر عدد من الأكلات مع احترام اللون المطلوب والحكم." : "اكسب أكبر عدد من الأكلات مع احترام اللون المطلوب."
        case .avoidPenalty:
            "تجنب أوراق العقوبة، خصوصًا الهاص والملكات."
        case .matchingDiscard:
            "تخلص من أوراقك بمطابقة الرقم أو النوع، والثمانية ورقة حرة."
        case .blackjack:
            "اقترب من 21 دون تجاوزها وتغلب على يد الموزع."
        case .war:
            "اكسب المواجهة الأعلى ورقة حتى تنتهي الحزمة."
        }
    }

    static func rules(for slug: String, title: String) -> OtherCardGameRules {
        switch slug {
        case "hand", "crazy-eights", "old-maid", "go-fish", "rummy", "gin-rummy", "canasta", "president", "durak", "basra":
            OtherCardGameRules(slug: slug, title: title, mode: .matchingDiscard, playerCount: 4, cardsPerPlayer: 7, allowsTrump: false, penaltySuit: nil)
        case "blackjack", "poker-texas-holdem":
            OtherCardGameRules(slug: slug, title: title, mode: .blackjack, playerCount: 2, cardsPerPlayer: 2, allowsTrump: false, penaltySuit: nil)
        case "war", "solitaire-klondike", "freecell", "spider-solitaire":
            OtherCardGameRules(slug: slug, title: title, mode: .war, playerCount: 2, cardsPerPlayer: 26, allowsTrump: false, penaltySuit: nil)
        case "hearts", "kout-bou-sitta":
            OtherCardGameRules(slug: slug, title: title, mode: .avoidPenalty, playerCount: 4, cardsPerPlayer: 13, allowsTrump: false, penaltySuit: .heart)
        case "tarneeb", "spades", "bridge", "hokm", "estimation":
            OtherCardGameRules(slug: slug, title: title, mode: .trickTaking, playerCount: 4, cardsPerPlayer: 13, allowsTrump: true, penaltySuit: nil)
        default:
            OtherCardGameRules(slug: slug, title: title, mode: .trickTaking, playerCount: 4, cardsPerPlayer: 13, allowsTrump: false, penaltySuit: nil)
        }
    }
}

struct OtherCardGamePlayer: Identifiable, Equatable {
    let id: Int
    let name: String
    var hand: [OtherCardGameCard]
    var wonCards: [OtherCardGameCard] = []
    var score: Int = 0
}

struct OtherCardGameTableState {
    let rules: OtherCardGameRules
    var players: [OtherCardGamePlayer]
    var drawPile: [OtherCardGameCard]
    var discardPile: [OtherCardGameCard]
    var currentTrick: [(playerID: Int, card: OtherCardGameCard)]
    var currentPlayerID: Int
    var trumpSuit: OtherCardGameCard.Suit?
    var message: String
    var roundFinished: Bool
    var userStand: Bool

    var user: OtherCardGamePlayer { players[0] }
    var legalCardsForUser: [OtherCardGameCard] {
        OtherCardGameEngine.legalCards(for: user, in: self)
    }
}

enum OtherCardGameEngine {
    static func newGame(slug: String, title: String, seed: UInt64 = 7_341) -> OtherCardGameTableState {
        let rules = OtherCardGameRules.rules(for: slug, title: title)
        var deck = shuffledDeck(seed: seed ^ UInt64(abs(slug.hashStable)))
        let trump = rules.allowsTrump ? deck.first?.suit : nil
        var players: [OtherCardGamePlayer] = (0..<rules.playerCount).map {
            OtherCardGamePlayer(id: $0, name: $0 == 0 ? "أنت" : "لاعب \($0 + 1)", hand: [])
        }

        for cardIndex in 0..<rules.cardsPerPlayer {
            for playerIndex in players.indices where !deck.isEmpty {
                let card = deck.removeFirst()
                players[playerIndex].hand.append(card)
            }
            if cardIndex > 0, rules.mode == .blackjack { break }
        }
        for index in players.indices {
            players[index].hand.sort()
        }

        var discardPile: [OtherCardGameCard] = []
        if rules.mode == .matchingDiscard, !deck.isEmpty {
            discardPile.append(deck.removeFirst())
        }

        return OtherCardGameTableState(
            rules: rules,
            players: players,
            drawPile: deck,
            discardPile: discardPile,
            currentTrick: [],
            currentPlayerID: 0,
            trumpSuit: trump,
            message: rules.goalText,
            roundFinished: false,
            userStand: false
        )
    }

    static func legalCards(for player: OtherCardGamePlayer, in state: OtherCardGameTableState) -> [OtherCardGameCard] {
        switch state.rules.mode {
        case .matchingDiscard:
            guard let top = state.discardPile.last else { return player.hand }
            let legal = player.hand.filter { $0.suit == top.suit || $0.rank == top.rank || $0.rank == .eight }
            return legal.isEmpty ? [] : legal
        case .blackjack, .war:
            return player.hand
        case .trickTaking, .avoidPenalty:
            guard let leadSuit = state.currentTrick.first?.card.suit else { return player.hand }
            let matching = player.hand.filter { $0.suit == leadSuit }
            return matching.isEmpty ? player.hand : matching
        }
    }

    static func playUserCard(_ card: OtherCardGameCard, in state: inout OtherCardGameTableState) {
        guard !state.roundFinished else { return }
        guard state.currentPlayerID == 0 else {
            advanceAI(in: &state)
            return
        }
        guard state.legalCardsForUser.contains(card), let index = state.players[0].hand.firstIndex(of: card) else {
            state.message = "هذه الورقة غير قانونية الآن. يجب اتباع النوع المطلوب أو مطابقة الورقة المفتوحة حسب اللعبة."
            return
        }

        switch state.rules.mode {
        case .matchingDiscard:
            state.discardPile.append(state.players[0].hand.remove(at: index))
            state.message = "لعبت \(card.rank.title) \(card.suit.title)."
            state.currentPlayerID = nextPlayer(after: 0, in: state)
            advanceAI(in: &state)
        case .blackjack:
            state.message = "اختر اسحب أو توقف في بلاك جاك."
        case .war:
            resolveWarTurn(in: &state)
        case .trickTaking, .avoidPenalty:
            state.currentTrick.append((0, state.players[0].hand.remove(at: index)))
            state.currentPlayerID = nextPlayer(after: 0, in: state)
            advanceAI(in: &state)
        }

        finishIfNeeded(&state)
    }

    static func drawForUser(in state: inout OtherCardGameTableState) {
        guard !state.drawPile.isEmpty, !state.roundFinished else { return }
        switch state.rules.mode {
        case .matchingDiscard:
            let card = state.drawPile.removeFirst()
            state.players[0].hand.append(card)
            state.players[0].hand.sort()
            state.message = "سحبت ورقة. إذا أصبحت لديك ورقة قانونية العبها."
        case .blackjack:
            let card = state.drawPile.removeFirst()
            state.players[0].hand.append(card)
            let value = blackjackValue(state.players[0].hand)
            state.message = value > 21 ? "تجاوزت 21. فاز الموزع." : "مجموعك الآن \(value)."
            if value > 21 { state.roundFinished = true }
        default:
            state.message = "السحب متاح فقط في ألعاب المطابقة وبلاك جاك."
        }
    }

    static func standUser(in state: inout OtherCardGameTableState) {
        guard state.rules.mode == .blackjack, !state.roundFinished else { return }
        state.userStand = true
        while blackjackValue(state.players[1].hand) < 17, !state.drawPile.isEmpty {
            state.players[1].hand.append(state.drawPile.removeFirst())
        }
        let userValue = blackjackValue(state.players[0].hand)
        let dealerValue = blackjackValue(state.players[1].hand)
        if dealerValue > 21 || userValue > dealerValue {
            state.players[0].score += 1
            state.message = "فزت: مجموعك \(userValue)، الموزع \(dealerValue)."
        } else if userValue == dealerValue {
            state.message = "تعادل: \(userValue) لكل طرف."
        } else {
            state.players[1].score += 1
            state.message = "فاز الموزع: مجموعك \(userValue)، الموزع \(dealerValue)."
        }
        state.roundFinished = true
    }

    static func advanceAI(in state: inout OtherCardGameTableState) {
        var guardCounter = 0
        while state.currentPlayerID != 0, !state.roundFinished, guardCounter < 20 {
            guardCounter += 1
            let playerIndex = state.currentPlayerID
            switch state.rules.mode {
            case .matchingDiscard:
                let legal = legalCards(for: state.players[playerIndex], in: state)
                if let card = legal.sorted().first, let handIndex = state.players[playerIndex].hand.firstIndex(of: card) {
                    state.discardPile.append(state.players[playerIndex].hand.remove(at: handIndex))
                    state.message = "\(state.players[playerIndex].name) لعب \(card.rank.title) \(card.suit.title)."
                } else if !state.drawPile.isEmpty {
                    state.players[playerIndex].hand.append(state.drawPile.removeFirst())
                    state.players[playerIndex].hand.sort()
                    state.message = "\(state.players[playerIndex].name) سحب ورقة."
                }
                state.currentPlayerID = nextPlayer(after: playerIndex, in: state)
            case .trickTaking, .avoidPenalty:
                let legal = legalCards(for: state.players[playerIndex], in: state)
                guard let card = aiCard(from: legal, state: state), let handIndex = state.players[playerIndex].hand.firstIndex(of: card) else {
                    state.roundFinished = true
                    break
                }
                state.currentTrick.append((playerIndex, state.players[playerIndex].hand.remove(at: handIndex)))
                if state.currentTrick.count == state.rules.playerCount {
                    resolveTrick(in: &state)
                } else {
                    state.currentPlayerID = nextPlayer(after: playerIndex, in: state)
                }
            case .blackjack, .war:
                state.currentPlayerID = 0
            }
            finishIfNeeded(&state)
        }
    }

    private static func resolveTrick(in state: inout OtherCardGameTableState) {
        guard let winner = trickWinner(in: state) else { return }
        let cards = state.currentTrick.map(\.card)
        state.players[winner].wonCards += cards
        switch state.rules.mode {
        case .avoidPenalty:
            state.players[winner].score += cards.reduce(0) { partial, card in
                partial + ((card.suit == state.rules.penaltySuit) ? 1 : 0) + (card.rank == .queen ? 5 : 0)
            }
        default:
            state.players[winner].score += 1
        }
        state.currentTrick.removeAll()
        state.currentPlayerID = winner
        state.message = "\(state.players[winner].name) كسب الأكلة."
    }

    private static func resolveWarTurn(in state: inout OtherCardGameTableState) {
        guard !state.players[0].hand.isEmpty, !state.players[1].hand.isEmpty else {
            finishIfNeeded(&state)
            return
        }
        let user = state.players[0].hand.removeFirst()
        let dealer = state.players[1].hand.removeFirst()
        if user.rank >= dealer.rank {
            state.players[0].score += 1
            state.message = "ورقتك \(user.rank.title) أعلى من \(dealer.rank.title)."
        } else {
            state.players[1].score += 1
            state.message = "ورقة الخصم \(dealer.rank.title) أعلى من \(user.rank.title)."
        }
        finishIfNeeded(&state)
    }

    private static func finishIfNeeded(_ state: inout OtherCardGameTableState) {
        switch state.rules.mode {
        case .matchingDiscard:
            if let winner = state.players.first(where: { $0.hand.isEmpty }) {
                state.roundFinished = true
                state.message = "\(winner.name) أنهى أوراقه وفاز بالجولة."
            }
        case .trickTaking, .avoidPenalty:
            if state.players.allSatisfy({ $0.hand.isEmpty }) && state.currentTrick.isEmpty {
                state.roundFinished = true
                let winner = state.rules.mode == .avoidPenalty
                    ? state.players.min { $0.score < $1.score }
                    : state.players.max { $0.score < $1.score }
                if let winner {
                    state.message = "\(winner.name) فاز بالجولة."
                }
            }
        case .blackjack:
            break
        case .war:
            if state.players[0].hand.isEmpty || state.players[1].hand.isEmpty {
                state.roundFinished = true
                state.message = state.players[0].score >= state.players[1].score ? "فزت بجولة الحرب." : "فاز الخصم بجولة الحرب."
            }
        }
    }

    private static func trickWinner(in state: OtherCardGameTableState) -> Int? {
        guard let lead = state.currentTrick.first else { return nil }
        return state.currentTrick.max { lhs, rhs in
            trickStrength(lhs.card, leadSuit: lead.card.suit, trumpSuit: state.trumpSuit) <
                trickStrength(rhs.card, leadSuit: lead.card.suit, trumpSuit: state.trumpSuit)
        }?.playerID
    }

    private static func trickStrength(_ card: OtherCardGameCard, leadSuit: OtherCardGameCard.Suit, trumpSuit: OtherCardGameCard.Suit?) -> Int {
        let base = card.rank.rawValue
        if let trumpSuit, card.suit == trumpSuit { return 200 + base }
        if card.suit == leadSuit { return 100 + base }
        return base
    }

    private static func aiCard(from cards: [OtherCardGameCard], state: OtherCardGameTableState) -> OtherCardGameCard? {
        switch state.rules.mode {
        case .avoidPenalty:
            cards.sorted().first
        default:
            cards.sorted().first
        }
    }

    private static func nextPlayer(after playerID: Int, in state: OtherCardGameTableState) -> Int {
        (playerID + 1) % state.players.count
    }

    private static func blackjackValue(_ cards: [OtherCardGameCard]) -> Int {
        var total = 0
        var aces = 0
        for card in cards {
            switch card.rank {
            case .jack, .queen, .king:
                total += 10
            case .ace:
                total += 11
                aces += 1
            default:
                total += card.rank.rawValue
            }
        }
        while total > 21, aces > 0 {
            total -= 10
            aces -= 1
        }
        return total
    }

    private static func shuffledDeck(seed: UInt64) -> [OtherCardGameCard] {
        var generator = StableRandom(seed: seed)
        var deck = OtherCardGameCard.Suit.allCases.flatMap { suit in
            OtherCardGameCard.Rank.allCases.map { rank in
                OtherCardGameCard(suit: suit, rank: rank)
            }
        }
        for index in deck.indices.reversed() {
            let target = Int(generator.next() % UInt64(index + 1))
            deck.swapAt(index, target)
        }
        return deck
    }
}

private struct StableRandom {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private extension String {
    var hashStable: Int {
        unicodeScalars.reduce(0) { partial, scalar in
            ((partial &* 31) &+ Int(scalar.value)) & 0x7fff_ffff
        }
    }
}
