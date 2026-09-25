import XCTest
import SwiftData
@testable import BalootHub

final class CatalogSeederTests: XCTestCase {
    func testStorageFailureFallsBackWithoutCrashingAndIsMarkedTemporary() {
        enum StoreFailure: Error { case unavailable }
        let container = PersistenceController.makeContainer(createPersistent: { _, _ in throw StoreFailure.unavailable })
        XCTAssertTrue(PersistenceController.isTemporary(container))
    }

    func testScoreDataSurvivesClosingAndReopeningPersistentStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("BalootHubPersistence-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let schema = PersistenceController.appSchema
        func open() throws -> ModelContainer {
            try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        }
        let id = UUID()
        do {
            let container = try open()
            XCTAssertFalse(PersistenceController.isTemporary(container))
            let context = ModelContext(container)
            let session = ScoreSession(id: id, teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 152)
            context.insert(session)
            let round = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
            round.session = session
            session.rounds = [round]
            try context.save()
        }
        let reopened = try open()
        let context = ModelContext(reopened)
        let session = try XCTUnwrap(try context.fetch(FetchDescriptor<ScoreSession>()).first)
        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.teamOneName, "فريقنا")
        XCTAssertEqual(session.rounds.count, 1)
        XCTAssertEqual(session.teamOneTotal(rules: .standard), 100)
    }

    func testFailedCatalogReadDoesNotInsertDuplicateRecords() throws {
        let container = PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        let before = try context.fetchCount(FetchDescriptor<GameCatalogItem>())
        enum ReadFailure: Error { case unavailable }

        XCTAssertThrowsError(try CatalogSeeder.refresh(context: context, fetchItems: { _ in throw ReadFailure.unavailable }))
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<GameCatalogItem>()), before)
    }

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
