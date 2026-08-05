import Foundation

/// بروتوكول لاعب آلي. يسمح باستبدال سياسة اللعب الآلي مستقبلًا (مثل ربطها بخادم لاحقًا)
/// دون تغيير محرك اللعبة.
public protocol BalootAgent: Sendable {
    /// يختار ورقة للعب من بين الأوراق القانونية المتاحة فقط.
    func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard

    /// يختار نمط الجولة (صن أو حكم) ونوع الحكم إن لزم، عند دور اللاعب الآلي بالمزايدة.
    func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?)
}
