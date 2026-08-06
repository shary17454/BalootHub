import Foundation

/// مستوى صعوبة اللعبة.
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "سهل".localized
        case .intermediate: "متوسط".localized
        case .advanced: "صعب".localized
        }
    }

    /// عدد النجوم المعروضة، مع نص بديل حتى لا يُعتمد على اللون وحده لتمييز المستوى.
    var starCount: Int {
        switch self {
        case .beginner: 1
        case .intermediate: 2
        case .advanced: 3
        }
    }
}
