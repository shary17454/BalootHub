import XCTest

/// يحرس بيان الخصوصية المطلوب للرفع.
///
/// التطبيق يستخدم `UserDefaults` (عبر `@AppStorage`)، وهي ضمن «Required Reason
/// APIs» التي تشترط أبل الإفصاح عن سبب استخدامها في `PrivacyInfo.xcprivacy`.
/// بدونه يُرفض الرفع برسالة **ITMS-91053: Missing API declaration** — وهو رفض
/// لا يظهر في أي بناء أو اختبار، بل عند محاولة الرفع فقط.
///
/// كان الملف غائبًا فعلًا، وكان README يدّعي أنه غير مطلوب.
final class PrivacyManifestTests: XCTestCase {

    private static let requiredReasonCategories = ["NSPrivacyAccessedAPICategoryUserDefaults"]

    func testPrivacyManifestExists() throws {
        XCTAssertNotNil(try? Self.loadManifest(), "PrivacyInfo.xcprivacy مفقود من مصادر المشروع")
    }

    func testDeclaresEveryRequiredReasonAPIUsedByTheApp() throws {
        let manifest = try Self.loadManifest()
        let declared = (manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]] ?? [])
            .compactMap { $0["NSPrivacyAccessedAPIType"] as? String }

        for category in Self.requiredReasonCategories {
            XCTAssertTrue(
                declared.contains(category),
                "‏\(category) مستخدمة في التطبيق وغير مُفصح عنها — الرفع سيُرفض بـITMS-91053"
            )
        }
    }

    func testEveryDeclaredAPIHasAtLeastOneReasonCode() throws {
        let manifest = try Self.loadManifest()
        let entries = manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]] ?? []

        XCTAssertFalse(entries.isEmpty, "لا يوجد أي إفصاح عن Required Reason API")
        for entry in entries {
            let type = entry["NSPrivacyAccessedAPIType"] as? String ?? "?"
            let reasons = entry["NSPrivacyAccessedAPITypeReasons"] as? [String] ?? []
            XCTAssertFalse(reasons.isEmpty, "‏\(type) بلا رمز سبب — الإفصاح ناقص")
        }
    }

    /// التطبيق لا يجمع بيانات ولا يتتبّع؛ أي تغيير هنا يستوجب تحديث إفصاح المتجر.
    func testDeclaresNoTrackingAndNoCollectedData() throws {
        let manifest = try Self.loadManifest()

        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((manifest["NSPrivacyTrackingDomains"] as? [String])?.isEmpty, true)
        XCTAssertEqual((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty, true)
    }

    /// يمنع تكرار ما حدث فعلًا: نص في README يدّعي أن البيان غير مطلوب.
    func testReadmeDoesNotClaimTheManifestIsUnnecessary() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let readme = try String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)

        XCTAssertFalse(
            readme.contains("لم تتم إضافة `PrivacyInfo.xcprivacy`"),
            "README يدّعي أن بيان الخصوصية غير مطلوب، وهو موجود ومطلوب فعلًا"
        )
    }

    private static func loadManifest() throws -> [String: Any] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root
            .appendingPathComponent("BalootHub")
            .appendingPathComponent("Resources")
            .appendingPathComponent("PrivacyInfo.xcprivacy")
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }
}
