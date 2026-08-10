import Foundation

/// أسلوب دورة المزايدة.
public enum BiddingStyle: String, Codable, Sendable, CaseIterable {
    /// اختيار مباشر للنمط من لاعب واحد بعد توزيع الأوراق الثماني كاملة.
    /// أبقيناه لأن الدروس والمواقف التعليمية وسيناريوهات الاختبار تحتاج حالة
    /// مضبوطة بلا دورة مزايدة، وكسره كان سيُبطل كل ما بُني فوقه.
    case simple
    /// دورة المزايدة الكاملة: 5 أوراق + ورقة مكشوفة، جولة أولى، جولة أشكال،
    /// مضاعفة، ثم توزيع الأوراق الثلاث المتبقية.
    case full
}

/// تهيئة قواعد محرك اللعب. تختلف تفاصيل البلوت بين المجالس، لذا تُفصل هنا
/// كإعدادات قابلة للتبديل بدل تثبيتها داخل منطق المحرك.
///
/// الإعداد الافتراضي الموثّق المستخدم في هذا التطبيق:
/// - مجموع نقاط جولة «حكم» = 162 نقطة (152 من الأوراق + 10 لآخر أكلة، بدون مضاعفة).
/// - مجموع نقاط جولة «صن» الأساسي = 130 نقطة (120 + 10)، وتُضاعف افتراضيًا (×2) ⇒ 260.
/// - يجب «التلزيم» عند الإمكان، ويجب «القطع» بالحكم عند الخلوّ من النوع المطلوب.
/// - «التعلية» غير إلزامية.
///
/// > القيم المتعلقة بالكبوت والمضاعفات والمشاريع هي **الأكثر شيوعًا** لا الوحيدة
/// > الصحيحة؛ ولهذا هي إعدادات لا ثوابت، ليستطيع المستخدم ضبط «قواعد مجلسي».
public struct BalootRulesConfiguration: Codable, Sendable, Equatable {

    // MARK: - النقاط الأساسية

    /// إجمالي نقاط جولة الحكم قبل أي مضاعفة (152 ورقة + 10 آخر أكلة).
    public var hokumRoundTotal: Int
    /// إجمالي نقاط جولة الصن الأساسي قبل المضاعفة.
    public var sunRoundBaseTotal: Int
    /// مضاعف نقاط الصن عند احتسابها باتجاه هدف المباراة.
    public var sunScoreMultiplier: Int
    /// مكافأة آخر أكلة في الجولة.
    public var lastTrickBonus: Int

    // MARK: - قواعد اللعب

    /// هل يلزم القطع بالحكم عند عدم توفر نوع الورقة المطلوبة؟
    public var mustTrumpWhenVoid: Bool
    /// هل تلزم التعلية عند القطع بالحكم؟
    public var mustOvertrump: Bool

    // MARK: - المزايدة

    /// أسلوب دورة المزايدة.
    public var biddingStyle: BiddingStyle
    /// عدد الأوراق الموزَّعة قبل بدء المزايدة في النمط الكامل.
    public var cardsBeforeBidding: Int
    /// هل يجوز شراء الصن في الجولة الأولى (قبل جولة الأشكال)؟
    public var sunAllowedInFirstRound: Bool

    // MARK: - المضاعفات

    /// هل تُفعَّل المضاعفات (دبل/ثري/فور/قهوة) داخل اللعب؟
    public var multipliersEnabled: Bool
    public var doubleFactor: Int
    public var tripleFactor: Int
    public var quadrupleFactor: Int
    /// معامل «القهوة».
    public var gahwaFactor: Int
    /// أعلى مضاعف مسموح به في هذه القواعد.
    public var maximumMultiplier: Multiplier
    /// هل يجوز «القفل» لإنهاء التصعيد؟
    public var lockEnabled: Bool
    /// هل يُسمح بالمضاعفة في نمط الصن أيضًا (بعض المجالس تقصرها على الحكم)؟
    public var multiplierAllowedInSun: Bool

    // MARK: - المشاريع

    /// مفتاح عام لتعطيل كل المشاريع.
    public var projectsEnabled: Bool
    /// مشاريع التسلسل (سرا/خمسين/مية).
    public var sequenceProjectsEnabled: Bool
    /// مشاريع نفس القيمة (أربعمية/مية).
    public var sameRankProjectsEnabled: Bool
    /// مشروع البلوت (شايب وبنت الحكم).
    public var belotProjectEnabled: Bool
    /// هل يجب على اللاعب إعلان مشروعه ليُحتسب؟ عند التعطيل تُحتسب المشاريع تلقائيًا.
    public var projectsRequireDeclaration: Bool
    public var siraPoints: Int
    public var fiftyPoints: Int
    public var hundredPoints: Int
    public var fourHundredPoints: Int
    public var belotPoints: Int
    public var fourHundredEnabled: Bool
    /// هل «أربعمية» مقصورة على الصن؟
    public var fourHundredSunOnly: Bool

