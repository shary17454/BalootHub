import XCTest
@testable import BalootHub

final class BalootEncyclopediaTests: XCTestCase {
    func testAllTermsHaveUniqueNonEmptyContent() {
        let terms = BalootEncyclopedia.terms
        XCTAssertFalse(terms.isEmpty)

        let ids = terms.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "معرّفات مصطلحات مكررة")

        for term in terms {
            XCTAssertFalse(term.term.isEmpty, "\(term.id): المصطلح فارغ")
            XCTAssertFalse(term.definition.isEmpty, "\(term.id): التعريف فارغ")
        }
    }

    func testFilterByCategoryOnlyReturnsThatCategory() {
        let result = BalootEncyclopedia.terms(in: .multiplier)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.category == .multiplier })
    }

    func testSearchMatchesTermOrDefinition() {
        let result = BalootEncyclopedia.search("كبوت")
        XCTAssertTrue(result.contains { $0.id == "kaboot" })
    }

    func testEmptySearchReturnsAllTerms() {
        XCTAssertEqual(BalootEncyclopedia.search("").count, BalootEncyclopedia.terms.count)
    }
}

final class RareCaseLibraryTests: XCTestCase {
    func testAllRulingsHaveUniqueNonEmptyContent() {
        let rulings = RareCaseLibrary.rulings
        XCTAssertFalse(rulings.isEmpty)

        let ids = rulings.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "معرّفات حالات مكررة")

        for ruling in rulings {
            XCTAssertFalse(ruling.question.isEmpty, "\(ruling.id): السؤال فارغ")
            XCTAssertFalse(ruling.ruling.isEmpty, "\(ruling.id): الحكم فارغ")
            XCTAssertFalse(ruling.rationale.isEmpty, "\(ruling.id): السبب فارغ")
        }
    }

    func testFilterByCategoryOnlyReturnsThatCategory() {
        let result = RareCaseLibrary.rulings(in: .bidding)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.category == .bidding })
    }

    func testSearchMatchesQuestionOrRuling() {
        let result = RareCaseLibrary.search("دورة ميتة")
        XCTAssertTrue(result.contains { $0.id == "all-pass-twice" })
    }

    func testEmptySearchReturnsAllRulings() {
        XCTAssertEqual(RareCaseLibrary.search("").count, RareCaseLibrary.rulings.count)
    }
}
