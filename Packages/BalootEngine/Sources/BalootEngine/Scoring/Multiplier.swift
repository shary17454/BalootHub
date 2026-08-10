import Foundation

/// مضاعف نتيجة الجولة، يقابل «الدبل» وتصعيداته أثناء المزايدة.
///
/// `rawValue` هنا **معرّف ثابت للحالة لا معامل ضرب**. المعامل الفعلي يُقرأ من
/// ``BalootRulesConfiguration`` عبر ``factor(rules:)`` لأن قيم التصعيد تختلف بين
/// المجالس (بعضها ثري ×3 وبعضها ×4). قيم الحالات الأربع الأولى تساوي معاملاتها
/// الافتراضية، فأي كود قديم كان يقرأ `rawValue` مباشرة يبقى سلوكه كما هو.
public enum Multiplier: Int, CaseIterable, Codable, Sendable, Comparable {
    case none = 1
    case double = 2
    case triple = 3
    case quadruple = 4
    /// «قهوة» — أعلى تصعيد متعارف عليه قبل القفل.
    case gahwa = 5

    public static func < (lhs: Multiplier, rhs: Multiplier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var arabicName: String {
        switch self {
        case .none: "بدون دبل"
        case .double: "دبل"
        case .triple: "ثري"
        case .quadruple: "فور"
        case .gahwa: "قهوة"
        }
    }

    /// معامل الضرب الفعلي حسب قواعد المجلس المختارة.
    public func factor(rules: BalootRulesConfiguration) -> Int {
        switch self {
        case .none: 1
        case .double: rules.doubleFactor
        case .triple: rules.tripleFactor
        case .quadruple: rules.quadrupleFactor
        case .gahwa: rules.gahwaFactor
        }
    }

    /// التصعيد التالي المتاح، أو `nil` عند بلوغ السقف.
    public var next: Multiplier? {
        switch self {
        case .none: .double
        case .double: .triple
        case .triple: .quadruple
        case .quadruple: .gahwa
        case .gahwa: nil
        }
    }
}
