import Foundation

/// مستوى صعوبة موقف «وش تلعب؟».
public enum WhatToPlayDifficulty: String, Sendable, Codable, CaseIterable {
    case easy
    case medium
    case hard

    public var expertSamples: Int {
        switch self {
        case .easy: 2
        case .medium: 6
        case .hard: 12
        }
    }
}

/// خيار ورقة في موقف تدريبي.
public struct WhatToPlayOption: Identifiable, Sendable, Equatable {
    public let card: PlayingCard
    public let rank: Int
    public let score: Int
    public let isExpertChoice: Bool
    public let expectedImpact: Int
    /// نقاط فريق اللاعب المتوقعة بعد فرض هذه الورقة واستكمال الجولة بسياسة ذكية حتمية.
    ///
    /// هذا يختلف عن ``expectedImpact``: الأثر المتوقع يشرح الأكلة الحالية مباشرة،
    /// أما هذه القيمة فتدعم تدريب "ماذا سيحدث لو؟" عبر تشغيل بقية الجولة من المحرك.
    public let projectedTeamPoints: Int
    public let impactBreakdown: WhatToPlayOptionImpactBreakdown
    public let simulation: WhatToPlayOptionSimulation
    public let outcome: WhatToPlayOptionOutcome
    public let outcomeReason: String
    public let explanation: String

    public var id: PlayingCard { card }
}

/// تفكيك أثر لعب ورقة معيّنة في موقف «وش تلعب؟».
///
/// هذا لا يحاول توقّع الجولة كاملة؛ بل يشرح الأثر المباشر القابل للإعادة من حالة
/// المحرك: هل أغلقت الورقة الأكلة، كم نقطة كانت على الطاولة، ولأي فريق ذهبت.
public struct WhatToPlayOptionImpactBreakdown: Sendable, Codable, Equatable {
    public let playedCardPoints: Int
    public let immediateImpact: Int
    public let trickPointsSwing: Int
    public let completesTrick: Bool
    public let winsForPlayerTeam: Bool?
    public let preservesLead: Bool

    public init(
        playedCardPoints: Int,
        immediateImpact: Int,
        trickPointsSwing: Int,
        completesTrick: Bool,
        winsForPlayerTeam: Bool?,
        preservesLead: Bool
    ) {
        self.playedCardPoints = playedCardPoints
        self.immediateImpact = immediateImpact
        self.trickPointsSwing = trickPointsSwing
        self.completesTrick = completesTrick
        self.winsForPlayerTeam = winsForPlayerTeam
        self.preservesLead = preservesLead
    }

    public var signedImpact: Int {
        completesTrick ? trickPointsSwing : immediateImpact
    }
}

/// محاكاة مختصرة لما يحدث مباشرة إذا لعب المستخدم هذه الورقة.
///
/// تحفظ نتيجة تطبيق فعل اللعب على المحرك نفسه، لا على تقدير واجهة المستخدم. هذا يجعل
/// مدرب «وش تلعب؟» وReplay وSandbox يشتركون في مصدر حقيقة واحد عند شرح القرار.
public struct WhatToPlayOptionSimulation: Sendable, Codable, Equatable {
    public let phaseAfterPlay: GamePhase
    public let currentTrickCardCount: Int
    public let completedTrickWinnerID: Player.ID?
    public let completedTrickWinnerTeamID: Team.ID?
    public let completedTrickWonByPlayerTeam: Bool?
    public let completedTrickPoints: Int
    public let nextTurnPlayerID: Player.ID?
    public let playerRemainingCards: Int
    public let actionHistoryCount: Int

    public init(
        phaseAfterPlay: GamePhase,
        currentTrickCardCount: Int,
        completedTrickWinnerID: Player.ID?,
        completedTrickWinnerTeamID: Team.ID?,
        completedTrickWonByPlayerTeam: Bool?,
        completedTrickPoints: Int,
        nextTurnPlayerID: Player.ID?,
        playerRemainingCards: Int,
        actionHistoryCount: Int
    ) {
        self.phaseAfterPlay = phaseAfterPlay
        self.currentTrickCardCount = currentTrickCardCount
        self.completedTrickWinnerID = completedTrickWinnerID
        self.completedTrickWinnerTeamID = completedTrickWinnerTeamID
        self.completedTrickWonByPlayerTeam = completedTrickWonByPlayerTeam
        self.completedTrickPoints = completedTrickPoints
        self.nextTurnPlayerID = nextTurnPlayerID
        self.playerRemainingCards = playerRemainingCards
        self.actionHistoryCount = actionHistoryCount
    }
}

