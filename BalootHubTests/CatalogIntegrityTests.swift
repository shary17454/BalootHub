import XCTest
import SwiftData
import BalootEngine
@testable import BalootHub

/// يتحقق من أن **كل** عنصر في الكتالوج جاهز فعليًا للفتح في الواجهة: بيانات مكتملة،
/// وأقسام قواعد كاملة، ونصوص مترجَمة، ووجهة تنقّل صالحة. الهدف اكتشاف عنصر
/// "يفتح على شاشة ناقصة" قبل أن يصل للمستخدم، لأن الواجهة تبني كل شيء من هذي البيانات.
final class CatalogIntegrityTests: XCTestCase {

    private func makeSeededContext() throws -> ModelContext {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        CatalogSeeder.seedIfNeeded(container: container)
        return ModelContext(container)
    }

    private func allItems() throws -> [GameCatalogItem] {
        try makeSeededContext().fetch(FetchDescriptor<GameCatalogItem>())
    }

    /// كل عنصر يجب أن يملك الحقول التي تعرضها صفحة التفاصيل، وإلا ظهرت فراغات.
    func testEveryCatalogItemHasCompleteDisplayData() throws {
        let items = try allItems()
        XCTAssertEqual(items.count, 27)

        for item in items {
            XCTAssertFalse(item.slug.isEmpty, "slug فارغ")
            XCTAssertFalse(item.arabicTitle.isEmpty, "\(item.slug): العنوان فارغ")
            XCTAssertFalse(item.shortDescription.isEmpty, "\(item.slug): الوصف فارغ")
            XCTAssertFalse(item.playerCountText.isEmpty, "\(item.slug): عدد اللاعبين فارغ")
            XCTAssertFalse(item.estimatedDuration.isEmpty, "\(item.slug): المدة فارغة")
            XCTAssertFalse(item.iconName.isEmpty, "\(item.slug): الأيقونة فارغة")
        }
    }

    /// صفحة القواعد تعرض الأقسام العشرة المعيارية؛ أي نقص يظهر كقسم مفقود للمستخدم.
    func testEveryCatalogItemHasAllTenRuleSections() throws {
        for item in try allItems() {
            XCTAssertEqual(item.rules.count, StandardRuleSectionKind.allCases.count,
                           "\(item.slug): عدد أقسام القواعد غير مكتمل")

            for kind in StandardRuleSectionKind.allCases {
                let section = item.ruleSection(kind)
                XCTAssertNotNil(section, "\(item.slug): القسم \(kind) مفقود")
                XCTAssertFalse(section?.body.isEmpty ?? true, "\(item.slug): نص القسم \(kind) فارغ")
                XCTAssertFalse(section?.title.isEmpty ?? true, "\(item.slug): عنوان القسم \(kind) فارغ")
            }
        }
    }

    /// لا يجوز أن يصل نص العنصر النائب للمستخدم في نسخة منشورة.
    func testNoPlaceholderTextLeaksIntoCatalog() throws {
        let placeholder = "سيُضاف هذا القسم قريبًا."
        for item in try allItems() {
            for section in item.rules {
                XCTAssertNotEqual(section.body, placeholder,
                                  "\(item.slug): القسم \(section.title) ما زال نصًا نائبًا")
            }
        }
    }

    /// خصائص العرض هي ما تستخدمه الواجهة فعليًا؛ يجب ألا تعود فارغة لأي عنصر.
    func testLocalizedDisplayPropertiesAreNeverEmpty() throws {
        for item in try allItems() {
            XCTAssertFalse(item.displayTitle.isEmpty, "\(item.slug): displayTitle فارغ")
            XCTAssertFalse(item.displayDescription.isEmpty, "\(item.slug): displayDescription فارغ")
            XCTAssertFalse(item.displayPlayerCount.isEmpty, "\(item.slug): displayPlayerCount فارغ")
            XCTAssertFalse(item.displayDuration.isEmpty, "\(item.slug): displayDuration فارغ")

            for section in item.rules {
                XCTAssertFalse(section.displayBody.isEmpty, "\(item.slug): displayBody فارغ")
                XCTAssertFalse(section.displayTitle.isEmpty, "\(item.slug): displayTitle للقسم فارغ")
            }
        }
    }

