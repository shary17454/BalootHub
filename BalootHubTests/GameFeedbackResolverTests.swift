import XCTest
import BalootEngine
@testable import BalootHub

/// يتحقق من "متى يصدر التطبيق صوتًا أو مؤثرًا" بلا تشغيل واجهة ولا محاكي.
final class GameFeedbackResolverTests: XCTestCase {

    /// يلعب جولة كاملة ويرجع الحالة النهائية مع سجل الحالات قبل/بعد كل فعل.
    private func playRound(
        rules: BalootRulesConfiguration = .simpleBidding,
        mode: GameMode = .sun,
        trumpSuit: Suit? = nil,
        seed: UInt64 = 4_242
    ) throws -> [(action: GameAction, before: GameState, after: GameState)] {
        let agent = SimpleBalootAgent()
        var state = GameState.newLocalMatch(rules: rules)
        var log: [(GameAction, GameState, GameState)] = []

        func apply(_ action: GameAction) throws {
            let before = state
            state = try GameEngine.apply(action, to: state)
            log.append((action, before, state))
        }

        try apply(.dealCards(seed: seed))
        let humanID = try XCTUnwrap(state.players.first { $0.kind == .human }?.id)
        try apply(.chooseMode(playerID: humanID, mode: mode, trumpSuit: trumpSuit))

        var counter = 0
        while state.phase == .playing || state.phase == .bidding || state.phase == .declaring {
            counter += 1
            XCTAssertLessThan(counter, 200, "الجولة لم تنتهِ")
            let currentID = try XCTUnwrap(state.currentTurnPlayerID)
            let player = try XCTUnwrap(state.player(id: currentID))

            if state.phase == .declaring {
                let projects = GameEngine.declarableProjects(for: currentID, state: state)
                try apply(.declareProjects(playerID: currentID, projects: projects))
                continue
            }

            if player.kind == .ai {
                let before = state
                state = try GameEngine.advanceAIPlayers(state: state, agent: agent, maxSteps: 1)
                if let last = state.actionHistory.last, state.actionHistory.count > before.actionHistory.count {
                    log.append((last, before, state))
                }
                continue
            }

            let legal = GameEngine.legalCards(for: currentID, state: state)
            try apply(.playCard(playerID: currentID, card: try XCTUnwrap(legal.first)))
        }

        if state.phase == .scoring {
            try apply(.finishRound)
        }
        return log.map { (action: $0.0, before: $0.1, after: $0.2) }
    }

    private func humanTeamID(in state: GameState) -> Team.ID? {
        state.players.first { $0.seat == .south }?.teamID
    }

    // MARK: - الأحداث الأساسية

    func testDealingProducesNoFeedback() throws {
        let steps = try playRound()
        let deal = try XCTUnwrap(steps.first)
        XCTAssertNil(
            GameFeedbackResolver.signal(for: deal.action, before: deal.before, after: deal.after, humanTeamID: nil),
            "التوزيع نفسه ما يستحق صوتًا"
        )
    }

    func testPlayingMidTrickCardGivesLightCardSound() throws {
        let steps = try playRound()
        let midTrick = try XCTUnwrap(steps.first { step in
            guard case .playCard = step.action else { return false }
            return step.after.completedTricks.count == step.before.completedTricks.count
        })

        let signal = GameFeedbackResolver.signal(
            for: midTrick.action,
            before: midTrick.before,
            after: midTrick.after,
            humanTeamID: humanTeamID(in: midTrick.after)
        )
        XCTAssertEqual(signal?.event, .cardPlayed)
        XCTAssertNil(signal?.celebration, "ورقة عادية ما لها مؤثر بصري")
    }

    func testCompletingTrickDistinguishesWinFromLoss() throws {
        let steps = try playRound()
        let closing = steps.filter { step in
            guard case .playCard = step.action else { return false }
            return step.after.completedTricks.count > step.before.completedTricks.count
        }
        XCTAssertEqual(closing.count, 8, "المفروض ثماني أكلات مكتملة")

        for step in closing {
            let team = humanTeamID(in: step.after)
            let signal = GameFeedbackResolver.signal(
                for: step.action,
                before: step.before,
                after: step.after,
                humanTeamID: team
            )
            let winnerTeam = step.after.completedTricks.last?.winnerPlayerID
                .flatMap { id in step.after.players.first { $0.id == id }?.teamID }
            XCTAssertEqual(signal?.event, winnerTeam == team ? .trickWon : .trickLost)
        }
    }

    func testUnknownWinnerTeamIsTreatedAsLoss() throws {
        // بلا فريق مرجعي (لا يوجد مقعد جنوبي معروف) لا يجوز الادعاء بأن اللاعب فاز.
        let steps = try playRound()
        let closing = try XCTUnwrap(steps.first { step in
            guard case .playCard = step.action else { return false }
            return step.after.completedTricks.count > step.before.completedTricks.count
        })

        let signal = GameFeedbackResolver.signal(
            for: closing.action,
            before: closing.before,
            after: closing.after,
            humanTeamID: nil
        )
        XCTAssertEqual(signal?.event, .trickLost)
    }

    // MARK: - المزايدة والمضاعفة

