import Foundation

/// صيغة احتساب مضاعفات تسجيل البلوت. لا تفترض هذه الصيغة اتفاقًا واحدًا بين كل المجالس،
/// لذا تُشتق من "Preset" قابل للاختيار من الإعدادات بدل أن تكون قيمًا ثابتة داخل الواجهة.
struct ScoreRules: Equatable {
    var doubleFactor: Int
    var tripleFactor: Int
    var quadrupleFactor: Int
    var coffeeFactor: Int
    var coffeeEnabled: Bool

    /// يحسب النتيجة النهائية لجولة: (النقاط الأساسية + المشاريع) × مضاعف الدبل المختار.
    func finalScore(baseScore: Int, projects: Int, multiplier: ScoreMultiplier) -> Int {
        let factor: Int
        switch multiplier {
        case .none: factor = 1
        case .double: factor = doubleFactor
        case .triple: factor = tripleFactor
        case .quadruple: factor = quadrupleFactor
        case .coffee: factor = coffeeEnabled ? coffeeFactor : 1
        }
        return (max(0, baseScore) + max(0, projects)) * factor
    }

    static let standard = ScoreRules.from(preset: .standard, coffeeEnabled: false)

    static func from(preset: ScoreRulePreset, coffeeEnabled: Bool) -> ScoreRules {
        switch preset {
        case .standard:
            ScoreRules(doubleFactor: 2, tripleFactor: 3, quadrupleFactor: 4, coffeeFactor: 4, coffeeEnabled: coffeeEnabled)
        case .highStakes:
            ScoreRules(doubleFactor: 2, tripleFactor: 4, quadrupleFactor: 6, coffeeFactor: 8, coffeeEnabled: coffeeEnabled)
        }
    }
}

/// أسماء صيغ التسجيل المتاحة للاختيار من الإعدادات.
enum ScoreRulePreset: String, Codable, CaseIterable, Identifiable {
    /// الصيغة الشائعة: دبل ×2، ثري ×3، فور ×4، قهوة ×4.
    case standard
    /// صيغة أكثر تشددًا تستخدمها بعض المجالس: دبل ×2، ثري ×4، فور ×6، قهوة ×8.
    case highStakes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "الصيغة القياسية"
        case .highStakes: "صيغة مضاعفات أعلى"
        }
    }

    var subtitle: String {
        switch self {
        case .standard: "دبل ×2 · ثري ×3 · فور ×4 · قهوة ×4"
        case .highStakes: "دبل ×2 · ثري ×4 · فور ×6 · قهوة ×8"
        }
    }
}
