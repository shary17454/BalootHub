import XCTest

final class AppReviewReadinessTests: XCTestCase {
    func testAppResourcesDoNotReferenceUnsubmittedDigitalPurchases() throws {
        let projectRoot = try Self.projectRoot()
        let scannedRelativePaths = [
            "BalootHub",
            "BalootHub.xcodeproj/project.pbxproj",
            "AppStore/METADATA.md",
            "AppStore/PRIVACY_POLICY.md"
        ]
        let forbiddenTerms = [
            "StoreKit",
            "In-App Purchase",
            "in-app purchase",
            "paywall",
            "subscription",
            "digital purchase",
            "digital purchases",
            "منتجات شراء",
            "عملية شراء داخل التطبيق",
            "اشتراكات"
        ]

        var matches: [String] = []
        for relativePath in scannedRelativePaths {
            let url = projectRoot.appendingPathComponent(relativePath)
            for file in try Self.textFiles(in: url) {
                let text = try String(contentsOf: file, encoding: .utf8)
                for term in forbiddenTerms where text.localizedCaseInsensitiveContains(term) {
                    matches.append("\(file.path.replacingOccurrences(of: projectRoot.path + "/", with: "")): \(term)")
                }
            }
        }

        XCTAssertTrue(
            matches.isEmpty,
            "App Review-sensitive purchase references found:\n\(matches.joined(separator: "\n"))"
        )
    }

    private static func projectRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "BalootHubTests" {
            let next = url.deletingLastPathComponent()
            if next.path == url.path {
                throw NSError(domain: "AppReviewReadinessTests", code: 1)
            }
            url = next
        }
        return url.deletingLastPathComponent()
    }

    private static func textFiles(in url: URL) throws -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return []
        }
        if !isDirectory.boolValue {
            return [url]
        }

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
