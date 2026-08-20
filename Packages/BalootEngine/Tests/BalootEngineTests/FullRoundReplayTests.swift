import Foundation
import Testing
@testable import BalootEngine

/// حالة مباراة كل لاعبيها آليون: تكتمل الجولة كاملة بلا تدخل بشري.
private func makeAIMatch(rules: BalootRulesConfiguration = .standard) -> GameState {
    var state = GameState.newLocalMatch(rules: rules)
    state.players = state.players.map { player in
        var updated = player
        updated.kind = .ai
        return updated
    }
    return state
}

private func agent(_ level: AIProfile.Level, _ personality: AIProfile.Personality = .balanced) -> ProfiledBalootAgent {
    ProfiledBalootAgent(profile: AIProfile(
        id: "test.\(level.rawValue).\(personality.rawValue)",
        level: level, personality: personality, avatarSystemName: "person"
    ))
}

// MARK: - جولة كاملة

@Suite("جولة كاملة بالمزايدة الحقيقية")
struct FullRoundTests {

    @Test("جولات كاملة بالمزايدة الجديدة تنتهي بنتيجة صحيحة", arguments: [1, 2, 3, 7, 11, 23, 42] as [UInt64])
    func fullRoundCompletes(seed: UInt64) throws {
        var state = makeAIMatch()
        state = try GameEngine.apply(.dealCards(seed: seed), to: state)
        state = try GameEngine.advanceAIPlayers(state: state, agent: agent(.casual))

        #expect(state.phase == .finished)

        // الدورة الميتة نتيجة مشروعة أيضًا: لا مشتري ولا نقاط.
        if state.bidding.stage == .voided {
            #expect(state.completedTricks.isEmpty)
            for team in state.teams { #expect(state.lastRoundResult?.teamPoints[team.id] == 0) }
            return
        }

        #expect(state.bidding.stage == .completed)
        #expect(state.bidding.declarerID != nil)
        #expect(state.mode != nil)
        #expect(state.completedTricks.count == ScoreCalculator.tricksPerRound)
        let allHandsEmpty = state.hands.values.allSatisfy(\.isEmpty)
        #expect(allHandsEmpty)
        #expect(state.lastRoundResult != nil)
    }

    @Test("كل الأوراق تبقى محفوظة طوال الجولة بلا تكرار ولا ضياع")
    func cardConservationHolds() throws {
        var state = makeAIMatch()
        state = try GameEngine.apply(.dealCards(seed: 99), to: state)
        state = try GameEngine.advanceAIPlayers(state: state, agent: agent(.pro))

        guard state.bidding.stage == .completed else { return }

        let playedCards = state.completedTricks.flatMap { $0.playedCards.map(\.card) }
        let inHands = state.players.flatMap { state.hands[$0.id] ?? [] }
        let all = playedCards + inHands + state.undealtCards

        #expect(all.count == Deck.fullCount)
        #expect(Set(all).count == Deck.fullCount)
    }

    @Test("مجموع نقاط الجولة قبل المضاعفات يطابق المعرَّف في القواعد")
    func roundTotalMatchesRules() throws {
        var rules = BalootRulesConfiguration.standard
        rules.projectsEnabled = false
        rules.kabootEnabled = false
        rules.multipliersEnabled = false
        rules.declarerMustWinMajority = false

        for seed in [5, 15, 25] as [UInt64] {
            var state = makeAIMatch(rules: rules)
            state = try GameEngine.apply(.dealCards(seed: seed), to: state)
            state = try GameEngine.advanceAIPlayers(state: state, agent: agent(.casual))
            guard state.bidding.stage == .completed, let mode = state.mode else { continue }

            let total = state.teams.reduce(0) { $0 + (state.lastRoundResult?.teamPoints[$1.id] ?? 0) }
            let expected = mode == .hokum
                ? rules.hokumRoundTotal
                : rules.sunRoundBaseTotal * rules.sunScoreMultiplier
            #expect(total == expected, "البذرة \(seed) في نمط \(mode.rawValue)")
        }
    }
}

// MARK: - إعادة التشغيل

@Suite("حتمية إعادة التشغيل")
struct ReplayDeterminismTests {

