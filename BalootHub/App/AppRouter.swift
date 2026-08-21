import Foundation
import BalootEngine

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
    case balootAcademy(lessonID: String? = nil)
    case handAnalyzer
    case whatToPlayTrainer(
        seed: UInt64? = nil,
        seedBase: UInt64? = nil,
        difficulty: WhatToPlayDifficulty? = nil,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        gameMode: GameMode? = nil,
        trumpSuit: Suit? = nil,
        targetCount: Int? = nil
    )
    case scoringQuiz
    case dailyChallenges
    case achievements
    case careerMode
    case offlineTournaments
    case balootSandbox
    case trainingIntro
    case balootEncyclopedia
    case rareCaseLibrary
}
