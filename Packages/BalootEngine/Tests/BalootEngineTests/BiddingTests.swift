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
    private struct IllegalSunBidAgent: BalootAgent {
        func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard {
            legalCards.first ?? PlayingCard(suit: .spades, rank: .seven)
        }

        func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?) {
            (.sun, nil)
        }

        func chooseBid(hand: [PlayingCard], legalBids: [Bid], state: GameState) -> Bid {
            .sun
        }

        func chooseMultiplierAction(hand: [PlayingCard], state: GameState) -> MultiplierDecision {
            .pass
        }
    }

    @Test("أسماء المزايدات عربية ومستقرة للـReplay والتحليل")
    func bidArabicNamesAreStable() {
        #expect(Bid.pass.arabicName == "بس")
        #expect(Bid.sun.arabicName == "صن")
        #expect(Bid.hokum(suit: .spades).arabicName == "حكم سباتي")
    }

    @Test("ملخص سجل المزايدة ثابت للـReplay")
    func bidRecordSummaryIsStable() {
        let record = BidRecord(
            playerID: Player(name: "سالم", kind: .human, seat: .south, teamID: Team(name: "أ").id).id,
            bid: .hokum(suit: .hearts),
            round: 2
        )

        #expect(record.summary(playerName: "سالم") == "الجولة 2: سالم - حكم هارت")
    }

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

    @Test("الصن والحكم خياران داخل لعبة البلوت الواحدة لا أوضاع مفروضة مسبقًا")
    func sunAndHokumAreBidsInsideOneBalootGame() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 31), to: state)

        let upSuit = try #require(state.bidding.upCard?.suit)
        let legal = GameEngine.legalBids(state: state)

        #expect(state.phase == .bidding)
        #expect(state.rules.biddingStyle == .full)
        #expect(state.mode == nil)
        #expect(state.trumpSuit == nil)
        #expect(legal.contains(.pass))
        #expect(legal.contains(.sun))
        #expect(legal.contains(.hokum(suit: upSuit)))
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

    @Test("استعلام مزايدات اللاعب لا يعرض خيارات إلا لصاحب الدور")
    func legalBidsForPlayerRequiresCurrentTurn() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 14), to: state)

        let currentID = try #require(state.currentTurnPlayerID)
        let waitingID = try #require(state.players.first { $0.id != currentID }?.id)
        let upSuit = try #require(state.bidding.upCard?.suit)

        #expect(GameEngine.legalBids(for: currentID, state: state).contains(.sun))
        #expect(GameEngine.legalBids(for: currentID, state: state).contains(.hokum(suit: upSuit)))
        #expect(GameEngine.legalBids(for: waitingID, state: state).isEmpty)
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
        let initial = GameState.newLocalMatch(rules: .standard)
        var state = try GameEngine.apply(.dealCards(seed: 9), to: initial)
        let originalDealer = state.dealerSeat

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
        #expect(state.dealerSeat == originalDealer.next)

        let replayed = try GameEngine.replay(initialState: initial, actions: state.actionHistory)
        #expect(replayed.bidding.stage == .voided)
        #expect(replayed.dealerSeat == state.dealerSeat)
        #expect(replayed.lastRoundResult == state.lastRoundResult)
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

    @Test("جولة الأشكال تسمح بالصن فوق حكم لون غير المكشوف وتُعاد حتميًا")
    func secondRoundSunCanOutbidOffSuitHokumAndReplay() throws {
        var rules = BalootRulesConfiguration.standard
        rules.multipliersEnabled = false
        rules.projectsRequireDeclaration = false
        let initial = GameState.newLocalMatch(rules: rules)
        var state = try GameEngine.apply(.dealCards(seed: 25), to: initial)

        let upSuit = try #require(state.bidding.upCard?.suit)
        for _ in 0..<4 {
            state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)
        }

        #expect(state.bidding.stage == .secondRound)
        let hokumSuit = try #require(Suit.allCases.first { $0 != upSuit })
        let hokumBuyerID = try #require(state.currentTurnPlayerID)
        #expect(GameEngine.legalBids(for: hokumBuyerID, state: state).contains(.hokum(suit: hokumSuit)))
        state = try GameEngine.apply(.placeBid(playerID: hokumBuyerID, bid: .hokum(suit: hokumSuit)), to: state)

        let sunBuyerID = try #require(state.currentTurnPlayerID)
        #expect(GameEngine.legalBids(for: sunBuyerID, state: state) == [.pass, .sun])
        state = try GameEngine.apply(.placeBid(playerID: sunBuyerID, bid: .sun), to: state)

        #expect(state.bidding.stage == .completed)
        #expect(state.bidding.declarerID == sunBuyerID)
        #expect(state.mode == .sun)
        #expect(state.trumpSuit == nil)
        #expect(state.phase == .playing)

        let replayed = try GameEngine.replay(initialState: initial, actions: state.actionHistory)
        #expect(replayed.bidding == state.bidding)
        #expect(replayed.mode == state.mode)
        #expect(replayed.trumpSuit == state.trumpSuit)
        #expect(replayed.phase == state.phase)
    }

    @Test("تعطيل الصن في الجولة الأولى يمنعه حتى فوق شراء الحكم")
    func firstRoundSunDisableAlsoBlocksSunOverHokum() throws {
        var rules = BalootRulesConfiguration.standard
        rules.sunAllowedInFirstRound = false
        rules.multipliersEnabled = false
        rules.projectsRequireDeclaration = false
        var state = GameState.newLocalMatch(rules: rules)
        state = try GameEngine.apply(.dealCards(seed: 15), to: state)

        let upSuit = try #require(state.bidding.upCard?.suit)
        let buyerID = try #require(state.currentTurnPlayerID)

        #expect(GameEngine.legalBids(for: buyerID, state: state) == [.pass, .hokum(suit: upSuit)])
        state = try GameEngine.apply(.placeBid(playerID: buyerID, bid: .hokum(suit: upSuit)), to: state)

        let nextID = try #require(state.currentTurnPlayerID)
        #expect(GameEngine.legalBids(for: nextID, state: state) == [.pass])
        #expect(throws: GameEngineError.bidding(.illegalBid)) {
            try GameEngine.apply(.placeBid(playerID: nextID, bid: .sun), to: state)
        }
    }

    @Test("اختيار AI لمزايدة ممنوعة يسقط إلى بس قانونية")
    func illegalAIBidFallsBackToLegalPass() throws {
        var rules = BalootRulesConfiguration.standard
        rules.sunAllowedInFirstRound = false
        rules.multipliersEnabled = false
        rules.projectsRequireDeclaration = false
        var state = GameState.newLocalMatch(rules: rules)
        state.players = state.players.map { player in
            var updated = player
            updated.kind = .ai
            return updated
        }
        state = try GameEngine.apply(.dealCards(seed: 15), to: state)

        let upSuit = try #require(state.bidding.upCard?.suit)
        let buyerID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.placeBid(playerID: buyerID, bid: .hokum(suit: upSuit)), to: state)

        let passerID = try #require(state.currentTurnPlayerID)
        let advanced = try GameEngine.advanceAIPlayers(
            state: state,
            agent: IllegalSunBidAgent(),
            maxSteps: 1
        )

        #expect(advanced.actionHistory.last == .placeBid(playerID: passerID, bid: .pass))
        #expect(advanced.bidding.bids.last?.bid == .pass)
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

    @Test("تقييم شراء AI يحسب الورقة المكشوفة التي سيأخذها المشتري")
    func aiBidEvaluationIncludesUpCardForBuyer() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 31), to: state)

        let playerID = try #require(state.currentTurnPlayerID)
        state.bidding.upCard = PlayingCard(suit: .spades, rank: .queen)
        let hand = [
            PlayingCard(suit: .spades, rank: .jack),
            PlayingCard(suit: .spades, rank: .nine),
            PlayingCard(suit: .hearts, rank: .seven),
            PlayingCard(suit: .diamonds, rank: .eight),
            PlayingCard(suit: .clubs, rank: .seven)
        ]
        state.hands[playerID] = hand

        let legal = GameEngine.legalBids(for: playerID, state: state)

        #expect(HandEvaluator.hokumScore(hand: hand, trumpSuit: .spades) == Int.min)
        #expect(BiddingPolicy.standard.chooseBid(hand: hand, legalBids: legal, state: state) == .hokum(suit: .spades))
    }
}

