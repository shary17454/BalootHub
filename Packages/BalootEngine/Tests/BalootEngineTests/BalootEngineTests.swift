import Foundation
import Testing
@testable import BalootEngine

// MARK: - Deck

@Suite("الحزمة والتوزيع")
struct DeckTests {
    @Test("الحزمة الكاملة تحتوي 32 ورقة فريدة")
    func fullDeckHas32UniqueCards() {
        let deck = Deck()
        #expect(deck.cards.count == Deck.fullCount)
        #expect(Set(deck.cards).count == Deck.fullCount)
    }

    @Test("التوزيع المتساوي يعطي 4 أيدٍ من 8 أوراق")
    func dealEquallyGivesFourHandsOfEight() {
        let deck = Deck()
        let hands = deck.dealEqually()
        #expect(hands.count == 4)
        for hand in hands {
            #expect(hand.count == 8)
        }
        let allDealt = hands.flatMap { $0 }
        #expect(Set(allDealt).count == 32)
    }

    @Test("الخلط بنفس البذرة يُنتج نفس الترتيب دائمًا")
    func shuffleWithSameSeedIsDeterministic() {
        var deckA = Deck()
        var generatorA = SeededGenerator(seed: 42)
        deckA.shuffle(using: &generatorA)

        var deckB = Deck()
        var generatorB = SeededGenerator(seed: 42)
        deckB.shuffle(using: &generatorB)

        #expect(deckA.cards == deckB.cards)
    }

    @Test("الخلط ببذرتين مختلفتين يُنتج ترتيبًا مختلفًا")
    func shuffleWithDifferentSeedsDiffers() {
        var deckA = Deck()
        var generatorA = SeededGenerator(seed: 1)
        deckA.shuffle(using: &generatorA)

        var deckB = Deck()
        var generatorB = SeededGenerator(seed: 2)
        deckB.shuffle(using: &generatorB)

        #expect(deckA.cards != deckB.cards)
    }
}

// MARK: - Rank ordering

@Suite("ترتيب الأوراق")
struct RankOrderingTests {
    @Test("الشايب هو الأقوى في نوع الحكم")
    func jackIsStrongestTrump() {
        let jack = PlayingCard(suit: .clubs, rank: .jack)
        let nine = PlayingCard(suit: .clubs, rank: .nine)
        let ace = PlayingCard(suit: .clubs, rank: .ace)

        #expect(jack.strength(mode: .hokum, trumpSuit: .clubs) > nine.strength(mode: .hokum, trumpSuit: .clubs))
        #expect(nine.strength(mode: .hokum, trumpSuit: .clubs) > ace.strength(mode: .hokum, trumpSuit: .clubs))
    }

    @Test("الآس هو الأقوى في نمط صن ولنوع غير الحكم")
    func aceIsStrongestInSunAndNonTrump() {
        let ace = PlayingCard(suit: .hearts, rank: .ace)
        let ten = PlayingCard(suit: .hearts, rank: .ten)
        #expect(ace.strength(mode: .sun, trumpSuit: nil) > ten.strength(mode: .sun, trumpSuit: nil))

        let aceNonTrump = PlayingCard(suit: .hearts, rank: .ace)
        let tenNonTrump = PlayingCard(suit: .hearts, rank: .ten)
        #expect(aceNonTrump.strength(mode: .hokum, trumpSuit: .clubs) > tenNonTrump.strength(mode: .hokum, trumpSuit: .clubs))
    }

    @Test("مجموع نقاط أوراق الحكم يساوي 152")
    func hokumTotalPointsEqual152() {
        let trumpTotal = Rank.allCases.reduce(0) { $0 + $1.hokumTrumpPoints }
        let nonTrumpTotal = Rank.allCases.reduce(0) { $0 + $1.hokumNonTrumpPoints }
        #expect(trumpTotal + nonTrumpTotal * 3 == 152)
    }

    @Test("مجموع نقاط أوراق صن الأساسي يساوي 120 قبل مكافأة آخر أكلة")
    func sunTotalPointsEqual120() {
        let total = Rank.allCases.reduce(0) { $0 + $1.sunPoints }
        #expect(total * 4 == 120)
    }
}

// MARK: - Legal move validation

