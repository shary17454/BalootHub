import Foundation
import BalootEngine

struct WhatToPlaySimulationDisplay: Equatable {
    let summary: String
    let teamResult: String?
    let trickPoints: Int?
}

enum WhatToPlaySimulationFormatter {
    static func display(for simulation: WhatToPlayOptionSimulation) -> WhatToPlaySimulationDisplay {
        WhatToPlaySimulationDisplay(
            summary: summary(
                currentTrickCardCount: simulation.currentTrickCardCount,
                completedTrickWonByPlayerTeam: simulation.completedTrickWonByPlayerTeam
            ),
            teamResult: teamResult(simulation.completedTrickWonByPlayerTeam),
            trickPoints: simulation.completedTrickWinnerID == nil ? nil : simulation.completedTrickPoints
        )
    }

    static func display(for attempt: WhatToPlayAttempt) -> WhatToPlaySimulationDisplay? {
        guard let currentTrickCardCount = attempt.simulationCurrentTrickCardCount else { return nil }
        return WhatToPlaySimulationDisplay(
            summary: summary(
                currentTrickCardCount: currentTrickCardCount,
                completedTrickWonByPlayerTeam: attempt.simulationCompletedTrickWonByPlayerTeam
            ),
            teamResult: teamResult(attempt.simulationCompletedTrickWonByPlayerTeam),
            trickPoints: attempt.simulationCompletedTrickPoints
        )
    }

    private static func summary(
        currentTrickCardCount: Int,
        completedTrickWonByPlayerTeam: Bool?
    ) -> String {
        if completedTrickWonByPlayerTeam != nil {
            return "تكتمل الأكلة وتنتقل للفائز.".localized
        }
        return "\("تبقى الأكلة مفتوحة".localized) · \(currentTrickCardCount) \("أوراق على الطاولة".localized)"
    }

    private static func teamResult(_ wonByPlayerTeam: Bool?) -> String? {
        switch wonByPlayerTeam {
        case .some(true):
            return "لفريقك".localized
        case .some(false):
            return "للخصم".localized
        case .none:
            return nil
        }
    }
}
