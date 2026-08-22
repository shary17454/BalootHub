import XCTest
import BalootEngine
@testable import BalootHub

/// يتحقق من منطق تخصيص الطاولة: الفتح بالرتبة، رفض المقفول، والتعافي من قيم قديمة.
final class AppearanceCatalogTests: XCTestCase {

    // MARK: - الفتح بالرتبة

    func testNewcomerGetsOnlyFreeStyles() {
        let entries = AppearanceCatalog.allEntries(selection: .standard, rank: .newcomer)
        let unlocked = entries.filter(\.isUnlocked)

        XCTAssertFalse(unlocked.isEmpty, "لازم يبدأ اللاعب بأنماط متاحة من أول تشغيل")
        XCTAssertTrue(
            unlocked.allSatisfy { $0.requiredRank == .newcomer },
            "المبتدئ ما يفترض يفتح أي نمط يحتاج رتبة أعلى"
        )
    }

    func testEveryGroupHasAtLeastOneStyleAvailableAtStart() {
        for group in AppearanceGroup.allCases {
            let entries = AppearanceCatalog.entries(for: group, selection: .standard, rank: .newcomer)
            XCTAssertTrue(
                entries.contains { $0.isUnlocked },
                "قسم \(group.title) بلا أي نمط مفتوح للمبتدئ"
            )
        }
    }

    func testSheikhRankUnlocksEverything() {
        let progress = AppearanceCatalog.unlockProgress(at: .balootSheikh)
        XCTAssertEqual(progress.unlocked, progress.total, "أعلى رتبة يفترض تفتح كل الأنماط")
    }

    func testUnlockProgressGrowsWithRank() {
        let ranks: [CareerRank] = [.newcomer, .majlisRegular, .tableReader, .tournamentPlayer, .balootSheikh]
        let counts = ranks.map { AppearanceCatalog.unlockProgress(at: $0).unlocked }

        XCTAssertEqual(counts, counts.sorted(), "عدد الأنماط المفتوحة لا يجوز ينقص مع ارتفاع الرتبة")
        XCTAssertGreaterThan(counts.last ?? 0, counts.first ?? 0, "لازم يكون في محتوى فعلي يُفتح بالتقدّم")
    }

    // MARK: - الفتح غير مرتبط بأي شراء

    func testDefaultStandardSelectionIsFullyAvailableToNewcomer() {
        let resolved = AppearanceCatalog.resolve(.standard, at: .newcomer)
        XCTAssertEqual(resolved, .standard, "المظهر الافتراضي لازم يشتغل بلا أي تقدّم")
    }

    // MARK: - التعافي من قيم غير صالحة

    func testUnknownRawValueFallsBackToDefault() {
        let raw = AppearanceRawSelection(
            cardFace: "نمط-محذوف",
            cardBack: "نمط-محذوف",
            felt: "نمط-محذوف",
            backdrop: "نمط-محذوف",
            avatar: "نمط-محذوف",
            theme: "نمط-محذوف"
        )

        XCTAssertEqual(AppearanceCatalog.resolve(raw, at: .balootSheikh), .standard)
        XCTAssertEqual(AppearanceCatalog.resolveTrusted(raw), .standard)
    }

    func testLockedSelectionFallsBackWhenRankDrops() {
        // لاعب اختار نمطًا متقدمًا ثم حذف سجل مبارياته فنزلت رتبته.
        var raw = AppearanceRawSelection.standard
        raw.theme = TableThemeStyle.pearl.rawValue

        XCTAssertEqual(AppearanceCatalog.resolve(raw, at: .balootSheikh).theme, .pearl)
        XCTAssertEqual(
            AppearanceCatalog.resolve(raw, at: .newcomer).theme,
            .baloot,
            "النمط المقفول يرجع للافتراضي بدل ما تعلق الشاشة على نمط غير متاح"
        )
    }

    func testResolveTrustedKeepsSelectionWithoutRankCheck() {
        var raw = AppearanceRawSelection.standard
        raw.theme = TableThemeStyle.pearl.rawValue

        XCTAssertEqual(
            AppearanceCatalog.resolveTrusted(raw).theme,
            .pearl,
            "شاشة اللعب تثق بالمحفوظ ولا تعيد فحص الفتح"
        )
    }

    // MARK: - تطبيق الاختيار

