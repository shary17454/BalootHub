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

    func testHandCreatesPlayableMatchingTableWithDrawPile() {
        let state = OtherCardGameEngine.newGame(slug: "hand", title: "هاند", seed: 91)

        XCTAssertEqual(state.rules.mode, .matchingDiscard)
        XCTAssertEqual(state.players.count, 4)
        XCTAssertEqual(state.players[0].hand.count, 7)
        XCTAssertEqual(state.discardPile.count, 1)
        XCTAssertFalse(state.drawPile.isEmpty)
    }

    func testWarRoundCanAdvanceFromRevealAction() {
        var state = OtherCardGameEngine.newGame(slug: "war", title: "حرب", seed: 12)

        OtherCardGameEngine.playUserCard(state.players[0].hand[0], in: &state)

        XCTAssertEqual(state.players[0].hand.count, 25)
        XCTAssertEqual(state.players[1].hand.count, 25)
        XCTAssertEqual(state.players[0].score + state.players[1].score, 1)
    }
}