/// ورقة موجودة في يد اللاعب لكنها غير قانونية في موقف «وش تلعب؟» الحالي.
public struct WhatToPlayBlockedCard: Identifiable, Sendable, Equatable {
    public let card: PlayingCard
    public let reason: IllegalMoveReason

    public var id: PlayingCard { card }
}

/// نتيجة لعب خيار معيّن على حالة الأكلة الحالية.
public enum WhatToPlayOptionOutcome: String, Sendable, Codable, Equatable {
    case leadsTrick
    case developsTrick
    case winsTrick
    case losesTrick
}

/// محور الانتباه الأهم في موقف «وش تلعب؟».
public enum WhatToPlayScenarioFocusKind: String, Sendable, Codable, CaseIterable {
    case openingLead
    case followSuit
    case trumpPressure
    case narrowChoice
}

/// قراءة موجزة لسياق موقف «وش تلعب؟» من حالة المحرك.
public struct WhatToPlayScenarioContext: Sendable, Equatable {
    public let trickNumber: Int
    public let isLeading: Bool
    public let requiredSuit: Suit?
    public let playedCardCount: Int
    public let legalOptionCount: Int
    public let mode: GameMode?
    public let trumpSuit: Suit?
    public let hasTrumpInCurrentTrick: Bool
    public let playerTeamTrickPoints: Int
    public let opponentTeamTrickPoints: Int
    public let playerTeamPointMargin: Int
    public let focusKind: WhatToPlayScenarioFocusKind

    public init(
        trickNumber: Int,
        isLeading: Bool,
        requiredSuit: Suit?,
        playedCardCount: Int,
        legalOptionCount: Int,
        mode: GameMode?,
        trumpSuit: Suit?,
        hasTrumpInCurrentTrick: Bool,
        playerTeamTrickPoints: Int = 0,
        opponentTeamTrickPoints: Int = 0,
        playerTeamPointMargin: Int = 0,
        focusKind: WhatToPlayScenarioFocusKind
    ) {
        self.trickNumber = trickNumber
        self.isLeading = isLeading
        self.requiredSuit = requiredSuit
        self.playedCardCount = playedCardCount
        self.legalOptionCount = legalOptionCount
        self.mode = mode
        self.trumpSuit = trumpSuit
        self.hasTrumpInCurrentTrick = hasTrumpInCurrentTrick
        self.playerTeamTrickPoints = playerTeamTrickPoints
        self.opponentTeamTrickPoints = opponentTeamTrickPoints
        self.playerTeamPointMargin = playerTeamPointMargin
        self.focusKind = focusKind
    }
}

/// موقف «وش تلعب؟» قابل للإعادة من نفس البذرة.
public struct WhatToPlayScenario: Sendable {
    public let seed: UInt64
    public let difficulty: WhatToPlayDifficulty
    public let playerID: Player.ID
    public let initialState: GameState
    public let state: GameState
    public let context: WhatToPlayScenarioContext
    public let options: [WhatToPlayOption]
    public let blockedCards: [WhatToPlayBlockedCard]

    public var bestOption: WhatToPlayOption? {
        options.first { $0.rank == 1 }
    }

    public var secondBestOption: WhatToPlayOption? {
        options.first { $0.rank == 2 }
    }
}

/// Replay مرئي لقرار تدريب «وش تلعب؟».
///
/// يعيد الجولة من البداية حتى حالة الموقف، ثم يضيف ورقة المستخدم المختارة كآخر فعل.
/// بهذا يمكن للواجهة فتح نفس عارض Replay المستخدم في اللعبة بدون بناء منطق جانبي.
public struct WhatToPlayDecisionReplay: Sendable {
    public let initialState: GameState
    public let actions: [GameAction]
    public let playerID: Player.ID
    public let selectedCard: PlayingCard

    public init(initialState: GameState, actions: [GameAction], playerID: Player.ID, selectedCard: PlayingCard) {
        self.initialState = initialState
        self.actions = actions
        self.playerID = playerID
        self.selectedCard = selectedCard
    }
}

