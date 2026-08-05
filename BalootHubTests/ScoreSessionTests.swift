import XCTest
import SwiftData
@testable import BalootHub

final class ScoreSessionTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = PersistenceController.makePreviewContainer(seed: false)
        context = ModelContext(container)
    }

    func testTotalsAccumulateAcrossRounds() {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 152)
        context.insert(session)

        let roundOne = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 80, teamTwoBaseScore: 72)
        roundOne.session = session
        session.rounds.append(roundOne)

        let roundTwo = ScoreRound(roundNumber: 2, mode: .sun, teamOneBaseScore: 60, teamTwoBaseScore: 70, multiplier: .double)
        roundTwo.session = session
        session.rounds.append(roundTwo)

        let rules = ScoreRules.standard
        XCTAssertEqual(session.teamOneTotal(rules: rules), 80 + 120)
        XCTAssertEqual(session.teamTwoTotal(rules: rules), 72 + 140)
    }

    func testLeadingTeamNameReflectsHigherTotal() {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 152)
        let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 40)
        round.session = session
        session.rounds.append(round)

        XCTAssertEqual(session.leadingTeamName(rules: .standard), "أ")
    }

    func testWinnerIsNilBeforeReachingTarget() {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 152)
        let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 90, teamTwoBaseScore: 62)
        round.session = session
        session.rounds.append(round)

        XCTAssertNil(session.winnerName(rules: .standard))
    }

    func testWinnerIsDeclaredOnceTargetIsReached() {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 100)
        let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 110, teamTwoBaseScore: 42)
        round.session = session
        session.rounds.append(round)

        XCTAssertEqual(session.winnerName(rules: .standard), "أ")
    }

    func testUndoRemovesLastRoundOnly() {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 152)
        let roundOne = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 50, teamTwoBaseScore: 50)
        roundOne.session = session
        let roundTwo = ScoreRound(roundNumber: 2, mode: .hokum, teamOneBaseScore: 30, teamTwoBaseScore: 30)
        roundTwo.session = session
        session.rounds = [roundOne, roundTwo]

        guard let last = session.sortedRounds.last else {
            XCTFail("expected a last round")
            return
        }
        session.rounds.removeAll { $0.id == last.id }

        XCTAssertEqual(session.rounds.count, 1)
        XCTAssertEqual(session.sortedRounds.first?.roundNumber, 1)
    }

    func testNegativeScoresAreClampedToZeroAtCreation() {
        let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: -20, teamTwoBaseScore: -5, teamOneProjects: -3, teamTwoProjects: -1)
        XCTAssertEqual(round.teamOneBaseScore, 0)
        XCTAssertEqual(round.teamTwoBaseScore, 0)
        XCTAssertEqual(round.teamOneProjects, 0)
        XCTAssertEqual(round.teamTwoProjects, 0)
    }
}
