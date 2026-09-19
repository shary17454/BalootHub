import XCTest
import BalootEngine
@testable import BalootHub

@MainActor
final class OtherCardGameEngineTests: XCTestCase {
    func testEveryCatalogTableCanReachAnEndUsingAvailableActions() {
        for item in CatalogSeeder.previewItems().filter({ $0.category == .otherCardGame && !OtherCardGamePlayView.originalEngineSlugs.contains($0.slug) }) {
            for seed in UInt64(1)...10 {
                var state = OtherCardGameEngine.newGame(slug: item.slug, title: item.arabicTitle, seed: seed)
                for _ in 0..<600 where !state.roundFinished {
                    if state.rules.mode == .blackjack {
                        OtherCardGameEngine.standUser(in: &state)
                    } else if let card = state.legalCardsForUser.first {
                        OtherCardGameEngine.playUserCard(card, in: &state)
                    } else if OtherCardGameEngine.canDraw(in: state) {
                        OtherCardGameEngine.drawForUser(in: &state)
                    } else if OtherCardGameEngine.canPass(in: state) {
                        OtherCardGameEngine.passUser(in: &state)
                    } else {
                        break
                    }
                }
                XCTAssertTrue(state.roundFinished, "No reachable ending: \(item.slug), seed \(seed)")
            }
        }
    }

    func testOriginalEnginesHaveDedicatedRoutes() {
        XCTAssertEqual(OtherCardGamePlayView.originalEngineSlugs, ["kout-bou-sitta", "trex", "hand", "solitaire-klondike", "freecell", "spider-solitaire"])
        let games = CatalogSeeder.previewItems().filter { OtherCardGamePlayView.originalEngineSlugs.contains($0.slug) }
        XCTAssertEqual(games.count, 6)
        XCTAssertTrue(games.allSatisfy(\.isPlayable))
    }

    func testTrickTakingGamesFinishCompleteDealsAcrossSeeds() {
        for slug in ["tarneeb", "queen-spades", "seven-diamonds", "hearts", "diamonds-collector", "spades"] {
            for seed in UInt64(1)...30 {
                var state = OtherCardGameEngine.newGame(slug: slug, title: slug, seed: seed)
                for _ in 0..<52 where !state.roundFinished {
                    guard let card = state.legalCardsForUser.first else { break }
                    OtherCardGameEngine.playUserCard(card, in: &state)
                    XCTAssertLessThan(state.currentTrick.count, 4, "\(slug), seed \(seed)")
                    XCTAssertTrue(state.roundFinished || state.currentPlayerID == 0)
                }
                XCTAssertTrue(state.roundFinished, "\(slug), seed \(seed)")
                XCTAssertTrue(state.players.allSatisfy { $0.hand.isEmpty })
                XCTAssertEqual(state.players.flatMap(\.wonCards).count, 52)
                if slug == "hearts" { XCTAssertEqual(state.players.map(\.score).reduce(0, +), 26) }
                if slug == "diamonds-collector" { XCTAssertEqual(state.players.map(\.score).reduce(0, +), 13) }
            }
        }
    }

    func testSolitaireUsesDedicatedBoardsInsteadOfGenericHand() {
        let freecell = SolitaireGame(variant: .freecell, seed: 1)
        XCTAssertEqual(freecell.columns.count, 8)
        XCTAssertEqual(freecell.columns.flatMap { $0 }.count, 52)
        XCTAssertTrue(freecell.stock.isEmpty)
        let klondike = SolitaireGame(variant: .klondike, seed: 1)
        XCTAssertEqual(klondike.columns.count, 7)
        XCTAssertEqual(klondike.stock.count, 24)
        XCTAssertFalse(klondike.won)
    }

    func testUserWinningDiscardStopsBeforeOpponentsMove() {
        var state = OtherCardGameEngine.newGame(slug: "sahbiya", title: "Sahbiya")
        let card = OtherCardGameCard(suit: .heart, rank: .eight)
        state.players[0].hand = [card]
        let opponents = Array(state.players.dropFirst().map(\.hand))
        OtherCardGameEngine.playUserCard(card, in: &state)
        XCTAssertTrue(state.roundFinished)
        XCTAssertEqual(Array(state.players.dropFirst().map(\.hand)), opponents)
    }

    func testStockRecyclingPreservesVisibleCardAndCardCount() {
        var state = OtherCardGameEngine.newGame(slug: "sahbiya", title: "Sahbiya")
        let top = OtherCardGameCard(suit: .heart, rank: .king)
        let recycled = OtherCardGameCard(suit: .club, rank: .two)
        state.drawPile = []
        state.discardPile = [recycled, top]
        let count = state.user.hand.count
        XCTAssertTrue(OtherCardGameEngine.canDraw(in: state))
        OtherCardGameEngine.drawForUser(in: &state)
        XCTAssertEqual(state.discardPile, [top])
        XCTAssertEqual(state.user.hand.count, count + 1)
        XCTAssertTrue(state.user.hand.contains(recycled))
    }

    func testSpadesTrumpIsAlwaysSpades() {
        for seed in UInt64(1)...30 {
            XCTAssertEqual(OtherCardGameEngine.newGame(slug: "spades", title: "Spades", seed: seed).trumpSuit, .spade)
        }
    }