    @Test("نفس البذرة ونفس الأفعال تُنتج نفس الحالة النهائية تمامًا")
    func replayReproducesFinalState() throws {
        let initial = makeAIMatch()
        var played = try GameEngine.apply(.dealCards(seed: 2_024), to: initial)
        played = try GameEngine.advanceAIPlayers(state: played, agent: agent(.expert))

        let replayed = try GameEngine.replay(initialState: initial, actions: played.actionHistory)

        #expect(replayed.phase == played.phase)
        #expect(replayed.mode == played.mode)
        #expect(replayed.trumpSuit == played.trumpSuit)
        #expect(replayed.bidding == played.bidding)
        #expect(replayed.declaredProjects == played.declaredProjects)
        #expect(replayed.awardedProjects == played.awardedProjects)
        #expect(replayed.kabootTeamID == played.kabootTeamID)
        #expect(replayed.lastRoundResult == played.lastRoundResult)
        #expect(replayed.completedTricks.count == played.completedTricks.count)
        for (lhs, rhs) in zip(replayed.completedTricks, played.completedTricks) {
            #expect(lhs.playedCards.map(\.card) == rhs.playedCards.map(\.card))
            #expect(lhs.winnerPlayerID == rhs.winnerPlayerID)
        }
    }

    @Test("إعادة التشغيل حتى خطوة محددة تُنتج حالة وسيطة صحيحة")
    func partialReplayStopsAtStep() throws {
        let initial = makeAIMatch()
        var played = try GameEngine.apply(.dealCards(seed: 555), to: initial)
        played = try GameEngine.advanceAIPlayers(state: played, agent: agent(.casual))

        let actions = played.actionHistory
        let midpoint = actions.count / 2
        let partial = try GameEngine.replay(initialState: initial, actions: actions, upTo: midpoint)

        #expect(partial.actionHistory.count == midpoint)
        #expect(partial.phase != .finished || midpoint == actions.count)

        // الحدود: صفر يعطي الحالة الابتدائية، وما فوق العدد يعطي الحالة النهائية.
        let none = try GameEngine.replay(initialState: initial, actions: actions, upTo: 0)
        #expect(none.actionHistory.isEmpty)
        let beyond = try GameEngine.replay(initialState: initial, actions: actions, upTo: actions.count + 50)
        #expect(beyond.actionHistory.count == actions.count)
    }

    @Test("قرارات المزايدة تُسجَّل في سجل الأفعال فتُعاد كما جرت")
    func biddingActionsAreRecorded() throws {
        var state = makeAIMatch()
        state = try GameEngine.apply(.dealCards(seed: 314), to: state)
        state = try GameEngine.advanceAIPlayers(state: state, agent: agent(.casual))

        let bidActions = state.actionHistory.filter {
            if case .placeBid = $0 { return true }
            return false
        }
        #expect(!bidActions.isEmpty)
        #expect(state.bidding.bids.count == bidActions.count)
    }
}

// MARK: - مستويات وشخصيات الذكاء الاصطناعي

@Suite("مستويات الذكاء الاصطناعي وشخصياته")
struct AIProfileTests {

    @Test("كل الخصوم الجاهزين يلعبون جولات كاملة قانونية")
    func everyRosterProfilePlaysLegally() throws {
        for profile in AIProfile.roster {
            var state = makeAIMatch()
            state = try GameEngine.apply(.dealCards(seed: 77), to: state)
            state = try GameEngine.advanceAIPlayers(state: state, agent: ProfiledBalootAgent(profile: profile))
            #expect(state.phase == .finished, "الخصم \(profile.id) لم يُكمل الجولة")
        }
    }

    @Test("قرار الشخصية حتمي: نفس اليد تعطي نفس المزايدة")
    func personalityDecisionsAreDeterministic() throws {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 808), to: state)

        let playerID = try #require(state.currentTurnPlayerID)
        let hand = try #require(state.hands[playerID])
        let legal = state.bidding.legalBids(rules: state.rules)
        let subject = agent(.expert, .aggressive)

