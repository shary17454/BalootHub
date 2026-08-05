import Foundation

/// يدير ترتيب الأدوار بين اللاعبين الأربعة.
public enum TurnManager {
    /// اللاعب التالي دورًا بعد لاعب معيّن، باتجاه عقارب الساعة.
    public static func nextPlayer(after player: Player, in players: [Player]) -> Player? {
        let nextSeat = player.seat.next
        return players.first { $0.seat == nextSeat }
    }

    /// اللاعب الذي يبدأ الأكلة التالية، وهو اللاعب التالي لقائد الأكلة السابقة.
    public static func leaderOfNextTrick(previousLeaderSeat: SeatPosition, players: [Player]) -> Player? {
        players.first { $0.seat == previousLeaderSeat }
    }
}
