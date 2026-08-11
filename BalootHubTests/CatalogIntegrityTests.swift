import XCTest
import SwiftData
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
        XCTAssertEqual(items.count, 20)

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

    /// الألعاب القابلة للعب الثلاث يجب أن تُشتق منها أنماط مختلفة فعلًا،
    /// وإلا فتحت الثلاث نفس الجولة بلا فرق.
    func testPlayableGamesMapToDistinctVariants() throws {
        let playable = try allItems().filter(\.isPlayable).map(\.slug).sorted()
        XCTAssertEqual(playable, ["baloot-classic", "baloot-hokum", "baloot-sun"])

        XCTAssertEqual(BalootGameVariant(slug: "baloot-classic"), .free)
        XCTAssertEqual(BalootGameVariant(slug: "baloot-sun"), .sunOnly)
        XCTAssertEqual(BalootGameVariant(slug: "baloot-hokum"), .hokumOnly)

        // كل نمط يجب أن يتيح خيارًا واحدًا على الأقل، وإلا علقت لوحة المزايدة فارغة.
        for variant in [BalootGameVariant.free, .sunOnly, .hokumOnly] {
            XCTAssertTrue(variant.allowsSun || variant.allowsHokum,
                          "النمط \(variant) لا يتيح أي خيار مزايدة")
        }
    }

    /// الرتب والأيقونات يجب أن تكون فريدة/مرتبة حتى لا تتكرر البطاقات أو تختل الترتيب.
    func testSlugsAreUniqueAndSortOrdersAreDistinct() throws {
        let items = try allItems()
        let slugs = items.map(\.slug)
        XCTAssertEqual(Set(slugs).count, slugs.count, "توجد slugs مكررة")

        let orders = items.map(\.sortOrder)
        XCTAssertEqual(Set(orders).count, orders.count, "توجد قيم sortOrder مكررة")
    }
}
