import Foundation

/// مضاعف نتيجة الجولة، يقابل مفهوم "الدبل" أثناء المزايدة.
public enum Multiplier: Int, CaseIterable, Codable, Sendable {
    case none = 1
    case double = 2
    case triple = 3
    case quadruple = 4

    public var arabicName: String {
        switch self {
        case .none: "بدون دبل"
        case .double: "دبل"
        case .triple: "ثري"
        case .quadruple: "فور"
        }
    }
}
