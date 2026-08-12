import XCTest
import BalootEngine
@testable import BalootHub

final class BalootGameLocalHandoffTests: XCTestCase {
    @MainActor
    func testLocalHumansHideHandAndActionsUntilReady() {
        let viewModel = BalootGameViewModel(tableMode: .localHumans, rules: .standard)

        viewModel.deal()

        XCTAssertEqual(viewModel.tableMode, .localHumans)
        XCTAssertTrue(viewModel.isHumanTurn)
        XCTAssertTrue(viewModel.requiresLocalHandoffConfirmation)
        XCTAssertFalse(viewModel.isLocalHumanHandRevealed)
        XCTAssertFalse(viewModel.canCurrentHumanAct)
        XCTAssertTrue(viewModel.visibleHumanHand.isEmpty)
        XCTAssertTrue(viewModel.legalBidsForHuman.isEmpty)
        XCTAssertTrue(viewModel.moveValidationsForHuman.isEmpty)
        XCTAssertTrue(viewModel.legalCardsForHuman.isEmpty)

        viewModel.revealLocalHumanHand()

        XCTAssertFalse(viewModel.requiresLocalHandoffConfirmation)
        XCTAssertTrue(viewModel.isLocalHumanHandRevealed)
        XCTAssertTrue(viewModel.canCurrentHumanAct)
        XCTAssertEqual(viewModel.visibleHumanHand, viewModel.humanHand)
        XCTAssertFalse(viewModel.legalBidsForHuman.isEmpty)
    }

    @MainActor
    func testLocalHumansHideHandAgainAfterTurnAction() {
        let viewModel = BalootGameViewModel(tableMode: .localHumans, rules: .standard)

        viewModel.deal()
        viewModel.revealLocalHumanHand()
        let firstPlayer = viewModel.state.currentTurnPlayerID

        viewModel.placeBid(.pass)

        XCTAssertNotEqual(viewModel.state.currentTurnPlayerID, firstPlayer)
        XCTAssertTrue(viewModel.requiresLocalHandoffConfirmation)
        XCTAssertFalse(viewModel.isLocalHumanHandRevealed)
        XCTAssertFalse(viewModel.canCurrentHumanAct)
        XCTAssertTrue(viewModel.visibleHumanHand.isEmpty)
        XCTAssertTrue(viewModel.legalBidsForHuman.isEmpty)
        XCTAssertTrue(viewModel.moveValidationsForHuman.isEmpty)
        XCTAssertTrue(viewModel.legalCardsForHuman.isEmpty)
    }

    @MainActor
    func testPlayableHumanCardsMirrorEngineLegalMoveActions() throws {
        let viewModel = BalootGameViewModel(tableMode: .localHumans, rules: .standard)

        viewModel.deal()
        for _ in 0..<24 where viewModel.state.phase != .playing {
            if viewModel.requiresLocalHandoffConfirmation {
                viewModel.revealLocalHumanHand()
            }
            if viewModel.state.phase == .bidding {
                let bid = viewModel.legalBidsForHuman.first { $0 != .pass } ?? .pass
                if viewModel.isShowingHumanMultiplierControls {
                    viewModel.passMultiplier()
                } else {
                    viewModel.placeBid(bid)
                }
            } else if viewModel.state.phase == .declaring {
                viewModel.skipDeclaration()
            }
        }
        if viewModel.requiresLocalHandoffConfirmation {
            viewModel.revealLocalHumanHand()
        }
        let playerID = try XCTUnwrap(viewModel.activeHumanID)

        XCTAssertEqual(viewModel.state.phase, .playing)

        XCTAssertEqual(
            viewModel.legalCardsForHuman,
            GameEngine.legalMoves(for: playerID, state: viewModel.state).compactMap { action in
                guard case .playCard(_, let card) = action else { return nil }
                return card
            }
        )
    }
}