    /// كل عنصر لا بد أن يقود إلى وجهة صالحة: شاشة لعب للألعاب القابلة للعب،
    /// وصفحة قواعد لغيرها. عنصر بلا وجهة يعني زرًّا لا يفعل شيئًا.
    func testEveryItemResolvesToAValidDestination() throws {
        for item in try allItems() {
            XCTAssertFalse(item.slug.isEmpty)
            if item.isPlayable {
                // الألعاب القابلة للعب يجب أن تكون من فئة ألعاب البلوت حصرًا،
                // لأن شاشة اللعب مبنية على محرك البلوت وحده.
                XCTAssertEqual(item.category, .balootGame,
                               "\(item.slug): معلَّم كقابل للعب لكنه ليس لعبة بلوت")
            }
        }
    }

    /// البلوت لعبة واحدة في الواقع: الصن والحكم يُختاران داخل المزايدة، وليسا مدخلين
    /// منفصلين لطاولتين مختلفتين.
    func testPlayableBalootIsSingleClassicEntry() throws {
        let playable = try allItems().filter(\.isPlayable).map(\.slug).sorted()
        XCTAssertEqual(playable, ["baloot-classic"])

        XCTAssertEqual(BalootGameVariant(slug: "baloot-classic"), .free)
        XCTAssertEqual(BalootGameVariant(slug: "baloot-sun"), .free)
        XCTAssertEqual(BalootGameVariant(slug: "baloot-hokum"), .free)

        let sun = try XCTUnwrap(try allItems().first { $0.slug == "baloot-sun" })
        let hokum = try XCTUnwrap(try allItems().first { $0.slug == "baloot-hokum" })
        XCTAssertFalse(sun.isPlayable)
        XCTAssertFalse(hokum.isPlayable)
        XCTAssertEqual(sun.category, .balootTool)
        XCTAssertEqual(hokum.category, .balootTool)
        XCTAssertTrue(sun.isBalootModeReference)
        XCTAssertTrue(hokum.isBalootModeReference)
        XCTAssertEqual(sun.displayAvailabilityTitle, "مرجع نمط".localized)
        XCTAssertEqual(hokum.displayAvailabilityTitle, "مرجع نمط".localized)
    }

    /// حتى لو فُتح رابط قديم لصن أو حكم، يجب أن يدخل المستخدم لعبة البلوت الواحدة
    /// ذات المزايدة الكاملة، لا نمطًا منفصلًا يفرض الصن أو الحكم مسبقًا.
    @MainActor
    func testLegacySunAndHokumLinksKeepFullBalootBidding() {
        let sunViewModel = BalootGameViewModel(variant: BalootGameVariant(slug: "baloot-sun"), rules: .standard)
        let hokumViewModel = BalootGameViewModel(variant: BalootGameVariant(slug: "baloot-hokum"), rules: .standard)

        XCTAssertTrue(sunViewModel.usesFullBidding)
        XCTAssertTrue(hokumViewModel.usesFullBidding)
        XCTAssertEqual(sunViewModel.state.rules.biddingStyle, .full)
        XCTAssertEqual(hokumViewModel.state.rules.biddingStyle, .full)
    }

    /// بعد بدء الطاولة من أي رابط قديم، تكون الصن والحكم خيارات مزايدة داخل نفس
    /// اللعبة، وليست حالة مفروضة قبل التوزيع.
    @MainActor
    func testLegacyModeLinksExposeSunAndHokumAsBidsAfterDeal() throws {
        let viewModel = BalootGameViewModel(variant: BalootGameVariant(slug: "baloot-hokum"), tableMode: .localHumans, rules: .standard)

        viewModel.deal()
        viewModel.revealLocalHumanHand()

        let upSuit = try XCTUnwrap(viewModel.upCard?.suit)
        XCTAssertEqual(viewModel.state.phase, .bidding)
        XCTAssertNil(viewModel.state.mode)
        XCTAssertNil(viewModel.state.trumpSuit)
        XCTAssertTrue(viewModel.legalBidsForHuman.contains(.pass))
        XCTAssertTrue(viewModel.legalBidsForHuman.contains(.sun))
        XCTAssertTrue(viewModel.legalBidsForHuman.contains(.hokum(suit: upSuit)))
    }

