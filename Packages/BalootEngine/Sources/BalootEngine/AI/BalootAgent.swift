import Foundation

/// بروتوكول لاعب آلي. يسمح باستبدال سياسة اللعب الآلي مستقبلًا (مثل ربطها بخادم لاحقًا)
/// دون تغيير محرك اللعبة.
public protocol BalootAgent: Sendable {
    /// يختار ورقة للعب من بين الأوراق القانونية المتاحة فقط.
    func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard

    /// يختار نمط الجولة (صن أو حكم) ونوع الحكم إن لزم، عند دور اللاعب الآلي بالمزايدة.
    func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?)
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
}