/// مولّد ومحلّل مواقف «وش تلعب؟».
public enum WhatToPlayTrainer {
    public enum ScenarioError: Error, Sendable, Equatable {
        case unableToGenerate
        case noLegalCards
        case unknownPlayer
    }

    /// يولّد موقفًا حقيقيًا من محرك اللعبة، ثم يوقفه عند دور اللاعب البشري في مرحلة اللعب.
    public static func generateScenario(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty = .medium,
        preferredFocus: WhatToPlayScenarioFocusKind? = nil,
        rules: BalootRulesConfiguration = .standard
    ) throws -> WhatToPlayScenario {
        let agent = ExpertBalootAgent(samples: difficulty.expertSamples)

        let searchLimit = preferredFocus == nil ? 40 : 800
        for offset in 0..<searchLimit {
            let initialState = GameState.newLocalMatch(rules: rules)
            var state = initialState
            state = try GameEngine.apply(.dealCards(seed: seed &+ UInt64(offset)), to: state)

            guard let humanID = state.players.first(where: { $0.kind == .human })?.id else {
                throw ScenarioError.unknownPlayer
            }

            var guardSteps = 0
            while guardSteps < 96 {
                guardSteps += 1

                if state.phase == .playing, state.currentTurnPlayerID == humanID {
                    let options = try analyzeOptions(state: state, playerID: humanID, difficulty: difficulty)
                    guard options.count > 1 else { break }
                    let context = scenarioContext(state: state, options: options, playerID: humanID)
                    if preferredFocus == nil || context.focusKind == preferredFocus {
                        return WhatToPlayScenario(
                            seed: seed &+ UInt64(offset),
                            difficulty: difficulty,
                            playerID: humanID,
                            initialState: initialState,
                            state: state,
                            context: context,
                            options: options,
                            blockedCards: blockedCards(state: state, playerID: humanID, legalOptions: options)
                        )
                    }

                    guard let bestCard = options.first(where: \.isExpertChoice)?.card else { break }
                    state = try GameEngine.apply(.playCard(playerID: humanID, card: bestCard), to: state)
                    continue
                }

                guard let action = nextTrainingAction(state: state, humanID: humanID, agent: agent) else { break }
                state = try GameEngine.apply(action, to: state)
            }
        }

        throw ScenarioError.unableToGenerate
    }

    /// فعل تدريب واحد يتصرف عن كل اللاعبين في المزايدة والإعلان، ويتوقف عند دور
    /// اللاعب البشري في اللعب فقط. بهذه الطريقة تأتي مواقف «وش تلعب؟» من جولة بلوت
    /// كاملة فعلًا، لا من اختيار نمط مبسّط خارج دورة المزايدة.
    private static func nextTrainingAction(state: GameState, humanID: Player.ID, agent: BalootAgent) -> GameAction? {
        guard let playerID = state.currentTurnPlayerID,
              let hand = state.hands[playerID] else {
            return state.phase == .scoring ? .finishRound : nil
        }

        switch state.phase {
        case .bidding:
            switch state.bidding.stage {
            case .firstRound, .secondRound:
                if state.rules.biddingStyle == .simple {
                    let recommendation = HandAnalyzer.analyze(hand: hand, rules: state.rules).recommendedBid
                    let mode = recommendation.mode ?? .sun
                    return .chooseMode(playerID: playerID, mode: mode, trumpSuit: recommendation.trumpSuit)
                }

                let legal = GameEngine.legalBids(for: playerID, state: state)
                guard !legal.isEmpty else { return nil }
                return .placeBid(playerID: playerID, bid: agent.chooseBid(hand: hand, legalBids: legal, state: state))

            case .doubling:
                let legal = GameEngine.legalMultiplierActions(for: playerID, state: state)
                guard !legal.isEmpty else { return nil }
                return GameEngine.legalMultiplierGameAction(
                    playerID: playerID,
                    decision: agent.chooseMultiplierAction(hand: hand, state: state),
                    legal: legal
                )

            case .completed, .voided:
                return nil
            }

        case .declaring:
            let available = GameEngine.declarableProjects(for: playerID, state: state)
            return .declareProjects(playerID: playerID, projects: agent.chooseProjectsToDeclare(available: available, state: state))

        case .playing:
            guard playerID != humanID else { return nil }
            let legal = GameEngine.legalCards(for: playerID, state: state)
            guard !legal.isEmpty else { return nil }
            return .playCard(playerID: playerID, card: agent.chooseCard(hand: hand, legalCards: legal, state: state))

        case .scoring:
            return .finishRound

        case .setup, .dealing, .finished:
            return nil
        }
    }

