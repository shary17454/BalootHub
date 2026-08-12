import Foundation

/// أخطاء تطبيق فعل على حالة اللعبة.
public enum GameEngineError: Error, Sendable, Equatable {
    case wrongPhase(expected: GamePhase, actual: GamePhase)
    case illegalMove(IllegalMoveReason)
    case unknownPlayer
    case notPlayersTurn
    /// خطأ متعلق بدورة المزايدة أو المضاعفة أو إعلان المشاريع.
    case bidding(BiddingError)
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

        case .placeBid(let playerID, let bid):
            try BiddingEngine.placeBid(playerID: playerID, bid: bid, state: &newState)

        case .raiseMultiplier(let playerID, let level):
            try BiddingEngine.raiseMultiplier(playerID: playerID, level: level, state: &newState)

        case .passMultiplier(let playerID):
            try BiddingEngine.passMultiplier(playerID: playerID, state: &newState)

        case .lockMultiplier(let playerID):
            try BiddingEngine.lockMultiplier(playerID: playerID, state: &newState)

        case .declareProjects(let playerID, let projects):
            try BiddingEngine.declareProjects(playerID: playerID, projects: projects, state: &newState)

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

    /// يعيد بناء الحالة حتى فعل معيّن فقط — أساس شاشة الـReplay خطوةً بخطوة.
    ///
    /// - Parameter step: عدد الأفعال المطبَّقة (0 = الحالة الابتدائية قبل أي فعل).
    public static func replay(initialState: GameState, actions: [GameAction], upTo step: Int) throws -> GameState {
        let bounded = max(0, min(step, actions.count))
        return try replay(initialState: initialState, actions: Array(actions.prefix(bounded)))
    }

    // MARK: - استعلامات الحالة (مصدر حقيقة واحد للواجهة والتعليم والاختبارات)

    /// المزايدات القانونية المتاحة الآن.
    public static func legalBids(state: GameState) -> [Bid] {
        guard state.phase == .bidding else { return [] }
        return state.bidding.legalBids(rules: state.rules)
    }

    /// المزايدات القانونية للاعب محدد الآن.
    ///
    /// هذه هي الدالة الأنسب للواجهة: لا يكفي أن تكون مرحلة اللعبة `bidding`، بل يجب
    /// أن يكون اللاعب نفسه صاحب الدور. بدون هذا الشرط قد تعرض واجهة متعددة البشر
    /// خيارات مزايدة للاعب غير نشط إذا قرأت الحالة في لحظة انتقال.
    public static func legalBids(for playerID: Player.ID, state: GameState) -> [Bid] {
        guard state.phase == .bidding,
              state.currentTurnPlayerID == playerID,
              state.player(id: playerID) != nil
        else { return [] }
        return state.bidding.legalBids(rules: state.rules)
    }

    /// حركات المضاعفة القانونية للاعب محدد في لحظة المزايدة الحالية.
    public static func legalMultiplierActions(for playerID: Player.ID, state: GameState) -> [LegalMultiplierAction] {
        BiddingEngine.legalMultiplierActions(for: playerID, state: state)
    }

    /// المشاريع التي يستطيع لاعب معيّن إعلانها.
    public static func declarableProjects(for playerID: Player.ID, state: GameState) -> [Project] {
        BiddingEngine.declarableProjects(for: playerID, state: state)
    }

    /// الأوراق القانونية للاعب معيّن في وضعه الحالي.
    public static func legalCards(for playerID: Player.ID, state: GameState) -> [PlayingCard] {
        guard state.phase == .playing, let mode = state.mode,
              let hand = state.hands[playerID] else { return [] }
        return LegalMoveValidator.legalCards(
            hand: hand, trick: state.currentTrick, mode: mode,
            trumpSuit: state.trumpSuit, rules: state.rules
        )
    }

