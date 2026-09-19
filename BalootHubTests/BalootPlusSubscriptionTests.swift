import XCTest
@testable import BalootHub

final class BalootPlusSubscriptionTests: XCTestCase {
    func testLiveConfigurationDeclaresMonthlyAndYearlyProductsInStableOrder() {
        let configuration = BalootPlusSubscriptionConfiguration.live

        XCTAssertEqual(configuration.subscriptionGroupReferenceName, "Baloot Plus")
        XCTAssertEqual(configuration.productIDs, [
            "app.balooThub.ios.plus.monthly",
            "app.balooThub.ios.plus.yearly"
        ])
    }

    func testPaidFeaturesAreCosmeticTrainingOrAnalysisOnly() {
        let features = Set(BalootPlusFeature.allCases.map(\.rawValue))

        XCTAssertEqual(features, [
            "advancedTrainingAnalysis",
            "replayExpertReview",
            "sandboxScenarioLibrary",
            "expandedHandAnalyzer"
        ])
    }

    func testRestoreStateShowsProgressMessage() {
        XCTAssertEqual(BalootPlusPurchaseState.restoring.message, "جارِ التحميل…")
    }
}
