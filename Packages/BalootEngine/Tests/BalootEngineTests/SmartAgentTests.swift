import Testing
@testable import BalootEngine

/// يثبت أن الوكيل الذكي يلعب لعبًا صحيحًا **وأفضل فعليًا** من الوكيل البسيط،
/// عبر مواجهات كاملة مباشرة: فريق يلعبه الذكي وفريق يلعبه البسيط.
@Suite("SmartBalootAgent")
struct SmartAgentTests {

    /// يلعب جولة كاملة يقود فيها كل لاعب وكيلُ فريقه، ويعيد نقاط الفريقين.
    private func playRound(seed: UInt64, smartTeamIndex: Int) throws -> (smart: Int, simple: Int) {
        let smart = SmartBalootAgent()
        let simple = SimpleBalootAgent()
        var state = GameState.newLocalMatch()
        let smartTeamID = state.teams[smartTeamIndex].id

        func agent(for playerID: Player.ID) -> BalootAgent {
            state.player(id: playerID)?.teamID == smartTeamID ? smart : simple
        }

        state = try GameEngine.apply(.dealCards(seed: seed), to: state)

        var guardCounter = 0
        while state.phase == .bidding || state.phase == .playing {
            guardCounter += 1
            try #require(guardCounter < 200, "الجولة لم تنتهِ")
            let currentID = try #require(state.currentTurnPlayerID)
            let hand = try #require(state.hands[currentID])
            let actor = agent(for: currentID)

            if state.phase == .bidding {
                let choice = actor.chooseMode(hand: hand, state: state)
                state = try GameEngine.apply(.chooseMode(playerID: currentID, mode: choice.mode, trumpSuit: choice.trumpSuit), to: state)
            } else {
                let legal = LegalMoveValidator.legalCards(hand: hand, trick: state.currentTrick, mode: state.mode ?? .sun, trumpSuit: state.trumpSuit, rules: state.rules)
                let card = actor.chooseCard(hand: hand, legalCards: legal, state: state)
                #expect(legal.contains(card), "الوكيل اختار ورقة غير شرعية")
                state = try GameEngine.apply(.playCard(playerID: currentID, card: card), to: state)
            }
        }
        if state.phase == .scoring {
            state = try GameEngine.apply(.finishRound, to: state)
        }
        let result = try #require(state.lastRoundResult)
        let smartPoints = result.teamPoints[smartTeamID] ?? 0
        let simplePoints = result.teamPoints.first { $0.key != smartTeamID }?.value ?? 0
        return (smartPoints, simplePoints)
    }

    /// الوكيل الذكي لا يلعب إلا أوراقًا شرعية، وكل الجولات تكتمل بدون تعليق.
    @Test("جولات كاملة بلا أخطاء ولا حركات غير شرعية")
    func playsLegallyToCompletion() throws {
        for seed in stride(from: UInt64(1), through: 30, by: 1) {
            _ = try playRound(seed: seed, smartTeamIndex: 0)
        }
    }

    /// المقياس الحاسم: عبر 60 توزيعة (مع تبديل الفريقين لإلغاء أفضلية الجلوس)،
    /// يجب أن يجمع الذكي نقاطًا أكثر من البسيط بمجموع واضح.
    @Test("الوكيل الذكي يتفوق على البسيط في المواجهة المباشرة")
    func beatsSimpleAgentHeadToHead() throws {
        var smartTotal = 0
        var simpleTotal = 0
        var smartWins = 0
        var rounds = 0

        for seed in stride(from: UInt64(100), through: 129, by: 1) {
            for teamIndex in [0, 1] {
                let outcome = try playRound(seed: seed, smartTeamIndex: teamIndex)
                smartTotal += outcome.smart
                simpleTotal += outcome.simple
                if outcome.smart > outcome.simple { smartWins += 1 }
                rounds += 1
            }
        }

        // تفوق إجمالي بالنقاط، وأغلبية جولات مكسوبة.
        #expect(smartTotal > simpleTotal,
                "الذكي جمع \(smartTotal) مقابل \(simpleTotal) للبسيط عبر \(rounds) جولة")
        #expect(smartWins * 2 > rounds,
                "الذكي كسب \(smartWins) من \(rounds) جولة فقط")
    }

    /// عند فوز الشريك المضمون، يجب أن يحمّله الوكيل نقاطًا لا أن يهدر أوراقه القوية.
    @Test("المزايدة التقييمية تختار حكمًا بيد الحكم القوية وصنًّا بيد الآسات")
    func biddingEvaluatesHands() {
        let agent = SmartBalootAgent()
        let state = GameState.newLocalMatch()

        // يد حكم صريحة: ولد وتسعة وآس من نفس النوع مع طول.
        let hokumHand: [PlayingCard] = [
            PlayingCard(suit: .spades, rank: .jack),
            PlayingCard(suit: .spades, rank: .nine),
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .spades, rank: .seven),
            PlayingCard(suit: .hearts, rank: .eight),
            PlayingCard(suit: .diamonds, rank: .seven),
            PlayingCard(suit: .clubs, rank: .eight),
            PlayingCard(suit: .clubs, rank: .seven)
        ]
        let hokumChoice = agent.chooseMode(hand: hokumHand, state: state)
        #expect(hokumChoice.mode == .hokum)
        #expect(hokumChoice.trumpSuit == .spades)

        // يد صن صريحة: آسات وعشرات موزعة بلا طول حكم.
        let sunHand: [PlayingCard] = [
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .diamonds, rank: .ace),
            PlayingCard(suit: .clubs, rank: .ten),
            PlayingCard(suit: .spades, rank: .ten),
            PlayingCard(suit: .hearts, rank: .king),
            PlayingCard(suit: .diamonds, rank: .eight),
            PlayingCard(suit: .clubs, rank: .seven)
        ]
        let sunChoice = agent.chooseMode(hand: sunHand, state: state)
        #expect(sunChoice.mode == .sun)
    }
}
