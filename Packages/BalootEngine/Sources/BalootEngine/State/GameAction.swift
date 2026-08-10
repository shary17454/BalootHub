import Foundation

/// كل الأفعال الممكنة التي تُغيّر حالة اللعبة. تُسجَّل بالكامل في `GameState.actionHistory`
/// لتمكين إعادة تشغيل الجولة من سجل الأفعال.
///
/// > كل ميزة تُغيّر مجرى الجولة يجب أن تمر من هنا. أي تعديل على الحالة خارج هذا النوع
/// > يكسر الـReplay بصمت: الحالة المُعاد بناؤها لن تطابق الأصلية ولن يُنبّه أحد.
public enum GameAction: Codable, Sendable, Equatable {
    /// توزيع الأوراق ببذرة محددة (حتمي).
    case dealCards(seed: UInt64)

    /// اختيار مباشر للنمط بلا دورة مزايدة — متاح فقط في ``BiddingStyle/simple``.
    case chooseMode(playerID: Player.ID, mode: GameMode, trumpSuit: Suit?)

    /// مزايدة واحدة ضمن دورة المزايدة الكاملة: بس، صن، أو حكم بلون.
    case placeBid(playerID: Player.ID, bid: Bid)

    /// طلب مضاعفة أو تصعيدها (دبل ← ثري ← فور ← قهوة).
    case raiseMultiplier(playerID: Player.ID, level: Multiplier)

    /// تمرير الدور في جولة المضاعفة.
    case passMultiplier(playerID: Player.ID)

    /// «قفل» المضاعفة: إنهاء التصعيد عند المستوى الحالي.
    case lockMultiplier(playerID: Player.ID)

    /// إعلان مشاريع اللاعب. مصفوفة فارغة تعني «لا مشروع» وهي فعل مسجَّل أيضًا،
    /// لأن مرور الدور بلا إعلان جزء من مجرى الجولة ويجب أن يُعاد في الـReplay.
    case declareProjects(playerID: Player.ID, projects: [Project])

    /// لعب ورقة.
    case playCard(playerID: Player.ID, card: PlayingCard)

    /// إنهاء الجولة واحتساب نتيجتها.
    case finishRound
}
