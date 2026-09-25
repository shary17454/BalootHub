import XCTest
import SwiftUI
import SwiftData
import StoreKit
import StoreKitTest
@testable import BalootHub

/// Render actual views using disposable data. Attachments are for human visual review,
/// not pixel-diff assertions or proof of VoiceOver/physical-device accessibility.
@MainActor
final class ReviewSnapshotTests: XCTestCase {
    func testArabicSubscriptionRetrySnapshot() async throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/BalootPlus.storekit")
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.resetToDefaultState(); session.clearTransactions() }
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        let environment = AppEnvironment()
        await environment.subscriptionStore.loadProducts()
        try await attachSnapshot(
            NavigationStack { BalootPlusView() }.environment(environment),
            name: "Arabic-Subscription-Retry-iPad", size: CGSize(width: 834, height: 1194)
        )
        guard case .failed = environment.subscriptionStore.purchaseState else { return XCTFail("Expected network failure") }
        XCTAssertTrue(environment.subscriptionStore.products.isEmpty)
        XCTAssertFalse(environment.subscriptionStore.isBusy)
    }

    func testArabicScoreFormSnapshot() async throws {
        let container = PersistenceController.makePreviewContainer()
        let session = ScoreSession(teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 152)
        let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
        container.mainContext.insert(session)
        round.session = session
        session.rounds = [round]
        try await attachSnapshot(
            NavigationStack { AddEditRoundView(session: session, roundToEdit: round) }.modelContainer(container),
            name: "Arabic-Score-Form-iPhone", size: CGSize(width: 393, height: 852)
        )
    }

    func testArabicPlayerStatsSnapshot() async throws {
        let container = PersistenceController.makePreviewContainer()
        let session = ScoreSession(teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 152, status: .finished)
        container.mainContext.insert(session)
        let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 160, teamTwoBaseScore: 62)
        round.session = session
        session.rounds = [round]
        try container.mainContext.save()
        try await attachSnapshot(
            NavigationStack { PlayerStatsView() }.modelContainer(container),
            name: "Arabic-Player-Stats-iPad", size: CGSize(width: 834, height: 1194)
        )
    }

    private func attachSnapshot<Content: View>(_ content: Content, name: String, size: CGSize) async throws {
        let previousWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let controller = UIHostingController(rootView: content
            .environment(\.locale, Locale(identifier: "ar"))
            .environment(\.layoutDirection, .rightToLeft))
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previousWindow?.makeKey() }
        try await Task.sleep(for: .milliseconds(300))
        controller.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            XCTAssertTrue(controller.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

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
