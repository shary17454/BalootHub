import Foundation

/// Fixed-joker Hand: four individuals, five rounds, initial meld value 51.
public struct HandMatch: Sendable {
    public enum Phase: Sendable { case draw, arrange, roundEnd, matchEnd }
    public struct Meld: Identifiable, Equatable, Sendable {
        public enum Kind: Sendable { case set, run }
        public let id: Int
        public let owner: Int
        public var cards: [StandardCard]
        public var representedRanks: [Int]
        public let kind: Kind
        public var points: Int { representedRanks.reduce(0) { $0 + ($1 == 1 || $1 == 14 ? 11 : min($1, 10)) } }
    }
    public internal(set) var hands: [[StandardCard]] = []
    public private(set) var stock: [StandardCard] = []
    public internal(set) var discardPile: [StandardCard] = []
    public internal(set) var melds: [Meld] = []
    public internal(set) var opened = [false, false, false, false]
    public private(set) var scores = [0, 0, 0, 0]
    public private(set) var turn = 0
    public private(set) var round = 1
    public internal(set) var phase: Phase = .arrange
    public internal(set) var mustDiscardFirst = true
    public private(set) var winner: Int?
    public private(set) var fullHand = false
    private var seed: UInt64
    private var takenDiscardID: Int?
    private var openedAtTurnStart = false
    private var laidOffThisTurn = false

    public init(seed: UInt64) { self.seed = seed; deal() }

    private mutating func deal() {
        var deck = StandardCard.deck(copies: 2, jokers: 2, seed: seed)
        hands = (0..<4).map { _ in (0..<14).map { _ in deck.removeLast() } }
        turn = (round - 1) % 4; hands[turn].append(deck.removeLast()); stock = deck
        discardPile = []; melds = []; opened = [false, false, false, false]
        phase = .arrange; winner = nil; fullHand = false; mustDiscardFirst = true
        takenDiscardID = nil; openedAtTurnStart = false; laidOffThisTurn = false
    }

    /// Returns an ordered, unambiguous representation; Ace may be low or high, never wrap.
    public static func validate(_ cards: [StandardCard], owner: Int = 0, id: Int = 0, preferredKind: Meld.Kind? = nil) -> Meld? {
        validMelds(cards, owner: owner, id: id).filter { preferredKind == nil || $0.kind == preferredKind }.max { $0.points < $1.points }
    }

    public static func validMelds(_ cards: [StandardCard], owner: Int = 0, id: Int = 0) -> [Meld] {
        guard cards.count >= 3, Set(cards.map(\.id)).count == cards.count else { return [] }
        let natural = cards.filter { !$0.isJoker }
        let jokers = cards.filter(\.isJoker)
        guard !natural.isEmpty else { return [] }
        var result: [Meld] = []
        if cards.count <= 4, Set(natural.map(\.rank)).count == 1, Set(natural.map(\.suit)).count == natural.count {
            result.append(Meld(id: id, owner: owner, cards: natural + jokers, representedRanks: Array(repeating: natural[0].rank, count: cards.count), kind: .set))
        }
        guard Set(natural.map(\.suit)).count == 1, Set(natural.map(\.rank)).count == natural.count, cards.count <= 13 else { return result }
        for highAce in [false, true] {
            let ranks = natural.map { highAce ? $0.highRank : $0.rank }
            for start in 1...(15 - cards.count) {
                let range = Array(start..<(start + cards.count))
                guard range.last! <= (highAce ? 14 : 13), !highAce || start > 1, ranks.allSatisfy(range.contains) else { continue }
                var remainingJokers = jokers
                let ordered = range.map { rank -> StandardCard in
                    if let index = ranks.firstIndex(of: rank) { return natural[index] }
                    return remainingJokers.removeFirst()
                }
                let meld = Meld(id: id, owner: owner, cards: ordered, representedRanks: range, kind: .run)
                if !result.contains(meld) { result.append(meld) }
            }
        }
        return result
    }

    public mutating func draw(fromDiscard: Bool, player: Int) throws {
        guard phase == .draw else { throw CardGameError.wrongPhase }
        guard turn == player else { throw CardGameError.wrongTurn }
        if fromDiscard {
            guard let card = discardPile.last else { throw CardGameError.illegalMove }
            // The picked card must participate in a new meld before ending the turn.
            var proposed = self
            proposed.hands[player].append(card)
            guard !proposed.suggestedMelds(player: player, including: card.id).isEmpty else { throw CardGameError.illegalMove }
            discardPile.removeLast(); hands[player].append(card); takenDiscardID = card.id
        } else {
            if stock.isEmpty {
                guard discardPile.count > 1 else { throw CardGameError.illegalMove }
                let top = discardPile.removeLast()
                stock = discardPile; discardPile = [top]
                seed &+= 1; var generator = SeededGenerator(seed: seed); stock.shuffle(using: &generator)
            }
            hands[player].append(stock.removeLast()); takenDiscardID = nil
        }
        phase = .arrange; openedAtTurnStart = opened[player]; laidOffThisTurn = false
    }

