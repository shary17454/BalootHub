import XCTest

final class AppReviewReadinessTests: XCTestCase {
    func testSubscriptionProductsAreDeclaredForAppStoreReview() throws {
        let projectRoot = try Self.projectRoot()
        let subscriptionSource = projectRoot
            .appendingPathComponent("BalootHub/Domain/Services/BalootPlusSubscription.swift")
        let text = try String(contentsOf: subscriptionSource, encoding: .utf8)

        XCTAssertTrue(text.contains("app.balooThub.ios.plus.monthly"))
        XCTAssertTrue(text.contains("app.balooThub.ios.plus.yearly"))
        XCTAssertTrue(text.contains("Baloot Plus"))
        XCTAssertTrue(text.contains("Product.products(for: productIDs)"))
        XCTAssertTrue(text.contains("AppStore.sync()"))
        XCTAssertTrue(text.contains("Transaction.currentEntitlements"))
    }

    func testAppDoesNotReferenceExternalDigitalPurchasePaths() throws {
        let projectRoot = try Self.projectRoot()
        let scannedRelativePaths = [
            "BalootHub",
            "BalootHub.xcodeproj/project.pbxproj",
            "AppStore/METADATA.md",
            "AppStore/PRIVACY_POLICY.md"
        ]
        let forbiddenTerms = [
            "digital purchase",
            "digital purchases",
            "external purchase",
            "outside the app",
            "web purchase",
            "شراء خارجي",
            "خارج التطبيق",
            "دفع خارجي"
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
            "External purchase references found:\n\(matches.joined(separator: "\n"))"
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
