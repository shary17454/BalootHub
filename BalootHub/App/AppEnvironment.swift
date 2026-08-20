import Foundation
import Observation
import BalootEngine

/// حالة التنقّل والتبويب المشتركة عبر التطبيق. لا تحتوي منطق أعمال، فقط تنسيق واجهة.
@Observable
final class AppEnvironment {
    var selectedTab: AppTab = .home
    var homePath: [AppRoute] = []
    var catalogPath: [AppRoute] = []
    var scorekeeperPath: [AppRoute] = []
    var historyPath: [AppRoute] = []

    /// ينتقل إلى تبويب معيّن ويضيف وجهة جديدة إلى مساره.
    func navigate(to route: AppRoute, tab: AppTab) {
        selectedTab = tab
        switch tab {
        case .home: homePath.append(route)
        case .catalog: catalogPath.append(route)
        case .scorekeeper: scorekeeperPath.append(route)
        case .history: historyPath.append(route)
        case .settings: break
        }
    }

    func openScorekeeperSession(id: UUID, tab: AppTab = .scorekeeper) {
        navigate(to: .scorekeeperSession(id: id), tab: tab)
    }

    func openGameDetails(slug: String, from tab: AppTab) {
        navigate(to: .gameDetails(slug: slug), tab: tab)
    }

    func openPracticeRecommendation(_ recommendation: RoundPracticeRecommendation, from tab: AppTab) {
        navigate(
            to: .whatToPlayTrainer(
                seed: recommendation.scenarioSeed,
                difficulty: recommendation.difficulty
            ),
            tab: tab
        )
    }
}
