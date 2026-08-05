import Foundation

/// لاعب آلي بسياسة بسيطة وقابلة للاختبار: ليست سياسة احترافية أو تنافسية،
/// وإنما توفر خصمًا محليًا معقولًا للتدرّب دون اتصال بالإنترنت.
///
/// السياسة:
/// - عند المزايدة: يختار "حكم" على النوع الأكثر تكرارًا في يده إن ملك 5 أوراق أو أكثر منه،
///   وإلا يختار "صن".
/// - عند اللعب: إن استطاع الفوز بالأكلة الحالية بأقوى أوراقه القانونية يلعبها،
///   وإلا يتخلص من أضعف ورقة قانونية لديه.
public struct SimpleBalootAgent: BalootAgent, Sendable {
    public init() {}

    public func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?) {
        let countsBySuit = Dictionary(grouping: hand, by: \.suit).mapValues(\.count)
        if let (suit, count) = countsBySuit.max(by: { $0.value < $1.value }), count >= 5 {
            return (.hokum, suit)
        }
        return (.sun, nil)
    }

    public func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard {
        guard let fallback = legalCards.first else {
            // لا يجب أن يحدث هذا: المستدعي مسؤول عن ضمان توفر أوراق قانونية.
            return hand[0]
        }

        guard let mode = state.mode else { return fallback }
        let trumpSuit = state.trumpSuit
        let trick = state.currentTrick

        guard let trick, !trick.playedCards.isEmpty else {
            // اللاعب هو قائد الأكلة: يلعب أضعف ورقة للحفاظ على أوراقه القوية.
            return weakestCard(in: legalCards, mode: mode, trumpSuit: trumpSuit)
        }

        let currentBestStrength = trick.playedCards
            .map { effectiveStrength(of: $0.card, mode: mode, trumpSuit: trumpSuit) }
            .max() ?? -1

        let winningCards = legalCards.filter {
            effectiveStrength(of: $0, mode: mode, trumpSuit: trumpSuit) > currentBestStrength
        }

        if let bestWinningCard = winningCards.min(by: {
            effectiveStrength(of: $0, mode: mode, trumpSuit: trumpSuit) < effectiveStrength(of: $1, mode: mode, trumpSuit: trumpSuit)
        }) {
            return bestWinningCard
        }

        return weakestCard(in: legalCards, mode: mode, trumpSuit: trumpSuit)
    }

    private func weakestCard(in cards: [PlayingCard], mode: GameMode, trumpSuit: Suit?) -> PlayingCard {
        cards.min { effectiveStrength(of: $0, mode: mode, trumpSuit: trumpSuit) < effectiveStrength(of: $1, mode: mode, trumpSuit: trumpSuit) } ?? cards[0]
    }

    private func effectiveStrength(of card: PlayingCard, mode: GameMode, trumpSuit: Suit?) -> Int {
        let base = card.strength(mode: mode, trumpSuit: trumpSuit)
        let isTrump = mode == .hokum && card.suit == trumpSuit
        return isTrump ? base + 100 : base
    }
}