    /// يحلل كل الأوراق القانونية الحالية ويضع اختيار الخبير أولًا.
    public static func analyzeOptions(
        state: GameState,
        playerID: Player.ID,
        difficulty: WhatToPlayDifficulty = .medium
    ) throws -> [WhatToPlayOption] {
        guard let hand = state.hands[playerID], let player = state.player(id: playerID) else {
            throw ScenarioError.unknownPlayer
        }

        let legal = GameEngine.legalCards(for: playerID, state: state)
        guard !legal.isEmpty else { throw ScenarioError.noLegalCards }

        let expert = ExpertBalootAgent(samples: difficulty.expertSamples)
        let expertChoice = expert.chooseCard(hand: hand, legalCards: legal, state: state)
        let evaluated: [(
            card: PlayingCard,
            score: Int,
            projectedTeamPoints: Int,
            breakdown: WhatToPlayOptionImpactBreakdown,
            outcome: WhatToPlayOptionOutcome
        )] = legal.map { card in
            let breakdown = impactBreakdown(of: card, by: player, in: state)
            let projectedTeamPoints = projectedTeamPoints(afterPlaying: card, by: player, in: state)
            let score = heuristicScore(
                card: card,
                impact: breakdown.signedImpact,
                projectedTeamPoints: projectedTeamPoints,
                expertChoice: expertChoice,
                state: state
            )
            let outcome = optionOutcome(of: card, by: player, in: state)
            return (
                card: card,
                score: score,
                projectedTeamPoints: projectedTeamPoints,
                breakdown: breakdown,
                outcome: outcome
            )
        }
        .sorted { lhs, rhs in
            if lhs.card == expertChoice { return true }
            if rhs.card == expertChoice { return false }
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal { return lhs.card.suit.ordinal < rhs.card.suit.ordinal }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }

        let best = evaluated.first

        return evaluated.enumerated().map { index, entry in
            WhatToPlayOption(
                card: entry.card,
                rank: index + 1,
                score: entry.score,
                isExpertChoice: entry.card == expertChoice,
                expectedImpact: entry.breakdown.signedImpact,
                projectedTeamPoints: entry.projectedTeamPoints,
                impactBreakdown: entry.breakdown,
                simulation: simulation(of: entry.card, by: player, in: state),
                outcome: entry.outcome,
                outcomeReason: outcomeReason(for: entry.outcome),
                explanation: explanation(
                    rank: index + 1,
                    impact: entry.breakdown.signedImpact,
                    projectedTeamPoints: entry.projectedTeamPoints,
                    best: best,
                    isExpertChoice: entry.card == expertChoice,
                    state: state
                )
            )
        }
    }

    /// يقيّم اختيار المستخدم مقارنة باختيار الخبير.
    public static func evaluateChoice(card: PlayingCard, in scenario: WhatToPlayScenario) -> WhatToPlayOption? {
        scenario.options.first { $0.card == card }
    }

    /// يبني Replay قابلًا للتشغيل لقرار معيّن في موقف «وش تلعب؟».
    public static func decisionReplay(
        for card: PlayingCard,
        in scenario: WhatToPlayScenario
    ) -> WhatToPlayDecisionReplay? {
        guard evaluateChoice(card: card, in: scenario) != nil else { return nil }

        return WhatToPlayDecisionReplay(
            initialState: scenario.initialState,
            actions: scenario.state.actionHistory + [.playCard(playerID: scenario.playerID, card: card)],
            playerID: scenario.playerID,
            selectedCard: card
        )
    }

