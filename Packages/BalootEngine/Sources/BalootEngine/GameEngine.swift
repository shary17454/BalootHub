import Foundation

/// أخطاء تطبيق فعل على حالة اللعبة.
public enum GameEngineError: Error, Sendable, Equatable {
    case wrongPhase(expected: GamePhase, actual: GamePhase)
    case illegalMove(IllegalMoveReason)
    case unknownPlayer
    case notPlayersTurn
}

/// المسؤول الوحيد عن الانتقال بين حالات اللعبة. لا يحتوي أي منطق واجهة.
/// يستقبل فعلًا (`GameAction`) وحالة حالية، ويُعيد الحالة الجديدة أو يرمي خطأ عند حركة غير قانونية.
public enum GameEngine {
    /// يطبّق فعلًا واحدًا على الحالة ويُعيد الحالة الناتجة. الحالة المُمرَّرة لا تتغيّر (immutable).
    @discardableResult
    public static func apply(_ action: GameAction, to state: GameState) throws -> GameState {
        var newState = state

        switch action {
        case .dealCards(let seed):
            try applyDeal(seed: seed, to: &newState)

        case .chooseMode(let playerID, let mode, let trumpSuit):
            try applyChooseMode(playerID: playerID, mode: mode, trumpSuit: trumpSuit, to: &newState)

        case .playCard(let playerID, let card):
            try applyPlayCard(playerID: playerID, card: card, to: &newState)

        case .finishRound:
            try applyFinishRound(to: &newState)
        }

        newState.actionHistory.append(action)
        return newState
    }

    /// يعيد بناء الحالة كاملة من الصفر بتشغيل كل الأفعال المسجّلة بالترتيب.
    /// يُستخدم لإعادة تشغيل جولة سابقة من سجل أفعالها فقط.
    public static func replay(initialState: GameState, actions: [GameAction]) throws -> GameState {
        var state = initialState
        state.actionHistory = []
        for action in actions {
            state = try apply(action, to: state)
        }
        return state
    }

    /// يحسب الفعل التالي للاعب الآلي صاحب الدور **دون تطبيقه**، ويُعيد `nil`
    /// إن لم يكن الدور للاعب آلي أو تعذّر تحديد فعل.
    ///
    /// فصل الحساب عن التطبيق ضروري للأداء: اختيار الورقة في ``ExpertBalootAgent``
    /// بحث بالمحاكاة يستغرق زمنًا محسوسًا، وتشغيله على خيط الواجهة يُجمّدها قبل كل
    /// نقلة. الدالة `nonisolated` وكل مدخلاتها ومخرجاتها `Sendable`، فيمكن تنفيذها
    /// على خيط خلفي ثم تطبيق النتيجة على `@MainActor`.
    public static func nextAIAction(state: GameState, agent: BalootAgent) -> GameAction? {
        switch state.phase {
        case .bidding:
            guard let playerID = state.currentTurnPlayerID,
                  state.player(id: playerID)?.kind == .ai,
                  let hand = state.hands[playerID] else { return nil }
            let choice = agent.chooseMode(hand: hand, state: state)
            return .chooseMode(playerID: playerID, mode: choice.mode, trumpSuit: choice.trumpSuit)

        case .playing:
            guard let playerID = state.currentTurnPlayerID,
                  state.player(id: playerID)?.kind == .ai,
                  let hand = state.hands[playerID], !hand.isEmpty else { return nil }
            let legal = LegalMoveValidator.legalCards(
                hand: hand, trick: state.currentTrick,
                mode: state.mode ?? .sun, trumpSuit: state.trumpSuit, rules: state.rules
            )
            guard !legal.isEmpty else { return nil }
            return .playCard(playerID: playerID, card: agent.chooseCard(hand: hand, legalCards: legal, state: state))

        case .scoring:
            return .finishRound

        case .setup, .dealing, .finished:
            return nil
        }
    }

    /// يُشغّل دور المزايدة أو اللعب تلقائيًا لكل اللاعبين الآليين بالتتابع،
    /// ويتوقف عند دور لاعب إنسان أو عند انتهاء الجولة.
    /// - Parameter maxSteps: سقف أمان ضد أي حلقة لا تنتهي. القيمة الافتراضية تكفي
    ///   جولة كاملة كل لاعبيها آليون: مزايدة واحدة + 32 ورقة + إنهاء الجولة = 34 خطوة.
    ///   كانت 32 فتتوقف قبل نهاية الجولة بخطوتين دون أي إشارة.
    public static func advanceAIPlayers(state: GameState, agent: BalootAgent, maxSteps: Int = 40) throws -> GameState {
        var current = state
        var steps = 0

        while steps < maxSteps, let action = nextAIAction(state: current, agent: agent) {
            steps += 1
            current = try apply(action, to: current)
        }

        return current
    }

    // MARK: - Deal

    private static func applyDeal(seed: UInt64, to state: inout GameState) throws {
        // التوزيع مسموح من بداية المباراة ومن جولة منتهية أيضًا: إعادة التوزيع بعد
        // انتهاء الجولة هي المسار الطبيعي لـ"جولة جديدة" على نفس اللاعبين، وكان
        // المحرك يرفضها فيضطر المستدعي إلى بناء حالة جديدة من الصفر.
        guard state.phase == .setup || state.phase == .dealing || state.phase == .finished else {
            throw GameEngineError.wrongPhase(expected: .setup, actual: state.phase)
        }
        guard state.players.count == 4 else {
            throw GameEngineError.unknownPlayer
        }

        var deck = Deck()
        var generator = SeededGenerator(seed: seed)
        deck.shuffle(using: &generator)

        let dealtHands = deck.dealEqually()
        var hands: [Player.ID: [PlayingCard]] = [:]
        for (seat, cards) in zip(SeatPosition.allCases, dealtHands) {
            if let player = state.player(at: seat) {
                hands[player.id] = cards
            }
        }

        state.hands = hands
        state.originalHands = hands
        // تصفير بقايا الجولة السابقة: بدونها تتراكم أكلات ونقاط جولة قديمة على جولة
        // جديدة وُزّعت فوق نفس الحالة (وهو ما يفعله `replay` وأي إعادة توزيع).
        state.completedTricks = []
        state.currentTrick = nil
        state.teamTrickPoints = [:]
        state.lastRoundResult = nil
        state.mode = nil
        state.trumpSuit = nil
        state.phase = .bidding
        // المزايدة تبدأ من اللاعب التالي للموزّع.
        state.currentTurnPlayerID = TurnManager.player(at: state.dealerSeat.next, in: state.players)?.id
    }