    func testPokerDoesNotCombineUnrelatedStraightAndFlush() {
        let mixed: [OtherCardGameCard] = [
            .init(suit: .heart, rank: .two), .init(suit: .heart, rank: .three),
            .init(suit: .heart, rank: .four), .init(suit: .heart, rank: .nine),
            .init(suit: .heart, rank: .king), .init(suit: .club, rank: .five),
            .init(suit: .spade, rank: .six)
        ]
        let fourOfAKind = OtherCardGameCard.Suit.allCases.map { OtherCardGameCard(suit: $0, rank: .two) }
            + [OtherCardGameCard(suit: .club, rank: .three)]
        XCTAssertLessThan(OtherCardGameEngine.pokerScore(cards: mixed), OtherCardGameEngine.pokerScore(cards: fourOfAKind))
    }

    func testPokerKickersAndWheelAreComparedCorrectly() {
        let wheel = [14, 2, 3, 4, 5].enumerated().map {
            OtherCardGameCard(suit: OtherCardGameCard.Suit.allCases[$0.offset % 4], rank: .init(rawValue: $0.element)!)
        }
        let sixHigh = [2, 3, 4, 5, 6].enumerated().map {
            OtherCardGameCard(suit: OtherCardGameCard.Suit.allCases[$0.offset % 4], rank: .init(rawValue: $0.element)!)
        }
        XCTAssertLessThan(OtherCardGameEngine.pokerScore(cards: wheel), OtherCardGameEngine.pokerScore(cards: sixHigh))
        let base: [OtherCardGameCard] = [.init(suit: .heart, rank: .queen), .init(suit: .club, rank: .queen),
            .init(suit: .spade, rank: .two), .init(suit: .diamond, rank: .three)]
        XCTAssertGreaterThan(OtherCardGameEngine.pokerScore(cards: base + [.init(suit: .heart, rank: .ace)]),
                             OtherCardGameEngine.pokerScore(cards: base + [.init(suit: .heart, rank: .king)]))
    }

    func testOtherCardGamesArePlayableWithoutMakingBalootModeReferencesPlayable() {
        let items = CatalogSeeder.previewItems()
        let otherGames = items.filter { $0.category == .otherCardGame }
        let balootModeReferences = items.filter(\.isBalootModeReference)

        XCTAssertFalse(otherGames.isEmpty)
        XCTAssertTrue(otherGames.allSatisfy(\.isPlayable))
        XCTAssertTrue(balootModeReferences.allSatisfy { !$0.isPlayable })
    }

    func testTarneebCreatesPlayableTrickTakingTable() {
        let state = OtherCardGameEngine.newGame(slug: "tarneeb", title: "طرنيب", seed: 44)

        XCTAssertEqual(state.rules.mode, .trickTaking)
        XCTAssertEqual(state.players.count, 4)
        XCTAssertEqual(state.players[0].hand.count, 13)
        XCTAssertFalse(state.legalCardsForUser.isEmpty)
        XCTAssertNotNil(state.trumpSuit)
    }

    func testHandCreatesPlayableMeldTableWithDrawPile() {
        let state = HandMatch(seed: 91)
        XCTAssertEqual(state.hands.count, 4)
        XCTAssertEqual(state.hands.map(\.count), [15, 14, 14, 14])
        XCTAssertEqual(state.stock.count, 49)
        XCTAssertEqual(state.phase, .arrange)
    }

    func testWarRoundCanAdvanceFromRevealAction() {
        var state = OtherCardGameEngine.newGame(slug: "war", title: "حرب", seed: 12)

        OtherCardGameEngine.playUserCard(state.players[0].hand[0], in: &state)

        XCTAssertEqual(state.players[0].hand.count, 25)
        XCTAssertEqual(state.players[1].hand.count, 25)
        XCTAssertEqual(state.players[0].score + state.players[1].score, 1)
    }

    func testMajlisGamesHaveSpecificPlayableRulesets() {
        let expectedModes: [String: OtherCardGameRules.Mode] = [
            "seven-diamonds": .avoidPenalty,
            "queen-spades": .avoidPenalty,
            "sahbiya": .matchingDiscard,
            "jack-clubs": .avoidPenalty,
            "king-hearts": .avoidPenalty,
            "diamonds-collector": .trickTaking,
            "hearts-penalty": .avoidPenalty,
            "queens-penalty": .avoidPenalty,
            "last-two": .trickTaking,
            "no-tricks": .avoidPenalty,
            "no-hearts-no-queens": .avoidPenalty,
            "sequence": .meldCollection,
            "memory-pairs": .meldCollection
        ]

        for (slug, mode) in expectedModes {
            let state = OtherCardGameEngine.newGame(slug: slug, title: slug, seed: 19)

            XCTAssertEqual(state.rules.mode, mode, "\(slug): نوع القاعدة غير صحيح")
            XCTAssertFalse(state.rules.setupText.isEmpty, "\(slug): شرح الإعداد فارغ")
            XCTAssertFalse(state.rules.playText.isEmpty, "\(slug): شرح اللعب فارغ")
            XCTAssertFalse(state.rules.scoringText.isEmpty, "\(slug): شرح التسجيل فارغ")
            XCTAssertFalse(state.players.isEmpty, "\(slug): لم تُنشأ طاولة")
            XCTAssertFalse(state.players[0].hand.isEmpty, "\(slug): يد اللاعب فارغة")
        }
    }

    func testPokerUsesShowdownTableWithCommunityCards() {
        let state = OtherCardGameEngine.newGame(slug: "poker-texas-holdem", title: "بوكر", seed: 33)

        XCTAssertEqual(state.rules.mode, .pokerShowdown)
        XCTAssertEqual(state.players.count, 2)
        XCTAssertEqual(state.players[0].hand.count, 2)
        XCTAssertEqual(state.communityCards.count, 5)
    }
}