    /// Replay يجب أن يبدأ من لقطة ما قبل التوزيع لا من الحالة النهائية، لأن الدورة
    /// الميتة تنقل الموزّع للجولة التالية.
    @MainActor
    func testGameplayReplayInitialStateSurvivesVoidDealerRotation() throws {
        let viewModel = BalootGameViewModel(tableMode: .localHumans, rules: .standard)

        viewModel.deal()
        let replayInitial = viewModel.currentRoundReplayInitialState
        let startingDealer = viewModel.state.dealerSeat

        for _ in 0..<8 {
            viewModel.revealLocalHumanHand()
            viewModel.placeBid(.pass)
        }

        XCTAssertEqual(viewModel.state.bidding.stage, .voided)
        XCTAssertEqual(viewModel.state.dealerSeat, startingDealer.next)
        XCTAssertEqual(replayInitial.dealerSeat, startingDealer)

        let replayed = try GameEngine.replay(
            initialState: replayInitial,
            actions: viewModel.state.actionHistory
        )
        XCTAssertEqual(replayed.bidding.stage, .voided)
        XCTAssertEqual(replayed.dealerSeat, viewModel.state.dealerSeat)
        XCTAssertEqual(replayed.lastRoundResult, viewModel.state.lastRoundResult)
    }

    @MainActor
    func testGameplayNextRoundReusesFinishedStateInsteadOfNewMatch() {
        let viewModel = BalootGameViewModel(tableMode: .localHumans, rules: .standard)

        viewModel.deal()
        let firstRoundPlayerIDs = viewModel.state.players.map(\.id)
        let originalDealer = viewModel.state.dealerSeat

        for _ in 0..<8 {
            viewModel.revealLocalHumanHand()
            viewModel.placeBid(.pass)
        }

        XCTAssertEqual(viewModel.state.phase, .finished)
        XCTAssertEqual(viewModel.state.dealerSeat, originalDealer.next)

        viewModel.startNextRound()

        XCTAssertEqual(viewModel.state.roundNumber, 2)
        XCTAssertEqual(viewModel.state.players.map(\.id), firstRoundPlayerIDs)
        XCTAssertEqual(viewModel.state.dealerSeat, originalDealer.next)
        XCTAssertEqual(viewModel.state.phase, .bidding)
        XCTAssertEqual(viewModel.state.actionHistory.count, 1)
        if case .dealCards = viewModel.state.actionHistory.first {
            XCTAssertTrue(true)
        } else {
            XCTFail("الجولة التالية يجب أن تبدأ بفعل توزيع واحد فقط")
        }
    }

    /// إعدادات المجلس قد تُستخدم في المحرك لاختبارات أو دروس مبسطة، لكن شاشة اللعب
    /// النهائية لا تفصل الصن والحكم؛ تفرض مزايدة بلوت كاملة دائمًا.
    @MainActor
    func testGameplayForcesFullBiddingEvenWhenRulesPresetIsSimple() {
        let viewModel = BalootGameViewModel(rules: .simpleBidding)

        XCTAssertTrue(viewModel.usesFullBidding)
        XCTAssertEqual(viewModel.state.rules.biddingStyle, .full)
    }

    /// اختيار الخصم في الواجهة يجب أن يغيّر الشخصية والسياسة الفعلية لا العنوان فقط.
    @MainActor
    func testGameplayCanSwitchAIProfile() throws {
        let viewModel = BalootGameViewModel(rules: .standard)
        let wall = try XCTUnwrap(AIProfile.profile(id: "ai.wall"))

        viewModel.setAIProfile(wall)

        XCTAssertEqual(viewModel.selectedAIProfile, wall)
        XCTAssertEqual(viewModel.aiLevel, wall.level)
        XCTAssertEqual(viewModel.state.rules.biddingStyle, .full)
        XCTAssertNotEqual(viewModel.state.phase, .setup)
    }

