import Foundation

/// مشروع (إعلان) في يد لاعب.
///
/// المعرّف ``id`` مشتق من محتوى المشروع لا من `UUID` عشوائي: حالة اللعبة تُعاد
/// بناؤها بالكامل من سجل الأفعال في الـReplay، ومعرّف عشوائي كان يجعل الحالة
/// المُعاد بناؤها مختلفة عن الأصلية رغم تطابق كل ما يهم فعلًا.
public struct Project: Identifiable, Codable, Sendable, Hashable, Equatable {
    /// نوع المشروع. الترتيب هنا هو ترتيب الأولوية عند المقارنة بين الفريقين.
    public enum Kind: String, Codable, Sendable, CaseIterable, Comparable {
        /// «سرا» — ثلاث أوراق متتالية من نوع واحد.
        case sira
        /// «خمسين» — أربع أوراق متتالية من نوع واحد.
        case fifty
        /// «مية» — خمس أوراق متتالية فأكثر من نوع واحد.
        case hundred
        /// «مية» — أربع أوراق من نفس القيمة (شايب/بنت/ولد/عشرة).
        case hundredSameRank
        /// «أربعمية» — أربعة آسات.
        case fourHundred
        /// «البلوت» — شايب وبنت الحكم في يد واحدة (حكم فقط).
        case belot

        /// ترتيب الأولوية الأساسي عند المفاضلة بين مشاريع الفريقين.
        public var priorityOrder: Int {
            switch self {
            case .sira: 0
            case .fifty: 1
            case .hundred: 2
            case .hundredSameRank: 3
            case .fourHundred: 4
            // البلوت خارج المفاضلة أصلًا (يُحتسب دائمًا)، ويأخذ أدنى ترتيب احتياطًا.
            case .belot: -1
            }
        }

        public var arabicName: String {
            switch self {
            case .sira: "سرا"
            case .fifty: "خمسين"
            case .hundred: "مية"
            case .hundredSameRank: "مية"
            case .fourHundred: "أربعمية"
            case .belot: "بلوت"
            }
        }

        public static func < (lhs: Kind, rhs: Kind) -> Bool {
            lhs.priorityOrder < rhs.priorityOrder
        }
    }

    public let kind: Kind
    public let teamID: Team.ID
    public let playerID: Player.ID
    /// الأوراق المكوِّنة للمشروع، مرتبة تصاعديًا حسب ``Rank/sequenceOrder``.
    public let cards: [PlayingCard]
    public let points: Int

    public init(kind: Kind, teamID: Team.ID, playerID: Player.ID, cards: [PlayingCard], points: Int) {
        self.kind = kind
        self.teamID = teamID
        self.playerID = playerID
        self.cards = cards.sorted { $0.rank.sequenceOrder < $1.rank.sequenceOrder }
        self.points = points
    }

    public var id: String {
        let cardKey = cards.map { "\($0.suit.rawValue)\($0.rank.rawValue)" }.joined(separator: "_")
        return "\(playerID.uuidString)|\(kind.rawValue)|\(cardKey)"
    }

    /// أعلى ورقة في المشروع حسب الترتيب الطبيعي (7…A)، وتُستخدم لفض التعادل.
    public var topCard: PlayingCard? { cards.last }

    /// هل يُحتسب هذا المشروع دائمًا بغض النظر عن مشاريع الخصم؟
    ///
    /// «البلوت» وحده كذلك: هو ملك الحكم لا منافسة عليه، بينما بقية المشاريع تدخل
    /// في المفاضلة ويأخذها الفريق صاحب أقوى مشروع وحده.
    public var isExemptFromComparison: Bool { kind == .belot }

    /// مفتاح مقارنة مركّب لفض التعادل: النقاط، ثم طول المشروع، ثم أعلى ورقة.
    public var comparisonKey: (Int, Int, Int, Int) {
        (points, kind.priorityOrder, cards.count, topCard?.rank.sequenceOrder ?? 0)
    }

    /// هل هذا المشروع أقوى من الآخر في المفاضلة بين الفريقين؟
    public func isStronger(than other: Project) -> Bool {
        comparisonKey > other.comparisonKey
    }
}