    // MARK: - الكبوت

    /// هل تُحتسب مكافأة الكبوت (أخذ الأكلات الثماني كلها)؟
    public var kabootEnabled: Bool
    /// مكافأة الكبوت في نمط الحكم.
    public var kabootBonusHokum: Int
    /// مكافأة الكبوت في نمط الصن (قبل مضاعف الصن).
    public var kabootBonusSun: Int

    // MARK: - المشتري

    /// هل يلزم فريق المشتري بتحقيق نقاط أكثر من الخصم («الطياح»)؟
    ///
    /// عند التفعيل، إذا لم يتجاوز فريق المشتري خصمه تذهب **كل** نقاط الجولة
    /// (بما فيها المشاريع) إلى الخصم. هذه قاعدة أساسية في البلوت لا تفصيل ثانوي:
    /// بدونها يصبح الشراء بلا مخاطرة، وتفقد المزايدة معناها بالكامل.
    public var declarerMustWinMajority: Bool

    // MARK: - المباراة

    /// هدف المباراة بالنقاط.
    public var matchTargetScore: Int

    public init(
        hokumRoundTotal: Int = 162,
        sunRoundBaseTotal: Int = 130,
        sunScoreMultiplier: Int = 2,
        lastTrickBonus: Int = 10,
        mustTrumpWhenVoid: Bool = true,
        mustOvertrump: Bool = false,
        biddingStyle: BiddingStyle = .full,
        cardsBeforeBidding: Int = 5,
        sunAllowedInFirstRound: Bool = true,
        multipliersEnabled: Bool = true,
        doubleFactor: Int = 2,
        tripleFactor: Int = 3,
        quadrupleFactor: Int = 4,
        gahwaFactor: Int = 6,
        maximumMultiplier: Multiplier = .gahwa,
        lockEnabled: Bool = true,
        multiplierAllowedInSun: Bool = true,
        projectsEnabled: Bool = true,
        sequenceProjectsEnabled: Bool = true,
        sameRankProjectsEnabled: Bool = true,
        belotProjectEnabled: Bool = true,
        projectsRequireDeclaration: Bool = true,
        siraPoints: Int = 20,
        fiftyPoints: Int = 50,
        hundredPoints: Int = 100,
        fourHundredPoints: Int = 400,
        belotPoints: Int = 20,
        fourHundredEnabled: Bool = true,
        fourHundredSunOnly: Bool = false,
        kabootEnabled: Bool = true,
        kabootBonusHokum: Int = 26,
        kabootBonusSun: Int = 44,
        declarerMustWinMajority: Bool = true,
        matchTargetScore: Int = 152
    ) {
        self.hokumRoundTotal = hokumRoundTotal
        self.sunRoundBaseTotal = sunRoundBaseTotal
        self.sunScoreMultiplier = sunScoreMultiplier
        self.lastTrickBonus = lastTrickBonus
        self.mustTrumpWhenVoid = mustTrumpWhenVoid
        self.mustOvertrump = mustOvertrump
        self.biddingStyle = biddingStyle
        self.cardsBeforeBidding = cardsBeforeBidding
        self.sunAllowedInFirstRound = sunAllowedInFirstRound
        self.multipliersEnabled = multipliersEnabled
        self.doubleFactor = doubleFactor
        self.tripleFactor = tripleFactor
        self.quadrupleFactor = quadrupleFactor
        self.gahwaFactor = gahwaFactor
        self.maximumMultiplier = maximumMultiplier
        self.lockEnabled = lockEnabled
        self.multiplierAllowedInSun = multiplierAllowedInSun
        self.projectsEnabled = projectsEnabled
        self.sequenceProjectsEnabled = sequenceProjectsEnabled
        self.sameRankProjectsEnabled = sameRankProjectsEnabled
        self.belotProjectEnabled = belotProjectEnabled
        self.projectsRequireDeclaration = projectsRequireDeclaration
        self.siraPoints = siraPoints
        self.fiftyPoints = fiftyPoints
        self.hundredPoints = hundredPoints
        self.fourHundredPoints = fourHundredPoints
        self.belotPoints = belotPoints
        self.fourHundredEnabled = fourHundredEnabled
        self.fourHundredSunOnly = fourHundredSunOnly
        self.kabootEnabled = kabootEnabled
        self.kabootBonusHokum = kabootBonusHokum
        self.kabootBonusSun = kabootBonusSun
        self.declarerMustWinMajority = declarerMustWinMajority
        self.matchTargetScore = matchTargetScore
    }

    // MARK: - إعدادات جاهزة

