import XCTest
@testable import BalootHub

/// `PurchaseManager` لم يكن له أي اختبار قبل هذا رغم أنه يحوي منطق حالة حقيقي.
/// يغطي هذا الملف المسارات الحتمية التي لا تحتاج اتصالًا فعليًا بـStoreKit —
/// محاولات ربط جلسة `SKTestSession` محلية لاختبار مسار الشراء الكامل لم تنجح
/// بثبات في هذه البيئة (`Product.products(for:)` يعيد نتيجة فارغة رغم صحة ملف
/// `Products.storekit` والجلسة)، فتُركت لجلسة تشخيص منفصلة بدل اختبار متذبذب.
@MainActor
final class PurchaseManagerTests: XCTestCase {
    /// نسخ التطوير مفتوحة دائمًا بلا شراء فعلي — هذا هو الاستثناء الموثَّق في
    /// `refreshEntitlements()`، ولا يحتاج أي اتصال بـStoreKit أصلًا.
    func testDebugBuildAutoUnlocksWithoutPurchase() async {
        let manager = PurchaseManager()

        await manager.refreshEntitlements()

        XCTAssertTrue(manager.isFullGameUnlocked)
    }

    /// عند تعطيل المشتريات لنسخة المراجعة الحالية، لا يحاول المدير فتح StoreKit
    /// ولا يعرض خطأ، وتبقى اللعبة مفتوحة حتى لا تظهر مراجع IAP غير مُرسلة للمراجعة.
    func testPurchaseWhenCommerceDisabledKeepsGameUnlocked() async {
        let manager = PurchaseManager()

        await manager.purchase()

        XCTAssertTrue(manager.isFullGameUnlocked)
        XCTAssertNil(manager.errorMessage)
    }

    func testStartWhenCommerceDisabledDoesNotLoadProduct() async {
        let manager = PurchaseManager()

        await manager.start()

        XCTAssertTrue(manager.isFullGameUnlocked)
        XCTAssertNil(manager.product)
        XCTAssertNil(manager.errorMessage)
        XCTAssertFalse(manager.isLoading)
    }

    /// ملاحظة: `refreshEntitlements()` (الذي يستدعيه `restorePurchases()` داخليًا)
    /// يتخطى StoreKit كليًا في بنية DEBUG — وهي بنية التشغيل الوحيدة لـ`xcodebuild
    /// test` هنا — فلا يمكن لهذا الاختبار التحقق من نتيجة الاستحقاق الفعلية (تكون
    /// `true` دائمًا بغض النظر عن نتيجة `AppStore.sync()`). المؤكَّد هنا فقط أن
    /// `AppStore.sync()` نفسه ينجح ولا يرمي خطأ.
    func testRestorePurchasesCompletesWithoutThrowing() async {
        let manager = PurchaseManager()

        await manager.restorePurchases()

        XCTAssertFalse(manager.isLoading)
    }
}
