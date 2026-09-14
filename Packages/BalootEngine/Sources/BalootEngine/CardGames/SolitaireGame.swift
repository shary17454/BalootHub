import Foundation

public struct SolitaireGame: Sendable {
    public enum Variant: String, Sendable { case klondike, freecell, spider }
    public enum Pile: Hashable, Sendable { case tableau(Int), cell(Int), foundation(Int), waste }
    public struct Card: Equatable, Sendable {
        public let value: StandardCard
        public var faceUp: Bool
    }
    public let variant: Variant
    public let spiderSuitCount: Int
    public let drawCount: Int
    public internal(set) var columns: [[Card]]
    public internal(set) var cells: [StandardCard?] = Array(repeating: nil, count: 4)
    public internal(set) var foundations: [[StandardCard]] = Array(repeating: [], count: 4)
    public internal(set) var stock: [StandardCard]
    public private(set) var waste: [StandardCard] = []
    public private(set) var completed: [[StandardCard]] = []
    public private(set) var moves = 0
    public var won: Bool { variant == .spider ? completed.count == 8 : foundations.reduce(0) { $0 + $1.count } == 52 }

    public init(variant: Variant, seed: UInt64, spiderSuitCount: Int = 1, drawCount: Int = 1) {
        self.variant = variant
        self.spiderSuitCount = [1, 2, 4].contains(spiderSuitCount) ? spiderSuitCount : 1
        self.drawCount = drawCount == 3 ? 3 : 1
        var deck = StandardCard.deck(copies: variant == .spider ? 2 : 1, seed: seed)
        if variant == .spider {
            let suits: [Suit] = self.spiderSuitCount == 1 ? [.spades] : self.spiderSuitCount == 2 ? [.spades, .hearts] : Suit.allCases
            deck = deck.map { StandardCard(id: $0.id, suit: suits[$0.suit.ordinal % suits.count], rank: $0.rank) }
        }
        columns = []
        switch variant {
        case .klondike:
            for count in 1...7 {
                columns.append((0..<count).map { index in Card(value: deck.removeLast(), faceUp: index == count - 1) })
            }
        case .freecell:
            for index in 0..<8 { columns.append((0..<(index < 4 ? 7 : 6)).map { _ in Card(value: deck.removeLast(), faceUp: true) }) }
        case .spider:
            for index in 0..<10 {
                let count = index < 4 ? 6 : 5
                columns.append((0..<count).map { offset in Card(value: deck.removeLast(), faceUp: offset == count - 1) })
            }
        }
        stock = deck
    }

    public mutating func draw() throws {
        guard !won, variant != .freecell else { throw CardGameError.wrongPhase }
        if variant == .spider {
            guard stock.count >= 10, columns.allSatisfy({ !$0.isEmpty }) else { throw CardGameError.illegalMove }
            for index in columns.indices { columns[index].append(Card(value: stock.removeLast(), faceUp: true)) }
            collectSpider()
        } else if !stock.isEmpty {
            for _ in 0..<min(drawCount, stock.count) { waste.append(stock.removeLast()) }
        }
        else {
            guard !waste.isEmpty else { throw CardGameError.illegalMove }
            stock = waste.reversed(); waste = []
        }
        moves += 1
    }

    public func movableCards(from source: Pile, count: Int = 1) -> [StandardCard]? {
        guard count > 0 else { return nil }
        switch source {
        case .tableau(let index):
            guard columns.indices.contains(index), count <= columns[index].count else { return nil }
            let cards = Array(columns[index].suffix(count))
            guard cards.allSatisfy(\.faceUp) else { return nil }
            for pair in zip(cards, cards.dropFirst()) {
                guard pair.0.value.rank == pair.1.value.rank + 1 else { return nil }
                if variant == .spider {
                    guard pair.0.value.suit == pair.1.value.suit else { return nil }
                } else if pair.0.value.suit.isRed == pair.1.value.suit.isRed { return nil }
            }
            return cards.map(\.value)
        case .cell(let index):
            guard variant == .freecell, count == 1, cells.indices.contains(index), let card = cells[index] else { return nil }
            return [card]
        case .foundation(let index):
            guard variant == .klondike, count == 1, foundations.indices.contains(index), let card = foundations[index].last else { return nil }
            return [card]
        case .waste:
            guard variant == .klondike, count == 1, let card = waste.last else { return nil }
            return [card]
        }
    }