    /// الإعداد الافتراضي الموثّق.
    public static let standard = BalootRulesConfiguration()

    /// إعداد الاختبارات والدروس: مزايدة مبسّطة بلا دورة كاملة، ومشاريع تُحتسب تلقائيًا.
    /// يحافظ على سلوك المحرك السابق حرفيًا لكل ما بُني عليه.
    public static let simpleBidding = BalootRulesConfiguration(
        biddingStyle: .simple,
        projectsRequireDeclaration: false
    )

    /// قواعد البطولات: تعلية إلزامية، وسقف مضاعفة عند «فور»، وبلا أربعمية.
    public static let tournament = BalootRulesConfiguration(
        mustOvertrump: true,
        maximumMultiplier: .quadruple,
        fourHundredEnabled: false
    )

    // MARK: - Codable متسامح

    /// فك ترميز متسامح: أي مفتاح غير موجود يأخذ قيمته الافتراضية.
    ///
    /// ضروري لأن هذه البنية ستُحفظ ضمن «قواعد مجلسي» في بيانات المستخدم، وإضافة
    /// أي إعداد جديد لاحقًا كانت ستُفشل فك ترميز كل الإعدادات المحفوظة سابقًا.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = BalootRulesConfiguration()

        func value<T: Decodable>(_ key: CodingKeys, _ defaultValue: T) throws -> T {
            try container.decodeIfPresent(T.self, forKey: key) ?? defaultValue
        }

        hokumRoundTotal = try value(.hokumRoundTotal, fallback.hokumRoundTotal)
        sunRoundBaseTotal = try value(.sunRoundBaseTotal, fallback.sunRoundBaseTotal)
        sunScoreMultiplier = try value(.sunScoreMultiplier, fallback.sunScoreMultiplier)
        lastTrickBonus = try value(.lastTrickBonus, fallback.lastTrickBonus)
        mustTrumpWhenVoid = try value(.mustTrumpWhenVoid, fallback.mustTrumpWhenVoid)
        mustOvertrump = try value(.mustOvertrump, fallback.mustOvertrump)
        biddingStyle = try value(.biddingStyle, fallback.biddingStyle)
        cardsBeforeBidding = try value(.cardsBeforeBidding, fallback.cardsBeforeBidding)
        sunAllowedInFirstRound = try value(.sunAllowedInFirstRound, fallback.sunAllowedInFirstRound)
        multipliersEnabled = try value(.multipliersEnabled, fallback.multipliersEnabled)
        doubleFactor = try value(.doubleFactor, fallback.doubleFactor)
        tripleFactor = try value(.tripleFactor, fallback.tripleFactor)
        quadrupleFactor = try value(.quadrupleFactor, fallback.quadrupleFactor)
        gahwaFactor = try value(.gahwaFactor, fallback.gahwaFactor)
        maximumMultiplier = try value(.maximumMultiplier, fallback.maximumMultiplier)
        lockEnabled = try value(.lockEnabled, fallback.lockEnabled)
        multiplierAllowedInSun = try value(.multiplierAllowedInSun, fallback.multiplierAllowedInSun)
        projectsEnabled = try value(.projectsEnabled, fallback.projectsEnabled)
        sequenceProjectsEnabled = try value(.sequenceProjectsEnabled, fallback.sequenceProjectsEnabled)
        sameRankProjectsEnabled = try value(.sameRankProjectsEnabled, fallback.sameRankProjectsEnabled)
        belotProjectEnabled = try value(.belotProjectEnabled, fallback.belotProjectEnabled)
        projectsRequireDeclaration = try value(.projectsRequireDeclaration, fallback.projectsRequireDeclaration)
        siraPoints = try value(.siraPoints, fallback.siraPoints)
        fiftyPoints = try value(.fiftyPoints, fallback.fiftyPoints)
        hundredPoints = try value(.hundredPoints, fallback.hundredPoints)
        fourHundredPoints = try value(.fourHundredPoints, fallback.fourHundredPoints)
        belotPoints = try value(.belotPoints, fallback.belotPoints)
        fourHundredEnabled = try value(.fourHundredEnabled, fallback.fourHundredEnabled)
        fourHundredSunOnly = try value(.fourHundredSunOnly, fallback.fourHundredSunOnly)
        kabootEnabled = try value(.kabootEnabled, fallback.kabootEnabled)
        kabootBonusHokum = try value(.kabootBonusHokum, fallback.kabootBonusHokum)
        kabootBonusSun = try value(.kabootBonusSun, fallback.kabootBonusSun)
        declarerMustWinMajority = try value(.declarerMustWinMajority, fallback.declarerMustWinMajority)
        matchTargetScore = try value(.matchTargetScore, fallback.matchTargetScore)
    }
}
