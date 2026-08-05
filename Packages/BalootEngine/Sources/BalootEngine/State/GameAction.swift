import Foundation

/// كل الأفعال الممكنة التي تُغيّر حالة اللعبة. تُسجَّل بالكامل في `GameState.actionHistory`
/// لتمكين إعادة تشغيل الجولة من سجل الأفعال.
public enum GameAction: Codable, Sendable, Equatable {
    case dealCards(seed: UInt64)
    case chooseMode(playerID: Player.ID, mode: GameMode, trumpSuit: Suit?)
    case playCard(playerID: Player.ID, card: PlayingCard)
    case finishRound
}
