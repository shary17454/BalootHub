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
        XCTAssertEqual(count, CatalogSeeder.previewItems().count)
    }

    func testSeedIfNeededDoesNotDuplicateOnSecondCall() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])

        CatalogSeeder.seedIfNeeded(container: container)
        CatalogSeeder.seedIfNeeded(container: container)

        let context = ModelContext(container)
        let count = try context.fetchCount(FetchDescriptor<GameCatalogItem>())
        XCTAssertEqual(count, CatalogSeeder.previewItems().count)
    }

    func testSeedIfNeededUpdatesLegacySunAndHokumEntriesIntoReferences() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        let context = ModelContext(container)
        let legacySun = GameCatalogItem(
            slug: "baloot-sun",
            arabicTitle: "بلوت صن",
            englishTitle: "Baloot Sun",
            shortDescription: "قديم",
            category: .balootGame,
            playerCountText: "4",
            difficulty: .beginner,
            estimatedDuration: "قديم",
            iconName: "sun.max.fill",
            accentToken: "accent",
            isPlayable: true,
            isFavorite: true,
            sortOrder: 100
        )
        context.insert(legacySun)
        try context.save()

        CatalogSeeder.seedIfNeeded(container: container)

        let descriptor = FetchDescriptor<GameCatalogItem>(
            predicate: #Predicate<GameCatalogItem> { $0.slug == "baloot-sun" }
        )
        let updatedSun = try XCTUnwrap(try context.fetch(descriptor).first)
        XCTAssertEqual(updatedSun.arabicTitle, "مرجع الصن")
        XCTAssertEqual(updatedSun.category, .balootTool)
        XCTAssertFalse(updatedSun.isPlayable)
        XCTAssertTrue(updatedSun.isFavorite)
        XCTAssertEqual(updatedSun.rules.count, StandardRuleSectionKind.allCases.count)

        let allItems = try context.fetch(FetchDescriptor<GameCatalogItem>())
        let playable = allItems.filter(\.isPlayable).map(\.slug)
        XCTAssertTrue(playable.contains("baloot-classic"))
        XCTAssertTrue(playable.contains("tarneeb"))
        XCTAssertTrue(playable.contains("trex"))
        XCTAssertTrue(playable.contains("hand"))
        XCTAssertFalse(playable.contains("baloot-sun"))
        XCTAssertFalse(playable.contains("baloot-hokum"))
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

    @MainActor
    func testHomeRefreshCoordinatorRefreshesLocalDataAndStoresTimestamp() async throws {
        UserDefaults.standard.removeObject(forKey: HomeRefreshCoordinator.lastRefreshDefaultsKey)

        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        let context = ModelContext(container)
        let coordinator = HomeRefreshCoordinator()
        let subscriptionStore = SubscriptionStore()

        await coordinator.refresh(
            modelContext: context,
            subscriptionStore: subscriptionStore,
            stageDelayNanoseconds: 0
        )

        let count = try context.fetchCount(FetchDescriptor<GameCatalogItem>())
        XCTAssertEqual(count, CatalogSeeder.previewItems().count)
        XCTAssertFalse(coordinator.isRefreshing)
        XCTAssertTrue(coordinator.didFinishSuccessfully)
        XCTAssertEqual(coordinator.progress, 1)
        XCTAssertGreaterThan(coordinator.lastRefreshTimestamp, 0)
        XCTAssertEqual(
            UserDefaults.standard.double(forKey: HomeRefreshCoordinator.lastRefreshDefaultsKey),
            coordinator.lastRefreshTimestamp
        )
    }
}
