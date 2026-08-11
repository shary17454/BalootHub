import XCTest
@testable import BalootHub

final class AchievementCenterTests: XCTestCase {
    func testAchievementIDsAreUnique() {
        let ids = AchievementCenter.all.map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEveryAchievementHasDisplayDataAndRequirement() {
        for achievement in AchievementCenter.all {
            XCTAssertFalse(achievement.title.isEmpty)
            XCTAssertFalse(achievement.detail.isEmpty)
            XCTAssertFalse(achievement.requirement.isEmpty)
            XCTAssertFalse(achievement.iconName.isEmpty)
        }
    }

    func testUnlockedAchievementsFilterByIDs() {
        let unlocked = AchievementCenter.unlockedAchievements(from: ["first-kaboot", "scorekeeper"])

        XCTAssertEqual(Set(unlocked.map(\.id)), ["first-kaboot", "scorekeeper"])
    }
}
