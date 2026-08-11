import XCTest
@testable import BalootHub

final class PlayerStatsAnalyzerTests: XCTestCase {
    func testSummarizesFinishedSessions() {
        let win = ScoreSession(createdAt: Date(timeIntervalSince1970: 1), teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 100, status: .finished)
        let winRound = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 120, teamTwoBaseScore: 40, teamOneProjects: 20)
        win.rounds.append(winRound)

        let loss = ScoreSession(createdAt: Date(timeIntervalSince1970: 2), teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 100, status: .finished)
        let lossRound = ScoreRound(roundNumber: 1, mode: .sun, teamOneBaseScore: 40, teamTwoBaseScore: 120)
        loss.rounds.append(lossRound)

        let summary = PlayerStatsAnalyzer.summarize(sessions: [win, loss], rules: .standard)

        XCTAssertEqual(summary.finishedMatches, 2)
        XCTAssertEqual(summary.wins, 1)
        XCTAssertEqual(summary.losses, 1)
        XCTAssertEqual(summary.projectPoints, 20)
        XCTAssertEqual(summary.sunRounds, 1)
        XCTAssertEqual(summary.hokumRounds, 1)
        XCTAssertEqual(summary.winRate, 0.5)
    }

    func testIgnoresUnfinishedSessionsWithoutWinner() {
        let active = ScoreSession(teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 500, status: .active)
        active.rounds.append(ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 80, teamTwoBaseScore: 70))

        let summary = PlayerStatsAnalyzer.summarize(sessions: [active], rules: .standard)

        XCTAssertEqual(summary.finishedMatches, 0)
    }

    func testDetectsProjectFocusedStyle() {
        let session = ScoreSession(teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 100, status: .finished)
        session.rounds.append(ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 80, teamTwoBaseScore: 20, teamOneProjects: 200))

        let summary = PlayerStatsAnalyzer.summarize(sessions: [session], rules: .standard)

        XCTAssertEqual(summary.styleTitle, "صياد مشاريع")
    }
}
