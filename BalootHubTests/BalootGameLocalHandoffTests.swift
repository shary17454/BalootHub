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
    }
}
