import XCTest
@testable import BalootEngine

final class OriginalCardGamesTests: XCTestCase {
    private func card(_ rank: Int, _ suit: Suit = .spades, id: Int? = nil) -> StandardCard {
        StandardCard(id: id ?? suit.ordinal * 13 + rank, suit: suit, rank: rank)
    }

    func testPhysicalDecksAndDeterministicShuffle() {
        let deck = StandardCard.deck(copies: 2, jokers: 2, seed: 42)
        XCTAssertEqual(deck.count, 106)
        XCTAssertEqual(Set(deck.map(\.id)).count, 106)
        XCTAssertEqual(deck.filter(\.isJoker).count, 2)
        XCTAssertEqual(deck, StandardCard.deck(copies: 2, jokers: 2, seed: 42))
    }

    func testTrexCompleteFourKingdomsConserveCardsAndZeroSum() throws {
        for seed in UInt64(1)...12 {
            var game = TrexMatch(seed: seed)
            XCTAssertTrue(game.hands[game.kingdomOwner].contains { $0.rank == 7 && $0.suit == .hearts })
            var steps = 0; var rounds = 0
            while !game.matchFinished && steps < 4_000 {
                if game.roundFinished { rounds += 1; try game.nextRound() }
                else { try game.stepAI() }
                if game.contract == .trex {
                    XCTAssertEqual(game.hands.flatMap { $0 }.count + game.layout.values.reduce(0) { $0 + $1.count }, 52)
                } else {
                    XCTAssertEqual(game.hands.flatMap { $0 }.count + game.trick.count + game.captured.flatMap { $0 }.count, 52)
                }
                steps += 1
            }
            XCTAssertTrue(game.matchFinished)
            XCTAssertEqual(rounds, 20)
            XCTAssertEqual(game.scores.reduce(0, +), 0)
        }
    }

    func testTrexRejectsWrongOwnerAndReusedContract() throws {
        var game = TrexMatch(seed: 4)
        XCTAssertThrowsError(try game.choose(.king, player: (game.kingdomOwner + 1) % 4))
        try game.choose(.king, player: game.kingdomOwner)
        XCTAssertThrowsError(try game.choose(.trex, player: game.kingdomOwner))
        while !game.roundFinished { try game.stepAI() }
        try game.nextRound()
        XCTAssertThrowsError(try game.choose(.king, player: game.kingdomOwner))
    }

    func testKoutForcedBidAndCompleteMatches() throws {
        for seed in UInt64(1)...15 {
            var game = KoutMatch(seed: seed)
            for _ in 0..<6 { try game.offer(nil, player: game.turn) }
            XCTAssertEqual(game.bid, 5); XCTAssertTrue(game.forcedBid); XCTAssertEqual(game.bidder, 5)
            var steps = 0
            while game.phase != .matchEnd && steps < 10_000 {
                if game.phase == .roundEnd { try game.nextRound() }
                else { try game.stepAI() }
                let cards = game.hands.flatMap { $0 } + game.trick.map(\.card) + game.captured
                XCTAssertEqual(cards.count, 54); XCTAssertEqual(Set(cards.map(\.id)).count, 54)
                steps += 1
            }
            XCTAssertEqual(game.phase, .matchEnd)
        }
    }

    func testKoutBidsAreIncreasingAndCannotSkipTurn() throws {
        var game = KoutMatch(seed: 8)
        XCTAssertThrowsError(try game.offer(5, player: 1))
        try game.offer(6, player: 0)
        XCTAssertEqual(game.legalBids, [7, 8, 9])
        XCTAssertThrowsError(try game.offer(6, player: 1))
        try game.offer(9, player: 1)
        XCTAssertEqual(game.phase, .trump)
        XCTAssertThrowsError(try game.selectTrump(.spades, player: 0))
    }

