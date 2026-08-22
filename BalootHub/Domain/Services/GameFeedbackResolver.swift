import Foundation
import BalootEngine

/// إشارة ردّ فعل واحدة ناتجة عن فعل داخل الجولة: صوت واهتزاز، وربما مؤثر بصري.
struct GameFeedbackSignal: Identifiable, Equatable {
    /// معرّف يتغيّر مع كل إشارة حتى لو تكرر نفس الحدث، فتتمكن الواجهة من إعادة
    /// تشغيل المؤثر بدل ابتلاع الحدث الثاني لتطابقه مع الأول.
    let id: UUID
    let event: FeedbackEvent
    let celebration: CelebrationKind?

    init(id: UUID = UUID(), event: FeedbackEvent, celebration: CelebrationKind? = nil) {
        self.id = id
        self.event = event
        self.celebration = celebration
    }

    static func == (lhs: GameFeedbackSignal, rhs: GameFeedbackSignal) -> Bool {
        lhs.id == rhs.id
    }
}

/// يحوّل فعلًا داخل الجولة إلى ردّ الفعل المناسب له.
///
/// منطق خالص خارج الواجهة وخارج ``BalootGameViewModel``: يأخذ الحالة قبل الفعل
/// وبعده ويقرر ما الذي يستحق صوتًا أو مؤثرًا. هكذا يمكن اختبار "متى يظهر مؤثر
/// الكبوت" بلا تشغيل واجهة ولا محاكي.
enum GameFeedbackResolver {
    static func signal(
        for action: GameAction,
        before: GameState,
        after: GameState,
        humanTeamID: Team.ID?
    ) -> GameFeedbackSignal? {
        switch action {
        case .dealCards:
            return nil

        case .chooseMode, .placeBid:
            return GameFeedbackSignal(event: .bidPlaced)

        case .raiseMultiplier, .lockMultiplier:
            return GameFeedbackSignal(event: .multiplierRaised)

        case .passMultiplier:
            // تمرير المضاعفة حدث صامت عمدًا: يتكرر أربع مرات في الجولة الواحدة،
            // وإصدار صوت له يحوّل المضاعفة إلى ضجيج بلا معلومة.
            return nil

        case .declareProjects(_, let projects):
            guard let strongest = projects.max(by: { $0.comparisonKey < $1.comparisonKey }) else {
                return nil
            }
            let total = projects.reduce(0) { $0 + $1.points }
            return GameFeedbackSignal(
                event: .projectDeclared,
                celebration: .project(title: strongest.kind.arabicName, points: total)
            )

        case .playCard:
            guard after.completedTricks.count > before.completedTricks.count else {
                return GameFeedbackSignal(event: .cardPlayed)
            }
            let winnerTeamID = after.completedTricks.last?.winnerPlayerID
                .flatMap { id in after.players.first { $0.id == id }?.teamID }
            let isHumanTeam = humanTeamID != nil && winnerTeamID == humanTeamID
            return GameFeedbackSignal(event: isHumanTeam ? .trickWon : .trickLost)

        case .finishRound:
            if let kabootTeamID = after.kabootTeamID {
                let name = after.teams.first { $0.id == kabootTeamID }?.name ?? "الفريق".localized
                return GameFeedbackSignal(event: .kaboot, celebration: .kaboot(teamName: name))
            }
            return GameFeedbackSignal(event: .roundFinished)
        }
    }
}
