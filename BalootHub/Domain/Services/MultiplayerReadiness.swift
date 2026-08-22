import Foundation
import BalootEngine

// MARK: - طبقة النقل

/// قناة نقل أفعال جولة بلوت بين المشاركين.
///
/// الغرض منها **تهيئة البنية** لا تشغيل لعب أونلاين الآن: كل ما تحتاجه أي طبقة
/// شبكة مستقبلية (Game Center أو خادم غرف) هو تنفيذ هذا البروتوكول، لأن الجولة
/// كلها معرَّفة أصلًا بسجل ``GameAction`` القابل لإعادة التشغيل حرفيًا.
///
/// > لا يوجد أي اتصال شبكة في هذا الإصدار، ولا صلاحية شبكة مطلوبة.
protocol MatchTransport: AnyObject {
    /// معرّف المشارك المحلي.
    var localParticipantID: UUID { get }
    /// هل القناة جاهزة لاستقبال الأفعال؟
    var isReady: Bool { get }
    /// يرسل فعلًا للمشاركين الآخرين.
    func send(_ action: GameAction) throws
    /// الأفعال الواردة بالترتيب منذ آخر قراءة.
    func drainIncoming() -> [GameAction]
}

/// قناة نقل محلية تُرجع ما أُرسل إليها.
///
/// تُستخدم في الاختبارات وفي وضع المجلس (كل اللاعبين على نفس الجهاز)، فتثبت أن
/// مسار "فعل ← نقل ← تطبيق" يعمل من طرف لطرف بلا شبكة، وتبقى نقطة الاستبدال
/// الوحيدة عند إضافة Game Center لاحقًا.
final class LocalLoopbackTransport: MatchTransport {
    let localParticipantID: UUID
    private(set) var isReady = true
    private var queue: [GameAction] = []

    init(localParticipantID: UUID = UUID()) {
        self.localParticipantID = localParticipantID
    }

    func send(_ action: GameAction) throws {
        guard isReady else { throw MatchTransportError.notReady }
        queue.append(action)
    }

    func drainIncoming() -> [GameAction] {
        defer { queue.removeAll() }
        return queue
    }

    func setReady(_ ready: Bool) {
        isReady = ready
    }
}

enum MatchTransportError: Error, Equatable {
    case notReady
}

// MARK: - وضع المتفرّج

/// لقطة حالة صالحة للعرض على متفرّج أو على لاعب لا يملك حق رؤية كل الأيدي.
///
/// الحجب يتم **بحذف الأوراق فعليًا** لا بإخفائها في الواجهة، لأن إخفاءها بصريًا
/// فقط يعني أن الحالة الكاملة ما تزال موجودة في الجهاز/القناة ويمكن استخراجها.
struct SpectatorSnapshot: Equatable {
    /// الحالة بعد الحجب.
    let state: GameState
    /// عدد الأوراق المتبقية بيد كل لاعب — معلومة عامة أصلًا على الطاولة.
    let handCounts: [Player.ID: Int]
    /// اللاعب الذي يُسمح له برؤية يده، إن وُجد.
    let revealedPlayerID: Player.ID?

    static func == (lhs: SpectatorSnapshot, rhs: SpectatorSnapshot) -> Bool {
        lhs.handCounts == rhs.handCounts
            && lhs.revealedPlayerID == rhs.revealedPlayerID
            && lhs.state.phase == rhs.state.phase
            && lhs.state.actionHistory == rhs.state.actionHistory
    }
}