    func testHandMeldValidationAndJokerValues() {
        let joker = StandardCard(id: 104, suit: .spades, rank: 0, joker: 1)
        XCTAssertNil(HandMatch.validate([card(8), card(8, id: 90), card(8, .hearts)]))
        XCTAssertNotNil(HandMatch.validate([card(8), card(8, .clubs), card(8, .hearts)]))
        XCTAssertNil(HandMatch.validate([card(13), card(1), card(2)]))
        XCTAssertNotNil(HandMatch.validate([card(12), card(13), card(1)]))
        XCTAssertNotNil(HandMatch.validate([card(1), card(2), card(3)]))
        let run = HandMatch.validate([card(9), joker, card(11)])
        XCTAssertEqual(run?.representedRanks, [9, 10, 11])
        XCTAssertEqual(run?.points, 29)
        XCTAssertNil(HandMatch.validate([card(3), joker, joker]))
    }

    func testHandTurnsAndAtomicRejection() throws {
        var game = HandMatch(seed: 3)
        XCTAssertEqual(game.hands.map(\.count), [15, 14, 14, 14])
        XCTAssertThrowsError(try game.draw(fromDiscard: false, player: 0))
        let previous = game.hands
        XCTAssertThrowsError(try game.lay([[game.hands[0][0]]], player: 0))
        XCTAssertEqual(game.hands, previous)
        try game.discard(game.hands[0][0], player: 0)
        XCTAssertEqual(game.phase, .draw); XCTAssertEqual(game.turn, 1)
        XCTAssertThrowsError(try game.draw(fromDiscard: false, player: 0))
        try game.draw(fromDiscard: false, player: 1)
        XCTAssertEqual(game.hands[1].count, 15)
    }

    func testHandCompleteFiveRoundsWithCardConservation() throws {
        for seed in UInt64(1)...20 {
            var game = HandMatch(seed: seed); var steps = 0
            while game.phase != .matchEnd && steps < 10_000 {
                if game.phase == .roundEnd { try game.nextRound() }
                else { try game.stepAI() }
                let cards = game.hands.flatMap { $0 } + game.stock + game.discardPile + game.melds.flatMap(\.cards)
                XCTAssertEqual(cards.count, 106); XCTAssertEqual(Set(cards.map(\.id)).count, 106)
                steps += 1
            }
            XCTAssertEqual(game.phase, .matchEnd, "seed \(seed), \(steps) steps")
            XCTAssertEqual(game.round, 5)
        }
    }

    func testSolitaireInitialLayoutsAndStock() throws {
        var klondike = SolitaireGame(variant: .klondike, seed: 5)
        XCTAssertEqual(klondike.columns.map(\.count), Array(1...7))
        XCTAssertEqual(klondike.columns.flatMap { $0 }.filter(\.faceUp).count, 7)
        XCTAssertEqual(klondike.stock.count, 24)
        let stock = klondike.stock
        for _ in 0..<24 { try klondike.draw() }
        try klondike.draw(); XCTAssertEqual(klondike.stock, stock)
        let freecell = SolitaireGame(variant: .freecell, seed: 5)
        XCTAssertEqual(freecell.columns.map(\.count), [7, 7, 7, 7, 6, 6, 6, 6])
        XCTAssertTrue(freecell.stock.isEmpty)
        var spider = SolitaireGame(variant: .spider, seed: 5)
        XCTAssertEqual(spider.columns.map(\.count), [6, 6, 6, 6, 5, 5, 5, 5, 5, 5])
        XCTAssertEqual(spider.stock.count, 50)
        try spider.draw(); XCTAssertEqual(spider.stock.count, 40)
    }

    func testSolitaireLegalMovesPreserveDeckAndUndoSnapshot() throws {
        for variant in [SolitaireGame.Variant.klondike, .freecell, .spider] {
            var game = SolitaireGame(variant: variant, seed: 21)
            for _ in 0..<100 {
                let before = game
                if let hint = game.hint { try game.move(from: hint.source, count: hint.count, to: hint.destination) }
                else if !game.stock.isEmpty { try game.draw() }
                else { break }
                var all: [StandardCard] = game.columns.flatMap { $0.map(\.value) }
                all.append(contentsOf: game.cells.compactMap { $0 })
                all.append(contentsOf: game.foundations.flatMap { $0 })
                all.append(contentsOf: game.stock)
                all.append(contentsOf: game.waste)
                all.append(contentsOf: game.completed.flatMap { $0 })
                XCTAssertEqual(Set(all.map(\.id)).count, variant == .spider ? 104 : 52)
                XCTAssertEqual(all.count, variant == .spider ? 104 : 52)
                XCTAssertEqual(before.moves + 1, game.moves)
            }
        }
    }

