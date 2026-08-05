import Foundation
import SwiftData

/// يضمن وجود سجل إعدادات وحيد (Singleton) في قاعدة البيانات المحلية.
enum SettingsRepository {
    @discardableResult
    static func ensureSettingsExist(container: ModelContainer) -> AppSettings {
        let context = ModelContext(container)
        return ensureSettingsExist(context: context)
    }

    @discardableResult
    static func ensureSettingsExist(context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