    @MainActor
    func testGameplayAssignsDistinctProfilesToAISeats() throws {
        let viewModel = BalootGameViewModel(rules: .standard)
        let gambler = try XCTUnwrap(AIProfile.profile(id: "ai.gambler"))

        viewModel.setAIProfile(gambler)

        XCTAssertEqual(viewModel.aiOpponentProfiles.count, 3)
        XCTAssertTrue(viewModel.aiOpponentProfiles.contains(gambler))
        XCTAssertGreaterThan(Set(viewModel.aiOpponentProfiles.map(\.personality)).count, 1)
    }

    @MainActor
    func testGameplayRenamesAIPlayersFromAssignedProfiles() throws {
        let viewModel = BalootGameViewModel(rules: .standard)
        let profileNames = Set(viewModel.aiOpponentProfiles.map { $0.displayName.localized })
        let playerNames = Set(viewModel.state.players.filter { $0.kind == .ai }.map(\.name))

        XCTAssertEqual(playerNames, profileNames)
    }

    @MainActor
    func testGameplayAIProfileSummaryUsesSelectedProfileMetadata() throws {
        let viewModel = BalootGameViewModel(rules: .standard)
        let hokum = try XCTUnwrap(AIProfile.profile(id: "ai.hokum"))

        viewModel.setAIProfile(hokum)

        XCTAssertTrue(viewModel.selectedAIProfileTitle.contains(hokum.displayName.localized))
        XCTAssertTrue(viewModel.selectedAIProfileDetail.contains(hokum.levelTitle.localized))
        XCTAssertTrue(viewModel.selectedAIProfileRiskText.contains("\(hokum.riskScore)"))
        XCTAssertTrue(viewModel.selectedAIProfileMultiplierText.contains("\(hokum.multiplierAggression)"))
        XCTAssertEqual(viewModel.selectedAIProfileModePreferenceText, "\("الميل".localized): \("حكم".localized)")
    }

    /// أي رسالة خطأ جديدة في واجهات التدريب يجب أن تدخل كتالوج النصوص، حتى لا تظهر
    /// بالعربية فقط في اللغات الأخرى.
    func testShareCodeStatsSaveFailureMessageIsLocalized() throws {
        let localizations = try Self.localizations(
            for: "تم تحميل مراجعة القرار، لكن تعذّر حفظها في الإحصاءات."
        )

        XCTAssertTrue(localizations.keys.contains("ar"), "الرسالة تحتاج قيمة عربية في كتالوج النصوص")
        XCTAssertTrue(localizations.keys.contains("en"), "الرسالة تحتاج قيمة إنجليزية في كتالوج النصوص")
        XCTAssertEqual(
            localizations["en"],
            "The decision review was loaded, but it could not be saved to statistics."
        )
    }

    /// الرتب والأيقونات يجب أن تكون فريدة/مرتبة حتى لا تتكرر البطاقات أو تختل الترتيب.
    func testSlugsAreUniqueAndSortOrdersAreDistinct() throws {
        let items = try allItems()
        let slugs = items.map(\.slug)
        XCTAssertEqual(Set(slugs).count, slugs.count, "توجد slugs مكررة")

        let orders = items.map(\.sortOrder)
        XCTAssertEqual(Set(orders).count, orders.count, "توجد قيم sortOrder مكررة")
    }

    private static func localizations(for key: String) throws -> [String: String] {
        let catalogURL = try projectRoot()
            .appendingPathComponent("BalootHub")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(root["strings"] as? [String: Any])
        let entry = try XCTUnwrap(strings[key] as? [String: Any], "مفتاح الترجمة مفقود: \(key)")
        let localizationEntries = try XCTUnwrap(entry["localizations"] as? [String: Any])

        return localizationEntries.reduce(into: [:]) { result, pair in
            guard
                let localization = pair.value as? [String: Any],
                let stringUnit = localization["stringUnit"] as? [String: Any],
                let value = stringUnit["value"] as? String
            else { return }
            result[pair.key] = value
        }
    }

    private static func projectRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "BalootHubTests" {
            let next = url.deletingLastPathComponent()
            if next.path == url.path {
                throw NSError(domain: "CatalogIntegrityTests", code: 1)
            }
            url = next
        }
        return url.deletingLastPathComponent()
    }
}
