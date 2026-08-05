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
        case .home: "الرئيسية"
        case .catalog: "الألعاب"
        case .scorekeeper: "تسجيل البلوت"
        case .history: "السجل"
        case .settings: "الإعدادات"
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
    case trainingIntro
}
