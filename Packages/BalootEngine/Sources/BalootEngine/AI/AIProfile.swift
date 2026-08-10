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
