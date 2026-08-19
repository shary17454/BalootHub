import Foundation
import StoreKit
import Observation

/// معرّف منتج الشراء غير المستهلك (Non-Consumable) لفتح اللعبة الكاملة بدفعة واحدة.
enum ProductID {
    static let fullGameUnlock = "app.balooThub.ios.fullgame"
}

/// تتحكم في ظهور StoreKit داخل التطبيق.
///
/// منتج الشراء الكامل غير مُرسل حاليًا مع مراجعة App Store، لذلك تُبقي النسخة
/// الحالية اللعبة مفتوحة وتمنع ظهور أي مطالبة شراء حتى لا تُرفض المراجعة بسبب IAP
/// غير مرفق. عند تجهيز المنتج في App Store Connect وإرساله للمراجعة يمكن تفعيلها
/// من هنا فقط.
enum CommerceConfiguration {
    static let inAppPurchasesEnabled = false
}

/// يدير عملية شراء "فتح اللعبة الكاملة" مرة واحدة عبر StoreKit 2،
/// ويتحقق من الاستحقاقات الحالية (Entitlements) عند بدء التطبيق.
/// لا يحتوي أي بيانات دفع: Apple تتولى كامل عملية الدفع والفوترة عبر App Store.
@Observable
@MainActor
final class PurchaseManager {
    private(set) var product: Product?
    private(set) var isFullGameUnlocked = !CommerceConfiguration.inAppPurchasesEnabled
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let transactionListenerTask = CancellableTaskBox()

    init() {
        if CommerceConfiguration.inAppPurchasesEnabled {
            transactionListenerTask.replace(with: listenForTransactionUpdates())
        }
    }

    deinit {
        // `Transaction.updates` تيار لا ينتهي؛ بدون إلغاء صريح تبقى المهمة حيّة
        // بعد تحرّر المدير وتستهلك تحديثات لا مستقبِل لها.
        transactionListenerTask.cancel()
    }

    func start() async {
        guard CommerceConfiguration.inAppPurchasesEnabled else {
            isFullGameUnlocked = true
            product = nil
            errorMessage = nil
            return
        }
        await loadProduct()
        await refreshEntitlements()
    }

    func loadProduct() async {
        guard CommerceConfiguration.inAppPurchasesEnabled else {
            product = nil
            errorMessage = nil
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [ProductID.fullGameUnlock])
            product = products.first
            errorMessage = nil
        } catch {
            AppLogger.purchase.error("تعذّر تحميل المنتج \(ProductID.fullGameUnlock, privacy: .public): \(error.localizedDescription, privacy: .public)")
            errorMessage = "تعذّر تحميل معلومات الشراء. تحقق من الاتصال وحاول مرة أخرى."
        }
    }

    func refreshEntitlements() async {
        guard CommerceConfiguration.inAppPurchasesEnabled else {
            isFullGameUnlocked = true
            return
        }
        #if DEBUG
        // نسخ التطوير (تشغيل من Xcode مباشرة) مفتوحة دائمًا لصاحب المشروع دون شراء،
        // حتى لا يحتاج اختبار اللعبة الكاملة على جهازه الشخصي لعملية شراء فعلية.
        // نسخة App Store الحقيقية (Release) لا تتأثر بهذا الاستثناء وتمر بالشراء الفعلي.
        isFullGameUnlocked = true
        return
        #else
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == ProductID.fullGameUnlock {
                isFullGameUnlocked = true
                return
            }
        }
        isFullGameUnlocked = false
        #endif
    }

    func purchase() async {
        guard CommerceConfiguration.inAppPurchasesEnabled else {
            isFullGameUnlocked = true
            errorMessage = nil
            return
        }
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    isFullGameUnlocked = true
                    await transaction.finish()
                    errorMessage = nil
                case .unverified:
                    // توقيع المعاملة لم يجتز التحقق: لا نفتح المحتوى، وكان الفرع السابق
                    // يمرّ بصمت ويمسح الخطأ، فيرى المستخدم عملية "ناجحة" بلا أي أثر
                    // ولا أي تفسير. لا نُنهي المعاملة هنا حتى تُعاد المحاولة لاحقًا.
                    errorMessage = "تعذّر التحقق من عملية الشراء. جرّب \"استعادة المشتريات\" أو أعد المحاولة لاحقًا."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "عملية الشراء قيد الموافقة (مثل التحكم الأبوي)، ستُفعَّل تلقائيًا عند اكتمالها."
            @unknown default:
                break
            }
        } catch {
            AppLogger.purchase.error("فشلت عملية الشراء: \(error.localizedDescription, privacy: .public)")
            errorMessage = "تعذّرت عملية الشراء. حاول مرة أخرى لاحقًا."
        }
    }

    func restorePurchases() async {
        guard CommerceConfiguration.inAppPurchasesEnabled else {
            isFullGameUnlocked = true
            errorMessage = nil
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isFullGameUnlocked {
                errorMessage = "لم يُعثر على عملية شراء سابقة لهذا الحساب."
            } else {
                errorMessage = nil
            }
        } catch {
            AppLogger.purchase.error("فشلت استعادة المشتريات: \(error.localizedDescription, privacy: .public)")
            errorMessage = "تعذّرت استعادة المشتريات. حاول مرة أخرى لاحقًا."
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == ProductID.fullGameUnlock {
                    await self?.refreshEntitlements()
                }
                await transaction.finish()
            }
        }
    }
}