    // MARK: - Choose mode (bidding)

    private static func applyChooseMode(playerID: Player.ID, mode: GameMode, trumpSuit: Suit?, to state: inout GameState) throws {
        guard state.phase == .bidding else {
            throw GameEngineError.wrongPhase(expected: .bidding, actual: state.phase)
        }
        guard state.player(id: playerID) != nil else {
            throw GameEngineError.unknownPlayer
        }
        if mode == .hokum && trumpSuit == nil {
            throw GameEngineError.illegalMove(.wrongPhase)
        }

        state.mode = mode
        state.trumpSuit = mode == .hokum ? trumpSuit : nil
        state.phase = .playing

        let leaderID = state.currentTurnPlayerID ?? state.players.first?.id
        guard let leaderID, let leaderPlayer = state.player(id: leaderID) else {
            throw GameEngineError.unknownPlayer
        }

        state.currentTrick = Trick(leaderSeat: leaderPlayer.seat)
        state.currentTurnPlayerID = leaderID
    }

    // MARK: - Play card

    private static func applyPlayCard(playerID: Player.ID, card: PlayingCard, to state: inout GameState) throws {
        guard state.phase == .playing else {
            throw GameEngineError.wrongPhase(expected: .playing, actual: state.phase)
        }
        guard state.currentTurnPlayerID == playerID else {
            throw GameEngineError.notPlayersTurn
        }
        guard let mode = state.mode else {
            throw GameEngineError.wrongPhase(expected: .playing, actual: state.phase)
        }
        guard var trick = state.currentTrick else {
            throw GameEngineError.wrongPhase(expected: .playing, actual: state.phase)
        }
        guard let hand = state.hands[playerID] else {
            throw GameEngineError.unknownPlayer
        }

        let validation = LegalMoveValidator.validate(
            card: card, hand: hand, trick: trick, mode: mode, trumpSuit: state.trumpSuit, rules: state.rules
        )
        if case .failure(let reason) = validation {
            throw GameEngineError.illegalMove(reason)
        }

        state.hands[playerID]?.removeAll { $0 == card }
        trick.playedCards.append(PlayedCard(playerID: playerID, card: card))

        if trick.isComplete {
            let winnerID = ScoreCalculator.resolveTrickWinner(trick, mode: mode, trumpSuit: state.trumpSuit)
            trick.winnerPlayerID = winnerID
            state.completedTricks.append(trick)
            state.currentTrick = nil

            // نقاط الأوراق الجارية لكل فريق (بلا مكافأة آخر أكلة ولا مضاعفات). كان الحقل
            // معرّفًا في ``GameState`` ولا يُكتب فيه أبدًا، فكان يقرأ صفرًا دائمًا — بما في ذلك
            // في ``ExpertBalootAgent`` الذي يعتمده لتقييم المحاكاة غير المكتملة.
            if let winnerID, let winnerTeamID = state.player(id: winnerID)?.teamID {
                let cardPoints = trick.playedCards.reduce(0) {
                    $0 + $1.card.points(mode: mode, trumpSuit: state.trumpSuit)
                }
                state.teamTrickPoints[winnerTeamID, default: 0] += cardPoints
            }

            if state.completedTricks.count == ScoreCalculator.tricksPerRound {
                state.phase = .scoring
                state.currentTurnPlayerID = nil
            } else {
                // تعذّر تحديد فائز بأكلة مكتملة يعني خللًا في الحالة. تركُها بلا أكلة جارية
                // كان يُجمّد الجولة بصمت (مرحلة لعب بلا دور)، فنُظهرها خطأً واضحًا بدلًا من ذلك.
                guard let winnerID, let winnerPlayer = state.player(id: winnerID) else {
                    throw GameEngineError.unknownPlayer
                }
                state.currentTrick = Trick(leaderSeat: winnerPlayer.seat)
                state.currentTurnPlayerID = winnerID
            }
        } else {
            guard let currentPlayer = state.player(id: playerID),
                  let nextPlayer = TurnManager.nextPlayer(after: currentPlayer, in: state.players) else {
                throw GameEngineError.unknownPlayer
            }
            state.currentTrick = trick
            state.currentTurnPlayerID = nextPlayer.id
        }
    }

    // MARK: - Finish round

    private static func applyFinishRound(to state: inout GameState) throws {
        guard state.phase == .scoring else {
            throw GameEngineError.wrongPhase(expected: .scoring, actual: state.phase)
        }
        guard let mode = state.mode else {
            throw GameEngineError.wrongPhase(expected: .scoring, actual: state.phase)
        }

        state.lastRoundResult = ScoreCalculator.finalRoundScore(
            completedTricks: state.completedTricks,
            originalHands: state.originalHands,
            players: state.players,
            teams: state.teams,
            mode: mode,
            trumpSuit: state.trumpSuit,
            rules: state.rules
        )
        state.phase = .finished
    }
}
