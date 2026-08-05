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
            AppSettings.self
        ])
    }

    /// الحاوية الرئيسية المستخدمة في التطبيق الفعلي، مع تخزين محلي دائم على الجهاز فقط.
    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: appSchema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: appSchema, configurations: [configuration])
            CatalogSeeder.seedIfNeeded(container: container)
            SettingsRepository.ensureSettingsExist(container: container)
            return container
        } catch {
            fatalError("تعذّر إنشاء حاوية SwiftData: \(error.localizedDescription)")
        }
    }

    /// حاوية داخل الذاكرة فقط، تُستخدم في SwiftUI Previews واختبارات الوحدات.
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
}
