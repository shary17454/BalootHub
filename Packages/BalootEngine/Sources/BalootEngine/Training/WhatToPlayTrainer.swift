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
    public let outcome: WhatToPlayOptionOutcome
    public let explanation: String

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
    public let focusKind: WhatToPlayScenarioFocusKind
}

/// موقف «وش تلعب؟» قابل للإعادة من نفس البذرة.
public struct WhatToPlayScenario: Sendable {
    public let seed: UInt64
    public let difficulty: WhatToPlayDifficulty
    public let playerID: Player.ID
    public let state: GameState
    public let context: WhatToPlayScenarioContext
    public let options: [WhatToPlayOption]

    public var bestOption: WhatToPlayOption? {
        options.first { $0.rank == 1 }
    }

    public var secondBestOption: WhatToPlayOption? {
        options.first { $0.rank == 2 }
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
        rules: BalootRulesConfiguration = .simpleBidding
    ) throws -> WhatToPlayScenario {
        let agent = ExpertBalootAgent(samples: difficulty.expertSamples)

        let searchLimit = preferredFocus == nil ? 40 : 800
        for offset in 0..<searchLimit {
            var scenarioRules = rules
            scenarioRules.biddingStyle = .simple
            scenarioRules.projectsRequireDeclaration = false

            var state = GameState.newLocalMatch(rules: scenarioRules)
            state = try GameEngine.apply(.dealCards(seed: seed &+ UInt64(offset)), to: state)

            guard let humanID = state.players.first(where: { $0.kind == .human })?.id else {
                throw ScenarioError.unknownPlayer
            }

            if state.phase == .bidding, state.currentTurnPlayerID == humanID {
                let hand = state.hands[humanID] ?? []
                let recommendation = HandAnalyzer.analyze(hand: hand, rules: scenarioRules).recommendedBid
                let mode = recommendation.mode ?? .sun
                state = try GameEngine.apply(.chooseMode(playerID: humanID, mode: mode, trumpSuit: recommendation.trumpSuit), to: state)
            }

            state = try GameEngine.advanceAIPlayers(state: state, agent: agent)

            var guardSteps = 0
            while state.phase == .playing, guardSteps < 64 {
                guardSteps += 1

                if state.currentTurnPlayerID != humanID {
                    state = try GameEngine.advanceAIPlayers(state: state, agent: agent)
                    continue
                }

                let options = try analyzeOptions(state: state, playerID: humanID, difficulty: difficulty)
                guard options.count > 1 else { break }
                let context = scenarioContext(state: state, options: options)
                if preferredFocus == nil || context.focusKind == preferredFocus {
                    return WhatToPlayScenario(
                        seed: seed &+ UInt64(offset),
                        difficulty: difficulty,
                        playerID: humanID,
                        state: state,
                        context: context,
                        options: options
                    )
                }

                guard let bestCard = options.first(where: \.isExpertChoice)?.card else { break }
                state = try GameEngine.apply(.playCard(playerID: humanID, card: bestCard), to: state)
                state = try GameEngine.advanceAIPlayers(state: state, agent: agent)
            }
        }

        throw ScenarioError.unableToGenerate
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
        let evaluated: [(card: PlayingCard, score: Int, impact: Int, outcome: WhatToPlayOptionOutcome)] = legal.map { card in
            let impact = expectedImpact(of: card, by: player, in: state)
            let score = heuristicScore(card: card, impact: impact, expertChoice: expertChoice, state: state)
            let outcome = optionOutcome(of: card, by: player, in: state)
            return (card: card, score: score, impact: impact, outcome: outcome)
        }
        .sorted { lhs, rhs in
            if lhs.card == expertChoice { return true }
            if rhs.card == expertChoice { return false }
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal { return lhs.card.suit.ordinal < rhs.card.suit.ordinal }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }

        return evaluated.enumerated().map { index, entry in
            WhatToPlayOption(
                card: entry.card,
                rank: index + 1,
                score: entry.score,
                isExpertChoice: entry.card == expertChoice,
                expectedImpact: entry.impact,
                outcome: entry.outcome,
                explanation: explanation(for: entry.card, impact: entry.impact, isExpertChoice: entry.card == expertChoice, state: state)
            )
        }
    }

    /// يقيّم اختيار المستخدم مقارنة باختيار الخبير.
    public static func evaluateChoice(card: PlayingCard, in scenario: WhatToPlayScenario) -> WhatToPlayOption? {
        scenario.options.first { $0.card == card }
    }

    public static func scenarioContext(state: GameState, options: [WhatToPlayOption]) -> WhatToPlayScenarioContext {
        let trick = state.currentTrick
        let trumpSuit = state.trumpSuit
        let hasTrump = state.mode == .hokum
            && trumpSuit != nil
            && (trick?.playedCards.contains { $0.card.suit == trumpSuit } ?? false)

        return WhatToPlayScenarioContext(
            trickNumber: state.completedTricks.count + 1,
            isLeading: trick?.playedCards.isEmpty ?? true,
            requiredSuit: trick?.requiredSuit,
            playedCardCount: trick?.playedCards.count ?? 0,
            legalOptionCount: options.count,
            mode: state.mode,
            trumpSuit: trumpSuit,
            hasTrumpInCurrentTrick: hasTrump,
            focusKind: scenarioFocusKind(
                isLeading: trick?.playedCards.isEmpty ?? true,
                requiredSuit: trick?.requiredSuit,
                hasTrumpInCurrentTrick: hasTrump,
                legalOptionCount: options.count
            )
        )
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

    private static func expectedImpact(of card: PlayingCard, by player: Player, in state: GameState) -> Int {
        guard let after = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return Int.min
        }

        if let last = after.completedTricks.last,
           let winnerID = last.winnerPlayerID,
           let winner = after.player(id: winnerID) {
            let trickPoints = last.playedCards.reduce(0) {
                $0 + $1.card.points(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit)
            }
            return winner.teamID == player.teamID ? trickPoints : -trickPoints
        }

        let points = card.points(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit)
        let isLeading = state.currentTrick?.playedCards.isEmpty ?? true
        return isLeading ? leadValue(card: card, points: points, state: state) : -points
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

    private static func heuristicScore(
        card: PlayingCard,
        impact: Int,
        expertChoice: PlayingCard,
        state: GameState
    ) -> Int {
        var score = impact
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

    private static func explanation(
        for card: PlayingCard,
        impact: Int,
        isExpertChoice: Bool,
        state: GameState
    ) -> String {
        if isExpertChoice {
            return "اختيار الخبير لأنه يوازن بين حفظ القوة والفوز بالأكلة أو تقليل خسارتها."
        }
        if impact > 0 {
            return "خيار جيد لأنه يتوقع ربح نقاط هذه الأكلة، لكنه ليس أعلى قرار حسب تحليل الخبير."
        }
        if impact < 0 {
            return "خيار مخاطِر لأنه يتوقع خسارة نقاط في هذه الأكلة أو رمي ورقة ثمينة بلا مقابل."
        }
        if state.currentTrick?.playedCards.isEmpty == true {
            return "افتتاح محايد؛ قد يكون صحيحًا إذا أردت اختبار أوراق الخصوم، لكنه ليس اختيار الخبير."
        }
        return "تأثيره محدود في الأكلة الحالية مقارنة بالخيار الأفضل."
    }
}