    func testKoutTrumpAceBeatsBlackJokerAndRedBeatsBoth() throws {
        for red in [false, true] {
            var game = KoutMatch(seed: 1)
            try game.offer(9, player: 0); try game.selectTrump(.spades, player: 0)
            game.hands = [
                [card(2, .diamonds)], [StandardCard(id: 104, suit: .spades, rank: 0, joker: 1)],
                [card(1)], [card(13)], [card(3, .diamonds)],
                [red ? StandardCard(id: 105, suit: .hearts, rank: 0, joker: 2) : card(4, .diamonds)]
            ]
            for _ in 0..<6 { try game.play(game.hands[game.turn][0], player: game.turn) }
            XCTAssertEqual(game.tricksWon, red ? [0, 1] : [1, 0])
        }
    }

    func testKoutIllegalForcedJokerLeadIsDemoted() throws {
        var game = KoutMatch(seed: 1)
        try game.offer(5, player: 0)
        for _ in 0..<5 { try game.offer(nil, player: game.turn) }
        try game.selectTrump(.spades, player: 0)
        let joker = StandardCard(id: 105, suit: .hearts, rank: 0, joker: 2)
        game.hands[0] = [joker, card(2, .diamonds)]
        XCTAssertFalse(game.legalCards(player: 0).contains(joker))
        game.hands = [[joker], [card(1, .diamonds)], [card(3, .diamonds)], [card(4, .diamonds)], [card(5, .diamonds)], [card(6, .diamonds)]]
        for _ in 0..<6 { try game.play(game.hands[game.turn][0], player: game.turn) }
        XCTAssertEqual(game.tricksWon, [0, 1])
    }

    func testKoutFollowSuitStillAllowsJokers() throws {
        var game = KoutMatch(seed: 1)
        try game.offer(9, player: 0); try game.selectTrump(.spades, player: 0)
        let joker = StandardCard(id: 104, suit: .spades, rank: 0, joker: 1)
        game.hands[0] = [card(3, .hearts)]
        game.hands[1] = [card(4, .hearts), card(1), joker]
        try game.play(game.hands[0][0], player: 0)
        XCTAssertEqual(Set(game.legalCards(player: 1)), [card(4, .hearts), joker])
        XCTAssertThrowsError(try game.play(card(1), player: 1))
    }

    func testKoutNineSuccessAwards36AndFirstRoundMatchWin() throws {
        var game = KoutMatch(seed: 1)
        try game.offer(9, player: 0); try game.selectTrump(.spades, player: 0)
        game.tricksWon = [8, 0]
        game.hands = [[card(1)], [card(2)], [card(3)], [card(4)], [card(5)], [card(6)]]
        for _ in 0..<6 { try game.play(game.hands[game.turn][0], player: game.turn) }
        XCTAssertEqual(game.scores, [36, 0]); XCTAssertEqual(game.phase, .matchEnd)
    }

    func testHandOpeningBatchesAndFullHandScoring() throws {
        var game = HandMatch(seed: 1)
        game.mustDiscardFirst = false
        let kings = [card(13), card(13, .hearts), card(13, .clubs)]
        let queens = [card(12), card(12, .hearts), card(12, .clubs)]
        let discard = card(2)
        game.hands = [kings + queens + [discard], [card(1, .diamonds)], [card(8)], [card(9)]]
        XCTAssertThrowsError(try game.lay([kings], player: 0))
        XCTAssertEqual(game.hands[0].count, 7)
        try game.lay([kings, queens], player: 0)
        try game.discard(discard, player: 0)
        XCTAssertTrue(game.fullHand)
        XCTAssertEqual(game.scores, [-60, 222, 216, 218])
    }

