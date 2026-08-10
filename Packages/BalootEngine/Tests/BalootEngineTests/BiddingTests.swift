import Foundation
import Testing
@testable import BalootEngine

// MARK: - أدوات مشتركة

/// يبني حالة مباراة كل لاعبيها آليون، فتكتمل المزايدة واللعب بلا تدخل.
private func makeAIMatch(rules: BalootRulesConfiguration = .standard) -> GameState {
    var state = GameState.newLocalMatch(rules: rules)
    state.players = state.players.map { player in
        var updated = player
        updated.kind = .ai
        return updated
    }
    return state
}

private let referenceAgent = ProfiledBalootAgent(profile: AIProfile(
    id: "test.reference", level: .casual, personality: .balanced, avatarSystemName: "person"
))

// MARK: - دورة المزايدة

@Suite("دورة المزايدة الكاملة")
struct BiddingCycleTests {

    @Test("التوزيع الافتتاحي يعطي خمس أوراق لكل لاعب وورقة مكشوفة وأحد عشر مؤجلة")
    func openingDealMatchesFullBiddingStyle() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 42), to: state)

        #expect(state.phase == .bidding)
        #expect(state.bidding.stage == .firstRound)
        #expect(state.bidding.upCard != nil)
        #expect(state.undealtCards.count == 11)
        for player in state.players {
            #expect(state.hands[player.id]?.count == 5)
        }
        // مجموع ما وُزّع وما بقي والورقة المكشوفة = الحزمة كاملة بلا تكرار.
        let all = state.players.flatMap { state.hands[$0.id] ?? [] } + state.undealtCards + [state.bidding.upCard!]
        #expect(all.count == Deck.fullCount)
        #expect(Set(all).count == Deck.fullCount)
    }

    @Test("المزايدة تبدأ من اللاعب التالي للموزّع")
    func biddingStartsRightOfDealer() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 7), to: state)
        #expect(state.currentTurnPlayerID == state.player(at: state.dealerSeat.next)?.id)
    }

    @Test("الجولة الأولى لا تسمح بالحكم إلا على لون الورقة المكشوفة")
    func firstRoundHokumLimitedToUpCardSuit() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 11), to: state)

        let upSuit = try #require(state.bidding.upCard?.suit)
        let legal = state.bidding.legalBids(rules: state.rules)

        #expect(legal.contains(.hokum(suit: upSuit)))
        for suit in Suit.allCases where suit != upSuit {
            #expect(!legal.contains(.hokum(suit: suit)))
        }
    }

    @Test("شراء حكم بلون غير المكشوف في الجولة الأولى يُرفض")
    func illegalFirstRoundHokumIsRejected() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 3), to: state)

        let upSuit = try #require(state.bidding.upCard?.suit)
        let otherSuit = try #require(Suit.allCases.first { $0 != upSuit })
        let playerID = try #require(state.currentTurnPlayerID)

        #expect(throws: GameEngineError.bidding(.illegalBid)) {
            try GameEngine.apply(.placeBid(playerID: playerID, bid: .hokum(suit: otherSuit)), to: state)
        }
    }

    @Test("تمرير الأربعة في الجولة الأولى يفتح جولة الأشكال بكل الألوان عدا المكشوف")
    func fourPassesOpenSecondRound() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 5), to: state)
        let upSuit = try #require(state.bidding.upCard?.suit)

        for _ in 0..<4 {
            let playerID = try #require(state.currentTurnPlayerID)
            state = try GameEngine.apply(.placeBid(playerID: playerID, bid: .pass), to: state)
        }

        #expect(state.bidding.stage == .secondRound)
        #expect(state.currentTurnPlayerID == state.player(at: state.dealerSeat.next)?.id)

        let legal = state.bidding.legalBids(rules: state.rules)
        #expect(!legal.contains(.hokum(suit: upSuit)))
        for suit in Suit.allCases where suit != upSuit {
            #expect(legal.contains(.hokum(suit: suit)))
        }
    }

    @Test("تمرير الأربعة في الجولتين يُنتج دورة ميتة بلا نقاط لأي فريق")
    func allPassesProduceVoidRound() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 9), to: state)

        for _ in 0..<8 {
            let playerID = try #require(state.currentTurnPlayerID)
            state = try GameEngine.apply(.placeBid(playerID: playerID, bid: .pass), to: state)
        }

        #expect(state.bidding.stage == .voided)
        #expect(state.phase == .finished)
        #expect(state.mode == nil)
        for team in state.teams {
            #expect(state.lastRoundResult?.teamPoints[team.id] == 0)
        }
        #expect(state.lastRoundResult?.winningTeamID == nil)
    }

    @Test("الصن يعلو الحكم في نفس الجولة ولا يعلوه شيء")
    func sunOutbidsHokumAndClosesTheRound() throws {
        var rules = BalootRulesConfiguration.standard
        rules.multipliersEnabled = false
        var state = GameState.newLocalMatch(rules: rules)
        state = try GameEngine.apply(.dealCards(seed: 13), to: state)

        let upSuit = try #require(state.bidding.upCard?.suit)
        let firstID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.placeBid(playerID: firstID, bid: .hokum(suit: upSuit)), to: state)

        // بعد شراء الحكم، الخيار الوحيد المتاح فوقه هو الصن.
        let legal = state.bidding.legalBids(rules: state.rules)
        #expect(legal.contains(.sun))
        #expect(!legal.contains(.hokum(suit: upSuit)))

        let secondID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.placeBid(playerID: secondID, bid: .sun), to: state)

        #expect(state.bidding.declarerID == secondID)
        #expect(state.mode == .sun)
        // الصن لا يعلوه شيء فتُغلق الجولة فورًا دون انتظار بقية اللاعبين.
        #expect(state.bidding.stage == .completed)
    }

    @Test("بعد استقرار الشراء توزَّع الأوراق المتبقية والمشتري يأخذ الورقة المكشوفة")
    func declarerReceivesUpCardAfterBidding() throws {
        var rules = BalootRulesConfiguration.standard
        rules.multipliersEnabled = false
        rules.projectsRequireDeclaration = false
        var state = GameState.newLocalMatch(rules: rules)
        state = try GameEngine.apply(.dealCards(seed: 21), to: state)

        let upCard = try #require(state.bidding.upCard)
        let firstID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.placeBid(playerID: firstID, bid: .hokum(suit: upCard.suit)), to: state)
        state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)
        state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)
        state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)

        #expect(state.bidding.stage == .completed)
        #expect(state.phase == .playing)
        #expect(state.undealtCards.isEmpty)
        for player in state.players {
            #expect(state.hands[player.id]?.count == 8)
            #expect(state.originalHands[player.id]?.count == 8)
        }
        #expect(state.hands[firstID]?.contains(upCard) == true)
    }

    @Test("الاختيار المباشر للنمط مرفوض في نمط المزايدة الكاملة")
    func chooseModeRejectedInFullBidding() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 4), to: state)
        let playerID = try #require(state.currentTurnPlayerID)

        #expect(throws: GameEngineError.bidding(.unsupportedInBiddingStyle)) {
            try GameEngine.apply(.chooseMode(playerID: playerID, mode: .sun, trumpSuit: nil), to: state)
        }
    }
}

