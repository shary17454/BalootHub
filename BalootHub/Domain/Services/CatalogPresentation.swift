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

struct CatalogUsageGuideItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let iconName: String
    let tintToken: String
}

enum CatalogPresentation {
    static let workflowActions: [CatalogWorkflowAction] = [
        CatalogWorkflowAction(
            id: "play",
            title: "العب البلوت".localized,
            detail: "طاولة البلوت الكاملة: المزايدة تحدد صن أو حكم داخل نفس اللعبة.".localized,
            iconName: "play.fill",
            route: .balootGamePlay(slug: "baloot-classic"),
            tab: .home
        ),
        CatalogWorkflowAction(
            id: "score",
            title: "سجل البلوت".localized,
            detail: "استخدم مسجل المجلس للصكات والمشاريع والمضاعفات والهدف.".localized,
            iconName: "list.clipboard.fill",
            route: nil,
            tab: .scorekeeper
        ),
        CatalogWorkflowAction(
            id: "learn",
            title: "تعلّم وتدرّب".localized,
            detail: "الأكاديمية ومدرب وش تلعب وتحليل اليد واختبار النقاط.".localized,
            iconName: "graduationcap.fill",
            route: .balootAcademy(),
            tab: .home
        ),
        CatalogWorkflowAction(
            id: "library",
            title: "مكتبة ألعاب الورق".localized,
            detail: "قواعد البلوت والألعاب الأخرى مفصولة وواضحة: لعب، تدريب، أو مرجع.".localized,
            iconName: "books.vertical.fill",
            route: nil,
            tab: .catalog
        )
    ]

    static let usageGuideItems: [CatalogUsageGuideItem] = [
        CatalogUsageGuideItem(
            id: "playable",
            title: "قابل للعب الآن".localized,
            detail: "البلوت الكلاسيكي هو الطاولة الحقيقية؛ الصن والحكم يختارهما اللاعب من المزايدة.".localized,
            iconName: "play.circle.fill",
            tintToken: "success"
        ),
        CatalogUsageGuideItem(
            id: "training",
            title: "تدريب وأدوات".localized,
            detail: "الأكاديمية، وش تلعب، تحليل اليد، اختبار النقاط، والمختبر أدوات منفصلة عن طاولة اللعب.".localized,
            iconName: "graduationcap.fill",
            tintToken: "accent"
        ),
        CatalogUsageGuideItem(
            id: "baloot-reference",
            title: "مرجع بلوت".localized,
            detail: "الصن والحكم والمشاريع والدبل صفحات شرح لأنماط داخل لعبة البلوت، وليست ألعابًا مستقلة.".localized,
            iconName: "book.closed.fill",
            tintToken: "primary"
        ),
        CatalogUsageGuideItem(
            id: "card-reference",
            title: "ألعاب ورق أخرى".localized,
            detail: "طرنيب وتركس وهاند وبقية الألعاب تظهر كمراجع قواعد فقط إلى أن تُبنى لها طاولات كاملة.".localized,
            iconName: "rectangle.stack.fill",
            tintToken: "secondary"
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
                "hand-analyzer",
                "score-calculation-challenge",
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
                "baloot-encyclopedia",
                "baloot-bidding-guide",
                "baloot-sun",
                "baloot-hokum",
                "baloot-projects",
                "baloot-projects-reference",
                "baloot-double",
                "baloot-ashkal",
                "baloot-gahwa-lock",
                "baloot-kaboot",
                "baloot-rare-cases",
                "baloot-multiplayer-voice-guide"
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
                detail: "أكاديمية، مدرب قرارات، تحليل يد، اختبار نقاط، ومختبر مواقف.".localized,
                items: training
            ),
            CatalogPresentationSection(
                id: "management",
                title: "سجل وتابع".localized,
                detail: "تسجيل نقاط المجلس، تحديات، مسيرة، بطولات، وإنجازات.".localized,
                items: management
            ),
            CatalogPresentationSection(
                id: "references",
                title: "مراجع البلوت".localized,
                detail: "موسوعة، مزايدة، صن وحكم، مشاريع، مضاعفات، وحالات خلاف.".localized,
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
