import XCTest
import SwiftData
@testable import BalootHub

final class CatalogSeederTests: XCTestCase {
    func testSeedIfNeededPopulatesEmptyContainer() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])

        CatalogSeeder.seedIfNeeded(container: container)

        let context = ModelContext(container)
        let count = try context.fetchCount(FetchDescriptor<GameCatalogItem>())
        XCTAssertEqual(count, 18)
    }

    func testSeedIfNeededDoesNotDuplicateOnSecondCall() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])

        CatalogSeeder.seedIfNeeded(container: container)
        CatalogSeeder.seedIfNeeded(container: container)

        let context = ModelContext(container)
        let count = try context.fetchCount(FetchDescriptor<GameCatalogItem>())
        XCTAssertEqual(count, 18)
    }

    func testSettingsRepositoryCreatesSingletonOnce() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])

        let first = SettingsRepository.ensureSettingsExist(container: container)
        let second = SettingsRepository.ensureSettingsExist(container: container)

        XCTAssertEqual(first.defaultTargetScore, second.defaultTargetScore)

        let context = ModelContext(container)
        let count = try context.fetchCount(FetchDescriptor<AppSettings>())
        XCTAssertEqual(count, 1)
    }
}