    public mutating func lay(_ batches: [[StandardCard]], player: Int) throws {
        let groups = batches.compactMap { Self.validate($0) }
        guard groups.count == batches.count else { throw CardGameError.invalidSelection }
        try layMelds(groups, player: player)
    }

    public mutating func layMelds(_ groups: [Meld], player: Int) throws {
        guard phase == .arrange, !mustDiscardFirst else { throw CardGameError.wrongPhase }
        guard player == turn else { throw CardGameError.wrongTurn }
        let cards = groups.flatMap(\.cards)
        guard !cards.isEmpty, Set(cards.map(\.id)).count == cards.count, cards.allSatisfy(hands[player].contains), cards.count < hands[player].count else { throw CardGameError.invalidSelection }
        let validated = groups.enumerated().compactMap { offset, selected in
            Self.validMelds(selected.cards, owner: player, id: melds.count + offset).first {
                $0.kind == selected.kind && $0.cards == selected.cards && $0.representedRanks == selected.representedRanks
            }
        }
        guard validated.count == groups.count, opened[player] || validated.reduce(0, { $0 + $1.points }) >= 51 else { throw CardGameError.illegalMove }
        melds += validated; opened[player] = true
        let ids = Set(cards.map(\.id)); hands[player].removeAll { ids.contains($0.id) }
        if let takenDiscardID, ids.contains(takenDiscardID) { self.takenDiscardID = nil }
    }

    public mutating func layOff(_ card: StandardCard, onto meldID: Int, player: Int) throws {
        guard phase == .arrange, !mustDiscardFirst, player == turn, opened[player], hands[player].count > 1, hands[player].contains(card), !card.isJoker,
              let index = melds.firstIndex(where: { $0.id == meldID }) else { throw CardGameError.illegalMove }
        let old = melds[index]
        guard let updated = Self.validMelds(old.cards + [card], owner: old.owner, id: old.id).first(where: { candidate in
            candidate.kind == old.kind && old.cards.indices.filter { old.cards[$0].isJoker }.allSatisfy { offset in
                guard let position = candidate.cards.firstIndex(of: old.cards[offset]) else { return false }
                return candidate.representedRanks[position] == old.representedRanks[offset]
            }
        }) else { throw CardGameError.illegalMove }
        melds[index] = updated; hands[player].removeAll { $0.id == card.id }; laidOffThisTurn = laidOffThisTurn || old.owner != player
    }

    public mutating func replaceJoker(in meldID: Int, using cards: [StandardCard], player: Int) throws {
        guard phase == .arrange, !mustDiscardFirst, player == turn, opened[player], !cards.isEmpty, cards.allSatisfy({ !$0.isJoker && hands[player].contains($0) }), Set(cards.map(\.id)).count == cards.count,
              let index = melds.firstIndex(where: { $0.id == meldID }), melds[index].cards.contains(where: \.isJoker) else { throw CardGameError.illegalMove }
        let old = melds[index]
        let returnedJokers: [StandardCard]
        if old.kind == .run {
            guard cards.count == 1, cards[0].suit == old.cards.first(where: { !$0.isJoker })!.suit,
                  let jokerIndex = old.cards.indices.first(where: { old.cards[$0].isJoker && (cards[0].rank == old.representedRanks[$0] || cards[0].highRank == old.representedRanks[$0]) }) else { throw CardGameError.illegalMove }
            returnedJokers = [old.cards[jokerIndex]]
        } else {
            guard cards.count == 4 - old.cards.filter({ !$0.isJoker }).count else { throw CardGameError.illegalMove }
            returnedJokers = old.cards.filter(\.isJoker)
        }
        let updatedCards = old.cards.filter { !returnedJokers.contains($0) } + cards
        guard let updated = Self.validMelds(updatedCards, owner: old.owner, id: old.id).first(where: {
            $0.kind == old.kind && (old.kind == .set || $0.representedRanks == old.representedRanks)
        }) else { throw CardGameError.illegalMove }
        melds[index] = updated
        let ids = Set(cards.map(\.id)); hands[player].removeAll { ids.contains($0.id) }; hands[player] += returnedJokers; laidOffThisTurn = laidOffThisTurn || old.owner != player
    }

