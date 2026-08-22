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

#if DEBUG
    /// يفتح شاشة محددة عند الإقلاع حسب وسيط سطر أوامر، للتحقق البصري من الشاشات
    /// العميقة (طاولة اللعب مثلًا) على مقاسات وأجهزة مختلفة.
    ///
    /// موجودة في Debug فقط: التحقق البصري كان يتطلب الوصول يدويًا لكل شاشة، فتُترك
    /// الشاشات العميقة بلا فحص على مقاسات iPad. مع هذا الوسيط تصير لقطة أي شاشة
    /// أمرًا واحدًا:
    /// `xcrun simctl launch <device> app.balooThub.ios -BalootHubStartRoute balootGamePlay`
    func applyDebugStartRouteIfNeeded(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        guard let index = arguments.firstIndex(of: "-BalootHubStartRoute"),
              arguments.indices.contains(index + 1)
        else { return }

        switch arguments[index + 1] {
        case "balootGamePlay":
            navigate(to: .balootGamePlay(slug: "baloot-classic"), tab: .home)
        case "whatToPlay":
            navigate(to: .whatToPlayTrainer(), tab: .home)
        case "settings":
            selectedTab = .settings
        case "scorekeeper":
            selectedTab = .scorekeeper
        case "careerMode":
            navigate(to: .careerMode, tab: .home)
        default:
            break
        }
    }
#endif

    func openPracticeRecommendation(_ recommendation: RoundPracticeRecommendation, from tab: AppTab) {
        navigate(
            to: .whatToPlayTrainer(
                seed: recommendation.scenarioSeed,
                difficulty: recommendation.difficulty,
                focusKind: recommendation.focusKind,
                gameMode: recommendation.gameMode,
                trumpSuit: recommendation.trumpSuit,
                targetCount: recommendation.suggestedScenarioCount
            ),
            tab: tab
        )
    }
}