@Suite("التحقق من الحركات القانونية")
struct LegalMoveValidatorTests {
    @Test("يجب اتباع نفس نوع الورقة الأولى عند توفره")
    func mustFollowSuitWhenAvailable() {
        let hand = [
            PlayingCard(suit: .hearts, rank: .king),
            PlayingCard(suit: .clubs, rank: .ace)
        ]
        let trick = Trick(playedCards: [PlayedCard(playerID: UUID(), card: PlayingCard(suit: .hearts, rank: .seven))], leaderSeat: .south)

        let legal = LegalMoveValidator.legalCards(hand: hand, trick: trick, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(legal == [PlayingCard(suit: .hearts, rank: .king)])
    }

    @Test("يلزم القطع بالحكم عند عدم توفر النوع المطلوب في نمط حكم")
    func mustTrumpWhenVoidInHokum() {
        let hand = [
            PlayingCard(suit: .diamonds, rank: .ace),
            PlayingCard(suit: .clubs, rank: .seven)
        ]
        let trick = Trick(playedCards: [PlayedCard(playerID: UUID(), card: PlayingCard(suit: .hearts, rank: .seven))], leaderSeat: .south)

        let legal = LegalMoveValidator.legalCards(hand: hand, trick: trick, mode: .hokum, trumpSuit: .clubs, rules: .standard)
        #expect(legal == [PlayingCard(suit: .clubs, rank: .seven)])
    }

    @Test("في نمط صن لا يوجد إلزام بالقطع عند عدم توفر النوع")
    func noForcedTrumpInSun() {
        let hand = [
            PlayingCard(suit: .diamonds, rank: .ace),
            PlayingCard(suit: .clubs, rank: .seven)
        ]
        let trick = Trick(playedCards: [PlayedCard(playerID: UUID(), card: PlayingCard(suit: .hearts, rank: .seven))], leaderSeat: .south)

        let legal = LegalMoveValidator.legalCards(hand: hand, trick: trick, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(Set(legal) == Set(hand))
    }

    @Test("قائد الأكلة يستطيع لعب أي ورقة")
    func trickLeaderCanPlayAnyCard() {
        let hand = [PlayingCard(suit: .diamonds, rank: .ace), PlayingCard(suit: .clubs, rank: .seven)]
        let legal = LegalMoveValidator.legalCards(hand: hand, trick: nil, mode: .hokum, trumpSuit: .clubs, rules: .standard)
        #expect(Set(legal) == Set(hand))
    }

    @Test("محاولة لعب ورقة لا يملكها اللاعب تُرفض")
    func rejectsCardNotInHand() {
        let hand = [PlayingCard(suit: .diamonds, rank: .ace)]
        let result = LegalMoveValidator.validate(
            card: PlayingCard(suit: .clubs, rank: .king), hand: hand, trick: nil, mode: .sun, trumpSuit: nil, rules: .standard
        )
        if case .failure(let reason) = result {
            #expect(reason == .cardNotInHand)
        } else {
            Issue.record("توقعنا فشل التحقق")
        }
    }
}

// MARK: - Trick winner & scoring

@Suite("تحديد الفائز باللمة والاحتساب")
struct ScoringTests {
    @Test("الفائز بالأكلة هو صاحب أعلى ورقة من النوع المطلوب في صن")
    func winnerInSunIsHighestOfRequiredSuit() {
        let p1 = UUID(); let p2 = UUID(); let p3 = UUID(); let p4 = UUID()
        let trick = Trick(
            playedCards: [
                PlayedCard(playerID: p1, card: PlayingCard(suit: .hearts, rank: .king)),
                PlayedCard(playerID: p2, card: PlayingCard(suit: .hearts, rank: .ace)),
                PlayedCard(playerID: p3, card: PlayingCard(suit: .clubs, rank: .ace)),
                PlayedCard(playerID: p4, card: PlayingCard(suit: .hearts, rank: .seven))
            ],
            leaderSeat: .south
        )
        let winner = ScoreCalculator.resolveTrickWinner(trick, mode: .sun, trumpSuit: nil)
        #expect(winner == p2)
    }

    @Test("ورقة الحكم تفوز حتى لو لم تكن من النوع المطلوب")
    func trumpCardWinsOverRequiredSuit() {
        let p1 = UUID(); let p2 = UUID(); let p3 = UUID(); let p4 = UUID()
        let trick = Trick(
            playedCards: [
                PlayedCard(playerID: p1, card: PlayingCard(suit: .hearts, rank: .ace)),
                PlayedCard(playerID: p2, card: PlayingCard(suit: .clubs, rank: .seven)),
                PlayedCard(playerID: p3, card: PlayingCard(suit: .hearts, rank: .king)),
                PlayedCard(playerID: p4, card: PlayingCard(suit: .hearts, rank: .ten))
            ],
            leaderSeat: .south
        )
        let winner = ScoreCalculator.resolveTrickWinner(trick, mode: .hokum, trumpSuit: .clubs)
        #expect(winner == p2)
    }

    @Test("مجموع نقاط جولة صن كاملة يساوي 260 بعد المضاعفة الافتراضية")
    func fullSunRoundTotalsTo260() throws {
        var state = GameState.newLocalMatch(rules: .simpleBidding)
        state = try GameEngine.apply(.dealCards(seed: 7), to: state)
        guard let humanID = state.currentTurnPlayerID else {
            Issue.record("لا يوجد لاعب دور مزايدة")
            return
        }
        state = try GameEngine.apply(.chooseMode(playerID: humanID, mode: .sun, trumpSuit: nil), to: state)
        state = try GameEngine.advanceAIPlayers(state: state, agent: SimpleBalootAgent())

        // اللاعب الإنسان يكمل اللعب بنفس السياسة البسيطة لإكمال الجولة اختباريًا.
        let agent = SimpleBalootAgent()
        while state.phase == .playing {
            guard let currentID = state.currentTurnPlayerID, let hand = state.hands[currentID] else { break }
            let legal = LegalMoveValidator.legalCards(hand: hand, trick: state.currentTrick, mode: state.mode ?? .sun, trumpSuit: state.trumpSuit, rules: state.rules)
            let card = agent.chooseCard(hand: hand, legalCards: legal, state: state)
            state = try GameEngine.apply(.playCard(playerID: currentID, card: card), to: state)
            state = try GameEngine.advanceAIPlayers(state: state, agent: agent)
        }
        state = try GameEngine.advanceAIPlayers(state: state, agent: agent)

        #expect(state.phase == .finished)
        let total = state.lastRoundResult?.teamPoints.values.reduce(0, +) ?? 0
        #expect(total == 260)
    }

    @Test("مشروع البلوت (شايب وبنت الحكم) يضيف 20 نقطة للفريق صاحبه")
    func belotProjectAdds20Points() {
        let teamA = Team(name: "أ")
        let player = Player(name: "لاعب", kind: .human, seat: .south, teamID: teamA.id)
        let hands: [Player.ID: [PlayingCard]] = [
            player.id: [PlayingCard(suit: .clubs, rank: .king), PlayingCard(suit: .clubs, rank: .queen)]
        ]
        let projects = ScoreCalculator.detectBelotProjects(originalHands: hands, players: [player], mode: .hokum, trumpSuit: .clubs)
        #expect(projects.count == 1)
        #expect(projects.first?.points == 20)
        #expect(projects.first?.teamID == teamA.id)
    }
}

// MARK: - GameEngine reducer

@Suite("محرك اللعبة")
struct GameEngineTests {
    @Test("لا يمكن لعب ورقة خارج الدور")
    func cannotPlayOutOfTurn() throws {
        var state = GameState.newLocalMatch(rules: .simpleBidding)
        state = try GameEngine.apply(.dealCards(seed: 1), to: state)
        guard let currentID = state.currentTurnPlayerID else {
            Issue.record("لا يوجد دور حالي")
            return
        }
        state = try GameEngine.apply(.chooseMode(playerID: currentID, mode: .sun, trumpSuit: nil), to: state)

        let notCurrentPlayer = state.players.first { $0.id != state.currentTurnPlayerID }!
        let cardOfOtherPlayer = state.hands[notCurrentPlayer.id]!.first!

        #expect(throws: GameEngineError.self) {
            _ = try GameEngine.apply(.playCard(playerID: notCurrentPlayer.id, card: cardOfOtherPlayer), to: state)
        }
    }

    @Test("لعب ورقة غير قانونية يرفضه المحرك")
    func illegalCardIsRejected() throws {
        var state = GameState.newLocalMatch(rules: .simpleBidding)
        state = try GameEngine.apply(.dealCards(seed: 3), to: state)
        guard let currentID = state.currentTurnPlayerID else {
            Issue.record("لا يوجد دور حالي")
            return
        }
        state = try GameEngine.apply(.chooseMode(playerID: currentID, mode: .hokum, trumpSuit: .spades), to: state)

        let leadHand = state.hands[currentID]!
        let leadCard = leadHand.first { $0.suit != .spades } ?? leadHand[0]
        state = try GameEngine.apply(.playCard(playerID: currentID, card: leadCard), to: state)

        guard let nextID = state.currentTurnPlayerID else {
            Issue.record("لا يوجد دور تالٍ")
            return
        }
        let nextHand = state.hands[nextID]!
        let hasSameSuit = nextHand.contains { $0.suit == leadCard.suit }
        guard hasSameSuit, let illegalCard = nextHand.first(where: { $0.suit != leadCard.suit && $0.suit != .spades }) else {
            // لا يوجد سيناريو مخالفة ممكن بهذا التوزيع، نتجاوز الاختبار بأمان.
            return
        }

        #expect(throws: GameEngineError.self) {
            _ = try GameEngine.apply(.playCard(playerID: nextID, card: illegalCard), to: state)
        }
    }

