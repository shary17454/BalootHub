import XCTest
import BalootEngine
@testable import BalootHub

final class AppRouteTests: XCTestCase {
    func testWhatToPlayTrainerRouteCarriesGameMode() {
        let sunRoute = AppRoute.whatToPlayTrainer(
            seed: 123,
            difficulty: .medium,
            focusKind: .openingLead,
            gameMode: .sun
        )
        let hokumRoute = AppRoute.whatToPlayTrainer(
            seed: 123,
            difficulty: .medium,
            focusKind: .openingLead,
            gameMode: .hokum
        )

        XCTAssertNotEqual(sunRoute, hokumRoute)
        XCTAssertEqual(
            sunRoute,
            .whatToPlayTrainer(
                seed: 123,
                difficulty: .medium,
                focusKind: .openingLead,
                gameMode: .sun
            )
        )
    }

    @MainActor
    func testPracticeRecommendationNavigationOpensSeededWhatToPlayTrainer() {
        let appEnvironment = AppEnvironment()
        let recommendation = RoundPracticeRecommendation(
            priority: .play,
            difficulty: .expert,
            scenarioSeed: 987_654,
            suggestedScenarioCount: 5,
            title: "تدرب على وش تلعب؟",
            detail: "اختبار"
        )

        appEnvironment.openPracticeRecommendation(recommendation, from: .catalog)

        XCTAssertEqual(appEnvironment.selectedTab, .catalog)
        XCTAssertEqual(appEnvironment.catalogPath, [
            .whatToPlayTrainer(seed: 987_654, difficulty: .expert)
        ])
        XCTAssertTrue(appEnvironment.homePath.isEmpty)
        XCTAssertTrue(appEnvironment.scorekeeperPath.isEmpty)
        XCTAssertTrue(appEnvironment.historyPath.isEmpty)
    }
}
