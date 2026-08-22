import XCTest

final class StringCatalogTests: XCTestCase {
    func testContextualWhatToPlayMistakeStringsAreLocalized() throws {
        let catalog = try loadStringCatalog()
        let requiredLocales = Set(["de", "en", "es", "fr", "hi", "id", "ru", "tr", "ur", "zh-Hans"])
        let keys = [
            "أخطاء عند التلزيم",
            "تكررت أخطاء مكلفة عندما كان على الطاولة لون مطلوب. قبل اختيار الورقة، احصر أوراق اللون أولًا ثم قارن هل تلعب للحماية أو لتخفيف الخسارة.",
            "ضغط الحكم يربك قرارك",
            "أكثر من خطأ حديث جاء في مواقف حكم أو وفيها حكم على الطاولة. راقب قوة الحكم المتبقية ولا تقطع إلا إذا كان القطع يربح الأكلة أو يحمي نقاط الفريق."
        ]

        for key in keys {
            let locales = try XCTUnwrap(catalog[key], "Missing string catalog key: \(key)")
            XCTAssertEqual(Set(locales.keys), requiredLocales, "Incomplete localizations for: \(key)")
            for locale in requiredLocales {
                let value = try XCTUnwrap(locales[locale], "Missing \(locale) localization for: \(key)")
                XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func loadStringCatalog() throws -> [String: [String: String]] {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogURL = projectRoot
            .appendingPathComponent("BalootHub")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = root?["strings"] as? [String: [String: Any]] ?? [:]

        return strings.mapValues { entry in
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            return localizations.compactMapValues { localization in
                let stringUnit = localization["stringUnit"] as? [String: Any]
                return stringUnit?["value"] as? String
            }
        }
    }
}