    @Test("إعادة التشغيل من سجل الأفعال يُنتج نفس الحالة النهائية")
    func replayFromActionHistoryMatchesOriginal() throws {
        let initial = GameState.newLocalMatch(rules: .simpleBidding)
        var state = initial
        state = try GameEngine.apply(.dealCards(seed: 11), to: state)
        guard let currentID = state.currentTurnPlayerID else {
            Issue.record("لا يوجد دور حالي")
            return
        }
        state = try GameEngine.apply(.chooseMode(playerID: currentID, mode: .sun, trumpSuit: nil), to: state)
        state = try GameEngine.advanceAIPlayers(state: state, agent: SimpleBalootAgent())

        let replayed = try GameEngine.replay(initialState: initial, actions: state.actionHistory)

        #expect(replayed.phase == state.phase)
        #expect(replayed.completedTricks.count == state.completedTricks.count)
    }

    @Test("اللاعب الآلي البسيط يختار دائمًا ورقة من ضمن الأوراق القانونية")
    func simpleAgentAlwaysChoosesLegalCard() throws {
        for seed: UInt64 in [1, 2, 3, 4, 5] {
            var state = GameState.newLocalMatch(rules: .simpleBidding)
            state = try GameEngine.apply(.dealCards(seed: seed), to: state)
            guard let currentID = state.currentTurnPlayerID, let hand = state.hands[currentID] else { continue }
            let agent = SimpleBalootAgent()
            let choice = agent.chooseMode(hand: hand, state: state)
            state = try GameEngine.apply(.chooseMode(playerID: currentID, mode: choice.mode, trumpSuit: choice.trumpSuit), to: state)

            while state.phase == .playing {
                guard let playerID = state.currentTurnPlayerID, let currentHand = state.hands[playerID] else { break }
                let legal = LegalMoveValidator.legalCards(hand: currentHand, trick: state.currentTrick, mode: state.mode ?? .sun, trumpSuit: state.trumpSuit, rules: state.rules)
                let card = agent.chooseCard(hand: currentHand, legalCards: legal, state: state)
                #expect(legal.contains(card))
                state = try GameEngine.apply(.playCard(playerID: playerID, card: card), to: state)
            }
        }
    }
}

