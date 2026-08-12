import XCTest
import BalootEngine
@testable import BalootHub

final class BalootSandboxShareCardTests: XCTestCase {
    func testSandboxShareTextIsDeterministic() {
        let configuration = BalootSandbox.defaultConfiguration

        XCTAssertEqual(
            BalootSandboxShareCard.text(configuration: configuration),
            BalootSandboxShareCard.text(configuration: configuration)
        )
    }

    func testSandboxShareTextIncludesCoreScenarioContext() {
        let text = BalootSandboxShareCard.text(configuration: BalootSandbox.defaultConfiguration)

        XCTAssertTrue(text.contains("مختبر البلوت".localized))
        XCTAssertTrue(text.contains("\("النمط".localized):"))
        XCTAssertTrue(text.contains("\("الصعوبة".localized):"))
        XCTAssertTrue(text.contains("\("المضاعف".localized):"))
        XCTAssertTrue(text.contains("\("الدور".localized):"))
        XCTAssertTrue(text.contains("\("الأوراق على الطاولة".localized):"))
        XCTAssertTrue(text.contains("\("الأوراق القانونية".localized):"))
        XCTAssertTrue(text.contains("وش تلعب؟".localized))
    }

    func testSandboxShareTextIncludesDeclaredProjects() throws {
        var configuration = BalootSandbox.defaultConfiguration
        configuration.handsBySeat[.south] = [
            PlayingCard(suit: .hearts, rank: .jack),
            PlayingCard(suit: .clubs, rank: .ten),
            PlayingCard(suit: .clubs, rank: .jack),
            PlayingCard(suit: .clubs, rank: .queen)
        ]
        configuration.declaredProjects = [
            try XCTUnwrap(BalootSandbox.suggestedProjectDeclaration(
                seat: .south,
                kind: .sira,
                configuration: configuration
            ))
        ]

        let text = BalootSandboxShareCard.text(configuration: configuration)

        XCTAssertTrue(text.contains("المشاريع المعلنة".localized))
        XCTAssertTrue(text.contains("سرا".localized))
        XCTAssertTrue(text.contains("+20"))
    }

    func testSandboxShareTextIncludesPreviewReview() throws {
        let configuration = BalootSandbox.defaultConfiguration
        let preview = try BalootSandbox.preview(
            playing: PlayingCard(suit: .hearts, rank: .jack),
            configuration: configuration
        )

        let text = BalootSandboxShareCard.text(configuration: configuration, preview: preview)

        XCTAssertTrue(text.contains("مراجعة القرار".localized))
        XCTAssertTrue(text.contains("\("اختيارك".localized): \(preview.selectedCard.accessibilityName)"))
        XCTAssertTrue(text.contains("\("اختيار الخبير".localized):"))
        XCTAssertTrue(text.contains("\("نقاط الأكلة".localized): 45"))
    }
}