    /// كل أوراق يد اللاعب غير القانونية في هذا الموقف، مع سبب الرفض من المحرك.
    public static func blockedCards(
        state: GameState,
        playerID: Player.ID,
        legalOptions: [WhatToPlayOption]
    ) -> [WhatToPlayBlockedCard] {
        let legalCards = Set(legalOptions.map(\.card))
        return GameEngine.moveValidations(for: playerID, state: state)
            .filter { !legalCards.contains($0.card) }
            .compactMap { validation in
                guard let reason = validation.invalidReason else {
                    return nil
                }
                return WhatToPlayBlockedCard(card: validation.card, reason: reason)
            }
            .sorted { lhs, rhs in
                if lhs.card.suit.ordinal != rhs.card.suit.ordinal {
                    return lhs.card.suit.ordinal < rhs.card.suit.ordinal
                }
                return lhs.card.rank.ordinal < rhs.card.rank.ordinal
            }
    }

    public static func scenarioContext(state: GameState, options: [WhatToPlayOption]) -> WhatToPlayScenarioContext {
        scenarioContext(state: state, options: options, playerID: state.currentTurnPlayerID)
    }

    public static func scenarioContext(
        state: GameState,
        options: [WhatToPlayOption],
        playerID: Player.ID?
    ) -> WhatToPlayScenarioContext {
        let trick = state.currentTrick
        let trumpSuit = state.trumpSuit
        let hasTrump = state.mode == .hokum
            && trumpSuit != nil
            && (trick?.playedCards.contains { $0.card.suit == trumpSuit } ?? false)
        let scoreboard = scenarioScoreboard(state: state, playerID: playerID)

        return WhatToPlayScenarioContext(
            trickNumber: state.completedTricks.count + 1,
            isLeading: trick?.playedCards.isEmpty ?? true,
            requiredSuit: trick?.requiredSuit,
            playedCardCount: trick?.playedCards.count ?? 0,
            legalOptionCount: options.count,
            mode: state.mode,
            trumpSuit: trumpSuit,
            hasTrumpInCurrentTrick: hasTrump,
            playerTeamTrickPoints: scoreboard.player,
            opponentTeamTrickPoints: scoreboard.opponent,
            playerTeamPointMargin: scoreboard.player - scoreboard.opponent,
            focusKind: scenarioFocusKind(
                isLeading: trick?.playedCards.isEmpty ?? true,
                requiredSuit: trick?.requiredSuit,
                hasTrumpInCurrentTrick: hasTrump,
                legalOptionCount: options.count
            )
        )
    }

    private static func scenarioScoreboard(state: GameState, playerID: Player.ID?) -> (player: Int, opponent: Int) {
        guard let playerID, let player = state.player(id: playerID) else {
            return (0, 0)
        }

        let playerPoints = state.teamTrickPoints[player.teamID] ?? 0
        let opponentPoints = state.teams
            .filter { $0.id != player.teamID }
            .reduce(0) { $0 + (state.teamTrickPoints[$1.id] ?? 0) }
        return (playerPoints, opponentPoints)
    }

    public static func scenarioFocusKind(
        isLeading: Bool,
        requiredSuit: Suit?,
        hasTrumpInCurrentTrick: Bool,
        legalOptionCount: Int
    ) -> WhatToPlayScenarioFocusKind {
        if hasTrumpInCurrentTrick {
            return .trumpPressure
        }
        if !isLeading, requiredSuit != nil {
            return .followSuit
        }
        if legalOptionCount <= 2 {
            return .narrowChoice
        }
        return .openingLead
    }

    public static func impactBreakdown(
        of card: PlayingCard,
        by playerID: Player.ID,
        in state: GameState
    ) -> WhatToPlayOptionImpactBreakdown? {
        guard let player = state.player(id: playerID),
              GameEngine.legalCards(for: playerID, state: state).contains(card)
        else { return nil }
        return impactBreakdown(of: card, by: player, in: state)
    }

    private static func impactBreakdown(
        of card: PlayingCard,
        by player: Player,
        in state: GameState
    ) -> WhatToPlayOptionImpactBreakdown {
        let mode = state.mode ?? .sun
        let playedCardPoints = card.points(mode: mode, trumpSuit: state.trumpSuit)
        guard let after = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return WhatToPlayOptionImpactBreakdown(
                playedCardPoints: playedCardPoints,
                immediateImpact: Int.min,
                trickPointsSwing: Int.min,
                completesTrick: false,
                winsForPlayerTeam: nil,
                preservesLead: false
            )
        }

