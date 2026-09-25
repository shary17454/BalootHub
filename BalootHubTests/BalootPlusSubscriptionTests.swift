import XCTest
import StoreKit
import StoreKitTest
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

/// SKTestSession routes every transaction to the local test store, never a real Apple account.
@MainActor
final class BalootPlusStoreKitTests: XCTestCase {
    private func session() throws -> SKTestSession {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/BalootPlus.storekit")
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    func testPurchaseRestoreAndExpirationUseCurrentEntitlements() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = SubscriptionStore()
        await store.configure()
        XCTAssertEqual(store.products.count, 2)
        let product = try XCTUnwrap(store.product(for: .monthly))
        await store.purchase(product)
        XCTAssertEqual(store.purchaseState, .purchased)
        XCTAssertTrue(store.purchasedProductIDs.contains(product.id))

        let restored = SubscriptionStore()
        await restored.restorePurchases()
        XCTAssertEqual(restored.purchaseState, .purchased)
        XCTAssertEqual(restored.purchasedProductIDs, store.purchasedProductIDs)

        try session.expireSubscription(productIdentifier: product.id)
        // The live updates listener must remove expired access without reopening the screen.
        for _ in 0..<100 where store.purchasedProductIDs.contains(product.id) {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertFalse(store.purchasedProductIDs.contains(product.id))
    }

    func testRefundRemovesEntitlement() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let transaction = try await session.buyProduct(identifier: BalootPlusProduct.yearly.rawValue)
        let store = SubscriptionStore()
        await store.configure()
        XCTAssertTrue(store.purchasedProductIDs.contains(transaction.productID))
        let testTransaction = try XCTUnwrap(session.allTransactions().first {
            $0.productIdentifier == transaction.productID
        })
        try session.refundTransaction(identifier: testTransaction.identifier)
        // Refund delivery through StoreKit is asynchronous. Require the live listener
        // to remove access, with a bounded wait rather than assuming synchronous delivery.
        for _ in 0..<100 where !store.purchasedProductIDs.isEmpty {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertTrue(store.purchasedProductIDs.isEmpty)
    }

    func testBillingGracePeriodKeepsEntitlement() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let productID = BalootPlusProduct.monthly.rawValue
        _ = try await session.buyProduct(identifier: productID)
        session.shouldEnterBillingRetryOnRenewal = true
        session.billingGracePeriodIsEnabled = true
        try session.forceRenewalOfSubscription(productIdentifier: productID)
        let products = try await Product.products(for: [productID])
        let subscription = try XCTUnwrap(products.first?.subscription)
        let statuses = try await subscription.status
        XCTAssertTrue(statuses.contains { $0.state == .inGracePeriod })
        let store = SubscriptionStore()
        await store.refreshEntitlements()
        XCTAssertTrue(store.purchasedProductIDs.contains(productID))
    }

    func testPendingApprovalDoesNotUnlockSubscription() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        session.askToBuyEnabled = true
        let store = SubscriptionStore()
        await store.loadProducts()
        await store.purchase(try XCTUnwrap(store.product(for: .monthly)))
        XCTAssertEqual(store.purchaseState, .pending)
        XCTAssertTrue(store.purchasedProductIDs.isEmpty)
        XCTAssertFalse(store.isBusy)
    }

    func testProductLoadingCanRetryAfterNetworkFailure() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        let store = SubscriptionStore()
        await store.loadProducts()
        guard case .failed = store.purchaseState else { return XCTFail("Expected loading failure") }
        XCTAssertFalse(store.isBusy)
        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        await store.loadProducts()
        XCTAssertEqual(store.products.count, 2)
        XCTAssertEqual(store.purchaseState, .idle)
    }

    func testPurchaseAndRestoreCannotOverlapAndCancellationReleasesLock() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = SubscriptionStore()
        await store.loadProducts()
        let product = try XCTUnwrap(store.product(for: .monthly))
        let started = expectation(description: "Purchase entered")
        var completion: CheckedContinuation<Product.PurchaseResult, Never>?
        let first = Task {
            await store.purchase(product) { _ in
                await withCheckedContinuation { continuation in
                    completion = continuation
                    started.fulfill()
                }
            }
        }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(store.isPurchasing)
        XCTAssertTrue(store.isBusy)
        var duplicateCalled = false
        await store.purchase(product) { _ in duplicateCalled = true; return .userCancelled }
        await store.restorePurchases()
        XCTAssertFalse(duplicateCalled)
        XCTAssertFalse(store.isRestoringPurchases)
        completion?.resume(returning: .userCancelled)
        await first.value
        XCTAssertEqual(store.purchaseState, .cancelled)
        XCTAssertFalse(store.isBusy)
    }
}