/// يبني لقطات المتفرّج من حالة الجولة.
enum SpectatorFeed {
    /// يحجب كل الأيدي إلا يد ``revealedPlayerID`` إن مُرِّرت.
    ///
    /// - Parameter revealedPlayerID: اللاعب صاحب الدور على هذا الجهاز، أو `nil`
    ///   لمتفرّج لا يرى أي يد.
    static func snapshot(of state: GameState, revealing revealedPlayerID: Player.ID? = nil) -> SpectatorSnapshot {
        let counts = state.hands.mapValues(\.count)
        var redacted = state
        redacted.hands = state.hands.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.key == revealedPlayerID ? entry.value : []
        }
        // الأيدي الأصلية تكشف التوزيع كاملًا، فتُحجب دائمًا عن المتفرّج.
        redacted.originalHands = redacted.originalHands.mapValues { _ in [] }
        redacted.undealtCards = []
        return SpectatorSnapshot(state: redacted, handCounts: counts, revealedPlayerID: revealedPlayerID)
    }

    /// هل اللقطة خالية فعلًا من أي ورقة لا يحق لصاحبها رؤيتها؟
    ///
    /// تُستخدم في الاختبارات كحارس ضد تسريب مستقبلي عند إضافة حقل جديد للحالة.
    static func isFullyRedacted(_ snapshot: SpectatorSnapshot) -> Bool {
        let leakedHands = snapshot.state.hands.contains { playerID, cards in
            playerID != snapshot.revealedPlayerID && !cards.isEmpty
        }
        let leakedOriginals = snapshot.state.originalHands.contains { !$0.value.isEmpty }
        return !leakedHands && !leakedOriginals && snapshot.state.undealtCards.isEmpty
    }
}

// MARK: - قائمة الجاهزية

/// بند واحد في قائمة جاهزية اللعب الجماعي.
struct MultiplayerReadinessItem: Identifiable, Equatable {
    enum Status: Equatable {
        /// منجز فعلًا في هذا الإصدار.
        case ready
        /// يحتاج عملًا لاحقًا قبل تفعيل الميزة.
        case pending

        var title: String {
            switch self {
            case .ready: "جاهز".localized
            case .pending: "يحتاج عملًا".localized
            }
        }
    }

    let id: String
    let title: String
    let detail: String
    let status: Status
}

/// حالة التطبيق الفعلية تجاه اللعب الجماعي عن بُعد.
///
/// القائمة **وصفية لا تنفيذية**: توثّق ما هو جاهز في البنية وما يبقى مطلوبًا قبل
/// تفعيل Game Center أو أي خادم غرف، حتى لا يُقدَّر العمل بالتخمين لاحقًا.
enum MultiplayerReadiness {
    static var items: [MultiplayerReadinessItem] {
        [
            MultiplayerReadinessItem(
                id: "deterministic-actions",
                title: "جولة قابلة لإعادة البناء من الأفعال".localized,
                detail: "كل ما يغيّر الجولة يمر عبر GameAction ويُسجَّل، فتُعاد الحالة من السجل بلا فرق.".localized,
                status: .ready
            ),
            MultiplayerReadinessItem(
                id: "seeded-deal",
                title: "توزيع حتمي ببذرة".localized,
                detail: "نفس البذرة تعطي نفس التوزيع على أي جهاز، وهو شرط مزامنة أي جولة مشتركة.".localized,
                status: .ready
            ),
            MultiplayerReadinessItem(
                id: "transport-protocol",
                title: "طبقة نقل مجرّدة".localized,
                detail: "MatchTransport يفصل المحرك عن وسيلة النقل، وتنفيذه المحلي يعمل اليوم بلا شبكة.".localized,
                status: .ready
            ),
            MultiplayerReadinessItem(
                id: "spectator-redaction",
                title: "حجب الأيدي لوضع المتفرّج".localized,
                detail: "الحجب بحذف الأوراق من اللقطة لا بإخفائها بصريًا، فلا تُسرَّب عبر أي قناة.".localized,
                status: .ready
            ),
            MultiplayerReadinessItem(
                id: "game-center-auth",
                title: "مصادقة Game Center".localized,
                detail: "تحتاج تفعيل القدرة في المشروع وربط التطبيق في App Store Connect.".localized,
                status: .pending
            ),
            MultiplayerReadinessItem(
                id: "matchmaking",
                title: "المطابقة والغرف".localized,
                detail: "تحتاج خادم غرف أو GKMatchmaker، مع اختبارات انقطاع وإعادة اتصال.".localized,
                status: .pending
            ),
            MultiplayerReadinessItem(
                id: "privacy-policy",
                title: "سياسة خصوصية محدّثة".localized,
                detail: "أي اتصال شبكة أو أسماء لاعبين عن بُعد يغيّر إفصاح الخصوصية الحالي.".localized,
                status: .pending
            )
        ]
    }

    static var readyCount: Int { items.filter { $0.status == .ready }.count }
}
