import Foundation
import CryptoKit
import Observation
import StoreKit

enum BalootPlusProduct: String, CaseIterable, Identifiable, Sendable {
    case monthly = "app.balooThub.ios.plus.monthly"
    case yearly = "app.balooThub.ios.plus.yearly"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "بلوت بلس الشهري".localized
        case .yearly: "بلوت بلس السنوي".localized
        }
    }

    var periodTitle: String {
        switch self {
        case .monthly: "شهري".localized
        case .yearly: "سنوي".localized
        }
    }

    var recommendedSaudiPrice: String {
        switch self {
        case .monthly: "9.99 ر.س"
        case .yearly: "79.99 ر.س"
        }
    }

    var sortOrder: Int {
        switch self {
        case .monthly: 0
        case .yearly: 1
        }
    }
}

enum BalootPlusFeature: String, CaseIterable, Identifiable, Sendable {
    case advancedTrainingAnalysis
    case replayExpertReview
    case sandboxScenarioLibrary
    case expandedHandAnalyzer
    case visualCustomizationPacks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .advancedTrainingAnalysis: "تحليل تدريبي متقدم".localized
        case .replayExpertReview: "مراجعة الخبير للتسجيلات".localized
        case .sandboxScenarioLibrary: "مكتبة مواقف المختبر".localized
        case .expandedHandAnalyzer: "تحليل يد موسّع".localized
        case .visualCustomizationPacks: "حزم تخصيص تجميلية".localized
        }
    }

    var detail: String {
        switch self {
        case .advancedTrainingAnalysis:
            "يفتح شرحًا أعمق للأثر المتوقع في مواقف وش تلعب وتحليل ما بعد الجولة.".localized
        case .replayExpertReview:
            "يعرض مقارنة إضافية بين قراراتك وقرار Expert Agent داخل الإعادة.".localized
        case .sandboxScenarioLibrary:
            "يحفظ مواقف مختبر البلوت المتقدمة ويعيد تشغيلها كتمارين قابلة للمشاركة.".localized
        case .expandedHandAnalyzer:
            "يوسّع توصية حلّل يدي بتقييم المخاطر والمشاريع والشراء السنوي أو الشهري.".localized
        case .visualCustomizationPacks:
            "يفتح طاولات وظهور أوراق وثيمات شكلية فقط، بلا أي أفضلية داخل اللعب.".localized
        }
    }
}

struct BalootPlusSubscriptionConfiguration: Sendable {
    let subscriptionGroupReferenceName: String
    let products: [BalootPlusProduct]

    static let live = BalootPlusSubscriptionConfiguration(
        subscriptionGroupReferenceName: "Baloot Plus",
        products: BalootPlusProduct.allCases.sorted { $0.sortOrder < $1.sortOrder }
    )

    var productIDs: [String] {
        products.map(\.rawValue)
    }

    func product(for productID: String) -> BalootPlusProduct? {
        products.first { $0.rawValue == productID }
    }
}

struct BalootPlusOwnerEntitlementOverride {
    static let defaultsDigestKey = "BalootHubOwnerAccountEmailSHA256"
    static let environmentDigestKey = "BALOOT_HUB_OWNER_EMAIL_SHA256"

    private static let ownerEmailDigest = "036a6f30eceeeeac0d800e80c2e824b3686decfe06d353a246ba282ce39cb36e"

    func isUnlocked(
        defaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Bool {
        let candidates = [
            defaults.string(forKey: Self.defaultsDigestKey),
            environment[Self.environmentDigestKey]
        ]

        return candidates.contains { candidate in
            guard let digest = candidate?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                return false
            }
            return digest == Self.ownerEmailDigest
        }
    }