        if let last = after.completedTricks.last,
           let winnerID = last.winnerPlayerID,
           let winner = after.player(id: winnerID) {
            let trickPoints = last.playedCards.reduce(0) {
                $0 + $1.card.points(mode: mode, trumpSuit: state.trumpSuit)
            }
            let wins = winner.teamID == player.teamID
            return WhatToPlayOptionImpactBreakdown(
                playedCardPoints: playedCardPoints,
                immediateImpact: wins ? trickPoints : -trickPoints,
                trickPointsSwing: wins ? trickPoints : -trickPoints,
                completesTrick: true,
                winsForPlayerTeam: wins,
                preservesLead: wins
            )
        }

        let isLeading = state.currentTrick?.playedCards.isEmpty ?? true
        return WhatToPlayOptionImpactBreakdown(
            playedCardPoints: playedCardPoints,
            immediateImpact: isLeading ? leadValue(card: card, points: playedCardPoints, state: state) : -playedCardPoints,
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: isLeading
        )
    }

    private static func optionOutcome(of card: PlayingCard, by player: Player, in state: GameState) -> WhatToPlayOptionOutcome {
        let wasLeading = state.currentTrick?.playedCards.isEmpty ?? true
        guard let after = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return wasLeading ? .leadsTrick : .developsTrick
        }

        if let last = after.completedTricks.last,
           let winnerID = last.winnerPlayerID,
           let winner = after.player(id: winnerID) {
            return winner.teamID == player.teamID ? .winsTrick : .losesTrick
        }

        return wasLeading ? .leadsTrick : .developsTrick
    }

    private static func simulation(of card: PlayingCard, by player: Player, in state: GameState) -> WhatToPlayOptionSimulation {
        let mode = state.mode ?? .sun
        guard let after = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return WhatToPlayOptionSimulation(
                phaseAfterPlay: state.phase,
                currentTrickCardCount: state.currentTrick?.playedCards.count ?? 0,
                completedTrickWinnerID: nil,
                completedTrickWinnerTeamID: nil,
                completedTrickWonByPlayerTeam: nil,
                completedTrickPoints: 0,
                nextTurnPlayerID: state.currentTurnPlayerID,
                playerRemainingCards: state.hands[player.id]?.count ?? 0,
                actionHistoryCount: state.actionHistory.count
            )
        }

        let completedTrick = after.completedTricks.last
        let winnerID = completedTrick?.winnerPlayerID
        let winnerTeamID = winnerID.flatMap { after.player(id: $0)?.teamID }
        let wonByPlayerTeam = winnerTeamID.map { $0 == player.teamID }
        let completedTrickPoints = completedTrick?.playedCards.reduce(0) {
            $0 + $1.card.points(mode: mode, trumpSuit: state.trumpSuit)
        } ?? 0

        return WhatToPlayOptionSimulation(
            phaseAfterPlay: after.phase,
            currentTrickCardCount: after.currentTrick?.playedCards.count ?? 0,
            completedTrickWinnerID: winnerID,
            completedTrickWinnerTeamID: winnerTeamID,
            completedTrickWonByPlayerTeam: wonByPlayerTeam,
            completedTrickPoints: completedTrickPoints,
            nextTurnPlayerID: after.currentTurnPlayerID,
            playerRemainingCards: after.hands[player.id]?.count ?? 0,
            actionHistoryCount: after.actionHistory.count
        )
    }

    private static func outcomeReason(for outcome: WhatToPlayOptionOutcome) -> String {
        switch outcome {
        case .leadsTrick:
            return "هذه الورقة تبدأ الأكلة، لذلك يعتمد أثرها النهائي على ردود بقية اللاعبين."
        case .developsTrick:
            return "هذه الورقة لا تحسم الأكلة فورًا؛ ما زالت نتيجة الأكلة معلقة على الأوراق التالية."
        case .winsTrick:
            return "هذه الورقة تحسم الأكلة لفريقك حسب الأوراق المطروحة وقواعد الحكم والصن."
        case .losesTrick:
            return "هذه الورقة تنهي الأكلة لصالح الخصم، لذلك تُحسب نقاطها عليه في هذا الموقف."
        }
    }

    private static func heuristicScore(
        card: PlayingCard,
        impact: Int,
        projectedTeamPoints: Int,
        expertChoice: PlayingCard,
        state: GameState
    ) -> Int {
        var score = projectedTeamPoints == Int.min ? impact : projectedTeamPoints
        if card == expertChoice { score += 10_000 }
        if state.currentTrick?.playedCards.isEmpty == true {
            score += card.points(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit) / 2
        }
        return score
    }

    private static func leadValue(card: PlayingCard, points: Int, state: GameState) -> Int {
        if state.mode == .hokum, card.suit == state.trumpSuit {
            return points - 8
        }
        return points
    }

    private static func projectedTeamPoints(
        afterPlaying card: PlayingCard,
        by player: Player,
        in state: GameState
    ) -> Int {
        guard var current = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return Int.min
        }

        let policy = SmartBalootAgent()
        var steps = 0
        while current.phase == .playing, steps < 40 {
            steps += 1
            guard let playerID = current.currentTurnPlayerID,
                  let hand = current.hands[playerID], !hand.isEmpty
            else { break }

            let legal = GameEngine.legalCards(for: playerID, state: current)
            guard !legal.isEmpty else { break }

            let selected = policy.chooseCard(hand: hand, legalCards: legal, state: current)
            guard let next = try? GameEngine.apply(.playCard(playerID: playerID, card: selected), to: current) else {
                break
            }
            current = next
        }

        if current.phase == .scoring, let finished = try? GameEngine.apply(.finishRound, to: current) {
            current = finished
        }

        return current.lastRoundResult?.teamPoints[player.teamID]
            ?? current.teamTrickPoints[player.teamID]
            ?? 0
    }

    private static func explanation(
        rank: Int,
        impact: Int,
        projectedTeamPoints: Int,
        best: (
            card: PlayingCard,
            score: Int,
            projectedTeamPoints: Int,
            breakdown: WhatToPlayOptionImpactBreakdown,
            outcome: WhatToPlayOptionOutcome
        )?,
        isExpertChoice: Bool,
        state: GameState
    ) -> String {
        let selectedComparableScore = heuristicComparableScore(projectedTeamPoints: projectedTeamPoints, impact: impact)
        let bestGap = best.map {
            max(
                0,
                heuristicComparableScore(
                    projectedTeamPoints: $0.projectedTeamPoints,
                    impact: $0.breakdown.signedImpact
                ) - selectedComparableScore
            )
        } ?? 0
        let projectedGap = best.map { max(0, $0.projectedTeamPoints - projectedTeamPoints) } ?? 0

        if isExpertChoice {
            return "اختيار الخبير رقم \(rank) لأنه أعلى تقييم في هذا الموقف ويوازن بين حفظ القوة ونتيجة الجولة المتوقعة."
        }
        if projectedGap > max(2, abs(impact)) {
            return "هذا الخيار يبدو مقبولًا في الأكلة الحالية، لكنه يخسر بعد استكمال الجولة؛ الفارق عن الخبير \(bestGap) في التقييم و\(projectedGap) في نقاط المحاكاة."
        }
        if impact > 0 {
            return "خيار جيد لأنه يتوقع ربح نقاط هذه الأكلة، لكنه أقل من اختيار الخبير بفارق تقييم \(bestGap) وفارق نقاط المحاكاة \(projectedGap)."
        }
        if impact < 0 {
            return "خيار مخاطِر لأنه يتوقع خسارة نقاط في هذه الأكلة أو رمي ورقة ثمينة؛ الفارق عن الخبير \(bestGap) في التقييم و\(projectedGap) في نقاط المحاكاة."
        }
        if state.currentTrick?.playedCards.isEmpty == true {
            return "افتتاح محايد؛ قد يختبر أوراق الخصوم، لكنه أدنى من اختيار الخبير بفارق تقييم \(bestGap) وفارق نقاط المحاكاة \(projectedGap)."
        }
        return "تأثيره محدود في الأكلة الحالية مقارنة بالخيار الأفضل؛ فارق التقييم \(bestGap) وفارق نقاط المحاكاة \(projectedGap)."
    }

    private static func heuristicComparableScore(projectedTeamPoints: Int, impact: Int) -> Int {
        projectedTeamPoints == Int.min ? impact : projectedTeamPoints
    }
}
