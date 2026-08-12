import Foundation

/// ملف تعريف خصم آلي: مستواه وشخصيته وما يترتب عليهما من سلوك.
///
/// الاختلاف بين الخصوم مبني على **عمق التحليل ومعاملات القرار**، لا على حقن أخطاء
/// عشوائية. الخصم المبتدئ هنا لا «يخطئ عمدًا»؛ هو ببساطة لا يتتبع الأوراق الخارجة
/// ولا يحاكي التوزيعات المحتملة، فيلعب لعبًا سليمًا لكنه سطحي — وهذا ما يجعل التدرّج
/// في الصعوبة قابلًا للتعلّم بدل أن يكون عشوائيًا.
public struct AIProfile: Sendable, Equatable, Codable, Identifiable {

    /// مستوى الخصم: يحدد عمق التحليل.
    public enum Level: String, Codable, Sendable, CaseIterable, Comparable {
        /// لعب سليم بلا ذاكرة أوراق ولا محاكاة.
        case beginner
        /// وعي بالشريك وذاكرة أوراق، بلا محاكاة.
        case casual
        /// محاكاة ضحلة فوق الخبرة.
        case pro
        /// محاكاة كاملة.
        case expert
        /// محاكاة عميقة وقرارات مزايدة ومضاعفة جريئة.
        case sheikh

        public var order: Int {
            switch self {
            case .beginner: 0
            case .casual: 1
            case .pro: 2
            case .expert: 3
            case .sheikh: 4
            }
        }

        public static func < (lhs: Level, rhs: Level) -> Bool { lhs.order < rhs.order }

        /// عدد التوزيعات المحاكاة لكل ورقة مرشحة. صفر = بلا محاكاة.
        public var monteCarloSamples: Int {
            switch self {
            case .beginner, .casual: 0
            case .pro: 4
            case .expert: 8
            case .sheikh: 16
            }
        }

        /// هل يتتبع هذا المستوى الأوراق الخارجة ويستنتج منها؟
        public var tracksCardMemory: Bool { self != .beginner }
    }

    /// شخصية الخصم: تحدد ميوله في المزايدة والمضاعفة.
    public enum Personality: String, Codable, Sendable, CaseIterable {
        case balanced
        case conservative
        case aggressive
        case hokumSpecialist
        case sunSpecialist
        case gambler
        case defensive
    }

    public let id: String
    public var level: Level
    public var personality: Personality
    /// اسم رمز SF المستخدم كصورة رمزية.
    public var avatarSystemName: String

    public init(id: String, level: Level, personality: Personality, avatarSystemName: String) {
        self.id = id
        self.level = level
        self.personality = personality
        self.avatarSystemName = avatarSystemName
    }

    // MARK: - بيانات العرض والتحليل

    /// اسم المستوى كما يظهر للمستخدم.
    public var levelTitle: String {
        switch level {
        case .beginner: "مبتدئ"
        case .casual: "عادي"
        case .pro: "محترف"
        case .expert: "خبير"
        case .sheikh: "شيخ البلوت"
        }
    }

    /// اسم الشخصية كما يظهر للمستخدم.
    public var personalityTitle: String {
        switch personality {
        case .balanced: "متوازن"
        case .conservative: "محافظ"
        case .aggressive: "هجومي"
        case .hokumSpecialist: "متخصص حكم"
        case .sunSpecialist: "متخصص صن"
        case .gambler: "مخاطر"
        case .defensive: "دفاعي"
        }
    }

    /// اسم خصم جاهز وثابت. لا يعتمد على عشوائية حتى تبقى الإحصائيات قابلة للربط بالمعرّف.
    public var displayName: String {
        switch personality {
        case .balanced where level == .beginner: "سالم"
        case .balanced where level == .sheikh: "أبو ناصر"
        case .balanced: "فهد"
        case .conservative: "ماجد المحافظ"
        case .aggressive: "راكان الهجومي"
        case .hokumSpecialist: "ناصر الحكم"
        case .sunSpecialist: "بدر الصن"
        case .gambler: "تركي المخاطر"
        case .defensive: "خالد الدفاعي"
        }
    }

