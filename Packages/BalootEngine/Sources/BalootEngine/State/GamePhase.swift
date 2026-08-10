import Foundation

/// المرحلة الحالية لجولة البلوت.
public enum GamePhase: String, Codable, Sendable, Equatable {
    case setup
    case dealing
    /// دورة المزايدة (بما فيها جولة المضاعفة).
    case bidding
    /// إعلان المشاريع قبل أول ورقة. مرحلة مستقلة لأن توقيت الإعلان في البلوت
    /// **قبل بداية اللعب**، ودمجها في مرحلة اللعب كان يسمح بإعلان متأخر غير قانوني.
    case declaring
    case playing
    case scoring
    case finished
}