    public mutating func discard(_ card: StandardCard, player: Int) throws {
        guard phase == .arrange, turn == player, takenDiscardID == nil, let index = hands[player].firstIndex(of: card) else { throw CardGameError.illegalMove }
        hands[player].remove(at: index); discardPile.append(card); mustDiscardFirst = false
        if hands[player].isEmpty {
            winner = player; fullHand = !openedAtTurnStart && !laidOffThisTurn
            let factor = fullHand ? 2 : 1
            for seat in 0..<4 {
                scores[seat] += seat == player ? -30 * factor : (hands[seat].reduce(0) { $0 + Self.points($1) } + (opened[seat] ? 0 : 100)) * factor
            }
            phase = round == 5 ? .matchEnd : .roundEnd
        } else { turn = (turn + 1) % 4; phase = .draw }
    }

    public mutating func nextRound() throws {
        guard phase == .roundEnd else { throw CardGameError.wrongPhase }
        round += 1; seed &+= 1; deal()
    }

    public static func points(_ card: StandardCard) -> Int { card.isJoker ? 15 : card.rank == 1 ? 11 : min(card.rank, 10) }

    /// Bounded candidate generation, avoiding exhaustive subsets on the UI thread.
    public func candidates(in hand: [StandardCard]) -> [[StandardCard]] {
        let natural = hand.filter { !$0.isJoker }; let jokers = hand.filter(\.isJoker)
        var results: [[StandardCard]] = []
        var seen: Set<Set<Int>> = []
        func append(_ cards: [StandardCard]) {
            let ids = Set(cards.map(\.id))
            if Self.validate(cards) != nil && seen.insert(ids).inserted { results.append(cards) }
        }
        for rank in 1...13 {
            let group = natural.filter { $0.rank == rank }
            guard !group.isEmpty else { continue }
            for mask in 1..<(1 << group.count) where mask.nonzeroBitCount <= 4 {
                let cards = group.indices.filter { mask & (1 << $0) != 0 }.map { group[$0] }
                for count in 0...min(jokers.count, 4 - cards.count) { append(cards + jokers.prefix(count)) }
            }
        }
        for suit in Suit.allCases {
            let suited = natural.filter { $0.suit == suit }
            func buildRun(_ rank: Int, through end: Int, cards: [StandardCard], spareJokers: [StandardCard]) {
                if rank > end { append(cards); return }
                for card in suited where card.rank == (rank == 14 ? 1 : rank) && !cards.contains(card) {
                    buildRun(rank + 1, through: end, cards: cards + [card], spareJokers: spareJokers)
                }
                for joker in spareJokers {
                    buildRun(rank + 1, through: end, cards: cards + [joker], spareJokers: spareJokers.filter { $0.id != joker.id })
                }
            }
            for start in 1...12 {
                for end in (start + 2)...min(14, start + 12) {
                    buildRun(start, through: end, cards: [], spareJokers: jokers)
                }
            }
        }
        return results.sorted { $0.count > $1.count }
    }

    public func suggestedMelds(player: Int, including requiredID: Int? = nil) -> [[StandardCard]] {
        guard hands.indices.contains(player) else { return [] }
        let requiredID = requiredID ?? (player == turn ? takenDiscardID : nil)
        let options = candidates(in: hands[player]); var best: [[StandardCard]] = []; var bestCount = 0; var visits = 0
        func search(_ start: Int, _ selected: [[StandardCard]], _ ids: Set<Int>, _ points: Int) {
            visits += 1
            // Suggestions have a work budget; legality checks for a picked discard do not.
            if requiredID == nil && visits > 2_000 { return }
            if requiredID != nil && !best.isEmpty { return }
            if opened[player] || points >= 51, ids.count > bestCount, ids.count < hands[player].count,
               requiredID.map(ids.contains) ?? true {
                best = selected; bestCount = ids.count
            }
            guard start < options.count else { return }
            for index in start..<options.count {
                let nextIDs = Set(options[index].map(\.id))
                guard ids.isDisjoint(with: nextIDs), ids.count + nextIDs.count < hands[player].count else { continue }
                search(index + 1, selected + [options[index]], ids.union(nextIDs), points + Self.validate(options[index])!.points)
            }
        }
        search(0, [], [], 0); return best
    }

    public mutating func stepAI() throws {
        if phase == .draw { try draw(fromDiscard: false, player: turn); return }
        guard phase == .arrange else { throw CardGameError.wrongPhase }
        let player = turn; let batches = mustDiscardFirst ? [] : suggestedMelds(player: player)
        if !batches.isEmpty { try lay(batches, player: player) }
        if opened[player] {
            for card in hands[player] {
                for meld in melds {
                    if (try? layOff(card, onto: meld.id, player: player)) != nil { break }
                }
            }
        }
        guard let card = hands[player].max(by: { Self.points($0) < Self.points($1) }) else { throw CardGameError.illegalMove }
        try discard(card, player: player)
    }
}