    /// وصف مختصر يشرح للاعب ما الذي يميّز الخصم قبل بدء المباراة.
    public var profileDescription: String {
        switch personality {
        case .balanced:
            level == .sheikh
                ? "يوازن بين قراءة الشريك والمخاطرة، ويستخدم محاكاة أعمق قبل القرارات الحساسة."
                : "يلعب بأسلوب متزن، لا يبالغ في الشراء ولا يترك اليد القوية تمر بسهولة."
        case .conservative:
            "يتجنب الشراء الهش، ولا يضاعف إلا عندما يرى أفضلية دفاعية واضحة."
        case .aggressive:
            "يضغط مبكرًا في المزايدة، ويميل لرفع قيمة اليد المتوسطة إذا وجد فرصة."
        case .hokumSpecialist:
            "يفضل الحكم عندما يملك طولًا وسيطرة في لون واضح، ويحسن استغلال ولد وتسعة الحكم."
        case .sunSpecialist:
            "يميل للصن عند وجود آسات وعشرات موزعة، ويقلل الاعتماد على لون حكم قصير."
        case .gambler:
            "يتقبل المخاطرة، يشتري أكثر من غيره، ولا يتردد في الدبل والتصعيد."
        case .defensive:
            "يركز على إسقاط المشتري، ويحافظ على الأوراق المؤثرة لقطع مجرى الجولة."
        }
    }

    /// ملخص عملي لأسلوب اللعب، يستخدمه التطبيق في صفحة اختيار الخصوم والإحصائيات.
    public var styleSummary: String {
        switch personality {
        case .balanced: "قرارات متوازنة بين الشراء والدفاع"
        case .conservative: "شراء قليل ومضاعفة نادرة"
        case .aggressive: "شراء وضغط مبكر"
        case .hokumSpecialist: "يفضل الحكم والسيطرة باللون"
        case .sunSpecialist: "يفضل الصن والأوراق العالية"
        case .gambler: "مخاطرة عالية وتصعيد مضاعفات"
        case .defensive: "دفاع قوي ضد المشتري"
        }
    }

    /// ملخص عمق التحليل الحقيقي خلف المستوى، لعرضه للمستخدم بدل الاكتفاء باسم الصعوبة.
    public var analysisSummary: String {
        if level.monteCarloSamples > 0 {
            return "يحاكي \(level.monteCarloSamples) احتمالات لكل قرار"
        }
        return level.tracksCardMemory
            ? "يتتبع الأوراق الخارجة بلا محاكاة"
            : "يلعب قانونيًا بلا ذاكرة أوراق"
    }

    /// درجة المخاطرة من 0 إلى 100. مشتقة من الشخصية والمستوى، وليست رقمًا تجميليًا.
    public var riskScore: Int {
        let base: Int
        switch personality {
        case .conservative: base = 20
        case .defensive: base = 35
        case .balanced: base = 45
        case .hokumSpecialist, .sunSpecialist: base = 50
        case .aggressive: base = 70
        case .gambler: base = 88
        }
        return min(100, max(0, base + level.order * 3))
    }

    /// ميل نمط اللعب: يوضح هل الخصم أقرب للصن أو الحكم أو متوازن.
    public var preferredMode: GameMode? {
        switch personality {
        case .hokumSpecialist: .hokum
        case .sunSpecialist: .sun
        default: nil
        }
    }

    /// درجة الميل للمضاعفة من 0 إلى 100، مشتقة من السياسة الفعلية.
    public var multiplierAggression: Int {
        let policy = biddingPolicy
        let thresholdPressure = max(0, 60 - policy.doubleThreshold)
        let escalationBonus = policy.escalatesMultiplier ? 24 : 0
        return min(100, max(0, thresholdPressure + policy.riskTolerance + escalationBonus + level.order * 4))
    }