        let first = subject.chooseBid(hand: hand, legalBids: legal, state: state)
        for _ in 0..<20 {
            #expect(subject.chooseBid(hand: hand, legalBids: legal, state: state) == first)
        }
    }

    @Test("المخاطر يشتري في مواضع يمرّ فيها المحافظ")
    func riskProfilesBidMoreOften() throws {
        let gambler = agent(.pro, .gambler)
        let conservative = agent(.pro, .conservative)

        var gamblerBids = 0
        var conservativeBids = 0

        for seed in (1...40).map(UInt64.init) {
            var state = GameState.newLocalMatch(rules: .standard)
            state = try GameEngine.apply(.dealCards(seed: seed), to: state)
            let playerID = try #require(state.currentTurnPlayerID)
            let hand = try #require(state.hands[playerID])
            let legal = state.bidding.legalBids(rules: state.rules)

            if gambler.chooseBid(hand: hand, legalBids: legal, state: state).isBid { gamblerBids += 1 }
            if conservative.chooseBid(hand: hand, legalBids: legal, state: state).isBid { conservativeBids += 1 }
        }

        #expect(gamblerBids > conservativeBids, "المخاطر \(gamblerBids) مقابل المحافظ \(conservativeBids)")
    }

    @Test("متخصص الحكم يميل للحكم أكثر من متخصص الصن")
    func specialistsPreferTheirMode() throws {
        let hokumFan = agent(.pro, .hokumSpecialist)
        let sunFan = agent(.pro, .sunSpecialist)

        var hokumChoices = 0
        var sunFanHokumChoices = 0

        for seed in (100...160).map(UInt64.init) {
            var state = GameState.newLocalMatch(rules: .standard)
            state = try GameEngine.apply(.dealCards(seed: seed), to: state)
            let playerID = try #require(state.currentTurnPlayerID)
            let hand = try #require(state.hands[playerID])
            let legal = state.bidding.legalBids(rules: state.rules)

            if hokumFan.chooseBid(hand: hand, legalBids: legal, state: state).mode == .hokum { hokumChoices += 1 }
            if sunFan.chooseBid(hand: hand, legalBids: legal, state: state).mode == .hokum { sunFanHokumChoices += 1 }
        }

        #expect(hokumChoices >= sunFanHokumChoices)
    }

    @Test("المستوى الأعلى يحاكي أعمق")
    func higherLevelsSimulateDeeper() {
        #expect(AIProfile.Level.beginner.monteCarloSamples == 0)
        #expect(AIProfile.Level.casual.monteCarloSamples == 0)
        #expect(AIProfile.Level.pro.monteCarloSamples < AIProfile.Level.expert.monteCarloSamples)
        #expect(AIProfile.Level.expert.monteCarloSamples < AIProfile.Level.sheikh.monteCarloSamples)
        #expect(!AIProfile.Level.beginner.tracksCardMemory)
        #expect(AIProfile.Level.casual.tracksCardMemory)
    }

    @Test("اختيار الخصوم لمستوى معيّن حتمي ويعطي ثلاثة خصوم")
    func opponentSelectionIsDeterministic() {
        for level in AIProfile.Level.allCases {
            let first = AIProfile.opponents(for: level)
            #expect(first.count == 3)
            let allMatchLevel = first.allSatisfy { $0.level == level }
            #expect(allMatchLevel)
            #expect(AIProfile.opponents(for: level) == first)
        }
    }

    @Test("اختيار خصوم المستوى لا يكرر معرّفات الخصوم")
    func opponentSelectionKeepsUniqueIDs() {
        for level in AIProfile.Level.allCases {
            let opponents = AIProfile.opponents(for: level)
            #expect(Set(opponents.map(\.id)).count == opponents.count)
        }
    }

    @Test("كل خصم يملك بيانات عرض قابلة للاستخدام في الواجهة والإحصائيات")
    func profilesExposeDisplayMetadata() {
        for profile in AIProfile.roster {
            #expect(!profile.displayName.isEmpty)
            #expect(!profile.levelTitle.isEmpty)
            #expect(!profile.personalityTitle.isEmpty)
            #expect(!profile.profileDescription.isEmpty)
            #expect(!profile.styleSummary.isEmpty)
            #expect(!profile.analysisSummary.isEmpty)
            #expect((0...100).contains(profile.riskScore))
            #expect((0...100).contains(profile.multiplierAggression))
        }
    }

    @Test("ملخص تحليل الخصم يعكس الذاكرة والمحاكاة")
    func profileAnalysisSummaryReflectsAnalysisDepth() {
        let beginner = AIProfile(id: "test.beginner", level: .beginner, personality: .balanced, avatarSystemName: "person.fill")
        let casual = AIProfile(id: "test.casual", level: .casual, personality: .balanced, avatarSystemName: "person.fill")
        let sheikh = AIProfile(id: "test.sheikh", level: .sheikh, personality: .balanced, avatarSystemName: "crown.fill")

        #expect(beginner.analysisSummary.contains("بلا ذاكرة"))
        #expect(casual.analysisSummary.contains("يتتبع"))
        #expect(sheikh.analysisSummary.contains("\(AIProfile.Level.sheikh.monteCarloSamples)"))
    }

    @Test("ميل الصن والحكم في بيانات الخصم يطابق شخصيته")
    func profileModePreferenceMatchesPersonality() {
        let hokum = AIProfile(
            id: "test.hokum", level: .pro, personality: .hokumSpecialist,
            avatarSystemName: "suit.spade.fill"
        )
        let sun = AIProfile(
            id: "test.sun", level: .pro, personality: .sunSpecialist,
            avatarSystemName: "sun.max.fill"
        )
        let balanced = AIProfile(
            id: "test.balanced", level: .pro, personality: .balanced,
            avatarSystemName: "person.fill"
        )

        #expect(hokum.preferredMode == .hokum)
        #expect(sun.preferredMode == .sun)
        #expect(balanced.preferredMode == nil)
    }

    @Test("المخاطر أكثر مخاطرة وميلًا للمضاعفة من المحافظ")
    func profileRiskMetadataReflectsBiddingPolicy() {
        let gambler = AIProfile(
            id: "test.gambler", level: .expert, personality: .gambler,
            avatarSystemName: "dice.fill"
        )
        let conservative = AIProfile(
            id: "test.conservative", level: .expert, personality: .conservative,
            avatarSystemName: "shield.fill"
        )

        #expect(gambler.riskScore > conservative.riskScore)
        #expect(gambler.multiplierAggression > conservative.multiplierAggression)
    }
}