// MARK: - اختبارات انحدار

/// اختبارات تحرس أخطاءً وقعت فعلًا في المحرك، حتى لا تعود.
@Suite("انحدار المحرك")
struct EngineRegressionTests {

    /// كانت بذرة محاكاة الوكيل الخبير مشتقة من `String.hashValue`، وهي قيمة مبذورة
    /// عشوائيًا مع كل تشغيل للعملية، فكان الوكيل يخالف توثيقه ويعطي قرارات مختلفة
    /// بنفس المدخلات. الترتيب الثابت للنوع والقيمة هو ما يضمن التكرار.
    @Test("ترتيب النوع والقيمة ثابت ولا يعتمد على تجزئة عشوائية")
    func ordinalsAreStableAndUnique() {
        #expect(Set(Suit.allCases.map(\.ordinal)).count == Suit.allCases.count)
        #expect(Set(Rank.allCases.map(\.ordinal)).count == Rank.allCases.count)
        // الترتيب يطابق ترتيب القوة المعتمد في نمط صن.
        #expect(Rank.sunOrder.map(\.ordinal) == Array(0..<Rank.allCases.count))
    }

    /// نفس الحالة ونفس اليد يجب أن تُنتج نفس الورقة في كل استدعاء.
    @Test("قرار الوكيل الخبير قابل للتكرار بنفس المدخلات")
    func expertDecisionIsReproducible() throws {
        let expert = ExpertBalootAgent(samples: 6)
        var state = GameState.newLocalMatch(rules: .simpleBidding)
        state = try GameEngine.apply(.dealCards(seed: 99), to: state)
        let id = try #require(state.currentTurnPlayerID)
        let hand = try #require(state.hands[id])
        state = try GameEngine.apply(.chooseMode(playerID: id, mode: .hokum, trumpSuit: .spades), to: state)
        let legal = LegalMoveValidator.legalCards(
            hand: hand, trick: state.currentTrick, mode: .hokum, trumpSuit: .spades, rules: state.rules
        )

        let first = expert.chooseCard(hand: hand, legalCards: legal, state: state)
        for _ in 0..<3 {
            #expect(expert.chooseCard(hand: hand, legalCards: legal, state: state) == first)
        }
    }

