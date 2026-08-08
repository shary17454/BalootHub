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

// MARK: - اختبارات انحدار

/// اختبارات تحرس أخطاءً وقعت فعلًا في طبقة التطبيق، حتى لا تعود.
final class ScorekeeperRegressionTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = PersistenceController.makePreviewContainer(seed: false)
        context = ModelContext(container)
    }

    /// رقم الصكة الجديدة كان `rounds.count + 1`، فبعد حذف صكة وسطية يتكرر رقم موجود:
    /// ثلاث صكات ⇒ حذف الثانية ⇒ الصكة الجديدة تأخذ الرقم 3 وهو رقم صكة قائمة.
    /// القاعدة الصحيحة هي أكبر رقم مستخدم + 1.
    func testNextRoundNumberDoesNotCollideAfterDeletingMiddleRound() throws {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 152)
        context.insert(session)

        for number in 1...3 {
            let round = ScoreRound(roundNumber: number, mode: .hokum, teamOneBaseScore: 10 * number, teamTwoBaseScore: 5)
            round.session = session
            session.rounds.append(round)
        }

        // حذف الصكة الوسطى (رقم 2).
        let middle = try XCTUnwrap(session.sortedRounds.first { $0.roundNumber == 2 })
        session.rounds.removeAll { $0.roundNumber == 2 }
        context.delete(middle)

        let nextRoundNumber = (session.rounds.map(\.roundNumber).max() ?? 0) + 1
        XCTAssertEqual(nextRoundNumber, 4, "الرقم التالي يجب أن يتجاوز أكبر رقم مستخدم")
        XCTAssertFalse(session.rounds.map(\.roundNumber).contains(nextRoundNumber),
                       "الرقم التالي يتصادم مع صكة قائمة")
    }

    /// حذف صكة يجب أن يُسقط نقاطها من الإجمالي فورًا.
    func testDeletingRoundRemovesItsPointsFromTotals() throws {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 152)
        context.insert(session)

        let first = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
        first.session = session
        session.rounds.append(first)
        let second = ScoreRound(roundNumber: 2, mode: .hokum, teamOneBaseScore: 40, teamTwoBaseScore: 122)
        second.session = session
        session.rounds.append(second)

        let rules = ScoreRules.standard
        XCTAssertEqual(session.teamOneTotal(rules: rules), 140)

        session.rounds.removeAll { $0.roundNumber == 2 }
        context.delete(second)

        XCTAssertEqual(session.teamOneTotal(rules: rules), 100)
        XCTAssertEqual(session.teamTwoTotal(rules: rules), 62)
    }

    /// التعادل عند بلوغ الهدف لا يُعلن فائزًا.
    func testTieAtTargetDeclaresNoWinner() {
        let session = ScoreSession(teamOneName: "أ", teamTwoName: "ب", targetScore: 152)
        let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 152, teamTwoBaseScore: 152)
        round.session = session
        session.rounds.append(round)

        XCTAssertNil(session.winnerName(rules: .standard))
        XCTAssertNil(session.leadingTeamName(rules: .standard))
    }
}