// MARK: - المضاعفات

@Suite("المضاعفات داخل اللعب")
struct MultiplierTests {

    /// يوصل الحالة إلى جولة المضاعفة بشراء حكم من أول لاعب.
    private func stateInDoublingStage(seed: UInt64 = 17) throws -> GameState {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: seed), to: state)
        let upSuit = try #require(state.bidding.upCard?.suit)
        let firstID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.placeBid(playerID: firstID, bid: .hokum(suit: upSuit)), to: state)
        for _ in 0..<3 {
            state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)
        }
        return state
    }

    @Test("جولة المضاعفة تُفتح بعد الشراء ودورها لخصوم المشتري")
    func doublingStageOpensForOpponents() throws {
        let state = try stateInDoublingStage()
        #expect(state.bidding.stage == .doubling)

        let declarerTeam = try #require(state.declaringTeamID)
        let currentTeam = try #require(state.currentTurnPlayerID.flatMap { state.player(id: $0)?.teamID })
        #expect(currentTeam != declarerTeam)
    }

    @Test("فريق المشتري لا يملك حق الدبل الابتدائي")
    func declaringTeamCannotDoubleItself() throws {
        let state = try stateInDoublingStage()
        let declarer = try #require(state.declarer)

        #expect(throws: GameEngineError.notPlayersTurn) {
            try GameEngine.apply(.raiseMultiplier(playerID: declarer.id, level: .double), to: state)
        }
    }

    @Test("التصعيد يجب أن يكون بالدرجة التالية تحديدًا")
    func multiplierMustEscalateOneStep() throws {
        let state = try stateInDoublingStage()
        let playerID = try #require(state.currentTurnPlayerID)

        #expect(throws: GameEngineError.bidding(.invalidMultiplierLevel)) {
            try GameEngine.apply(.raiseMultiplier(playerID: playerID, level: .quadruple), to: state)
        }
    }

    @Test("بعد الدبل ينتقل حق التصعيد إلى الفريق المقابل")
    func raiseTransfersEscalationRight() throws {
        var state = try stateInDoublingStage()
        let doublerID = try #require(state.currentTurnPlayerID)
        let doublerTeam = try #require(state.player(id: doublerID)?.teamID)

        state = try GameEngine.apply(.raiseMultiplier(playerID: doublerID, level: .double), to: state)

        #expect(state.bidding.multiplier == .double)
        #expect(state.bidding.multiplierRequesterTeamID == doublerTeam)
        let nextTeam = try #require(state.currentTurnPlayerID.flatMap { state.player(id: $0)?.teamID })
        #expect(nextTeam != doublerTeam)
    }

    @Test("تمرير لاعبَي الفريق صاحب الحق يُنهي المضاعفة")
    func twoPassesCloseDoubling() throws {
        var state = try stateInDoublingStage()
        state = try GameEngine.apply(.passMultiplier(playerID: try #require(state.currentTurnPlayerID)), to: state)
        #expect(state.bidding.stage == .doubling)
        state = try GameEngine.apply(.passMultiplier(playerID: try #require(state.currentTurnPlayerID)), to: state)

        #expect(state.bidding.stage == .completed)
        #expect(state.bidding.multiplier == .none)
    }

    @Test("القفل يُنهي التصعيد ولا يجوز إلا لصاحب المضاعفة الحالية")
    func lockEndsEscalation() throws {
        var state = try stateInDoublingStage()
        let doublerID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.raiseMultiplier(playerID: doublerID, level: .double), to: state)

        // الفريق المقابل لا يملك المضاعفة فلا يملك القفل.
        let opponentID = try #require(state.currentTurnPlayerID)
        #expect(throws: GameEngineError.bidding(.lockNotAllowed)) {
            try GameEngine.apply(.lockMultiplier(playerID: opponentID), to: state)
        }
    }

    @Test("المضاعف يضرب نتيجة الجولة بالمعامل المعرَّف في القواعد")
    func multiplierScalesRoundScore() {
        let teamA = Team(name: "أ")
        let teamB = Team(name: "ب")
        let players = [
            Player(name: "1", kind: .ai, seat: .south, teamID: teamA.id),
            Player(name: "2", kind: .ai, seat: .west, teamID: teamB.id),
            Player(name: "3", kind: .ai, seat: .north, teamID: teamA.id),
            Player(name: "4", kind: .ai, seat: .east, teamID: teamB.id)
        ]
        var rules = BalootRulesConfiguration.standard
        rules.declarerMustWinMajority = false
        rules.projectsEnabled = false

        let single = ScoreCalculator.finalRoundScore(
            completedTricks: [], originalHands: [:], players: players, teams: [teamA, teamB],
            mode: .hokum, trumpSuit: .spades, rules: rules, multiplier: .none, declaredProjects: []
        )
        let tripled = ScoreCalculator.finalRoundScore(
            completedTricks: [], originalHands: [:], players: players, teams: [teamA, teamB],
            mode: .hokum, trumpSuit: .spades, rules: rules, multiplier: .triple, declaredProjects: []
        )

        #expect(single.multiplier == .none)
        #expect(tripled.multiplier == .triple)
        #expect(Multiplier.triple.factor(rules: rules) == rules.tripleFactor)
    }
}