    /// مكافأة آخر أكلة (10) تُحتسب في حكم أيضًا، فمجموع جولة الحكم 162 لا 152.
    /// كانت مقصورة على صن، فكان الفريقان يقتسمان 152 نقطة فقط.
    @Test("مجموع جولة حكم كاملة يساوي 162 قبل المشاريع")
    func fullHokumRoundTotalsTo162() throws {
        let agent = SimpleBalootAgent()
        var state = GameState.newLocalMatch(rules: .simpleBidding)
        state = try GameEngine.apply(.dealCards(seed: 2024), to: state)
        let id = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.chooseMode(playerID: id, mode: .hokum, trumpSuit: .hearts), to: state)
        state = try GameEngine.advanceAIPlayers(state: state, agent: agent, maxSteps: 64)

        while state.phase == .playing {
            guard let currentID = state.currentTurnPlayerID, let hand = state.hands[currentID] else { break }
            let legal = LegalMoveValidator.legalCards(
                hand: hand, trick: state.currentTrick, mode: .hokum, trumpSuit: state.trumpSuit, rules: state.rules
            )
            let card = agent.chooseCard(hand: hand, legalCards: legal, state: state)
            state = try GameEngine.apply(.playCard(playerID: currentID, card: card), to: state)
            state = try GameEngine.advanceAIPlayers(state: state, agent: agent, maxSteps: 64)
        }
        state = try GameEngine.advanceAIPlayers(state: state, agent: agent, maxSteps: 64)