    func testHandCannotMeldFinalDiscardCard() throws {
        var game = HandMatch(seed: 1)
        game.mustDiscardFirst = false
        let set = [card(13), card(13, .hearts), card(13, .clubs)]
        game.hands[0] = set; game.opened[0] = true
        XCTAssertThrowsError(try game.lay([set], player: 0))
        XCTAssertEqual(game.hands[0], set)
    }

    func testHandDiscardPickupRequiresOpeningAndUseInNewMeld() throws {
        var game = HandMatch(seed: 1)
        game.mustDiscardFirst = false
        game.hands[0] = [card(3), card(4), card(9, .hearts)]
        game.discardPile = [card(5)]; game.phase = .draw
        XCTAssertThrowsError(try game.draw(fromDiscard: true, player: 0))
        game.opened[0] = true
        try game.draw(fromDiscard: true, player: 0)
        XCTAssertThrowsError(try game.discard(card(9, .hearts), player: 0))
        try game.lay([[card(3), card(4), card(5)]], player: 0)
        try game.discard(card(9, .hearts), player: 0)
        XCTAssertFalse(game.fullHand)
    }

    func testHandJokerReplacementInRunAndTwoJokerSet() throws {
        let black = StandardCard(id: 104, suit: .spades, rank: 0, joker: 1)
        let red = StandardCard(id: 105, suit: .hearts, rank: 0, joker: 2)
        var game = HandMatch(seed: 1); game.opened[0] = true; game.mustDiscardFirst = false
        game.melds = [HandMatch.validate([card(9), black, card(11)], id: 0)!]
        game.hands[0] = [card(10), card(3)]
        try game.replaceJoker(in: 0, using: [card(10)], player: 0)
        XCTAssertEqual(game.melds[0].representedRanks, [9, 10, 11])
        XCTAssertTrue(game.hands[0].contains(black))
        game.melds = [HandMatch.validate([card(8), card(8, .hearts), black, red], id: 0)!]
        game.hands[0] = [card(8, .clubs), card(8, .diamonds), card(3)]
        try game.replaceJoker(in: 0, using: [card(8, .clubs), card(8, .diamonds)], player: 0)
        XCTAssertEqual(game.hands[0].filter(\.isJoker).count, 2)
        XCTAssertEqual(game.melds[0].cards.count, 4)
        XCTAssertFalse(game.melds[0].cards.contains(where: \.isJoker))
    }

    func testKlondikeKingsOnlyEmptyAndAlternatingColors() throws {
        var game = SolitaireGame(variant: .klondike, seed: 1)
        game.columns = [[.init(value: card(12, .hearts), faceUp: true)], [.init(value: card(13), faceUp: true)], [], [.init(value: card(13, .diamonds), faceUp: true)]]
        XCTAssertFalse(game.canMove(from: .tableau(0), to: .tableau(2)))
        XCTAssertFalse(game.canMove(from: .tableau(0), to: .tableau(3)))
        try game.move(from: .tableau(0), to: .tableau(1))
        try game.move(from: .tableau(1), count: 2, to: .tableau(2))
        XCTAssertEqual(game.columns[2].count, 2)
    }

    func testFreeCellSupermoveCapacityExcludesDestination() throws {
        var game = SolitaireGame(variant: .freecell, seed: 1)
        game.columns = [[card(8), card(7, .hearts), card(6)].map { .init(value: $0, faceUp: true) }, [], [.init(value: card(9, .hearts), faceUp: true)]]
        game.cells = [card(2), card(3), card(4), nil]
        XCTAssertFalse(game.canMove(from: .tableau(0), count: 3, to: .tableau(1)))
        XCTAssertTrue(game.canMove(from: .tableau(0), count: 3, to: .tableau(2)))
        game.cells[2] = nil
        XCTAssertTrue(game.canMove(from: .tableau(0), count: 3, to: .tableau(1)))
    }

