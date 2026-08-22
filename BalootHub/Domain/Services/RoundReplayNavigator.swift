import BalootEngine

enum RoundReplayNavigator {
    static func previousTrickStep(initialState: GameState, actions: [GameAction], currentStep: Int) -> Int {
        let step = min(actions.count, max(0, currentStep))
        let snapshot = replay(initialState: initialState, actions: actions, upTo: step)
        let currentTricks = snapshot.completedTricks.count
        var best = 0
        guard step > 0 else { return 0 }

        for candidate in 0..<step {
            let candidateState = replay(initialState: initialState, actions: actions, upTo: candidate)
            if candidateState.completedTricks.count < currentTricks {
                best = candidate
            }
        }

        return best
    }

    static func nextTrickStep(initialState: GameState, actions: [GameAction], currentStep: Int) -> Int {
        let step = min(actions.count, max(0, currentStep))
        let snapshot = replay(initialState: initialState, actions: actions, upTo: step)
        let currentTricks = snapshot.completedTricks.count
        guard step < actions.count else { return actions.count }

        for candidate in (step + 1)...actions.count {
            let candidateState = replay(initialState: initialState, actions: actions, upTo: candidate)
            if candidateState.completedTricks.count > currentTricks || candidate == actions.count {
                return candidate
            }
        }

        return actions.count
    }

    private static func replay(initialState: GameState, actions: [GameAction], upTo step: Int) -> GameState {
        (try? GameEngine.replay(initialState: initialState, actions: actions, upTo: step)) ?? initialState
    }
}

enum RoundReplayShareSummary {
    static func text(initialState: GameState, actions: [GameAction]) -> String {
        let finalState = (try? GameEngine.replay(initialState: initialState, actions: actions)) ?? initialState
        var lines = [
            "ملخص Replay البلوت".localized,
            "\("الجولة".localized): \(finalState.roundNumber)",
            "\("الموزّع".localized): \(dealerName(in: finalState))",
            "\("الحالة".localized): \(phaseTitle(finalState.phase))",
            "\("النمط".localized): \(modeTitle(finalState.mode, trumpSuit: finalState.trumpSuit))"
        ]

        if let declarerID = finalState.bidding.declarerID {
            lines.append("\("المشتري".localized): \(playerName(declarerID, in: finalState))")
        }
        if finalState.bidding.multiplier != .none {
            lines.append("\("المضاعفة".localized): \(finalState.bidding.multiplier.arabicName)")
        }

        let biddingTimeline = GameEngine.biddingTimeline(state: finalState)
        if !biddingTimeline.isEmpty {
            lines.append("المزايدة".localized)
            for line in biddingTimeline {
                lines.append("- \(line)")
            }
        }

        let multiplierTimeline = GameEngine.multiplierTimeline(state: finalState)
        if !multiplierTimeline.isEmpty {
            lines.append("المضاعفات".localized)
            for line in multiplierTimeline {
                lines.append("- \(line)")
            }
        }

        let projectDeclarationTimeline = GameEngine.projectDeclarationTimeline(state: finalState)
        if !projectDeclarationTimeline.isEmpty {
            lines.append("إعلانات المشاريع".localized)
            for line in projectDeclarationTimeline {
                lines.append("- \(line)")
            }
        }

        if !finalState.awardedProjects.isEmpty {
            lines.append("المشاريع المحتسَبة".localized)
            for project in finalState.awardedProjects.sorted(by: projectSort) {
                lines.append("- \(playerName(project.playerID, in: finalState)): \(project.kind.arabicName) +\(project.points)")
            }
        }

        if !finalState.completedTricks.isEmpty {
            lines.append("الأكلات".localized)
            for (index, trick) in finalState.completedTricks.enumerated() {
                lines.append(trickSummaryLine(index: index, trick: trick, state: finalState))
            }
        }

        if let result = finalState.lastRoundResult {
            lines.append("النتيجة".localized)
            for team in finalState.teams.sorted(by: { $0.name < $1.name }) {
                lines.append("- \(team.name): \(result.teamPoints[team.id] ?? 0)")
            }
            if let winnerID = result.winningTeamID,
               let winner = finalState.teams.first(where: { $0.id == winnerID }) {
                lines.append("\("الفائز".localized): \(winner.name)")
            }
            if result.didDeclarerFail {
                lines.append("طاح المشتري".localized)
            }
            if let kabootTeamID = result.kabootTeamID,
               let team = finalState.teams.first(where: { $0.id == kabootTeamID }) {
                lines.append("\("كبوت".localized): \(team.name)")
            }
        }

        appendExpertDecisionSummary(
            initialState: initialState,
            actions: actions,
            finalState: finalState,
            to: &lines
        )

        lines.append("سجل الأحداث".localized)
        for (index, line) in GameEngine.actionTimeline(state: finalState).enumerated() {
            lines.append("\(index + 1). \(line)")
        }

        return lines.joined(separator: "\n")
    }