    public func canMove(from source: Pile, count: Int = 1, to destination: Pile) -> Bool {
        guard !won, source != destination, let cards = movableCards(from: source, count: count), let first = cards.first else { return false }
        switch destination {
        case .tableau(let index):
            guard columns.indices.contains(index) else { return false }
            if variant == .freecell {
                let emptyColumns = columns.indices.filter { columns[$0].isEmpty && $0 != index }.count
                let capacity = (cells.filter { $0 == nil }.count + 1) * (1 << emptyColumns)
                guard count <= capacity else { return false }
            }
            guard let top = columns[index].last else { return variant != .klondike || first.rank == 13 }
            return top.faceUp && top.value.rank == first.rank + 1 && (variant == .spider || top.value.suit.isRed != first.suit.isRed)
        case .cell(let index): return variant == .freecell && count == 1 && cells.indices.contains(index) && cells[index] == nil
        case .foundation(let index):
            guard variant != .spider, count == 1, foundations.indices.contains(index) else { return false }
            if let top = foundations[index].last { return top.suit == first.suit && first.rank == top.rank + 1 }
            return first.rank == 1
        case .waste: return false
        }
    }

    public mutating func move(from source: Pile, count: Int = 1, to destination: Pile) throws {
        guard canMove(from: source, count: count, to: destination), let cards = movableCards(from: source, count: count) else { throw CardGameError.illegalMove }
        switch source {
        case .tableau(let index):
            columns[index].removeLast(count)
            if !columns[index].isEmpty { columns[index][columns[index].count - 1].faceUp = true }
        case .cell(let index): cells[index] = nil
        case .foundation(let index): foundations[index].removeLast()
        case .waste: waste.removeLast()
        }
        switch destination {
        case .tableau(let index): columns[index] += cards.map { Card(value: $0, faceUp: true) }
        case .cell(let index): cells[index] = cards[0]
        case .foundation(let index): foundations[index] += cards
        case .waste: break
        }
        if variant == .spider { collectSpider() }
        moves += 1
    }

    private mutating func collectSpider() {
        for index in columns.indices {
            while columns[index].count >= 13 {
                let tail = Array(columns[index].suffix(13))
                guard tail.allSatisfy(\.faceUp), tail.map({ $0.value.rank }) == Array((1...13).reversed()), Set(tail.map { $0.value.suit }).count == 1 else { break }
                completed.append(tail.map(\.value)); columns[index].removeLast(13)
                if !columns[index].isEmpty { columns[index][columns[index].count - 1].faceUp = true }
            }
        }
    }

    public var hint: (source: Pile, count: Int, destination: Pile)? {
        let destinations: [Pile] = (variant == .spider ? [] : (0..<4).map(Pile.foundation)) + columns.indices.map(Pile.tableau) + (variant == .freecell ? (0..<4).map(Pile.cell) : [])
        let sources: [Pile] = [.waste] + (0..<4).map(Pile.cell) + columns.indices.map(Pile.tableau)
        for source in sources {
            let maximum: Int
            if case .tableau(let index) = source { maximum = columns[index].count } else { maximum = 1 }
            guard maximum > 0 else { continue }
            for count in (1...maximum).reversed() {
                for destination in destinations where canMove(from: source, count: count, to: destination) {
                    if case .tableau(let sourceIndex) = source, case .tableau(let targetIndex) = destination,
                       columns[targetIndex].isEmpty, count == columns[sourceIndex].count { continue }
                    return (source, count, destination)
                }
            }
        }
        return nil
    }
}
