import Foundation
import SwiftData

/// عنصر واحد في كتالوج الألعاب والأنماط. النموذج الموحد الذي يسمح بإضافة لعبة جديدة
/// عبر إضافة بيانات فقط، دون تعديل شاشات الرئيسية أو الألعاب يدويًا.
@Model
final class GameCatalogItem {
    var id: UUID
    var slug: String
    var arabicTitle: String
    var englishTitle: String?
    var shortDescription: String
    var categoryRaw: String
    var playerCountText: String
    var difficultyRaw: String
    var estimatedDuration: String
    var iconName: String
    var accentToken: String
    var isPlayable: Bool
    var isFavorite: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \GameRuleSection.game)
    var rules: [GameRuleSection] = []

    init(
        id: UUID = UUID(),
        slug: String,
        arabicTitle: String,
        englishTitle: String? = nil,
        shortDescription: String,
        category: GameCategory,
        playerCountText: String,
        difficulty: Difficulty,
        estimatedDuration: String,
        iconName: String,
        accentToken: String,
        isPlayable: Bool,
        isFavorite: Bool = false,
        sortOrder: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.slug = slug
        self.arabicTitle = arabicTitle
        self.englishTitle = englishTitle
        self.shortDescription = shortDescription
        self.categoryRaw = category.rawValue
        self.playerCountText = playerCountText
        self.difficultyRaw = difficulty.rawValue
        self.estimatedDuration = estimatedDuration
        self.iconName = iconName
        self.accentToken = accentToken
        self.isPlayable = isPlayable
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var category: GameCategory {
        get { GameCategory(rawValue: categoryRaw) ?? .balootGame }
        set { categoryRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .beginner }
        set { difficultyRaw = newValue.rawValue }
    }

    var sortedRules: [GameRuleSection] {
        rules.sorted { $0.order < $1.order }
    }

    // MARK: - نصوص العرض المترجَمة
    //
    // المحتوى يُزرع في قاعدة البيانات بالعربية مرة واحدة عند أول تشغيل، لذا لا يصح ترجمته
    // وقت الزرع (وإلا تجمّد على لغة أول تشغيل). بدل ذلك يبقى النص العربي مفتاحًا في
    // ``Localizable.xcstrings`` ويُترجَم وقت العرض، فيتبع لغة الجهاز فورًا عند تغييرها.

    /// عنوان اللعبة بلغة الجهاز الحالية.
    var displayTitle: String { arabicTitle.localized }

    /// الوصف المختصر بلغة الجهاز الحالية.
    var displayDescription: String { shortDescription.localized }

    /// نص عدد اللاعبين بلغة الجهاز الحالية.
    var displayPlayerCount: String { playerCountText.localized }

    /// المدة المتوقعة بلغة الجهاز الحالية.
    var displayDuration: String { estimatedDuration.localized }

    /// مراجع تشرح أنماطًا داخل لعبة البلوت الواحدة، ولا تمثل ألعابًا مستقلة.
    var isBalootModeReference: Bool {
        switch slug {
        case "baloot-sun",
             "baloot-hokum",
             "baloot-projects",
             "baloot-double",
             "baloot-ashkal",
             "baloot-gahwa-lock",
             "baloot-kaboot":
            true
        default:
            false
        }
    }

    /// عنوان حالة البطاقة في الكتالوج: يميّز مرجع النمط عن "قواعد فقط" العامة.
    var displayAvailabilityTitle: String {
        if isPlayable { return "متاح للعب".localized }
        if isBalootModeReference { return "مرجع نمط".localized }
        return "قواعد فقط".localized
    }

    var availabilityIconName: String {
        if isPlayable { return "play.fill" }
        if isBalootModeReference { return "rectangle.stack.fill" }
        return "book.fill"
    }

    /// وصف عملي قصير يشرح للمستخدم ماذا يفعل بهذا العنصر الآن.
    var displayUseTitle: String {
        if isPlayable { return "لعبة قابلة للعب".localized }
        if isBalootModeReference { return "شرح نمط داخل البلوت".localized }
        if category == .otherCardGame { return "لعبة ورق قابلة للعب".localized }

        switch slug {
        case "baloot-training":
            return "أكاديمية تفاعلية".localized
        case "what-to-play-trainer":
            return "مدرب قرار".localized
        case "hand-analyzer":
            return "تحليل يد".localized
        case "score-calculation-challenge":
            return "اختبار حساب".localized
        case "baloot-sandbox":
            return "مختبر مواقف".localized
        case "baloot-scorekeeper":
            return "مسجل نقاط".localized
        case "daily-baloot-challenges":
            return "تحديات يومية".localized
        case "baloot-career-mode":
            return "مسيرة وتقدم".localized
        case "offline-tournaments":
            return "تنظيم بطولة".localized
        case "baloot-achievements":
            return "إنجازات وألقاب".localized
        case "baloot-encyclopedia", "baloot-rare-cases", "baloot-bidding-guide", "baloot-projects-reference", "baloot-multiplayer-voice-guide":
            return "مرجع بلوت".localized
        default:
            return displayAvailabilityTitle
        }
    }

    /// خطوة الاستخدام المختصرة التي تظهر في بطاقة الكتالوج وصفحة التفاصيل.
    var displayUseDescription: String {
        if isPlayable {
            return "اضغط بدء اللعب. الصن والحكم يجيان داخل مزايدة واحدة مثل الواقع.".localized
        }
        if isBalootModeReference {
            return "اقرأ القاعدة هنا، ثم العبها من طاولة البلوت الكاملة.".localized
        }
        if category == .otherCardGame {
            return "اضغط بدء اللعب لفتح طاولة سريعة لهذه اللعبة، أو اقرأ القواعد قبل البداية.".localized
        }

        switch slug {
        case "baloot-training":
            return "افتح الأكاديمية واختر درسًا؛ كل درس فيه شرح ومثال وموقف عملي.".localized
        case "what-to-play-trainer":
            return "افتح المدرب واختر ورقة من الخيارات القانونية ثم قارن قرارك بالخبير.".localized
        case "hand-analyzer":
            return "أدخل أوراق يدك، وسيقترح التطبيق شراء صن أو حكم أو بس.".localized
        case "score-calculation-challenge":
            return "ابدأ الاختبار واحسب نتيجة الصكة قبل انتهاء المؤقت.".localized
        case "baloot-sandbox":
            return "افتح المختبر وجرب أثر الورقة على موقف محدد من المحرك.".localized
        case "baloot-scorekeeper":
            return "استخدمه أثناء مجلس حقيقي لتسجيل الصكات والمشاريع والمضاعفات.".localized
        case "daily-baloot-challenges":
            return "اختر تحدي اليوم أو الأسبوع وتابع تقدمك المحلي.".localized
        case "baloot-career-mode":
            return "تابع رتبتك وXP وما فُتح لك من محتوى تدريبي وتجميلي.".localized
        case "offline-tournaments":
            return "أنشئ بطولة محلية وأدخل الفرق وجدول المباريات بدون إنترنت.".localized
        case "baloot-achievements":
            return "راجع الألقاب وشروط فتحها من اللعب والتدريب.".localized
        case "baloot-encyclopedia":
            return "ابحث عن مصطلح بلوت واقرأ تعريفه ومثاله بسرعة.".localized
        case "baloot-rare-cases":
            return "افتح الحالات المختلف عليها واقرأ الحكم وسبب الحكم.".localized
        default:
            return displayDescription
        }
    }

    /// يبحث عن قسم قواعد بترتيبه المعياري الثابت (انظر ``StandardRuleSectionKind``).
    func ruleSection(_ kind: StandardRuleSectionKind) -> GameRuleSection? {
        sortedRules.first { $0.order == kind.order }
    }
}

