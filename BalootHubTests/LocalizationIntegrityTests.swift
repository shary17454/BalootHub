import XCTest

/// يحرس **سلامة الترجمة نفسها**، لا وجودها فقط.
///
/// الترجمات تُضاف دفعات كبيرة (مئات النصوص × عشر لغات). أخطر خطأ في هذا العمل ليس
/// نصًا ناقصًا — بل نص **في غير لغته**: إزاحة صف واحد في قائمة دفعة تُسند الفرنسية
/// للإسبانية والروسية للأردية وهكذا. هذا الخطأ يبني بنجاح، ويمر من كل اختبار وحدة،
/// ولا يراه إلا مستخدم يقرأ بتلك اللغة. وقع فعلًا أثناء إضافة دفعات الترجمة.
///
/// الفحص هنا بنظام الكتابة: الروسية سيريلية، والهندية ديفاناغارية، والأردية عربية،
/// والصينية المبسّطة هان — فأي إزاحة تكسر هذا فورًا.
final class LocalizationIntegrityTests: XCTestCase {

    /// أنظمة الكتابة المتوقعة لكل لغة غير لاتينية.
    private static let scriptRanges: [String: [ClosedRange<UInt32>]] = [
        "ru": [0x0400...0x04FF],
        "hi": [0x0900...0x097F],
        "ur": [0x0600...0x06FF, 0x0750...0x077F],
        "zh-Hans": [0x4E00...0x9FFF]
    ]

    /// أسماء عَلَم تبقى بحروف لاتينية في كل اللغات باتفاق المشروع الموثّق في README
    /// (مصطلحات البلوت مثل `trump` في البريدج)، بالإضافة إلى رموز قيم الأوراق.
    private static let allowedLatinValues: Set<String> = [
        "Sun", "Hokum", "Coffee", "Kaboot", "Kaboot!", "Kaboot！",
        "Trix", "Tarneeb", "Kout Bou Sitta", "Hand",
        "A", "K", "Q", "J"
    ]

    /// أنظمة كتابة لا يجوز أن تظهر في لغة لاتينية — دليل قاطع على إزاحة صف.
    private static let nonLatinRanges: [ClosedRange<UInt32>] = [
        0x0400...0x04FF, 0x0900...0x097F, 0x0600...0x06FF, 0x4E00...0x9FFF
    ]

    private static let latinLanguages = ["fr", "es", "de", "tr", "id", "en"]

    // MARK: - الفحوصات

    func testNonLatinLanguagesUseTheirOwnScript() throws {
        let catalog = try Self.loadCatalog()
        var offenders: [String] = []

        for (key, localizations) in catalog {
            for (language, ranges) in Self.scriptRanges {
                guard let value = localizations[language], !value.isEmpty else { continue }
                guard !Self.allowedLatinValues.contains(value) else { continue }
                guard !Self.containsScalar(value, in: ranges) else { continue }
                offenders.append("[\(language)] \(key) -> \(value)")
            }
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "ترجمات بلا حروف لغتها المتوقعة (إزاحة صف أو نص إنجليزي منسوخ):\n"
                + offenders.prefix(20).joined(separator: "\n")
        )
    }

    func testLatinLanguagesDoNotContainOtherScripts() throws {
        let catalog = try Self.loadCatalog()
        var offenders: [String] = []

        for (key, localizations) in catalog {
            for language in Self.latinLanguages {
                guard let value = localizations[language], !value.isEmpty else { continue }
                guard Self.containsScalar(value, in: Self.nonLatinRanges) else { continue }
                offenders.append("[\(language)] \(key) -> \(value)")
            }
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "لغة لاتينية تحمل نصًا بنظام كتابة آخر (إزاحة صف):\n"
                + offenders.prefix(20).joined(separator: "\n")
        )
    }

    /// بادئة `en:` تُستخدم في سكربتات الدمج للتمييز، ويجب ألا تتسرب لملف الترجمة.
    func testNoMergeMarkerLeakedIntoValues() throws {
        let catalog = try Self.loadCatalog()
        let leaked = catalog.flatMap { key, localizations in
            localizations.compactMap { language, value in
                value.hasPrefix("en:") ? "[\(language)] \(key)" : nil
            }
        }

        XCTAssertTrue(leaked.isEmpty, "بادئة دمج تسربت للترجمة:\n\(leaked.joined(separator: "\n"))")
    }

    /// اللغة المصدر عربية، فأي مفتاح بلا أي ترجمة إنجليزية يظهر إنجليزيًا بالعربية.
    /// هذا الفحص وصفي: يثبّت العدد الحالي حتى لا يزيد بصمت مع كل شاشة جديدة.
    func testEnglishCoverageDoesNotRegress() throws {
        let catalog = try Self.loadCatalog()
        let withoutEnglish = catalog.filter { $0.value["en"]?.isEmpty ?? true }.count

        XCTAssertLessThanOrEqual(
            withoutEnglish,
            180,
            "عدد المفاتيح بلا ترجمة إنجليزية ارتفع؛ أي شاشة جديدة يجب أن تُضاف نصوصها للكتالوج"
        )
    }

