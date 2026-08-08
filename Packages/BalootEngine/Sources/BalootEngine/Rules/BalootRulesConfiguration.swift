import Foundation

/// تهيئة قواعد محرك اللعب. تختلف بعض تفاصيل البلوت بين المجالس،
/// لذا تُفصل هنا كإعدادات قابلة للتبديل بدل تثبيتها داخل منطق المحرك.
///
/// الإعداد الافتراضي الموثّق المستخدم في هذا التطبيق:
/// - مجموع نقاط جولة "حكم" = 162 نقطة (152 من الأوراق + 10 لآخر أكلة، بدون مضاعفة).
/// - مجموع نقاط جولة "صن" الأساسي = 130 نقطة (120 من الأوراق + 10 لآخر أكلة)،
///   وتُضاعف افتراضيًا (×2) لتصبح 260 عند الاحتساب باتجاه هدف المباراة،
///   وهو ما يجعل هدف 152 منطقيًا كافتراضي مشترك بين النمطين.
/// - يجب "التلزيم" (اللعب على نفس نوع الورقة الأولى) عند الإمكان.
/// - في نمط حكم، إن لم تتوفر ورقة من نفس النوع ولدى اللاعب حكم، يجب "القطع" بالحكم.
/// - "التعلية" (اللعب بحكم أعلى من الحكم المطروح) غير إلزامية في هذا الإعداد الافتراضي.
public struct BalootRulesConfiguration: Codable, Sendable, Equatable {
    /// إجمالي نقاط جولة الحكم قبل أي مضاعفة (152 ورقة + 10 آخر أكلة).
    public var hokumRoundTotal: Int
    /// إجمالي نقاط جولة الصن الأساسي قبل المضاعفة.
    public var sunRoundBaseTotal: Int
    /// مضاعف نقاط الصن عند احتسابها باتجاه هدف المباراة.
    public var sunScoreMultiplier: Int
    /// مكافأة آخر أكلة في الجولة.
    public var lastTrickBonus: Int
    /// هل يلزم القطع بالحكم عند عدم توفر نوع الورقة المطلوبة؟
    public var mustTrumpWhenVoid: Bool
    /// هل تلزم التعلية عند القطع بالحكم (اللعب بحكم أعلى من الحكم المطروح إن أمكن)؟
    public var mustOvertrump: Bool

    public init(
        hokumRoundTotal: Int = 162,
        sunRoundBaseTotal: Int = 130,
        sunScoreMultiplier: Int = 2,
        lastTrickBonus: Int = 10,
        mustTrumpWhenVoid: Bool = true,
        mustOvertrump: Bool = false
    ) {
        self.hokumRoundTotal = hokumRoundTotal
        self.sunRoundBaseTotal = sunRoundBaseTotal
        self.sunScoreMultiplier = sunScoreMultiplier
        self.lastTrickBonus = lastTrickBonus
        self.mustTrumpWhenVoid = mustTrumpWhenVoid
        self.mustOvertrump = mustOvertrump
    }

    /// الإعداد الافتراضي الموثّق.
    public static let standard = BalootRulesConfiguration()
}
