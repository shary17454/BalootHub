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
        // Keep previously stored extreme values readable; new input is validated before saving.
        checkedFinalScore(baseScore: baseScore, projects: projects, multiplier: multiplier) ?? Int.max
    }

    func checkedFinalScore(baseScore: Int, projects: Int, multiplier: ScoreMultiplier) -> Int? {
        let sum = max(0, baseScore).addingReportingOverflow(max(0, projects))
        guard !sum.overflow else { return nil }
        let result = sum.partialValue.multipliedReportingOverflow(by: multiplierFactor(for: multiplier))
        return result.overflow ? nil : result.partialValue
    }

    static func addingScores(_ lhs: Int, _ rhs: Int) -> Int {
        let sum = lhs.addingReportingOverflow(rhs)
        return sum.overflow ? Int.max : sum.partialValue
    }

    /// عامل المضاعف الفعلي حسب إعدادات المجلس الحالية.
    func multiplierFactor(for multiplier: ScoreMultiplier) -> Int {
        switch multiplier {
        case .none:
            return 1
        case .double:
            return doubleFactor
        case .triple:
            return tripleFactor
        case .quadruple:
            return quadrupleFactor
        case .coffee:
            return coffeeEnabled ? coffeeFactor : 1
        }
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

/// Accepts decimal digits from Arabic/English keyboards without losing invalid project values as zero.
enum ScoreRoundInput {
    static func points(_ text: String, allowsEmpty: Bool = false) -> Int? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return allowsEmpty ? 0 : nil }
        var value = 0
        for character in text {
            guard character.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }),
                  let digit = character.wholeNumberValue, (0...9).contains(digit) else { return nil }
            let shifted = value.multipliedReportingOverflow(by: 10)
            guard !shifted.overflow else { return nil }
            let next = shifted.partialValue.addingReportingOverflow(digit)
            guard !next.overflow else { return nil }
            value = next.partialValue
        }
        return value
    }
}

/// قواعد مساعدة لتسريع إدخال صكة البلوت في المسجل.
///
/// تحتسب النقاط الأساسية فقط، أما المشاريع والمضاعفات فتظل حقولًا مستقلة حتى
/// لا تختلط نقاط الأوراق بنقاط المشاريع عند تعديل الصكة لاحقًا.
enum ScoreRoundAutofill {
    static func basePointTotal(for mode: BalootMode) -> Int {
        switch mode {
        case .sun:
            return 130
        case .hokum:
            return 162
        }
    }

    static func complementaryScore(for enteredScore: Int, mode: BalootMode) -> Int {
        max(basePointTotal(for: mode) - max(0, enteredScore), 0)
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
        case .standard: "الصيغة القياسية".localized
        case .highStakes: "صيغة مضاعفات أعلى".localized
        }
    }

    var subtitle: String {
        switch self {
        case .standard: "دبل ×2 · ثري ×3 · فور ×4 · قهوة ×4".localized
        case .highStakes: "دبل ×2 · ثري ×4 · فور ×6 · قهوة ×8".localized
        }
    }
}
