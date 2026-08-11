import XCTest
@testable import BalootHub

final class WhatToPlayOptionDisclosureTests: XCTestCase {
    func testBadgeDoesNotRevealRankBeforeChoice() {
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 1, isRevealed: false), "اختر".localized)
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 3, isRevealed: false), "اختر".localized)
    }

    func testBadgeRevealsRankAfterChoice() {
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 1, isRevealed: true), "الأفضل".localized)
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 3, isRevealed: true), "#3")
    }

    func testAccessibilityDoesNotRevealRankBeforeChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(cardName: "إكة سباتي", rank: 1, isRevealed: false)

        XCTAssertTrue(label.contains("إكة سباتي"))
        XCTAssertFalse(label.contains("1"))
        XCTAssertFalse(label.contains("الترتيب".localized))
    }

    func testAccessibilityRevealsRankAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(cardName: "إكة سباتي", rank: 2, isRevealed: true)

        XCTAssertTrue(label.contains("إكة سباتي"))
        XCTAssertTrue(label.contains("2"))
        XCTAssertTrue(label.contains("الترتيب".localized))
    }

    func testAccessibilityIdentifiesSelectedAndExpertCardsAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 1,
            isRevealed: true,
            isSelected: true,
            isExpertChoice: true
        )

        XCTAssertTrue(label.contains("اختيارك".localized))
        XCTAssertTrue(label.contains("الأفضل".localized))
    }

    func testAccessibilityDoesNotRevealSelectedOrExpertBeforeChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 1,
            isRevealed: false,
            isSelected: true,
            isExpertChoice: true
        )

        XCTAssertFalse(label.contains("اختيارك".localized))
        XCTAssertFalse(label.contains("الأفضل".localized))
    }
}
