import Foundation

/// تصنيف عنصر الكتالوج. صن وحكم والمشاريع والدبل هي أنماط ضمن لعبة البلوت،
/// بينما كوت بو ستة وطرنيب وتركس وهاند ألعاب ورق مستقلة تمامًا عن البلوت.
enum GameCategory: String, Codable, CaseIterable, Identifiable {
    /// مدخل لعب فعلي للبلوت. الصن والحكم لا يظهران هنا كألعاب منفصلة؛ يختارهما اللاعب
    /// داخل مزايدة البلوت نفسها.
    case balootGame
    /// أداة أو مرجع مرتبط بالبلوت لا يُعتبر "لعبة" بحد ذاته.
    case balootTool
    /// لعبة ورق مستقلة عن البلوت (كوت بو ستة، طرنيب، تركس، هاند).
    case otherCardGame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balootGame: "لعبة البلوت".localized
        case .balootTool: "أدوات البلوت".localized
        case .otherCardGame: "ألعاب ورق أخرى".localized
        }
    }

    var shortBadgeTitle: String {
        switch self {
        case .balootGame: "لعبة".localized
        case .balootTool: "أداة".localized
        case .otherCardGame: "ورق".localized
        }
    }

    var iconName: String {
        switch self {
        case .balootGame: "suit.spade.fill"
        case .balootTool: "square.and.pencil"
        case .otherCardGame: "rectangle.stack.fill"
        }
    }
}