// MARK: - تقييم اليد

@Suite("تقييم اليد")
struct HandEvaluatorTests {

    @Test("الحكم على أقل من ثلاث أوراق مرفوض تمامًا")
    func shortTrumpIsNeverPlayable() {
        let hand = [PlayingCard(suit: .spades, rank: .ace), PlayingCard(suit: .spades, rank: .king),
                    PlayingCard(suit: .hearts, rank: .ace), PlayingCard(suit: .hearts, rank: .ten)]
        #expect(HandEvaluator.hokumScore(hand: hand, trumpSuit: .spades) == Int.min)
    }

    @Test("يد غنية بالآسات تقيَّم صنًّا أعلى من يد فقيرة")
    func aceRichHandScoresHigherInSun() {
        let rich = Suit.allCases.map { PlayingCard(suit: $0, rank: .ace) }
        let poor = Suit.allCases.map { PlayingCard(suit: $0, rank: .seven) }
        #expect(HandEvaluator.sunScore(hand: rich) > HandEvaluator.sunScore(hand: poor))
    }

    @Test("ولد وتسعة الحكم يرفعان تقييم لونهما")
    func trumpJackAndNineRaiseScore() {
        let base = [PlayingCard(suit: .clubs, rank: .seven), PlayingCard(suit: .clubs, rank: .eight),
                    PlayingCard(suit: .clubs, rank: .queen)]
        let strong = [PlayingCard(suit: .clubs, rank: .jack), PlayingCard(suit: .clubs, rank: .nine),
                      PlayingCard(suit: .clubs, rank: .queen)]
        #expect(HandEvaluator.hokumScore(hand: strong, trumpSuit: .clubs)
                > HandEvaluator.hokumScore(hand: base, trumpSuit: .clubs))
    }

    @Test("التقييم حتمي ولا يتأثر بترتيب الأوراق في اليد")
    func evaluationIsOrderIndependent() {
        let hand = [PlayingCard(suit: .clubs, rank: .jack), PlayingCard(suit: .clubs, rank: .nine),
                    PlayingCard(suit: .hearts, rank: .ace), PlayingCard(suit: .clubs, rank: .queen),
                    PlayingCard(suit: .spades, rank: .ten)]
        let first = HandEvaluator.evaluate(hand: hand)
        #expect(HandEvaluator.evaluate(hand: hand.reversed()) == first)
    }
}