/// الترتيب المعياري الثابت لأقسام القواعد، يُستخدم للعثور على قسم معيّن (مثل "احتساب النقاط")
/// لعرض ملخص عنه في صفحة التفاصيل دون تكرار المحتوى يدويًا.
enum StandardRuleSectionKind: Int, CaseIterable {
    case objective = 0
    case playerCount = 1
    case setup = 2
    case dealing = 3
    case cardRanking = 4
    case howToPlay = 5
    case scoring = 6
    case projects = 7
    case roundEnd = 8
    case commonMistakes = 9

    var order: Int { rawValue }

    var title: String {
        switch self {
        case .objective: "الهدف من اللعبة"
        case .playerCount: "عدد اللاعبين"
        case .setup: "تجهيز اللعب"
        case .dealing: "توزيع الأوراق"
        case .cardRanking: "ترتيب الأوراق"
        case .howToPlay: "طريقة اللعب"
        case .scoring: "احتساب النقاط"
        case .projects: "المشاريع أو المضاعفات"
        case .roundEnd: "نهاية الجولة"
        case .commonMistakes: "الأخطاء الشائعة"
        }
    }

    var iconName: String {
        switch self {
        case .objective: "target"
        case .playerCount: "person.3.fill"
        case .setup: "square.grid.2x2"
        case .dealing: "rectangle.on.rectangle.angled"
        case .cardRanking: "list.number"
        case .howToPlay: "hand.point.up.left.fill"
        case .scoring: "sum"
        case .projects: "star.fill"
        case .roundEnd: "flag.checkered"
        case .commonMistakes: "exclamationmark.triangle.fill"
        }
    }
}
