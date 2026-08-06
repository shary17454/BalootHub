import Foundation
import StoreKit
import Observation

/// معرّف منتج الشراء غير المستهلك (Non-Consumable) لفتح اللعبة الكاملة بدفعة واحدة.
enum ProductID {
    static let fullGameUnlock = "app.balooThub.ios.fullgame"
}

/// يدير عملية شراء "فتح اللعبة الكاملة" مرة واحدة عبر StoreKit 2،
/// ويتحقق من الاستحقاقات الحالية (Entitlements) عند بدء التطبيق.
/// لا يحتوي أي بيانات دفع: Apple تتولى كامل عملية الدفع والفوترة عبر App Store.
@Observable
@MainActor
final class PurchaseManager {
    private(set) var product: Product?
    private(set) var isFullGameUnlocked = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = listenForTransactionUpdates()
    }

    func start() async {
        await loadProduct()
        await refreshEntitlements()
    }

    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [ProductID.fullGameUnlock])
            product = products.first
            errorMessage = nil
        } catch {
            errorMessage = "تعذّر تحميل معلومات الشراء. تحقق من الاتصال وحاول مرة أخرى."
        }
    }

    func refreshEntitlements() async {
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
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isFullGameUnlocked = true
                    await transaction.finish()
                }
                errorMessage = nil
            case .userCancelled:
                break
            case .pending:
                errorMessage = "عملية الشراء قيد الموافقة (مثل التحكم الأبوي)، ستُفعَّل تلقائيًا عند اكتمالها."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "تعذّرت عملية الشراء. حاول مرة أخرى لاحقًا."
        }
    }

    func restorePurchases() async {
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
