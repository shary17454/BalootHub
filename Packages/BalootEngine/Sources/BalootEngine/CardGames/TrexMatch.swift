import Foundation

/// Individual Trex without optional doubling, four kingdoms of five contracts.
public struct TrexMatch: Sendable {
    public enum Contract: String, CaseIterable, Sendable {
        case king, diamonds, queens, tricks, trex
        public var title: String {
            switch self {
            case .king: "شايب الهاص"
            case .diamonds: "ديمن"
            case .queens: "البنات"
            case .tricks: "اللطوش"
            case .trex: "تركس"
            }
        }
    }
    public private(set) var hands: [[StandardCard]] = []
    public private(set) var scores = [0, 0, 0, 0]
    public private(set) var kingdomOwner = 0
    public private(set) var kingdomsCompleted = 0
    public private(set) var usedContracts: Set<Contract> = []
    public private(set) var contract: Contract?
    public private(set) var turn = 0
    public private(set) var trick: [(player: Int, card: StandardCard)] = []
    public private(set) var lastTrick: [StandardCard] = []
    public private(set) var captured: [[StandardCard]] = Array(repeating: [], count: 4)
    public private(set) var layout: [Suit: Set<Int>] = [:]
    public private(set) var finishOrder: [Int] = []
    public private(set) var roundFinished = false
    public var matchFinished: Bool { kingdomsCompleted == 4 }
    public var availableContracts: [Contract] { Contract.allCases.filter { !usedContracts.contains($0) } }
    private var seed: UInt64

    public init(seed: UInt64) {
        self.seed = seed
        deal()
        kingdomOwner = hands.firstIndex { $0.contains { $0.suit == .hearts && $0.rank == 7 } } ?? 0
        turn = kingdomOwner
    }

    private mutating func deal() {
        let deck = StandardCard.deck(seed: seed)
        hands = (0..<4).map { Array(deck[($0 * 13)..<(($0 + 1) * 13)]) }
        trick = []; lastTrick = []; captured = Array(repeating: [], count: 4)
        layout = [:]; finishOrder = []; contract = nil; roundFinished = false
        turn = kingdomOwner
    }

    public mutating func choose(_ choice: Contract, player: Int) throws {
        guard !matchFinished, !roundFinished, contract == nil else { throw CardGameError.wrongPhase }
        guard player == kingdomOwner else { throw CardGameError.wrongTurn }
        guard availableContracts.contains(choice) else { throw CardGameError.illegalMove }
        contract = choice
        usedContracts.insert(choice)
    }

    public func legalCards(player: Int) -> [StandardCard] {
        guard hands.indices.contains(player), player == turn, !roundFinished, let contract else { return [] }
        if contract == .trex {
            return hands[player].filter { card in
                card.rank == 11 || layout[card.suit, default: []].contains(card.highRank - 1)
                    || layout[card.suit, default: []].contains(card.highRank + 1)
            }
        }
        if let lead = trick.first {
            let matching = hands[player].filter { $0.suit == lead.card.suit }
            return matching.isEmpty ? hands[player] : matching
        }
        if contract == .king {
            let nonHearts = hands[player].filter { $0.suit != .hearts }
            if !nonHearts.isEmpty { return nonHearts }
        }
        return hands[player]
    }

    public mutating func play(_ card: StandardCard, player: Int) throws {
        guard legalCards(player: player).contains(card), let index = hands[player].firstIndex(of: card) else { throw CardGameError.illegalMove }
        hands[player].remove(at: index)
        if contract == .trex {
            layout[card.suit, default: []].insert(card.highRank)
            if hands[player].isEmpty {
                scores[player] += [200, 150, 100, 50][finishOrder.count]
                finishOrder.append(player)
            }
            if finishOrder.count == 4 { roundFinished = true } else { advanceTrexTurn() }
            return
        }
        trick.append((player, card))
        if trick.count == 4 {
            let lead = trick[0].card.suit
            let winner = trick.filter { $0.card.suit == lead }.max { $0.card.highRank < $1.card.highRank }!.player
            let cards = trick.map(\.card)
            let penalty: Int
            switch contract {
            case .king: penalty = cards.contains { $0.suit == .hearts && $0.rank == 13 } ? 75 : 0
            case .diamonds: penalty = cards.filter { $0.suit == .diamonds }.count * 10
            case .queens: penalty = cards.filter { $0.rank == 12 }.count * 25
            case .tricks: penalty = 15
            default: penalty = 0
            }
            scores[winner] -= penalty
            captured[winner] += cards; lastTrick = cards; trick = []; turn = winner
            roundFinished = hands.allSatisfy(\.isEmpty)
        } else { turn = (turn + 1) % 4 }
    }

    public mutating func pass(player: Int) throws {
        guard contract == .trex, !roundFinished, player == turn, legalCards(player: player).isEmpty else { throw CardGameError.illegalMove }
        advanceTrexTurn()
    }

    public func canRequestRedeal(player: Int) -> Bool {
        guard contract == .trex, layout.isEmpty, hands.indices.contains(player) else { return false }
        let twos = hands[player].filter { $0.rank == 2 }
        if twos.count == 4 { return true }
        guard twos.count == 3 else { return false }
        return hands[player].contains { $0.rank == 3 && !twos.map(\.suit).contains($0.suit) }
    }

    public mutating func requestRedeal(player: Int) throws {
        guard canRequestRedeal(player: player) else { throw CardGameError.illegalMove }
        seed &+= 1; deal(); contract = .trex
    }

    private mutating func advanceTrexTurn() {
        for _ in 0..<4 {
            turn = (turn + 1) % 4
            if !hands[turn].isEmpty { return }
        }
    }

    public mutating func nextRound() throws {
        guard roundFinished, !matchFinished else { throw CardGameError.wrongPhase }
        if usedContracts.count == 5 {
            kingdomsCompleted += 1
            if matchFinished { return }
            kingdomOwner = (kingdomOwner + 1) % 4
            usedContracts = []
        }
        seed &+= 1
        deal()
    }

    public mutating func stepAI() throws {
        if contract == nil { try choose(availableContracts[0], player: kingdomOwner); return }
        let choices = legalCards(player: turn).sorted { $0.highRank < $1.highRank }
        if let card = choices.first { try play(card, player: turn) } else { try pass(player: turn) }
    }
}