// MARK: - المضاعفات

@Suite("المضاعفات داخل اللعب")
struct MultiplierTests {
    private struct IllegalMultiplierAgent: BalootAgent {
        func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard {
            legalCards.first ?? PlayingCard(suit: .spades, rank: .seven)
        }

        func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?) {
            (.sun, nil)
        }

        func chooseBid(hand: [PlayingCard], legalBids: [Bid], state: GameState) -> Bid {
            .pass
        }

        func chooseMultiplierAction(hand: [PlayingCard], state: GameState) -> MultiplierDecision {
            .raise(.quadruple)
        }
    }

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

    @Test("حركات المضاعفة القانونية تعكس حق الدبل الابتدائي")
    func legalMultiplierActionsExposeInitialDoubleRight() throws {
        let state = try stateInDoublingStage()
        let doublerID = try #require(state.currentTurnPlayerID)
        let declarerID = try #require(state.bidding.declarerID)

        #expect(GameEngine.legalMultiplierActions(for: doublerID, state: state) == [.pass, .raise(.double)])
        #expect(GameEngine.legalMultiplierActions(for: declarerID, state: state).isEmpty)
    }

    @Test("فريق المشتري لا يملك حق الدبل الابتدائي")
    func declaringTeamCannotDoubleItself() throws {
        let state = try stateInDoublingStage()
        let declarer = try #require(state.declarer)

        #expect(throws: GameEngineError.notPlayersTurn) {
            try GameEngine.apply(.raiseMultiplier(playerID: declarer.id, level: .double), to: state)
        }
    }

    @Test("تمرير المضاعفة يُرفض إن لم يكن اللاعب من الفريق صاحب حق التصعيد")
    func passMultiplierRequiresEligibleRaisingTeam() throws {
        var state = try stateInDoublingStage()
        let declarer = try #require(state.declarer)
        state.currentTurnPlayerID = declarer.id

        #expect(throws: GameEngineError.bidding(.notEligibleToRaise)) {
            try GameEngine.apply(.passMultiplier(playerID: declarer.id), to: state)
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

    @Test("حركات المضاعفة القانونية بعد الدبل تسمح بالثري للفريق المقابل وبالقفل لصاحب الدبل")
    func legalMultiplierActionsExposeEscalationAndLockRights() throws {
        var state = try stateInDoublingStage()
        let doublerID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.raiseMultiplier(playerID: doublerID, level: .double), to: state)
        let raiserID = try #require(state.currentTurnPlayerID)

        #expect(GameEngine.legalMultiplierActions(for: raiserID, state: state) == [.pass, .raise(.triple)])
        #expect(GameEngine.legalMultiplierActions(for: doublerID, state: state) == [.lock])
    }

    @Test("قرار AI غير القانوني في المضاعفة يسقط إلى تمرير قانوني")
    func aiIllegalMultiplierDecisionFallsBackToLegalPass() throws {
        var state = try stateInDoublingStage()
        state.players = state.players.map { player in
            var updated = player
            updated.kind = .ai
            return updated
        }
        let playerID = try #require(state.currentTurnPlayerID)

        let advanced = try GameEngine.advanceAIPlayers(
            state: state,
            agent: IllegalMultiplierAgent(),
            maxSteps: 1
        )

        #expect(advanced.actionHistory.last == .passMultiplier(playerID: playerID))
        #expect(advanced.bidding.doublingPasses == 1)
        #expect(advanced.bidding.stage == .doubling)
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

        // صاحب الدبل يستطيع القفل حتى بعد انتقال حق التصعيد للفريق المقابل.
        state = try GameEngine.apply(.lockMultiplier(playerID: doublerID), to: state)

        #expect(state.bidding.stage == .completed)
        #expect(state.bidding.isLocked)
        #expect(state.bidding.multiplier == .double)
        #expect(state.actionHistory.last == .lockMultiplier(playerID: doublerID))
    }

    @Test("حركات المضاعفة القانونية فارغة خارج مرحلة المضاعفة")
    func legalMultiplierActionsAreEmptyOutsideDoubling() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 17), to: state)
        let playerID = try #require(state.currentTurnPlayerID)

        #expect(GameEngine.legalMultiplierActions(for: playerID, state: state).isEmpty)
    }

    @Test("إعلان نفس المشروع مرتين يُرفض بدل مضاعفة نقاطه")
    func duplicateProjectDeclarationIsRejected() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        let player = try #require(state.player(at: state.dealerSeat.next))
        state.phase = .declaring
        state.mode = .hokum
        state.trumpSuit = .spades
        state.currentTurnPlayerID = player.id
        state.originalHands[player.id] = [
            PlayingCard(suit: .spades, rank: .king),
            PlayingCard(suit: .spades, rank: .queen),
            PlayingCard(suit: .hearts, rank: .seven)
        ]

        let belot = try #require(GameEngine.declarableProjects(for: player.id, state: state).first)

        #expect(throws: GameEngineError.bidding(.duplicateProjectDeclaration)) {
            try GameEngine.apply(.declareProjects(playerID: player.id, projects: [belot, belot]), to: state)
        }
    }

    @Test("قفل المضاعفة يُعاد من سجل الأفعال كما حدث")
    func lockedMultiplierReplaysDeterministically() throws {
        let initial = GameState.newLocalMatch(rules: .standard)
        var state = try GameEngine.apply(.dealCards(seed: 17), to: initial)
        let upSuit = try #require(state.bidding.upCard?.suit)
        let buyerID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.placeBid(playerID: buyerID, bid: .hokum(suit: upSuit)), to: state)
        for _ in 0..<3 {
            state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)
        }
        let doublerID = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.raiseMultiplier(playerID: doublerID, level: .double), to: state)
        state = try GameEngine.apply(.lockMultiplier(playerID: doublerID), to: state)

        let replayed = try GameEngine.replay(initialState: initial, actions: state.actionHistory)

        #expect(replayed.bidding == state.bidding)
        #expect(replayed.phase == state.phase)
        #expect(replayed.mode == state.mode)
        #expect(replayed.trumpSuit == state.trumpSuit)
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
        rules.kabootEnabled = false

        var trick = Trick(leaderSeat: .south)
        trick.playedCards = [
            PlayedCard(playerID: players[0].id, card: PlayingCard(suit: .spades, rank: .ace)),
            PlayedCard(playerID: players[1].id, card: PlayingCard(suit: .hearts, rank: .ace)),
            PlayedCard(playerID: players[2].id, card: PlayingCard(suit: .clubs, rank: .ten)),
            PlayedCard(playerID: players[3].id, card: PlayingCard(suit: .diamonds, rank: .king))
        ]
        trick.winnerPlayerID = players[0].id

        let single = ScoreCalculator.finalRoundScore(
            completedTricks: [trick], originalHands: [:], players: players, teams: [teamA, teamB],
            mode: .hokum, trumpSuit: .spades, rules: rules, multiplier: .none, declaredProjects: []
        )
        let tripled = ScoreCalculator.finalRoundScore(
            completedTricks: [trick], originalHands: [:], players: players, teams: [teamA, teamB],
            mode: .hokum, trumpSuit: .spades, rules: rules, multiplier: .triple, declaredProjects: []
        )

        #expect(single.multiplier == .none)
        #expect(tripled.multiplier == .triple)
        #expect(Multiplier.triple.factor(rules: rules) == rules.tripleFactor)
        #expect((single.teamPoints[teamA.id] ?? 0) > 0)
        #expect(tripled.teamPoints[teamA.id] == (single.teamPoints[teamA.id] ?? 0) * rules.tripleFactor)
        #expect(tripled.teamPoints[teamB.id] == (single.teamPoints[teamB.id] ?? 0) * rules.tripleFactor)
    }
}
