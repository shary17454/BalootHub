import Foundation
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

enum BalootPlusPurchaseState: Equatable, Sendable {
    case idle
    case purchased
    case pending
    case cancelled
    case failed(String)

    var message: String? {
        switch self {
        case .idle: nil
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
    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var purchaseState: BalootPlusPurchaseState = .idle

    init(configuration: BalootPlusSubscriptionConfiguration = .live) {
        self.configuration = configuration
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var productIDs: [String] {
        configuration.productIDs
    }

    var isPremiumUnlocked: Bool {
        !purchasedProductIDs.isDisjoint(with: Set(productIDs))
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

    func purchase(_ product: Product) async {
        purchaseState = .idle

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try Self.verifiedTransaction(from: verificationResult)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                purchaseState = .purchased
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
        purchaseState = .idle

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = isPremiumUnlocked
                ? .purchased
                : .failed("لا توجد اشتراكات بلوت بلس فعالة على هذا الحساب.".localized)
        } catch {
            purchaseState = .failed("تعذر استعادة المشتريات من App Store.".localized)
        }
    }

    func refreshEntitlements() async {
        var activeProductIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.verifiedTransaction(from: result) else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                continue
            }
            activeProductIDs.insert(transaction.productID)
        }

        purchasedProductIDs = activeProductIDs
    }

    func hasAccess(to feature: BalootPlusFeature) -> Bool {
        isPremiumUnlocked
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard let transaction = try? Self.verifiedTransaction(from: result) else { return }
        guard productIDs.contains(transaction.productID) else { return }

        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
        } else {
            purchasedProductIDs.remove(transaction.productID)
        }

        await transaction.finish()
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
