import XCTest
@testable import BalootHub

final class WhatToPlayOptionDisclosureTests: XCTestCase {
    func testBadgeDoesNotRevealRankBeforeChoice() {
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 1, isRevealed: false), "اختر".localized)
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 3, isRevealed: false), "اختر".localized)
    }

    func testBadgeRevealsRankAfterChoice() {
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 1, isRevealed: true), "الأفضل".localized)
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 2, isRevealed: true), "ثاني أفضل".localized)
        XCTAssertEqual(WhatToPlayOptionDisclosure.badgeText(rank: 3, isRevealed: true), "#3")
    }

    func testAccessibilityDoesNotRevealRankBeforeChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 1,
            isRevealed: false,
            expectedImpact: 8,
            projectedTeamPoints: 42
        )

        XCTAssertTrue(label.contains("إكة سباتي"))
        XCTAssertFalse(label.contains("1"))
        XCTAssertFalse(label.contains("الترتيب".localized))
        XCTAssertFalse(label.contains("أثر القرار".localized))
        XCTAssertFalse(label.contains("نقاط فريقك بعد المحاكاة".localized))
    }

    func testAccessibilityRevealsRankAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(cardName: "إكة سباتي", rank: 2, isRevealed: true)

        XCTAssertTrue(label.contains("إكة سباتي"))
        XCTAssertTrue(label.contains("2"))
        XCTAssertTrue(label.contains("الترتيب".localized))
    }

    func testAccessibilityIdentifiesSecondBestAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(cardName: "إكة سباتي", rank: 2, isRevealed: true)

        XCTAssertTrue(label.contains("ثاني أفضل".localized))
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

    func testAccessibilityIncludesImpactAndSimulationAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 1,
            isRevealed: true,
            expectedImpact: 8,
            projectedTeamPoints: 42
        )

        XCTAssertTrue(label.contains("أثر القرار".localized))
        XCTAssertTrue(label.contains("+8"))
        XCTAssertTrue(label.contains("نقاط فريقك بعد المحاكاة".localized))
        XCTAssertTrue(label.contains("42"))
    }

    func testAccessibilityIncludesExpectedLossAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 3,
            isRevealed: true,
            expectedImpact: -2,
            lostExpectedPoints: 9
        )

        XCTAssertTrue(label.contains("فارق عن الأفضل".localized))
        XCTAssertTrue(label.contains("9"))
    }

    func testAccessibilityIncludesImprovementSourceAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 3,
            isRevealed: true,
            expectedImprovement: 16,
            expectedImprovementSourceTitle: "محاكاة الجولة".localized
        )

        XCTAssertTrue(label.contains("تحسن متوقع".localized))
        XCTAssertTrue(label.contains("+16"))
        XCTAssertTrue(label.contains("مصدر التحسن".localized))
        XCTAssertTrue(label.contains("محاكاة الجولة".localized))
    }

    func testAccessibilityIncludesProjectedLossesAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 4,
            isRevealed: true,
            projectedTeamPoints: 40,
            lostProjectedTeamPoints: 12,
            lostProjectedAgainstSecondBestPoints: 8
        )

        XCTAssertTrue(label.contains("نقاط محاكاة ضائعة".localized))
        XCTAssertTrue(label.contains("12"))
        XCTAssertTrue(label.contains("فاقد ثاني محاكاة".localized))
        XCTAssertTrue(label.contains("8"))
    }

    func testAccessibilityOmitsDuplicateSecondSimulationLoss() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 4,
            isRevealed: true,
            projectedTeamPoints: 40,
            lostProjectedTeamPoints: 12,
            lostProjectedAgainstSecondBestPoints: 12
        )

        XCTAssertTrue(label.contains("نقاط محاكاة ضائعة".localized))
        XCTAssertFalse(label.contains("فاقد ثاني محاكاة".localized))
    }

    func testAccessibilityHidesImprovementBeforeChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 3,
            isRevealed: false,
            lostExpectedPoints: 9,
            lostProjectedTeamPoints: 12,
            lostProjectedAgainstSecondBestPoints: 8,
            expectedImprovement: 16,
            expectedImprovementSourceTitle: "محاكاة الجولة".localized
        )

        XCTAssertFalse(label.contains("فارق عن الأفضل".localized))
        XCTAssertFalse(label.contains("نقاط محاكاة ضائعة".localized))
        XCTAssertFalse(label.contains("فاقد ثاني محاكاة".localized))
        XCTAssertFalse(label.contains("تحسن متوقع".localized))
        XCTAssertFalse(label.contains("مصدر التحسن".localized))
        XCTAssertFalse(label.contains("محاكاة الجولة".localized))
    }

    func testAccessibilityHidesNonpositiveImprovementAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 1,
            isRevealed: true,
            expectedImprovement: 0,
            expectedImprovementSourceTitle: "محاكاة الجولة".localized
        )

        XCTAssertFalse(label.contains("تحسن متوقع".localized))
        XCTAssertFalse(label.contains("مصدر التحسن".localized))
    }

    func testAccessibilityIdentifiesBestSimulationResultAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 3,
            isRevealed: true,
            isBestSimulationResult: true
        )

        XCTAssertTrue(label.contains("أفضل نتيجة محاكاة".localized))
    }

    func testAccessibilityIdentifiesSecondBestSimulationResultAfterChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "عشرة هاص",
            rank: 2,
            isRevealed: true,
            isSecondBestSimulationResult: true
        )

        XCTAssertTrue(label.contains("ثاني نتيجة محاكاة".localized))
    }

    func testAccessibilityDoesNotRevealSelectedOrExpertBeforeChoice() {
        let label = WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: "إكة سباتي",
            rank: 1,
            isRevealed: false,
            isSelected: true,
            isExpertChoice: true,
            isBestSimulationResult: true,
            isSecondBestSimulationResult: true
        )

        XCTAssertFalse(label.contains("اختيارك".localized))
        XCTAssertFalse(label.contains("الأفضل".localized))
        XCTAssertFalse(label.contains("أفضل نتيجة محاكاة".localized))
        XCTAssertFalse(label.contains("ثاني نتيجة محاكاة".localized))
    }
}