    /// سياسة المزايدة الناتجة عن دمج المستوى بالشخصية.
    ///
    /// المستوى يضبط جودة التقدير (كلما ارتفع قلّ الهامش الاحتياطي لأن التقدير أدق)،
    /// والشخصية تضبط الميل والمخاطرة.
    public var biddingPolicy: BiddingPolicy {
        var policy = BiddingPolicy.standard

        // المستوى: الأدنى يشتري بتحفّظ زائد لأن تقديره لليد أضعف.
        switch level {
        case .beginner:
            policy.sunThreshold += 8
            policy.hokumThreshold += 8
            policy.doubleThreshold += 14
        case .casual:
            policy.sunThreshold += 4
            policy.hokumThreshold += 4
            policy.doubleThreshold += 6
        case .pro:
            break
        case .expert:
            policy.sunThreshold -= 2
            policy.hokumThreshold -= 2
            policy.escalatesMultiplier = true
        case .sheikh:
            policy.sunThreshold -= 4
            policy.hokumThreshold -= 4
            policy.doubleThreshold -= 4
            policy.escalatesMultiplier = true
            policy.hidesSmallProjects = true
        }

        // الشخصية: الميل والمخاطرة.
        switch personality {
        case .balanced:
            break
        case .conservative:
            policy.riskTolerance -= 6
            policy.doubleThreshold += 10
        case .aggressive:
            policy.riskTolerance += 7
            policy.doubleThreshold -= 4
        case .hokumSpecialist:
            policy.hokumBias += 8
            policy.sunBias -= 3
        case .sunSpecialist:
            policy.sunBias += 8
            policy.hokumBias -= 3
        case .gambler:
            policy.riskTolerance += 10
            policy.doubleThreshold -= 12
            policy.escalatesMultiplier = true
        case .defensive:
            policy.riskTolerance -= 4
            policy.doubleThreshold -= 6
        }

        return policy
    }

    // MARK: - الخصوم الجاهزون

    /// مجموعة الخصوم المعرَّفة في التطبيق. المعرّفات ثابتة لأن الإحصائيات وسجل
    /// المباريات يشير إليها، وتغييرها كان سيفصل كل تاريخ اللاعب عن خصومه.
    public static let roster: [AIProfile] = [
        AIProfile(id: "ai.rookie", level: .beginner, personality: .balanced, avatarSystemName: "person.fill"),
        AIProfile(id: "ai.cautious", level: .casual, personality: .conservative, avatarSystemName: "shield.fill"),
        AIProfile(id: "ai.attacker", level: .casual, personality: .aggressive, avatarSystemName: "flame.fill"),
        AIProfile(id: "ai.hokum", level: .pro, personality: .hokumSpecialist, avatarSystemName: "suit.spade.fill"),
        AIProfile(id: "ai.sun", level: .pro, personality: .sunSpecialist, avatarSystemName: "sun.max.fill"),
        AIProfile(id: "ai.gambler", level: .expert, personality: .gambler, avatarSystemName: "dice.fill"),
        AIProfile(id: "ai.wall", level: .expert, personality: .defensive, avatarSystemName: "lock.shield.fill"),
        AIProfile(id: "ai.sheikh", level: .sheikh, personality: .balanced, avatarSystemName: "crown.fill")
    ]

    /// ملف تعريف بمعرّف محدد، أو `nil` إن لم يوجد.
    public static func profile(id: String) -> AIProfile? {
        roster.first { $0.id == id }
    }

    /// ثلاثة خصوم لمستوى معيّن، مختلفو الشخصية قدر الإمكان.
    ///
    /// الاختيار حتمي (بلا عشوائية) حتى تُنتج نفس المباراة نفس الخصوم عند إعادة التشغيل.
    public static func opponents(for level: Level) -> [AIProfile] {
        let sameLevel = roster.filter { $0.level == level }
        guard sameLevel.count >= 3 else {
            let sorted = roster.sorted {
                (abs($0.level.order - level.order), $0.id) < (abs($1.level.order - level.order), $1.id)
            }
            return Array(sorted.prefix(3)).map { profile in
                AIProfile(id: profile.id, level: level, personality: profile.personality,
                          avatarSystemName: profile.avatarSystemName)
            }
        }
        return Array(sameLevel.prefix(3))
    }
}
