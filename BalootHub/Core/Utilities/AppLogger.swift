import Foundation
import os

/// نقطة تسجيل موحّدة عبر `os.Logger`، مصنَّفة حسب الطبقة. تُستخدم في مسارات
/// الأخطاء التي كانت تصل المستخدم كرسالة عربية عامة بلا أي أثر تشخيصي — قبل هذا
/// لم يكن أي خطأ فعلي (فشل حفظ SwiftData، رفض فعل من المحرك، فشل StoreKit) يُسجَّل
/// في أي مكان، فتشخيص مشكلة بعد نشرها كان مستحيلًا بلا وصف المستخدم لها يدويًا.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app.balooThub.ios"

    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let game = Logger(subsystem: subsystem, category: "game")
    static let purchase = Logger(subsystem: subsystem, category: "purchase")
}
