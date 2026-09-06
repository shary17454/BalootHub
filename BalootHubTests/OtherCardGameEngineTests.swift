import XCTest
@testable import BalootHub

final class OtherCardGameEngineTests: XCTestCase {
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
        let state = OtherCardGameEngine.newGame(slug: "hand", title: "هاند", seed: 91)

        XCTAssertEqual(state.rules.mode, .meldCollection)
        XCTAssertEqual(state.players.count, 4)
        XCTAssertEqual(state.players[0].hand.count, 10)
        XCTAssertFalse(state.drawPile.isEmpty)
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
