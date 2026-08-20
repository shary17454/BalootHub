import Foundation

/// مزايدة واحدة يقدّمها لاعب في دوره ضمن دورة المزايدة.
///
/// البلوت يزايد على ثلاثة خيارات فقط لا رابع لها: **بس** (تمرير)، **صن**، أو **حكم**
/// بلون محدد. لا يوجد في البلوت مزايدة بعدد نقاط كما في بعض ألعاب الورق الأخرى،
/// فالمزايدة هنا تصنيفية لا عددية.
public enum Bid: Codable, Sendable, Equatable, Hashable {
    /// «بس» — تمرير الدور دون شراء.
    case pass
    /// شراء صن.
    case sun
    /// شراء حكم على لون محدد.
    case hokum(suit: Suit)

    /// هل هذه المزايدة شراء فعلي (لا تمرير)؟
    public var isBid: Bool {
        switch self {
        case .pass: false
        case .sun, .hokum: true
        }
    }

    /// النمط الناتج عن هذه المزايدة، أو `nil` عند التمرير.
    public var mode: GameMode? {
        switch self {
        case .pass: nil
        case .sun: .sun
        case .hokum: .hokum
        }
    }

    /// لون الحكم المطلوب، أو `nil` لغير الحكم.
    public var trumpSuit: Suit? {
        switch self {
        case .hokum(let suit): suit
        case .pass, .sun: nil
        }
    }
}

/// سجل مزايدة واحدة: من زايد، وبماذا، وفي أي جولة مزايدة.
///
/// يُحفظ داخل ``BiddingState`` كاملًا حتى يستطيع التحليل بعد المباراة وشاشة الـReplay
/// عرض دورة المزايدة كما جرت فعلًا، لا نتيجتها النهائية فقط.
public struct BidRecord: Codable, Sendable, Equatable, Hashable {
    public let playerID: Player.ID
    public let bid: Bid
    /// رقم جولة المزايدة: 1 للجولة الأولى (على الورقة المكشوفة)، 2 لجولة الأشكال.
    public let round: Int

    public init(playerID: Player.ID, bid: Bid, round: Int) {
        self.playerID = playerID
        self.bid = bid
        self.round = round
    }
}