    func testBiddingActionsMapToBidSound() {
        let state = GameState.newLocalMatch()
        let playerID = state.players[0].id

        XCTAssertEqual(
            GameFeedbackResolver.signal(
                for: .placeBid(playerID: playerID, bid: .sun),
                before: state, after: state, humanTeamID: nil
            )?.event,
            .bidPlaced
        )
        XCTAssertEqual(
            GameFeedbackResolver.signal(
                for: .raiseMultiplier(playerID: playerID, level: .double),
                before: state, after: state, humanTeamID: nil
            )?.event,
            .multiplierRaised
        )
        XCTAssertEqual(
            GameFeedbackResolver.signal(
                for: .lockMultiplier(playerID: playerID),
                before: state, after: state, humanTeamID: nil
            )?.event,
            .multiplierRaised
        )
    }

    func testPassingMultiplierStaysSilent() {
        let state = GameState.newLocalMatch()
        XCTAssertNil(
            GameFeedbackResolver.signal(
                for: .passMultiplier(playerID: state.players[0].id),
                before: state, after: state, humanTeamID: nil
            ),
            "تمرير المضاعفة يتكرر كثيرًا، وإصدار صوت له ضجيج بلا معلومة"
        )
    }

    // MARK: - المشاريع

    func testEmptyDeclarationStaysSilent() {
        let state = GameState.newLocalMatch()
        XCTAssertNil(
            GameFeedbackResolver.signal(
                for: .declareProjects(playerID: state.players[0].id, projects: []),
                before: state, after: state, humanTeamID: nil
            )
        )
    }

    func testProjectDeclarationCelebratesStrongestAndSumsPoints() {
        let state = GameState.newLocalMatch()
        let player = state.players[0]
        let sira = Project(
            kind: .sira,
            teamID: player.teamID,
            playerID: player.id,
            cards: [
                PlayingCard(suit: .hearts, rank: .seven),
                PlayingCard(suit: .hearts, rank: .eight),
                PlayingCard(suit: .hearts, rank: .nine)
            ],
            points: 20
        )
        let fifty = Project(
            kind: .fifty,
            teamID: player.teamID,
            playerID: player.id,
            cards: [
                PlayingCard(suit: .spades, rank: .seven),
                PlayingCard(suit: .spades, rank: .eight),
                PlayingCard(suit: .spades, rank: .nine),
                PlayingCard(suit: .spades, rank: .ten)
            ],
            points: 50
        )

        let signal = GameFeedbackResolver.signal(
            for: .declareProjects(playerID: player.id, projects: [sira, fifty]),
            before: state, after: state, humanTeamID: player.teamID
        )

        XCTAssertEqual(signal?.event, .projectDeclared)
        XCTAssertEqual(
            signal?.celebration,
            .project(title: Project.Kind.fifty.arabicName, points: 70),
            "العنوان للأقوى والمجموع لكل المشاريع المعلنة"
        )
    }

    // MARK: - نهاية الجولة والكبوت

    func testRoundWithoutKabootEndsQuietly() throws {
        let steps = try playRound()
        let finish = try XCTUnwrap(steps.last)
        guard case .finishRound = finish.action else { return XCTFail("آخر فعل ليس إنهاء الجولة") }

        let signal = GameFeedbackResolver.signal(
            for: finish.action, before: finish.before, after: finish.after, humanTeamID: nil
        )
        if finish.after.kabootTeamID == nil {
            XCTAssertEqual(signal?.event, .roundFinished)
            XCTAssertNil(signal?.celebration)
        }
    }

    func testKabootTriggersCelebrationWithTeamName() {
        var state = GameState.newLocalMatch()
        let team = try? XCTUnwrap(state.teams.first)
        state.kabootTeamID = team?.id

        let signal = GameFeedbackResolver.signal(
            for: .finishRound, before: state, after: state, humanTeamID: nil
        )

        XCTAssertEqual(signal?.event, .kaboot)
        XCTAssertEqual(signal?.celebration, .kaboot(teamName: team?.name ?? ""))
    }

    func testSignalsWithSameContentStillGetDistinctIdentifiers() {
        let state = GameState.newLocalMatch()
        let first = GameFeedbackResolver.signal(
            for: .placeBid(playerID: state.players[0].id, bid: .sun),
            before: state, after: state, humanTeamID: nil
        )
        let second = GameFeedbackResolver.signal(
            for: .placeBid(playerID: state.players[0].id, bid: .sun),
            before: state, after: state, humanTeamID: nil
        )

        XCTAssertNotEqual(first, second, "تكرار نفس الحدث لازم يُشغّل المؤثر مرة ثانية لا يُبتلع")
    }

    // MARK: - تغطية كل الأحداث

    func testEveryFeedbackEventHasHapticAndSound() {
        for event in FeedbackEvent.allCases {
            XCTAssertGreaterThan(event.systemSoundID, 0, "\(event.rawValue): بلا صوت")
            _ = event.haptic
        }
    }

    func testOnlyBigMomentsDeserveCelebration() {
        XCTAssertTrue(FeedbackEvent.kaboot.deservesCelebration)
        XCTAssertTrue(FeedbackEvent.projectDeclared.deservesCelebration)
        XCTAssertFalse(FeedbackEvent.cardPlayed.deservesCelebration)
        XCTAssertFalse(FeedbackEvent.trickLost.deservesCelebration)
    }
}