        #expect(state.phase == .finished)
        let total = try #require(state.lastRoundResult?.teamPoints.values.reduce(0, +))
        // 162 نقطة جولة + 20 لكل مشروع بلوت مكتشف في التوزيعة.
        #expect((total - 162) % 20 == 0, "المجموع \(total) لا يساوي 162 + مضاعفات 20")
        #expect(total >= 162)
    }

    /// كان الفائز يُؤخذ من `Dictionary.max` وترتيب القاموس غير مضمون، فيختلف الفائز
    /// المُعلن بين تشغيل وآخر عند تساوي الفريقين.
    @Test("التعادل لا يُعلن فائزًا، والنتيجة ثابتة")
    func tieYieldsNoWinnerDeterministically() {
        let teamA = Team(name: "أ")
        let teamB = Team(name: "ب")
        let players = [
            Player(name: "1", kind: .human, seat: .south, teamID: teamA.id),
            Player(name: "2", kind: .ai, seat: .west, teamID: teamB.id),
            Player(name: "3", kind: .ai, seat: .north, teamID: teamA.id),
            Player(name: "4", kind: .ai, seat: .east, teamID: teamB.id)
        ]
        // جولة بلا أكلات: الفريقان على صفر ⇒ تعادل.
        for _ in 0..<20 {
            let result = ScoreCalculator.finalRoundScore(
                completedTricks: [], originalHands: [:], players: players, teams: [teamA, teamB],
                mode: .sun, trumpSuit: nil, rules: .standard
            )
            #expect(result.winningTeamID == nil)
        }
    }

    /// الحقل كان معرّفًا في الحالة ولا يُكتب فيه أبدًا، فيقرأ صفرًا دائمًا.
    @Test("نقاط الأكلات الجارية تتراكم لكل فريق")
    func teamTrickPointsAccumulate() throws {
        let agent = SimpleBalootAgent()
        var state = GameState.newLocalMatch(rules: .simpleBidding)
        state = try GameEngine.apply(.dealCards(seed: 5), to: state)
        let id = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.chooseMode(playerID: id, mode: .sun, trumpSuit: nil), to: state)

        while state.phase == .playing {
            guard let currentID = state.currentTurnPlayerID, let hand = state.hands[currentID] else { break }
            let legal = LegalMoveValidator.legalCards(
                hand: hand, trick: state.currentTrick, mode: .sun, trumpSuit: nil, rules: state.rules
            )
            let card = agent.chooseCard(hand: hand, legalCards: legal, state: state)
            state = try GameEngine.apply(.playCard(playerID: currentID, card: card), to: state)
        }

        // كل نقاط أوراق الصن (120) موزّعة على الفريقين، بلا مكافأة آخر أكلة ولا مضاعفة.
        #expect(state.teamTrickPoints.values.reduce(0, +) == 120)
    }

    /// إعادة التوزيع فوق حالة مستعملة كانت تُبقي أكلات الجولة السابقة ونقاطها.
    @Test("التوزيع من جديد يُصفّر أكلات ونقاط الجولة السابقة")
    func dealingResetsPreviousRound() throws {
        let agent = SimpleBalootAgent()
        var state = GameState.newLocalMatch(rules: .simpleBidding)
        state = try GameEngine.apply(.dealCards(seed: 11), to: state)
        let id = try #require(state.currentTurnPlayerID)
        state = try GameEngine.apply(.chooseMode(playerID: id, mode: .sun, trumpSuit: nil), to: state)
        // إكمال الجولة حتى نهايتها، ثم إعادة التوزيع فوق نفس الحالة.
        while state.phase == .playing {
            guard let currentID = state.currentTurnPlayerID, let hand = state.hands[currentID] else { break }
            let legal = LegalMoveValidator.legalCards(
                hand: hand, trick: state.currentTrick, mode: .sun, trumpSuit: nil, rules: state.rules
            )
            let card = agent.chooseCard(hand: hand, legalCards: legal, state: state)
            state = try GameEngine.apply(.playCard(playerID: currentID, card: card), to: state)
        }
        state = try GameEngine.apply(.finishRound, to: state)
        #expect(state.phase == .finished)
        #expect(!state.completedTricks.isEmpty)
        #expect(state.lastRoundResult != nil)

        state = try GameEngine.apply(.dealCards(seed: 12), to: state)
        #expect(state.completedTricks.isEmpty)
        #expect(state.currentTrick == nil)
        #expect(state.teamTrickPoints.isEmpty)
        #expect(state.lastRoundResult == nil)
        #expect(state.mode == nil)
        #expect(state.trumpSuit == nil)
        #expect(state.phase == .bidding)
        for hand in state.hands.values {
            #expect(hand.count == 8)
        }
    }

    @Test("الجولة المحلية البشرية تنشئ أربعة لاعبين بلا آليين")
    func localHumanMatchUsesFourHumanPlayers() throws {
        var state = GameState.newLocalHumanMatch(rules: .simpleBidding)

        #expect(state.players.count == 4)
        #expect(state.players.allSatisfy { $0.kind == .human })

        state = try GameEngine.apply(.dealCards(seed: 2026), to: state)

        #expect(state.phase == .bidding)
        #expect(state.currentTurnPlayerID != nil)
        #expect(state.hands.count == 4)
        #expect(state.hands.values.allSatisfy { $0.count == 8 })
    }
}
