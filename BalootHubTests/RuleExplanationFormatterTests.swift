import XCTest
import BalootEngine
@testable import BalootHub

final class RuleExplanationFormatterTests: XCTestCase {
    func testFollowSuitExplanationMatchesRuleLanguage() {
        let explanation = RuleExplanationFormatter.illegalMoveExplanation(
            for: .mustFollowSuit,
            trumpSuit: .spades
        )

        XCTAssertEqual(
            explanation,
            "لا يمكنك لعب هذه الورقة لأن لديك ورقة من اللون المطلوب ويجب عليك التلزيم.".localized
        )
    }

    func testTrumpCutExplanationIncludesTrumpSuitWhenAvailable() {
        let explanation = RuleExplanationFormatter.illegalMoveExplanation(
            for: .mustPlayTrumpWhenVoidOfSuit,
            trumpSuit: .clubs
        )

        XCTAssertTrue(explanation.contains("أنت لا تملك اللون المطلوب ويجب عليك القطع بالحكم وفق القاعدة الحالية.".localized))
        XCTAssertTrue(explanation.contains(Suit.clubs.spokenName))
    }

    func testEveryIllegalMoveReasonHasNonEmptyExplanation() {
        let reasons: [IllegalMoveReason] = [
            .cardNotInHand,
            .mustFollowSuit,
            .mustPlayTrumpWhenVoidOfSuit,
            .mustOvertrump,
            .notPlayersTurn,
            .wrongPhase
        ]

        for reason in reasons {
            XCTAssertFalse(
                RuleExplanationFormatter.illegalMoveExplanation(for: reason, trumpSuit: .hearts).isEmpty,
                "Missing explanation for \(reason)"
            )
        }
    }
}