    func testApplyingUnlockedEntryUpdatesOnlyItsGroup() {
        let entries = AppearanceCatalog.entries(for: .felt, selection: .standard, rank: .balootSheikh)
        guard let maroon = entries.first(where: { $0.optionRawValue == TableFeltStyle.maroon.rawValue }) else {
            return XCTFail("نمط الطاولة العنّابي غير موجود")
        }

        let updated = AppearanceCatalog.apply(entry: maroon, to: .standard)

        XCTAssertEqual(updated?.felt, TableFeltStyle.maroon.rawValue)
        XCTAssertEqual(updated?.cardFace, AppearanceRawSelection.standard.cardFace, "بقية الأقسام ما تتغير")
        XCTAssertEqual(updated?.theme, AppearanceRawSelection.standard.theme)
    }

    func testApplyingLockedEntryIsRejected() {
        let entries = AppearanceCatalog.entries(for: .theme, selection: .standard, rank: .newcomer)
        guard let locked = entries.first(where: { !$0.isUnlocked }) else {
            return XCTFail("يفترض يكون في ثيم مقفول على المبتدئ")
        }

        XCTAssertNil(
            AppearanceCatalog.apply(entry: locked, to: .standard),
            "الاختيار المقفول لازم يُرفض صراحة لا يُطبَّق بصمت"
        )
    }

    func testLockedEntryExplainsRequiredRank() {
        let entries = AppearanceCatalog.entries(for: .theme, selection: .standard, rank: .newcomer)
        let locked = entries.first { !$0.isUnlocked }

        XCTAssertNotNil(locked?.lockReason, "المقفول لازم يوضّح سبب قفله")
        XCTAssertNil(entries.first { $0.isUnlocked }?.lockReason, "المفتوح ما له سبب قفل")
    }

    // MARK: - الترتيب والمعرّفات

    func testUnlockedEntriesComeFirst() {
        for group in AppearanceGroup.allCases {
            let entries = AppearanceCatalog.entries(for: group, selection: .standard, rank: .majlisRegular)
            let flags = entries.map(\.isUnlocked)
            XCTAssertEqual(flags, flags.sorted(by: { $0 && !$1 }), "قسم \(group.title): المفتوح لازم يجي أولًا")
        }
    }

    func testEntryIdentifiersAreUniqueAcrossGroups() {
        let ids = AppearanceCatalog.allEntries(selection: .standard, rank: .balootSheikh).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "تكرار المعرّفات يخلط عناصر القائمة في SwiftUI")
    }

    func testExactlyOneEntryIsSelectedPerGroup() {
        for group in AppearanceGroup.allCases {
            let selected = AppearanceCatalog.entries(for: group, selection: .standard, rank: .balootSheikh)
                .filter(\.isSelected)
            XCTAssertEqual(selected.count, 1, "قسم \(group.title): لازم نمط واحد مختار بالضبط")
        }
    }

    // MARK: - القادم في الرتبة التالية

    func testUpcomingUnlocksAreLockedNow() {
        let upcoming = AppearanceCatalog.upcomingUnlocks(at: .newcomer)

        XCTAssertFalse(upcoming.isEmpty, "لازم يكون في حافز واضح للرتبة القادمة")
        XCTAssertTrue(
            upcoming.allSatisfy { $0.requiredRank == .majlisRegular },
            "القائمة تعرض ما يُفتح في الرتبة التالية مباشرة فقط"
        )
    }

    func testTopRankHasNoUpcomingUnlocks() {
        XCTAssertTrue(AppearanceCatalog.upcomingUnlocks(at: .balootSheikh).isEmpty)
    }

    // MARK: - نص الورقة

    func testHeritageFaceUsesArabicIndicDigits() {
        XCTAssertEqual(CardFaceStyle.heritage.label(for: .ten), "١٠")
        XCTAssertEqual(CardFaceStyle.heritage.label(for: .king), "ش")
        XCTAssertEqual(CardFaceStyle.classic.label(for: .ten), "10")
        XCTAssertEqual(CardFaceStyle.classic.label(for: .king), "K")
    }

    func testEveryFaceStyleProducesNonEmptyLabelForEveryRank() {
        for style in CardFaceStyle.allCases {
            for rank in Rank.allCases {
                XCTAssertFalse(style.label(for: rank).isEmpty, "\(style.rawValue)/\(rank.rawValue): نص فارغ")
            }
        }
    }
}
