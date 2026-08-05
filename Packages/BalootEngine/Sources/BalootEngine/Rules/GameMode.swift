import Foundation

/// نمط الجولة المُختار بعد المزايدة.
public enum GameMode: String, Codable, Sendable, CaseIterable {
    /// صن: لا يوجد نوع حكم، وتُحتسب كل الأنواع بنفس الترتيب.
    case sun
    /// حكم: يُختار نوع واحد يصبح الأقوى (الحكم).
    case hokum

    public var arabicName: String {
        switch self {
        case .sun: "صن"
        case .hokum: "حكم"
        }
    }
}
