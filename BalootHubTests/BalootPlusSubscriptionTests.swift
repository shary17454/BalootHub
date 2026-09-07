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

    func testRecommendedSaudiPricesAreConfiguredForAppStoreSetup() {
        XCTAssertEqual(BalootPlusProduct.monthly.recommendedSaudiPrice, "9.99 ر.س")
        XCTAssertEqual(BalootPlusProduct.yearly.recommendedSaudiPrice, "79.99 ر.س")
    }

    func testPaidFeaturesAreCosmeticTrainingOrAnalysisOnly() {
        let features = Set(BalootPlusFeature.allCases.map(\.rawValue))

        XCTAssertEqual(features, [
            "advancedTrainingAnalysis",
            "replayExpertReview",
            "sandboxScenarioLibrary",
            "expandedHandAnalyzer",
            "visualCustomizationPacks"
        ])
    }

    func testRestoreStateShowsProgressMessage() {
        XCTAssertEqual(BalootPlusPurchaseState.restoring.message, "جارِ التحميل…")
    }
}
