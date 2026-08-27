import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayScenarioCodeTests: XCTestCase {
    func testAttemptScenarioCodeIsStableAndUsesFullReplaySeed() {
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: UInt64.max,
            selectedCard: PlayingCard(suit: .spades, rank: .ace),
            bestCard: PlayingCard(suit: .hearts, rank: .jack),
            isCorrect: false,
            expectedImpact: -6,
            focusKind: .trumpPressure
        )

        XCTAssertEqual(attempt.replaySeed, UInt64.max)
        XCTAssertEqual(attempt.scenarioCode, "WTP-\(UInt64.max)-hard-trumpPressure-auto-C37")
    }

    func testReviewQueueCarriesScenarioCodeForReplayAndSharing() {
        let attempt = WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: 1),
            difficulty: .medium,
            seed: 2_026,
            selectedCard: PlayingCard(suit: .hearts, rank: .ace),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4,
            bestExpectedImpact: 3,
            focusKind: .followSuit
        )

        let item = WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt]).first

        XCTAssertEqual(item?.scenarioCode, "WTP-2026-medium-followSuit-auto-C07")
    }

    func testScenarioCodeParsesPromptAndReviewedDecision() {
        let prompt = WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead-P")
        let reviewed = WhatToPlayScenarioCode.parse("WTP-2026-hard-trumpPressure-hokum.3-C37")

        XCTAssertEqual(prompt?.seed, 2_026)
        XCTAssertEqual(prompt?.difficulty, .medium)
        XCTAssertEqual(prompt?.focusKind, .openingLead)
        XCTAssertNil(prompt?.gameMode)
        XCTAssertNil(prompt?.trumpSuit)
        XCTAssertNil(prompt?.selectedCard)
        XCTAssertEqual(reviewed?.seed, 2_026)
        XCTAssertEqual(reviewed?.difficulty, .hard)
        XCTAssertEqual(reviewed?.focusKind, .trumpPressure)
        XCTAssertEqual(reviewed?.gameMode, .hokum)
        XCTAssertEqual(reviewed?.trumpSuit, .spades)
        XCTAssertEqual(reviewed?.selectedCard, PlayingCard(suit: .spades, rank: .ace))
    }

    func testScenarioCodeParsesSunModeWithoutTrumpSuit() {
        let parsed = WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead-sun-P")

        XCTAssertEqual(parsed?.gameMode, .sun)
        XCTAssertNil(parsed?.trumpSuit)
        XCTAssertNil(parsed?.selectedCard)
    }

    func testScenarioCodeParsesKeyboardUppercasedTokens() {
        let prompt = WhatToPlayScenarioCode.parse("WTP-2026-MEDIUM-OPENINGLEAD-SUN-P")
        let reviewed = WhatToPlayScenarioCode.parse("WTP-2026-HARD-TRUMPPRESSURE-HOKUM.3-C37")

        XCTAssertEqual(prompt?.difficulty, .medium)
        XCTAssertEqual(prompt?.focusKind, .openingLead)
        XCTAssertEqual(prompt?.gameMode, .sun)
        XCTAssertNil(prompt?.selectedCard)
        XCTAssertEqual(reviewed?.difficulty, .hard)
        XCTAssertEqual(reviewed?.focusKind, .trumpPressure)
        XCTAssertEqual(reviewed?.gameMode, .hokum)
        XCTAssertEqual(reviewed?.trumpSuit, .spades)
        XCTAssertEqual(reviewed?.selectedCard, PlayingCard(suit: .spades, rank: .ace))
    }

    func testScenarioCodeExtractsCodeFromSharedText() {
        let text = """
        وش تلعب؟
        رمز الموقف: WTP-2026-medium-followSuit-sun-C07
        النمط: صن
        """

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-medium-followSuit-sun-C07"
        )
    }

    func testScenarioCodeExtractionSkipsInvalidCandidateBeforeValidCode() {
        let text = """
        نسخة قديمة: WTP-bad
        رمز الموقف: WTP-2026-hard-trumpPressure-hokum.3-C37
        """

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-hard-trumpPressure-hokum.3-C37"
        )
    }

    func testScenarioCodeExtractionStopsBeforeURLQueryParameters() {
        let text = "https://baloothub.local/what-to-play?code=WTP-2026-hard-trumpPressure-hokum.3-C37&source=share"

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-hard-trumpPressure-hokum.3-C37"
        )
    }

    func testScenarioCodeExtractionStopsBeforeURLPathSegments() {
        let text = "https://baloothub.local/share/WTP-2026-hard-trumpPressure-hokum.3-C37/open"

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-hard-trumpPressure-hokum.3-C37"
        )
    }

    func testScenarioCodeExtractionDecodesPercentEncodedCode() {
        let text = "WTP%2D2026%2Dhard%2DtrumpPressure%2Dhokum.3%2DC37"

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-hard-trumpPressure-hokum.3-C37"
        )
    }

    func testScenarioCodeExtractionDecodesPercentEncodedURL() {
        let text = "https%3A%2F%2Fbaloothub.local%2Fshare%2FWTP%2D2026%2Dhard%2DtrumpPressure%2Dhokum.3%2DC37%2Fopen"

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-hard-trumpPressure-hokum.3-C37"
        )
    }

    func testScenarioCodeExtractionDecodesKeyboardUppercasedPercentEncodedURL() {
        let text = "HTTPS%3A%2F%2FBALOOTHUB.LOCAL%2FSHARE%2FWTP%2D2026%2DHARD%2DTRUMPPRESSURE%2DHOKUM.3%2DC37%2FOPEN"

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-HARD-TRUMPPRESSURE-HOKUM.3-C37"
        )
    }

    func testScenarioCodeExtractionRejectsTextWithoutValidCode() {
        XCTAssertNil(WhatToPlayScenarioCode.extractCode(from: "رمز الموقف: WTP-bad"))
        XCTAssertNil(WhatToPlayScenarioCode.extractCode(from: "لا يوجد رمز هنا"))
    }

    func testScenarioCodeRejectsMalformedValues() {
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("BAD-2026-medium-openingLead-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-x-medium-openingLead-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-impossible-openingLead-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-unknownFocus-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead-C99"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead-unknown-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead-hokum.9-P"))
    }

    /// حارس انحدار لعطل تجميد الواجهة.
    ///
    /// كان استخراج الرمز يمسح *بقية النص كاملًا* عند كل مطابقة لـ`WTP-`، فيصير المسح
    /// تربيعيًا على نص بلا محارف إنهاء: قيس ١٠٫٥ ثانية عند ٣٢ ألف محرف و٤٠٫٧ ثانية عند
    /// ٦٤ ألفًا. وبما أن `loadShareCode()` تستدعيه على الـ`MainActor` قبل أي `Task`،
    /// كان لصق نص طويل يجمّد الواجهة حتى يقتل حارسُ النظام التطبيق.
    ///
    /// السقف المختار سخيّ عمدًا (ثانية واحدة مقابل ٤٠ ثانية سابقًا) حتى لا يتحول
    /// الاختبار إلى مصدر تذبذب على عامل بناء مزدحم، ومع ذلك يسقط فورًا لو عاد
    /// السلوك التربيعي.
    func testScenarioCodeExtractionStaysFastOnLongTextWithoutTerminators() {
        let hostileText = String(repeating: "WTP-", count: 16_000) // ٦٤ ألف محرف بلا فواصل

        let start = Date()
        let extracted = WhatToPlayScenarioCode.extractCode(from: hostileText)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertNil(extracted, "لا يوجد رمز صالح في النص، فالمتوقع لا شيء")
        XCTAssertLessThan(
            elapsed,
            1.0,
            "استخراج الرمز تجاوز ثانية على نص ٦٤ ألف محرف — عاد المسح التربيعي"
        )
    }

    /// السقف يقصّ المرشحات الطويلة، فلا بد أن يبقى الرمز الصالح مستخرَجًا
    /// حتى لو سبقته سلسلة `WTP-` طويلة لا تنتهي بفاصل.
    func testScenarioCodeExtractionStillFindsValidCodeAfterOverlongCandidate() {
        let noise = String(repeating: "WTP-", count: 200)
        let text = "\(noise) WTP-2026-hard-trumpPressure-hokum.3-C37"

        XCTAssertEqual(
            WhatToPlayScenarioCode.extractCode(from: text),
            "WTP-2026-hard-trumpPressure-hokum.3-C37"
        )
    }
}
