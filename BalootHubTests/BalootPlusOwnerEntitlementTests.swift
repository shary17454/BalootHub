import XCTest
@testable import BalootHub

final class BalootPlusOwnerEntitlementTests: XCTestCase {
    private let suiteName = "BalootPlusOwnerEntitlementTests"

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testOwnerEmailDigestIsStableWithoutStoringEmailInEntitlement() {
        XCTAssertEqual(
            BalootPlusOwnerEntitlementOverride.digest(for: "SHARYALHWAID@GMAIL.COM "),
            "036a6f30eceeeeac0d800e80c2e824b3686decfe06d353a246ba282ce39cb36e"
        )
    }

    func testOwnerOverrideUnlocksFromHiddenDefaultsDigest() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(
            "036a6f30eceeeeac0d800e80c2e824b3686decfe06d353a246ba282ce39cb36e",
            forKey: BalootPlusOwnerEntitlementOverride.defaultsDigestKey
        )

        XCTAssertTrue(BalootPlusOwnerEntitlementOverride().isUnlocked(defaults: defaults, environment: [:]))
    }

    func testOwnerOverrideUnlocksFromEnvironmentDigest() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let environment = [
            BalootPlusOwnerEntitlementOverride.environmentDigestKey:
                "036a6f30eceeeeac0d800e80c2e824b3686decfe06d353a246ba282ce39cb36e"
        ]

        XCTAssertTrue(BalootPlusOwnerEntitlementOverride().isUnlocked(defaults: defaults, environment: environment))
    }

    func testOwnerOverrideStaysLockedForUnknownDigest() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(String(repeating: "0", count: 64), forKey: BalootPlusOwnerEntitlementOverride.defaultsDigestKey)

        XCTAssertFalse(BalootPlusOwnerEntitlementOverride().isUnlocked(defaults: defaults, environment: [:]))
    }

    func testOwnerEmailIsNotStoredInShippedAppSources() throws {
        let projectRoot = try Self.projectRoot()
        let shippedSourceRoot = projectRoot.appendingPathComponent("BalootHub")
        let ownerEmail = "sharyalhwaid@gmail.com"

        let matches = try Self.textFiles(in: shippedSourceRoot).filter { file in
            let text = try String(contentsOf: file, encoding: .utf8)
            return text.localizedCaseInsensitiveContains(ownerEmail)
        }

        XCTAssertTrue(
            matches.isEmpty,
            "Owner email must not be stored in shipped app sources:\n\(matches.map(\.path).joined(separator: "\n"))"
        )
    }

    private static func projectRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "BalootHubTests" {
            let next = url.deletingLastPathComponent()
            if next.path == url.path {
                throw NSError(domain: "BalootPlusOwnerEntitlementTests", code: 1)
            }
            url = next
        }
        return url.deletingLastPathComponent()
    }

    private static func textFiles(in url: URL) throws -> [URL] {
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let file as URL in enumerator {
            let values = try file.resourceValues(forKeys: resourceKeys)
            guard values.isRegularFile == true else { continue }
            guard Self.isTextFile(file) else { continue }
            files.append(file)
        }
        return files
    }

    private static func isTextFile(_ url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "swift", "plist", "pbxproj", "xcstrings", "md", "yml", "yaml", "json":
            return true
        default:
            return false
        }
    }
}