    func testSpiderCompletesRunsAndRefusesDealIntoEmptyColumn() throws {
        var game = SolitaireGame(variant: .spider, seed: 1)
        game.columns = [(2...13).reversed().map { .init(value: card($0), faceUp: true) }, [.init(value: card(1), faceUp: true)]]
        try game.move(from: .tableau(1), to: .tableau(0))
        XCTAssertEqual(game.completed.count, 1); XCTAssertTrue(game.columns[0].isEmpty)
        let stock = game.stock
        XCTAssertThrowsError(try game.draw()); XCTAssertEqual(game.stock, stock)
    }

    func testSolitaireFoundationOrderAndRevealingHiddenCards() throws {
        var game = SolitaireGame(variant: .klondike, seed: 1)
        game.columns = [[.init(value: card(2), faceUp: false), .init(value: card(1), faceUp: true)], [.init(value: card(3), faceUp: true)]]
        XCTAssertFalse(game.canMove(from: .tableau(1), to: .foundation(0)))
        try game.move(from: .tableau(0), to: .foundation(0))
        XCTAssertTrue(game.columns[0][0].faceUp)
        XCTAssertFalse(game.canMove(from: .tableau(1), to: .foundation(0)))
        try game.move(from: .tableau(0), to: .foundation(0))
        try game.move(from: .tableau(1), to: .foundation(0))
        XCTAssertEqual(game.foundations[0].map(\.rank), [1, 2, 3])
    }

    func testSpiderDifficultiesAndThreeCardKlondike() throws {
        for count in [1, 2, 4] {
            let game = SolitaireGame(variant: .spider, seed: 1, spiderSuitCount: count)
            let cards = game.stock + game.columns.flatMap { $0.map(\.value) }
            XCTAssertEqual(Set(cards.map(\.suit)).count, count)
            XCTAssertEqual(Set(cards.map(\.id)).count, 104)
        }
        var game = SolitaireGame(variant: .klondike, seed: 1, drawCount: 3)
        let expected = Array(game.stock.suffix(3).reversed())
        try game.draw()
        XCTAssertEqual(game.waste, expected)
        XCTAssertEqual(game.stock.count, 21)
    }

    func testHandCandidatesKeepDuplicatePhysicalRunsAvailable() {
        let game = HandMatch(seed: 1)
        let first = [card(8), card(9), card(10)]
        let second = [card(8, id: 80), card(9, id: 81), card(10, id: 82)]
        let candidates = game.candidates(in: first + second)
        XCTAssertTrue(candidates.contains { Set($0) == Set(first) })
        XCTAssertTrue(candidates.contains { Set($0) == Set(second) })
    }

    func testHandPlayerChoosesJokerPositionsWithoutSilentReassignment() throws {
        let black = StandardCard(id: 104, suit: .spades, rank: 0, joker: 1)
        let red = StandardCard(id: 105, suit: .hearts, rank: 0, joker: 2)
        let cards = [card(4), black, red]
        let choices = HandMatch.validMelds(cards)
        XCTAssertTrue(choices.contains { $0.kind == .set })
        let selected = try XCTUnwrap(choices.first { $0.kind == .run && $0.representedRanks == [4, 5, 6] })
        var game = HandMatch(seed: 1); game.opened[0] = true; game.mustDiscardFirst = false
        game.hands[0] = cards + [card(7), card(2)]
        try game.layMelds([selected], player: 0)
        XCTAssertEqual(game.melds[0].representedRanks, [4, 5, 6])
        try game.layOff(card(7), onto: 0, player: 0)
        XCTAssertEqual(game.melds[0].representedRanks, [4, 5, 6, 7])
    }

    func testHandStarterMustDiscardBeforeAnyMeld() throws {
        var game = HandMatch(seed: 1)
        let cards = [card(13), card(13, .hearts), card(13, .clubs), card(12), card(12, .hearts), card(12, .clubs)]
        game.hands[0] = cards + [card(2)]
        XCTAssertThrowsError(try game.lay([Array(cards.prefix(3)), Array(cards.suffix(3))], player: 0))
        XCTAssertEqual(game.melds.count, 0)
        try game.discard(card(2), player: 0)
        XCTAssertFalse(game.mustDiscardFirst)
        XCTAssertEqual(game.turn, 1)
        XCTAssertEqual(game.phase, .draw)
    }
}
