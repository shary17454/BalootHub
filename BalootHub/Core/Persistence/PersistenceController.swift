import Foundation
import SwiftData

/// يبني حاوية SwiftData للتطبيق، مع نسخة داخل الذاكرة فقط للمعاينات والاختبارات.
enum PersistenceController {
    static var appSchema: Schema {
        Schema([
            GameCatalogItem.self,
            GameRuleSection.self,
            ScoreSession.self,
            ScoreRound.self,
            OfflineTournament.self,
            WhatToPlayAttempt.self,
            ScoringQuizAttempt.self,
            AcademyLessonProgress.self,
            AppSettings.self
        ])
    }

    /// الحاوية الرئيسية المستخدمة في التطبيق الفعلي، مع تخزين محلي دائم على الجهاز فقط.
    ///
    /// عند تعذّر فتح المخزن الدائم (ترحيل فاشل بعد تحديث، أو ملف تالف على الجهاز)
    /// كان `fatalError` يعني انهيار التطبيق عند كل تشغيل بلا أي مخرج للمستخدم.
    /// البديل هنا تدرّج آمن: نحاول الدائم، ثم نسقط إلى مخزن داخل الذاكرة يُبقي التطبيق
    /// صالحًا للاستخدام في تلك الجلسة بدل أن يصبح غير قابل للفتح إطلاقًا.
    static func makeContainer() -> ModelContainer {
        createApplicationSupportDirectoryIfNeeded()

        let configuration = ModelConfiguration(schema: appSchema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: appSchema, configurations: [configuration]) {
            CatalogSeeder.seedIfNeeded(container: container)
            SettingsRepository.ensureSettingsExist(container: container)
            return container
        }

        // المخزن الدائم غير صالح للفتح: نكمل بمخزن مؤقت بدل إسقاط التطبيق.
        // البيانات المحلية تبقى على القرص كما هي ولا تُمسح، فيمكن استرجاعها لاحقًا
        // إن أصلح تحديثٌ قادمٌ سببَ الفشل.
        assertionFailure("تعذّر فتح مخزن SwiftData الدائم؛ تم التحويل إلى مخزن داخل الذاكرة")
        return makePreviewContainer()
    }

    /// حاوية داخل الذاكرة فقط، تُستخدم في SwiftUI Previews واختبارات الوحدات،
    /// وكمخزن احتياطي في ``makeContainer()`` عند تعذّر فتح المخزن الدائم.
    /// فشلها يعني تعذّر تشغيل التطبيق أصلًا، فيبقى `fatalError` هنا هو التصرف الصحيح.
    static func makePreviewContainer(seed: Bool = true) -> ModelContainer {
        let configuration = ModelConfiguration(schema: appSchema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: appSchema, configurations: [configuration])
            if seed {
                CatalogSeeder.seedIfNeeded(container: container)
                SettingsRepository.ensureSettingsExist(container: container)
            }
            return container
        } catch {
            fatalError("تعذّر إنشاء حاوية المعاينة: \(error.localizedDescription)")
        }
    }

    /// ينشئ مجلد Application Support قبل أن يحاول SwiftData إنشاء `default.store`.
    /// CoreData يستطيع التعافي أحيانًا إذا كان المجلد مفقودًا، لكنه يملأ سجل التشغيل
    /// بأخطاء file-write-create؛ تجهيز المجلد مسبقًا يجعل الإقلاع أنظف وأكثر توقعًا.
    private static func createApplicationSupportDirectoryIfNeeded() {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        try? FileManager.default.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true
        )
    }
}
