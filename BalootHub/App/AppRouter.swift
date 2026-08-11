import Foundation

/// تبويبات الشريط السفلي.
enum AppTab: String, CaseIterable, Identifiable {
    case home
    case catalog
    case scorekeeper
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "الرئيسية".localized
        case .catalog: "الألعاب".localized
        case .scorekeeper: "تسجيل البلوت".localized
        case .history: "السجل".localized
        case .settings: "الإعدادات".localized
        }
    }

    var iconName: String {
        switch self {
        case .home: "house.fill"
        case .catalog: "square.grid.2x2.fill"
        case .scorekeeper: "list.clipboard.fill"
        case .history: "clock.arrow.circlepath"
        case .settings: "gearshape.fill"
        }
    }
}

/// وجهات التنقّل داخل تبويب واحد.
enum AppRoute: Hashable {
    case gameDetails(slug: String)
    case rules(slug: String)
    case scorekeeperSession(id: UUID)
    case scorekeeperNewSession
    case balootGamePlay(slug: String)
    case balootAcademy
    case handAnalyzer
    case whatToPlayTrainer
    case scoringQuiz
    case dailyChallenges
    case achievements
    case trainingIntro
}
