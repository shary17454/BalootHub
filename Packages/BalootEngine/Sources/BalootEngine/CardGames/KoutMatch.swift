import Foundation

/// Six seats run counterclockwise; even and odd seats form the two teams.
public struct KoutMatch: Sendable {
    public enum Phase: Sendable { case bidding, trump, playing, roundEnd, matchEnd }
    public internal(set) var hands: [[StandardCard]] = []
    public private(set) var scores = [0, 0]
    public internal(set) var tricksWon = [0, 0]
    public private(set) var dealer = 5
    public private(set) var turn = 0
    public private(set) var bidder = 0
    public private(set) var bid = 0
    public private(set) var forcedBid = false
    public private(set) var trump: Suit?
    public private(set) var phase: Phase = .bidding
    public private(set) var trick: [(player: Int, card: StandardCard)] = []
    public private(set) var captured: [StandardCard] = []
    public private(set) var lastTrick: [StandardCard] = []
    public private(set) var round = 1
    private var bidsTaken = 0
    private var seed: UInt64
    private var leadSuit: Suit?
    private var demotedJokers: Set<Int> = []

    public init(seed: UInt64) { self.seed = seed; deal() }

    private mutating func deal() {
        let deck = StandardCard.deck(jokers: 2, seed: seed)
        hands = (0..<6).map { Array(deck[$0 * 9..<($0 + 1) * 9]) }
        turn = (dealer + 1) % 6; bidder = turn; bid = 0; bidsTaken = 0
        forcedBid = false; trump = nil; phase = .bidding; tricksWon = [0, 0]
        trick = []; captured = []; lastTrick = []; leadSuit = nil; demotedJokers = []
    }

    public var legalBids: [Int] {
        guard phase == .bidding, bid < 9 else { return [] }
        return Array(max(5, bid + 1)...9)
    }

    public mutating func offer(_ value: Int?, player: Int) throws {
        guard phase == .bidding else { throw CardGameError.wrongPhase }
        guard player == turn else { throw CardGameError.wrongTurn }
        if let value {
            guard legalBids.contains(value) else { throw CardGameError.illegalMove }
            bid = value; bidder = player
        }
        bidsTaken += 1
        if bidsTaken == 6 || bid == 9 {
            if bid == 0 { bid = 5; bidder = player; forcedBid = true }
            turn = bidder; phase = .trump
        } else { turn = (turn + 1) % 6 }
    }

    public mutating func selectTrump(_ suit: Suit, player: Int) throws {
        guard phase == .trump else { throw CardGameError.wrongPhase }
        guard player == bidder else { throw CardGameError.wrongTurn }
        trump = suit; phase = .playing
    }

    private func mayLead(_ card: StandardCard) -> Bool {
        guard card.isJoker, let trump else { return true }
        if bid == 9 || (bid == 8 && card.joker == 2) { return true }
        return [1, 11, 12, 13].allSatisfy { rank in captured.contains { $0.suit == trump && $0.rank == rank && !$0.isJoker } }
    }

    public func legalCards(player: Int) -> [StandardCard] {
        guard phase == .playing, turn == player, hands.indices.contains(player) else { return [] }
        if let leadSuit {
            let matching = hands[player].filter { !$0.isJoker && $0.suit == leadSuit }
            return matching.isEmpty ? hands[player] : matching + hands[player].filter(\.isJoker)
        }
        let permitted = hands[player].filter { mayLead($0) }
        return permitted.isEmpty ? hands[player] : permitted
    }

    public mutating func play(_ card: StandardCard, player: Int) throws {
        guard legalCards(player: player).contains(card), let index = hands[player].firstIndex(of: card) else { throw CardGameError.illegalMove }
        hands[player].remove(at: index)
        if leadSuit == nil {
            if card.isJoker {
                if mayLead(card) { leadSuit = trump } else { demotedJokers.insert(card.id) }
            } else { leadSuit = card.suit }
        }
        trick.append((player, card))
        if trick.count < 6 { turn = (turn + 1) % 6; return }
        let winner = trick.max { strength($0.card) < strength($1.card) }!.player
        tricksWon[winner % 2] += 1
        lastTrick = trick.map(\.card); captured += lastTrick; trick = []
        leadSuit = nil; demotedJokers = []; turn = winner
        let team = bidder % 2
        let remaining = 9 - tricksWon.reduce(0, +)
        if tricksWon[team] >= bid || tricksWon[team] + remaining < bid {
            let succeeded = tricksWon[team] >= bid
            if succeeded { scores[team] += bid == 9 ? 36 : bid } else { scores[1 - team] += forcedBid ? 5 : bid * 2 }
            let shutout = (scores[0] >= 51 && scores[1] == 0) || (scores[1] >= 51 && scores[0] == 0)
            phase = scores.contains(where: { $0 >= 101 }) || shutout || (round == 1 && bid == 9 && succeeded) ? .matchEnd : .roundEnd
        }
    }

    private func strength(_ card: StandardCard) -> Int {
        if demotedJokers.contains(card.id) { return -1 }
        if card.joker == 2 { return 400 }
        if card.suit == trump && card.rank == 1 { return 350 }
        if card.joker == 1 { return 300 }
        if card.suit == trump { return 200 + card.highRank }
        if card.suit == leadSuit { return 100 + card.highRank }
        return 0
    }

    public mutating func nextRound() throws {
        guard phase == .roundEnd else { throw CardGameError.wrongPhase }
        round += 1; dealer = (dealer + 1) % 6; seed &+= 1; deal()
    }

    public mutating func stepAI() throws {
        switch phase {
        case .bidding:
            let strong = hands[turn].filter { $0.isJoker || $0.highRank >= 13 }.count
            try offer(strong >= 3 ? legalBids.first : nil, player: turn)
        case .trump:
            let hand = hands[turn]
            let suit = Suit.allCases.max { a, b in
                hand.filter { !$0.isJoker && $0.suit == a }.count < hand.filter { !$0.isJoker && $0.suit == b }.count
            }!
            try selectTrump(suit, player: turn)
        case .playing:
            let choices = legalCards(player: turn)
            guard let card = choices.min(by: { strength($0) < strength($1) }) else { throw CardGameError.illegalMove }
            try play(card, player: turn)
        default: throw CardGameError.wrongPhase
        }
    }
}
