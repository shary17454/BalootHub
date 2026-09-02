import Foundation

struct CatalogWorkflowAction: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let iconName: String
    let route: AppRoute?
    let tab: AppTab
}

struct CatalogPresentationSection: Identifiable {
    let id: String
    let title: String
    let detail: String
    let items: [GameCatalogItem]
}

enum CatalogPresentation {
    static let workflowActions: [CatalogWorkflowAction] = [
        CatalogWorkflowAction(
            id: "play",
            title: "ابدأ لعب البلوت".localized,
            detail: "طاولة واحدة تجمع الصن والحكم عبر المزايدة مثل الواقع.".localized,
            iconName: "play.fill",
            route: .balootGamePlay(slug: "baloot-classic"),
            tab: .home
        ),
        CatalogWorkflowAction(
            id: "learn",
            title: "تعلّم خطوة بخطوة".localized,
            detail: "أكاديمية تشرح ثم تعرض مثالًا وموقفًا عمليًا.".localized,
            iconName: "graduationcap.fill",
            route: .balootAcademy(),
            tab: .home
        ),
        CatalogWorkflowAction(
            id: "practice",
            title: "تدرّب: وش تلعب؟".localized,
            detail: "مواقف حقيقية تقارن اختيارك بقرار الخبير.".localized,
            iconName: "brain.head.profile",
            route: .whatToPlayTrainer(),
            tab: .home
        ),
        CatalogWorkflowAction(
            id: "score",
            title: "سجّل نقاط المجلس".localized,
            detail: "جلسات ونتائج ومضاعفات ومشاريع بدون اتصال.".localized,
            iconName: "list.clipboard.fill",
            route: nil,
            tab: .scorekeeper
        ),
        CatalogWorkflowAction(
            id: "analyze",
            title: "حلّل يدك".localized,
            detail: "أدخل أوراقك واعرف هل تشتري صن أو حكم أو تمرّر.".localized,
            iconName: "wand.and.stars",
            route: .handAnalyzer,
            tab: .home
        ),
        CatalogWorkflowAction(
            id: "rules",
            title: "افهم القواعد".localized,
            detail: "موسوعة ومراجع للحالات النادرة والمشاريع والمضاعفات.".localized,
            iconName: "book.closed.fill",
            route: .balootEncyclopedia,
            tab: .home
        )
    ]

    static func homeSections(from items: [GameCatalogItem]) -> [CatalogPresentationSection] {
        let play = orderedItems(
            slugs: ["baloot-classic"],
            from: items
        )
        let training = orderedItems(
            slugs: [
                "baloot-training",
                "what-to-play-trainer",
                "score-calculation-challenge",
                "hand-analyzer",
                "baloot-sandbox"
            ],
            from: items
        )
        let management = orderedItems(
            slugs: [
                "baloot-scorekeeper",
                "daily-baloot-challenges",
                "baloot-career-mode",
                "offline-tournaments",
                "baloot-achievements"
            ],
            from: items
        )
        let references = orderedItems(
            slugs: [
                "baloot-sun",
                "baloot-hokum",
                "baloot-bidding-guide",
                "baloot-projects",
                "baloot-projects-reference",
                "baloot-double",
                "baloot-ashkal",
                "baloot-gahwa-lock",
                "baloot-kaboot",
                "baloot-encyclopedia",
                "baloot-rare-cases"
            ],
            from: items
        )

        return [
            CatalogPresentationSection(
                id: "play",
                title: "ابدأ هنا".localized,
                detail: "مدخل اللعب الحقيقي للبلوت؛ الصن والحكم ليسا لعبتين منفصلتين.".localized,
                items: play
            ),
            CatalogPresentationSection(
                id: "training",
                title: "تعلّم وتدرّب".localized,
                detail: "دروس، مواقف، تحليل يد، واختبارات نقاط لتحسين قراراتك.".localized,
                items: training
            ),
            CatalogPresentationSection(
                id: "management",
                title: "تابع تقدمك".localized,
                detail: "سجّل النقاط، التحديات، المسيرة، البطولات، والإنجازات.".localized,
                items: management
            ),
            CatalogPresentationSection(
                id: "references",
                title: "مراجع البلوت".localized,
                detail: "شرح الأنماط والقواعد والحالات التي تسبب خلافًا بين اللاعبين.".localized,
                items: references
            )
        ].filter { !$0.items.isEmpty }
    }

    static func catalogSections(from items: [GameCatalogItem]) -> [CatalogPresentationSection] {
        let groupedSlugs = Set(homeSections(from: items).flatMap { $0.items.map(\.slug) })
        let otherGames = items
            .filter { $0.category == .otherCardGame }
            .sorted { $0.sortOrder < $1.sortOrder }
        let knownSections = homeSections(from: items)
        let uncategorized = items
            .filter { !groupedSlugs.contains($0.slug) && $0.category != .otherCardGame }
            .sorted { $0.sortOrder < $1.sortOrder }

        return knownSections
            + [
                CatalogPresentationSection(
                    id: "other-card-games",
                    title: "ألعاب ورق أخرى".localized,
                    detail: "مراجع منفصلة عن البلوت؛ ليست جزءًا من طاولة البلوت الحالية.".localized,
                    items: otherGames
                ),
                CatalogPresentationSection(
                    id: "more",
                    title: "عناصر إضافية".localized,
                    detail: "عناصر لم تدخل في المسارات الأساسية.".localized,
                    items: uncategorized
                )
            ].filter { !$0.items.isEmpty }
    }

    private static func orderedItems(slugs: [String], from items: [GameCatalogItem]) -> [GameCatalogItem] {
        let bySlug = Dictionary(uniqueKeysWithValues: items.map { ($0.slug, $0) })
        return slugs.compactMap { bySlug[$0] }
    }
}