    /// أفعال لعب الورق القانونية للاعب معيّن في وضعه الحالي.
    ///
    /// تستخدمها الواجهة، التدريب، وReplay عندما تحتاج "حركة" قابلة للتطبيق بدل
    /// قائمة أوراق فقط. تبقى مشتقة من ``legalCards`` حتى لا يتكرر منطق القواعد.
    public static func legalMoves(for playerID: Player.ID, state: GameState) -> [GameAction] {
        legalCards(for: playerID, state: state).map { .playCard(playerID: playerID, card: $0) }
    }

    /// نتيجة التحقق من لعب ورقة معيّنة، بلا تطبيق أي تغيير.
    public static func validationResult(playerID: Player.ID, card: PlayingCard, state: GameState) -> Result<Void, IllegalMoveReason> {
        guard state.phase == .playing, let mode = state.mode else { return .failure(.wrongPhase) }
        guard state.currentTurnPlayerID == playerID else { return .failure(.notPlayersTurn) }
        guard let hand = state.hands[playerID] else { return .failure(.cardNotInHand) }
        return LegalMoveValidator.validate(
            card: card, hand: hand, trick: state.currentTrick, mode: mode,
            trumpSuit: state.trumpSuit, rules: state.rules
        )
    }

    /// يقيّم كل أوراق يد اللاعب الحالية دفعة واحدة دون تغيير حالة اللعبة.
    ///
    /// الواجهة، التدريب، وReplay تستخدم هذا المخرج الموحد حتى تبقى أسباب المنع
    /// مطابقة تمامًا لمنطق ``LegalMoveValidator``.
    public static func moveValidations(for playerID: Player.ID, state: GameState) -> [MoveValidation] {
        guard let hand = state.hands[playerID] else { return [] }
        return hand.map { card in
            switch validationResult(playerID: playerID, card: card, state: state) {
            case .success:
                MoveValidation(card: card, isLegal: true, invalidReason: nil)
            case .failure(let reason):
                MoveValidation(card: card, isLegal: false, invalidReason: reason)
            }
        }
    }

    /// سبب رفض ورقة معيّنة، أو `nil` إن كانت قانونية.
    ///
    /// وجود هذا الاستعلام هو ما يسمح للواجهة أن **تشرح** المنع بدل أن تتجاهل الضغطة
    /// بصمت، وللدروس أن تستخدم نفس التفسير الذي يستخدمه المحرك حرفيًا.
    public static func invalidMoveReason(playerID: Player.ID, card: PlayingCard, state: GameState) -> IllegalMoveReason? {
        if case .failure(let reason) = validationResult(playerID: playerID, card: card, state: state) {
            return reason
        }
        return nil
    }

    // MARK: - قرارات اللاعب الآلي

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
            return nextBiddingAction(state: state, agent: agent)

        case .declaring:
            guard let playerID = state.currentTurnPlayerID,
                  state.player(id: playerID)?.kind == .ai else { return nil }
            let available = BiddingEngine.declarableProjects(for: playerID, state: state)
            return .declareProjects(playerID: playerID, projects: agent.chooseProjectsToDeclare(available: available, state: state))

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

    private static func nextBiddingAction(state: GameState, agent: BalootAgent) -> GameAction? {
        guard let playerID = state.currentTurnPlayerID,
              state.player(id: playerID)?.kind == .ai,
              let hand = state.hands[playerID] else { return nil }

        switch state.bidding.stage {
        case .firstRound, .secondRound:
            guard state.rules.biddingStyle == .full else {
                // النمط المبسّط: اختيار مباشر بلا دورة مزايدة.
                let choice = agent.chooseMode(hand: hand, state: state)
                return .chooseMode(playerID: playerID, mode: choice.mode, trumpSuit: choice.trumpSuit)
            }
            let legal = state.bidding.legalBids(rules: state.rules)
            guard !legal.isEmpty else { return nil }
            return .placeBid(playerID: playerID, bid: agent.chooseBid(hand: hand, legalBids: legal, state: state))

        case .doubling:
            let legal = legalMultiplierActions(for: playerID, state: state)
            guard !legal.isEmpty else { return nil }
            let decision = agent.chooseMultiplierAction(hand: hand, state: state)
            return legalMultiplierGameAction(playerID: playerID, decision: decision, legal: legal)

        case .completed, .voided:
            return nil
        }
    }

