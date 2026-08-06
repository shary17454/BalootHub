import Foundation

/// تصنيف عنصر الكتالوج. صن وحكم والمشاريع والدبل هي أنماط ضمن لعبة البلوت،
/// بينما كوت بو ستة وطرنيب وتركس وهاند ألعاب ورق مستقلة تمامًا عن البلوت.
enum GameCategory: String, Codable, CaseIterable, Identifiable {
    /// لعبة بلوت أو أحد أنماطها (كلاسيكي، صن، حكم، مشاريع، دبل، تدريب).
    case balootGame
    /// أداة مرتبطة بالبلوت لا تُعتبر "لعبة" بحد ذاتها (تسجيل البلوت، تحدي حساب النقاط).
    case balootTool
    /// لعبة ورق مستقلة عن البلوت (كوت بو ستة، طرنيب، تركس، هاند).
    case otherCardGame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balootGame: "ألعاب البلوت".localized
        case .balootTool: "أدوات البلوت".localized
        case .otherCardGame: "ألعاب ورق أخرى".localized
        }
    }

    var shortBadgeTitle: String {
        switch self {
        case .balootGame: "بلوت".localized
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
