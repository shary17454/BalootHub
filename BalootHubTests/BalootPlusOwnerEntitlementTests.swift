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

    func testOwnerOverrideStaysLockedForUnknownDigest() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(String(repeating: "0", count: 64), forKey: BalootPlusOwnerEntitlementOverride.defaultsDigestKey)

        XCTAssertFalse(BalootPlusOwnerEntitlementOverride().isUnlocked(defaults: defaults, environment: [:]))
    }
}
