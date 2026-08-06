import Foundation

/// نوع الجولة في مسجّل تسجيل البلوت (مستقل عن محرك اللعب).
enum BalootMode: String, Codable, CaseIterable, Identifiable {
    case sun
    case hokum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sun: "صن".localized
        case .hokum: "حكم".localized
        }
    }
}

/// مضاعف نتيجة الجولة في مسجّل تسجيل البلوت.
enum ScoreMultiplier: String, Codable, CaseIterable, Identifiable {
    case none
    case double
    case triple
    case quadruple
    case coffee

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "بدون دبل".localized
        case .double: "دبل".localized
        case .triple: "ثري".localized
        case .quadruple: "فور".localized
        case .coffee: "قهوة".localized
        }
    }
}

enum SessionStatus: String, Codable, CaseIterable {
    case active
    case finished
}
