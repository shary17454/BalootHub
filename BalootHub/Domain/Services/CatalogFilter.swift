import Foundation

/// خيار الفلترة في صفحة الألعاب.
enum CatalogFilter: String, CaseIterable, Identifiable {
    case all
    case balootGame
    case balootTool
    case otherCardGame
    case playable
    case rulesOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "الكل"
        case .balootGame: "بلوت"
        case .balootTool: "أدوات"
        case .otherCardGame: "ألعاب ورق"
        case .playable: "متاح للعب"
        case .rulesOnly: "قواعد فقط"
        }
    }
}

/// منطق بحث وفلترة الكتالوج، مفصول عن الواجهة ليكون قابلاً للاختبار.
enum CatalogSearch {
    static func apply(filter: CatalogFilter, query: String, to items: [GameCatalogItem]) -> [GameCatalogItem] {
        var result = items

        switch filter {
        case .all:
            break
        case .balootGame:
            result = result.filter { $0.category == .balootGame }
        case .balootTool:
            result = result.filter { $0.category == .balootTool }
        case .otherCardGame:
            result = result.filter { $0.category == .otherCardGame }
        case .playable:
            result = result.filter(\.isPlayable)
        case .rulesOnly:
            result = result.filter { !$0.isPlayable }
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return result }

        return result.filter { item in
            item.arabicTitle.localizedCaseInsensitiveContains(trimmedQuery)
                || (item.englishTitle?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
                || item.shortDescription.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}
