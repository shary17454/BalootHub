import XCTest
@testable import BalootHub

final class CatalogFilterTests: XCTestCase {
    private func makeItems() -> [GameCatalogItem] {
        CatalogSeeder.previewItems()
    }

    func testAllFilterReturnsEveryItem() {
        let items = makeItems()
        XCTAssertEqual(CatalogSearch.apply(filter: .all, query: "", to: items).count, items.count)
    }

    func testBalootGameFilterOnlyReturnsBalootGameCategory() {
        let items = makeItems()
        let result = CatalogSearch.apply(filter: .balootGame, query: "", to: items)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.category == .balootGame })
        XCTAssertEqual(result.map(\.slug), ["baloot-classic"])
    }

    func testOtherCardGameFilterExcludesBaloot() {
        let items = makeItems()
        let result = CatalogSearch.apply(filter: .otherCardGame, query: "", to: items)
        XCTAssertTrue(result.allSatisfy { $0.category == .otherCardGame })
        XCTAssertTrue(result.contains { $0.slug == "tarneeb" })
        XCTAssertFalse(result.contains { $0.slug == "baloot-classic" })
    }

    func testPlayableFilterOnlyReturnsPlayableItems() {
        let items = makeItems()
        let result = CatalogSearch.apply(filter: .playable, query: "", to: items)
        XCTAssertTrue(result.allSatisfy(\.isPlayable))
        XCTAssertEqual(result.map(\.slug), ["baloot-classic"])
    }

    func testRulesOnlyFilterExcludesPlayableItems() {
        let items = makeItems()
        let result = CatalogSearch.apply(filter: .rulesOnly, query: "", to: items)
        XCTAssertTrue(result.allSatisfy { !$0.isPlayable })
    }

    func testSearchQueryMatchesArabicTitle() {
        let items = makeItems()
        let result = CatalogSearch.apply(filter: .all, query: "طرنيب", to: items)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.slug, "tarneeb")
    }

    func testSearchQueryWithNoMatchesReturnsEmpty() {
        let items = makeItems()
        let result = CatalogSearch.apply(filter: .all, query: "لعبة غير موجودة إطلاقًا", to: items)
        XCTAssertTrue(result.isEmpty)
    }

    func testCatalogHasExactlyTwentyThreeSeedItems() {
        XCTAssertEqual(makeItems().count, 23)
    }

    func testCatalogIncludesAdvancedBalootReferences() {
        let slugs = Set(makeItems().map(\.slug))

        XCTAssertTrue(slugs.contains("baloot-ashkal"))
        XCTAssertTrue(slugs.contains("baloot-gahwa-lock"))
        XCTAssertTrue(slugs.contains("baloot-kaboot"))
        XCTAssertTrue(slugs.contains("baloot-bidding-guide"))
        XCTAssertTrue(slugs.contains("baloot-projects-reference"))
        XCTAssertTrue(slugs.contains("baloot-multiplayer-voice-guide"))
        XCTAssertTrue(slugs.contains("hand-analyzer"))
        XCTAssertTrue(slugs.contains("what-to-play-trainer"))
        XCTAssertTrue(slugs.contains("daily-baloot-challenges"))
        XCTAssertTrue(slugs.contains("baloot-achievements"))
        XCTAssertTrue(slugs.contains("offline-tournaments"))
    }

    func testBalootModesAreReferencesInsideSingleBalootGame() {
        let items = makeItems()
        let modeSlugs = [
            "baloot-sun",
            "baloot-hokum",
            "baloot-projects",
            "baloot-double",
            "baloot-ashkal",
            "baloot-gahwa-lock",
            "baloot-kaboot"
        ]

        let modes = items.filter { modeSlugs.contains($0.slug) }

        XCTAssertEqual(modes.count, modeSlugs.count)
        XCTAssertTrue(modes.allSatisfy { $0.category == .balootTool })
        XCTAssertTrue(modes.allSatisfy { !$0.isPlayable })
        XCTAssertTrue(modes.allSatisfy(\.isBalootModeReference))
        XCTAssertTrue(modes.allSatisfy { $0.displayAvailabilityTitle == "مرجع نمط".localized })
        XCTAssertTrue(modes.allSatisfy { $0.availabilityIconName == "rectangle.stack.fill" })
    }

    func testNewLearningReferencesAreRulesOnly() {
        let items = makeItems()
        let newItems = items.filter {
            [
                "baloot-ashkal",
                "baloot-gahwa-lock",
                "baloot-kaboot",
                "baloot-bidding-guide",
                "baloot-projects-reference",
                "baloot-multiplayer-voice-guide",
                "daily-baloot-challenges",
                "baloot-achievements",
                "offline-tournaments"
            ].contains($0.slug)
        }

        XCTAssertEqual(newItems.count, 9)
        XCTAssertTrue(newItems.allSatisfy { !$0.isPlayable })
    }

    func testEveryItemHasAllTenStandardRuleSections() {
        for item in makeItems() {
            XCTAssertEqual(item.rules.count, StandardRuleSectionKind.allCases.count, "اللعبة \(item.slug) لا تحتوي كل أقسام القواعد")
        }
    }
}
