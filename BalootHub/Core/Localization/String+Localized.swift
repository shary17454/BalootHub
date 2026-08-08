import Foundation
import BalootEngine

extension String {
    /// يبحث عن ترجمة هذا النص العربي (نص المصدر) داخل كتالوج السلاسل النصية
    /// عند التشغيل، حتى لو أتى النص من متغيّر ديناميكي بدل سلسلة حرفية مباشرة
    /// في Text(...) — وهي الحالة الشائعة لخصائص enum المحسوبة مثل title/subtitle.
    var localized: String {
        String(localized: String.LocalizationValue(self))
    }
}

// MARK: - أسماء الأوراق لقارئ الشاشة

extension Rank {
    /// الاسم المنطوق للقيمة بمصطلح البلوت المتعارف عليه.
    ///
    /// "الشايب" هو الملك (K) و"البنت" هي (Q) و"الولد" هو (J) — وهي التسمية نفسها
    /// التي يقوم عليها مشروع "البلوت" (شايب وبنت الحكم).
    var spokenName: String {
        switch self {
        case .seven: "سبعة".localized
        case .eight: "ثمانية".localized
        case .nine: "تسعة".localized
        case .jack: "ولد".localized
        case .queen: "بنت".localized
        case .king: "شايب".localized
        case .ten: "عشرة".localized
        case .ace: "إكة".localized
        }
    }
}

extension Suit {
    /// الاسم المنطوق للنوع، مترجمًا.
    var spokenName: String {
        switch self {
        case .hearts: "هارت".localized
        case .diamonds: "ديناري".localized
        case .clubs: "كلوب".localized
        case .spades: "سباتي".localized
        }
    }
}

extension PlayingCard {
    /// وصف الورقة لقارئ الشاشة.
    ///
    /// ``displayLabel`` مختصر بصري مثل "A♠"، وVoiceOver ينطقه حرفًا ورمزًا بلا معنى،
    /// فتُبنى هنا صيغة منطوقة مثل "إكة سباتي".
    var accessibilityName: String {
        "\(rank.spokenName) \(suit.spokenName)"
    }
}