    static func legalMultiplierGameAction(
        playerID: Player.ID,
        decision: MultiplierDecision,
        legal: [LegalMultiplierAction]
    ) -> GameAction? {
        switch decision {
        case .raise(let level) where legal.contains(.raise(level)):
            return .raiseMultiplier(playerID: playerID, level: level)
        case .lock where legal.contains(.lock):
            return .lockMultiplier(playerID: playerID)
        case .pass where legal.contains(.pass):
            return .passMultiplier(playerID: playerID)
        default:
            return legal.contains(.pass) ? .passMultiplier(playerID: playerID) : nil
        }
    }

    /// يُشغّل المزايدة أو الإعلان أو اللعب تلقائيًا لكل اللاعبين الآليين بالتتابع،
    /// ويتوقف عند دور لاعب إنسان أو عند انتهاء الجولة.
    ///
    /// - Parameter maxSteps: سقف أمان ضد أي حلقة لا تنتهي. الجولة الكاملة الآن أطول
    ///   مما كانت: حتى 8 مزايدات + حتى 4 أفعال مضاعفة + 4 إعلانات + 32 ورقة + إنهاء
    ///   الجولة = 49 خطوة، فرُفع السقف إلى 64 بهامش أمان. السقف القديم (40) كان
    ///   يتوقف في منتصف جولة كل لاعبيها آليون دون أي إشارة.
    public static func advanceAIPlayers(state: GameState, agent: BalootAgent, maxSteps: Int = 64) throws -> GameState {
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
        try BiddingEngine.deal(seed: seed, state: &state)
    }

    // MARK: - Choose mode (النمط المبسّط)

    private static func applyChooseMode(playerID: Player.ID, mode: GameMode, trumpSuit: Suit?, to state: inout GameState) throws {
        // في النمط الكامل هذا الفعل يتخطى دورة المزايدة كلها، فيُرفض صراحةً بدل أن
        // يمر ويُنتج جولة بلا مشترٍ ولا مضاعف ولا سجل مزايدة.
        guard state.rules.biddingStyle == .simple else {
            throw GameEngineError.bidding(.unsupportedInBiddingStyle)
        }
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
        state.bidding.declarerID = playerID
        state.bidding.mode = mode
        state.bidding.trumpSuit = state.trumpSuit
        state.bidding.stage = .completed

        // القائد هو صاحب الدور الحالي إن وُجد، وإلا صاحب الدور الأول بعد الموزّع.
        let leaderID = state.currentTurnPlayerID ?? state.firstToActPlayerID
        guard let leaderID, state.player(id: leaderID) != nil else {
            throw GameEngineError.unknownPlayer
        }
        state.currentTurnPlayerID = leaderID
        try BiddingEngine.openDeclarationOrPlay(state: &state)
        // مرحلة الإعلان تبدأ من صاحب الدور الأول؛ أما اللعب المباشر فيبدأ من القائد
        // المحدَّد أعلاه حفاظًا على سلوك النمط المبسّط كما كان.
        if state.phase == .playing, let leader = state.player(id: leaderID) {
            state.currentTrick = Trick(leaderSeat: leader.seat)
            state.currentTurnPlayerID = leaderID
        }
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

        // المشاريع المعلنة هي المصدر عند اشتراط الإعلان؛ وإلا فالاكتشاف التلقائي.
        let projects: [Project]? = state.rules.projectsEnabled
            ? (state.rules.projectsRequireDeclaration ? state.declaredProjects : nil)
            : []

        let result = ScoreCalculator.finalRoundScore(
            completedTricks: state.completedTricks,
            originalHands: state.originalHands,
            players: state.players,
            teams: state.teams,
            mode: mode,
            trumpSuit: state.trumpSuit,
            rules: state.rules,
            multiplier: state.bidding.multiplier,
            declaredProjects: projects,
            declaringTeamID: state.declaringTeamID
        )

        state.lastRoundResult = result
        state.awardedProjects = result.awardedProjects
        state.kabootTeamID = result.kabootTeamID
        state.phase = .finished
    }
}