    /// قيم يصحّ أن تتطابق مع الإنجليزية: أسماء عَلَم لألعاب ومصطلحات البلوت
    /// (موثّقة في README)، وكلمات متطابقة فعلًا في تلك اللغة (`Options` بالفرنسية،
    /// `System` بالألمانية، `Risk` بالتركية)، وسلاسل رمزية/رقمية بلا كلمات مترجَمة.
    ///
    /// القائمة مضبوطة على الوضع الحالي: أي تطابق **جديد** يسقط الاختبار ويفرض قرارًا
    /// صريحًا — إمّا ترجمته أو إضافته هنا بمبرّر.
    private static let allowedEnglishIdenticalValues: Set<String> = [
        "%d points", "10–20 minutes", "20–30 minutes",
        "Baloot", "Baloot Sandbox", "Baloot – Double",
        "Coffee", "Double",
        "Double ×2 · Triple ×3 · Quadruple ×4 · Coffee ×4",
        "Double ×2 · Triple ×4 · Quadruple ×6 · Coffee ×8",
        "Edit", "Expert", "Hand", "Hokum", "Jack", "Kaboot", "Kaboot!",
        "Kout Bou Sitta", "Level", "Minimal", "Mode", "Name", "OK", "Options",
        "Partner", "Pro", "Quadruple", "Risk", "Saad", "Sadu", "Sand", "Score",
        "Seed", "Session", "Simulation", "Sun", "System", "Tarneeb", "Teams",
        "Triple", "Trix", "Version", "point"
    ]

    /// يمنع **تسرّب الإنجليزية للغات اللاتينية**.
    ///
    /// فحص نظام الكتابة أعلاه يكشف الإزاحة في الروسية والهندية والأردية والصينية،
    /// لكنه **عاجز بنيويًا** عن الألمانية والإسبانية والفرنسية والإندونيسية والتركية:
    /// كلها لاتينية مثل الإنجليزية، فنصٌّ إنجليزي منسوخ فيها يمرّ من كل الفحوصات
    /// ويظهر للمستخدم إنجليزيًا وهو معلَّم `translated`.
    ///
    /// وقع هذا فعلًا: ٣٠ نصًا من صميم شاشة اللعب (المزايدة، إعلان المشاريع، تفسير
    /// المخالفات) كانت تحمل الإنجليزية حرفيًا في هذه اللغات الخمس، وخمسة نصوص ألمانية
    /// إضافية كانت معلَّمة `translated` وهي إنجليزية.
    func testLatinLanguagesDoNotShipEnglishVerbatim() throws {
        let catalog = try Self.loadCatalog()
        var offenders: [String] = []

        for (key, localizations) in catalog {
            guard let english = localizations["en"], !english.isEmpty else { continue }
            guard !Self.allowedEnglishIdenticalValues.contains(english) else { continue }

            for language in Self.latinLanguages where language != "en" {
                guard let value = localizations[language], value == english else { continue }
                offenders.append("[\(language)] \(key) -> \(value)")
            }
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "لغة لاتينية تعرض النص الإنجليزي حرفيًا (ترجمة زائفة):\n"
                + offenders.prefix(20).joined(separator: "\n")
        )
    }

    /// `needs_review` تعني ترجمة غير مؤكَّدة. كانت ٣٠ نصًا بهذه الحالة وكلها إنجليزية
    /// منسوخة، فوجودها مؤشر مبكر على دفعة ترجمة ناقصة قبل أن يراها مستخدم.
    func testNoLocalizationIsLeftNeedingReview() throws {
        let states = try Self.loadStates()
        let pending = states.filter { $0.value == "needs_review" }.map { $0.key }

        XCTAssertTrue(
            pending.isEmpty,
            "ترجمات ما زالت بحالة needs_review:\n" + pending.sorted().prefix(20).joined(separator: "\n")
        )
    }

    private static func loadStates() throws -> [String: String] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("BalootHub/Resources/Localizable.xcstrings")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let strings = object?["strings"] as? [String: [String: Any]] ?? [:]

        var states: [String: String] = [:]
        for (key, entry) in strings {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            for (language, localization) in localizations {
                guard let state = (localization["stringUnit"] as? [String: Any])?["state"] as? String
                else { continue }
                states["[\(language)] \(key)"] = state
            }
        }
        return states
    }

    // MARK: - أدوات

    private static func containsScalar(_ value: String, in ranges: [ClosedRange<UInt32>]) -> Bool {
        value.unicodeScalars.contains { scalar in
            ranges.contains { $0.contains(scalar.value) }
        }
    }

    private static func loadCatalog() throws -> [String: [String: String]] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root
            .appendingPathComponent("BalootHub")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = object?["strings"] as? [String: [String: Any]] ?? [:]

        return strings.mapValues { entry in
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            return localizations.compactMapValues { localization in
                (localization["stringUnit"] as? [String: Any])?["value"] as? String
            }
        }
    }
}
