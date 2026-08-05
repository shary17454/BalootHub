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
        XCTAssertTrue(result.contains { $0.slug == "baloot-hokum" })
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

    func testCatalogHasExactlyTwelveSeedItems() {
        XCTAssertEqual(makeItems().count, 12)
    }

    func testEveryItemHasAllTenStandardRuleSections() {
        for item in makeItems() {
            XCTAssertEqual(item.rules.count, StandardRuleSectionKind.allCases.count, "اللعبة \(item.slug) لا تحتوي كل أقسام القواعد")
        }
    }
}
