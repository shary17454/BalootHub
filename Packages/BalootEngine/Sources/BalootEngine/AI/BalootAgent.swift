import Foundation

/// قرار اللاعب الآلي في جولة المضاعفة.
public enum MultiplierDecision: Sendable, Equatable {
    case pass
    case raise(Multiplier)
    case lock
}

/// بروتوكول لاعب آلي. يسمح باستبدال سياسة اللعب الآلي مستقبلًا (مثل ربطها بخادم لاحقًا)
/// دون تغيير محرك اللعبة.
public protocol BalootAgent: Sendable {
    /// يختار ورقة للعب من بين الأوراق القانونية المتاحة فقط.
    func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard

    /// يختار نمط الجولة (صن أو حكم) ونوع الحكم إن لزم، في النمط المبسّط.
    func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?)

    /// يختار مزايدة من بين المزايدات القانونية في دورة المزايدة الكاملة.
    func chooseBid(hand: [PlayingCard], legalBids: [Bid], state: GameState) -> Bid

    /// يقرر المضاعفة أو التمرير أو القفل في جولة المضاعفة.
    func chooseMultiplierAction(hand: [PlayingCard], state: GameState) -> MultiplierDecision

    /// يختار أي المشاريع المكتشفة يُعلنها.
    func chooseProjectsToDeclare(available: [Project], state: GameState) -> [Project]
}

extension BalootAgent {
    /// مخرج آمن عند خرق عقد ``chooseCard(hand:legalCards:state:)``، أي استدعاء الوكيل
    /// بلا أوراق قانونية ولا أوراق في اليد أصلًا.
    ///
    /// القراءة المباشرة لـ`hand[0]` كانت تعني انهيار التطبيق (فهرس خارج المدى) عند أي
    /// خطأ في المستدعي. الورقة المُعادة هنا خارج يد اللاعب، فيرفضها ``LegalMoveValidator``
    /// كحركة غير قانونية ويتحول العطل إلى خطأ معالَج تعرضه الواجهة، بدل إسقاط التطبيق.
    /// و`assertionFailure` تكشف الخلل فورًا في نسخ التطوير.
    static func fallbackCard(hand: [PlayingCard], function: StaticString = #function) -> PlayingCard {
        assertionFailure("استُدعي \(function) بلا أوراق قانونية — خرق لعقد BalootAgent")
        return hand.first ?? PlayingCard(suit: .spades, rank: .seven)
    }

    // MARK: - تطبيقات افتراضية

    /// مزايدة افتراضية محافظة مبنية على ``HandEvaluator``.
    ///
    /// موجودة كتطبيق افتراضي حتى لا يُجبَر أي وكيل قائم أو مستقبلي على تنفيذ دورة
    /// المزايدة كاملة ليصبح صالحًا للاستخدام.
    public func chooseBid(hand: [PlayingCard], legalBids: [Bid], state: GameState) -> Bid {
        BiddingPolicy.standard.chooseBid(hand: hand, legalBids: legalBids, state: state)
    }

    /// الافتراضي: لا مضاعفة. المضاعفة قرار عالي المخاطرة، فجعلها سلوكًا افتراضيًا
    /// لكل وكيل كان سيجعل كل الخصوم يضاعفون بلا سبب.
    public func chooseMultiplierAction(hand: [PlayingCard], state: GameState) -> MultiplierDecision {
        .pass
    }

    /// الافتراضي: إعلان كل المشاريع. إخفاء المشروع تكتيك متقدم لا سلوك أساسي.
    public func chooseProjectsToDeclare(available: [Project], state: GameState) -> [Project] {
        available
    }
}
