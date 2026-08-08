import Foundation

/// يدير ترتيب الأدوار بين اللاعبين الأربعة.
public enum TurnManager {
    /// اللاعب التالي دورًا بعد لاعب معيّن، باتجاه عقارب الساعة.
    public static func nextPlayer(after player: Player, in players: [Player]) -> Player? {
        let nextSeat = player.seat.next
        return players.first { $0.seat == nextSeat }
    }

    /// اللاعب الجالس في موقع معيّن.
    ///
    /// كان اسم هذه الدالة `leaderOfNextTrick` وتوثيقها يَعِد بـ"اللاعب التالي لقائد الأكلة
    /// السابقة"، بينما جسدها يُعيد اللاعب الجالس في الموقع المُمرَّر نفسه. قائد الأكلة
    /// التالية في البلوت هو **الفائز** بالأكلة السابقة، ويحدده ``GameEngine`` مباشرة،
    /// فصار الاسم يصف ما تفعله الدالة فعلًا بدل وعد لا تفي به.
    public static func player(at seat: SeatPosition, in players: [Player]) -> Player? {
        players.first { $0.seat == seat }
    }
}