    static func digest(for email: String) -> String {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return SHA256.hash(data: Data(normalized.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

enum BalootPlusPurchaseState: Equatable, Sendable {
    case idle
    case restoring
    case purchased
    case pending
    case cancelled
    case failed(String)

    var message: String? {
        switch self {
        case .idle: nil
        case .restoring: "جارِ التحميل…".localized
        case .purchased: "تم تفعيل بلوت بلس على هذا الجهاز.".localized
        case .pending: "عملية الشراء بانتظار موافقة Apple أو إكمال الدفع.".localized
        case .cancelled: "أُلغيت عملية الشراء.".localized
        case .failed(let message): message
        }
    }
}

@MainActor
@Observable
final class SubscriptionStore {
    private let configuration: BalootPlusSubscriptionConfiguration
    private let ownerEntitlementOverride: BalootPlusOwnerEntitlementOverride
    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var entitlementRefreshGeneration = 0

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var isRestoringPurchases = false
    private(set) var isPurchasing = false
    private(set) var purchaseState: BalootPlusPurchaseState = .idle

    init(
        configuration: BalootPlusSubscriptionConfiguration = .live,
        ownerEntitlementOverride: BalootPlusOwnerEntitlementOverride = BalootPlusOwnerEntitlementOverride()
    ) {
        self.configuration = configuration
        self.ownerEntitlementOverride = ownerEntitlementOverride
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var productIDs: [String] {
        configuration.productIDs
    }

    var isPremiumUnlocked: Bool {
        ownerEntitlementOverride.isUnlocked()
            || !purchasedProductIDs.isDisjoint(with: Set(productIDs))
    }

    var isBusy: Bool {
        isLoading || isRestoringPurchases || isPurchasing
    }

    var configuredProducts: [BalootPlusProduct] {
        configuration.products
    }

    func configure() async {
        if transactionUpdatesTask == nil {
            transactionUpdatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    await self?.handleTransactionUpdate(result)
                }
            }
        }

        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        guard !isBusy else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedProducts = try await Product.products(for: productIDs)
            products = fetchedProducts.sorted { lhs, rhs in
                let lhsOrder = configuration.product(for: lhs.id)?.sortOrder ?? Int.max
                let rhsOrder = configuration.product(for: rhs.id)?.sortOrder ?? Int.max
                return lhsOrder < rhsOrder
            }
            purchaseState = .idle
        } catch {
            purchaseState = .failed("تعذر تحميل منتجات بلوت بلس من App Store. تحقق من إعدادات الاشتراكات أو جرّب لاحقًا.".localized)
        }
    }

    func product(for configuredProduct: BalootPlusProduct) -> Product? {
        products.first { $0.id == configuredProduct.rawValue }
    }

    func purchase(
        _ product: Product,
        performPurchase: @MainActor (Product) async throws -> Product.PurchaseResult = { try await $0.purchase() }
    ) async {
        guard !isBusy, productIDs.contains(product.id) else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        purchaseState = .idle

        do {
            let result = try await performPurchase(product)
            switch result {
            case .success(let verificationResult):
                let transaction = try Self.verifiedTransaction(from: verificationResult)
                await transaction.finish()
                await refreshEntitlements()
                purchaseState = isPremiumUnlocked ? .purchased : .idle
            case .pending:
                purchaseState = .pending
            case .userCancelled:
                purchaseState = .cancelled
            @unknown default:
                purchaseState = .failed("لم تُكمل Apple عملية الشراء. حاول مرة أخرى.".localized)
            }
        } catch {
            purchaseState = .failed("تعذر إكمال الشراء. تحقق من اتصال App Store أو إعدادات الحساب.".localized)
        }
    }

    func restorePurchases() async {
        guard !isBusy else { return }

        isRestoringPurchases = true
        purchaseState = .restoring
        defer { isRestoringPurchases = false }

        do {
            await refreshEntitlements()
            if isPremiumUnlocked {
                purchaseState = .purchased
                return
            }

            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = isPremiumUnlocked
                ? .purchased
                : .failed("لا توجد اشتراكات بلوت بلس فعالة على هذا الحساب.".localized)
        } catch {
            await refreshEntitlements()
            purchaseState = isPremiumUnlocked
                ? .purchased
                : .failed("تعذر استعادة المشتريات من App Store.".localized)
        }
    }

    func refreshEntitlements() async {
        entitlementRefreshGeneration &+= 1
        let generation = entitlementRefreshGeneration
        var activeProductIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.verifiedTransaction(from: result) else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil, !transaction.isUpgraded else { continue }
            // StoreKit includes auto-renewable subscriptions in billing grace period.
            // Filtering expirationDate here would incorrectly remove that valid entitlement.
            activeProductIDs.insert(transaction.productID)
        }

        guard generation == entitlementRefreshGeneration, !Task.isCancelled else { return }
        purchasedProductIDs = activeProductIDs
    }

    func hasAccess(to feature: BalootPlusFeature) -> Bool {
        isPremiumUnlocked
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard let transaction = try? Self.verifiedTransaction(from: result) else { return }
        guard productIDs.contains(transaction.productID) else { return }

        await transaction.finish()
        // An update can be expired, revoked, or superseded. Refresh the authoritative set.
        await refreshEntitlements()
    }

    private static func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            transaction
        case .unverified:
            throw StoreKitError.failedVerification
        }
    }
}

private enum StoreKitError: Error {
    case failedVerification
}
