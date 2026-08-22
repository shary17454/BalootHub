import XCTest
@testable import BalootHub

@MainActor
final class WhatToPlayShareCodeImportViewTests: XCTestCase {
    func testShareCodeImportToneMapsToMessageStyle() {
        let view = WhatToPlayTrainerView()

        XCTAssertEqual(view.shareCodeMessageStyle(for: .prompt), .neutral)
        XCTAssertEqual(view.shareCodeMessageStyle(for: .savedReview), .success)
        XCTAssertEqual(view.shareCodeMessageStyle(for: .duplicateReview), .warning)
    }
}