    private static func appendExpertDecisionSummary(
        initialState: GameState,
        actions: [GameAction],
        finalState: GameState,
        to lines: inout [String]
    ) {
        let hints = actions.indices.compactMap { index in
            RoundReplayDecisionAdvisor.hint(
                initialState: initialState,
                actions: actions,
                currentStep: index + 1
            )
        }
        guard !hints.isEmpty else { return }

        let costly = hints
            .filter { !$0.matchedExpert || $0.estimatedLostPoints > 0 }
            .sorted {
                if $0.estimatedLostPoints != $1.estimatedLostPoints {
                    return $0.estimatedLostPoints > $1.estimatedLostPoints
                }
                if $0.selectedRank != $1.selectedRank {
                    return $0.selectedRank > $1.selectedRank
                }
                return $0.stepIndex < $1.stepIndex
            }

        lines.append("تحليل قرارات الخبير".localized)
        guard !costly.isEmpty else {
            lines.append("- \("كل قرارات اللعب المعروضة طابقت اختيار الخبير.".localized)")
            return
        }

        for hint in costly.prefix(3) {
            let second = hint.secondBestCard.map { " · \("ثاني أفضل".localized): \($0.accessibilityName)" } ?? ""
            let projected = hint.bestProjectedCard != hint.bestCard || hint.estimatedProjectedLostPoints > hint.estimatedImmediateLostPoints
                ? " · \("أفضل نتيجة محاكاة".localized): \(hint.bestProjectedCard.accessibilityName)"
                : ""
            let secondProjected: String
            if let secondBestProjectedCard = hint.secondBestProjectedCard,
               secondBestProjectedCard != hint.bestProjectedCard,
               hint.estimatedProjectedLostAgainstSecondBestPoints > 0 {
                secondProjected = " · \("ثاني نتيجة محاكاة".localized): \(secondBestProjectedCard.accessibilityName)"
            } else {
                secondProjected = ""
            }
            lines.append(
                "- \("الأكلة".localized) \(hint.trickNumber) · \(playerName(hint.playerID, in: finalState)): " +
                "\("لعب".localized) \(hint.playedCard.accessibilityName) · " +
                "\("أفضل قرار".localized): \(hint.bestCard.accessibilityName)\(second)\(projected)\(secondProjected) · " +
                "\("الفاقد المتوقع".localized) \(hint.estimatedLostPoints)"
            )
        }
    }

    private static func trickSummaryLine(index: Int, trick: Trick, state: GameState) -> String {
        let winnerID = trick.winnerPlayerID
        let winnerName = winnerID.map { playerName($0, in: state) } ?? "غير محدد".localized
        let cards = trick.playedCards
            .map { "\($0.card.accessibilityName) (\(playerName($0.playerID, in: state)))" }
            .joined(separator: "، ")
        let points = trickPoints(index: index, trick: trick, state: state)
        return "- \("الأكلة".localized) \(index + 1): \("الفائز بالأكلة".localized) \(winnerName) · \("نقاط الأكلة".localized) \(points) · \(cards)"
    }

    private static func trickPoints(index: Int, trick: Trick, state: GameState) -> Int {
        guard let mode = state.mode else { return 0 }
        let cardPoints = trick.playedCards.reduce(0) {
            $0 + $1.card.points(mode: mode, trumpSuit: state.trumpSuit)
        }
        let lastTrickBonus = index == state.completedTricks.count - 1
            && state.completedTricks.count == ScoreCalculator.tricksPerRound
            ? state.rules.lastTrickBonus
            : 0
        return cardPoints + lastTrickBonus
    }

    private static func phaseTitle(_ phase: GamePhase) -> String {
        switch phase {
        case .setup: return "تجهيز".localized
        case .dealing: return "توزيع".localized
        case .bidding: return "مزايدة".localized
        case .declaring: return "إعلان مشاريع".localized
        case .playing: return "لعب".localized
        case .scoring: return "احتساب".localized
        case .finished: return "منتهية".localized
        }
    }

    private static func modeTitle(_ mode: GameMode?, trumpSuit: Suit?) -> String {
        guard let mode else { return "غير محدد".localized }
        switch mode {
        case .sun:
            return "صن".localized
        case .hokum:
            return trumpSuit.map { "\("حكم".localized) \($0.spokenName)" } ?? "حكم".localized
        }
    }

    private static func playerName(_ id: Player.ID, in state: GameState) -> String {
        state.player(id: id)?.name ?? "لاعب".localized
    }

    private static func dealerName(in state: GameState) -> String {
        state.player(at: state.dealerSeat)?.name ?? "غير محدد".localized
    }

    private static func projectSort(_ lhs: Project, _ rhs: Project) -> Bool {
        if lhs.points != rhs.points { return lhs.points > rhs.points }
        if lhs.kind.rawValue != rhs.kind.rawValue { return lhs.kind.rawValue < rhs.kind.rawValue }
        return lhs.id < rhs.id
    }
}
