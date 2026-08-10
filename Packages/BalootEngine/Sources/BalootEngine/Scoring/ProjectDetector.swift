import Foundation

/// يكتشف المشاريع الموجودة في يد لاعب، ويحسم المفاضلة بينها بين الفريقين.
///
/// الاكتشاف يجري على **اليد كما وُزّعت أول مرة** (`originalHands`) لا على اليد الحالية،
/// لأن المشروع يُقيَّم بما بيد اللاعب عند بداية الجولة ولا يبطل بلعب أوراقه.
public enum ProjectDetector {
    // MARK: - الاكتشاف

    /// كل المشاريع في يد لاعب واحد، بعد استبعاد الأوراق المستهلَكة في مشروع أقوى.
    ///
    /// الورقة الواحدة لا تُحتسب في أكثر من مشروع متتالٍ: يد فيها 7-8-9-10 هي «خمسين»
    /// واحدة لا «خمسين + سرا». أما مشاريع نفس القيمة (أربعمية/مية) ومشروع البلوت
    /// فمستقلة عن التسلسلات ولا تتزاحم معها.
    public static func detect(
        hand: [PlayingCard],
        player: Player,
        mode: GameMode,
        trumpSuit: Suit?,
        rules: BalootRulesConfiguration
    ) -> [Project] {
        guard rules.projectsEnabled else { return [] }
        var projects: [Project] = []

        if rules.sequenceProjectsEnabled {
            projects.append(contentsOf: sequenceProjects(hand: hand, player: player, rules: rules))
        }
        if rules.sameRankProjectsEnabled {
            projects.append(contentsOf: sameRankProjects(hand: hand, player: player, mode: mode, rules: rules))
        }
        if rules.belotProjectEnabled, mode == .hokum, let trumpSuit {
            if let belot = belotProject(hand: hand, player: player, trumpSuit: trumpSuit, rules: rules) {
                projects.append(belot)
            }
        }
        return projects
    }

    /// المشاريع المتتالية (سرا/خمسين/مية) لكل نوع على حدة.
    private static func sequenceProjects(hand: [PlayingCard], player: Player, rules: BalootRulesConfiguration) -> [Project] {
        var projects: [Project] = []

        for suit in Suit.allCases {
            let ordered = hand
                .filter { $0.suit == suit }
                .sorted { $0.rank.sequenceOrder < $1.rank.sequenceOrder }
            guard ordered.count >= 3 else { continue }

            var run: [PlayingCard] = [ordered[0]]
            for card in ordered.dropFirst() {
                if let previous = run.last, card.rank.sequenceOrder == previous.rank.sequenceOrder + 1 {
                    run.append(card)
                } else {
                    if let project = sequenceProject(run: run, player: player, rules: rules) {
                        projects.append(project)
                    }
                    run = [card]
                }
            }
            if let project = sequenceProject(run: run, player: player, rules: rules) {
                projects.append(project)
            }
        }
        return projects
    }

    /// يحوّل تسلسلًا متصلًا إلى مشروع واحد حسب طوله، أو `nil` إن كان أقصر من ثلاث أوراق.
    ///
    /// تسلسل من ست أوراق فأكثر يبقى «مية» واحدة: لا يوجد مشروع أعلى منها للتسلسلات،
    /// وتقسيمه إلى «مية + سرا» يمنح نقاطًا لا تقرّها القاعدة.
    private static func sequenceProject(run: [PlayingCard], player: Player, rules: BalootRulesConfiguration) -> Project? {
        let kind: Project.Kind
        let points: Int
        switch run.count {
        case 3:
            kind = .sira
            points = rules.siraPoints
        case 4:
            kind = .fifty
            points = rules.fiftyPoints
        case 5...:
            kind = .hundred
            points = rules.hundredPoints
        default:
            return nil
        }
        return Project(kind: kind, teamID: player.teamID, playerID: player.id, cards: run, points: points)
    }

    /// مشاريع «أربع أوراق من نفس القيمة»: أربعمية للآسات، ومية للشايب/البنت/الولد/العشرة.
    ///
    /// السبع والثمان والتسع لا مشروع لها في البلوت المعتمد هنا، خلافًا للبلوت الأوروبي.
    private static func sameRankProjects(hand: [PlayingCard], player: Player, mode: GameMode, rules: BalootRulesConfiguration) -> [Project] {
        var projects: [Project] = []
        let grouped = Dictionary(grouping: hand, by: \.rank)

        for (rank, cards) in grouped where cards.count == 4 {
            switch rank {
            case .ace:
                guard rules.fourHundredEnabled else { continue }
                if rules.fourHundredSunOnly && mode != .sun { continue }
                projects.append(Project(kind: .fourHundred, teamID: player.teamID, playerID: player.id,
                                        cards: cards, points: rules.fourHundredPoints))
            case .king, .queen, .jack, .ten:
                projects.append(Project(kind: .hundredSameRank, teamID: player.teamID, playerID: player.id,
                                        cards: cards, points: rules.hundredPoints))
            case .nine, .eight, .seven:
                continue
            }
        }
        // ترتيب ثابت لا يعتمد على ترتيب القاموس (غير مضمون في Swift) حتى تبقى
        // النتيجة نفسها في كل تشغيل — شرط أساسي لصحة الـReplay.
        return projects.sorted { $0.id < $1.id }
    }

    /// مشروع البلوت: شايب (K) وبنت (Q) من نوع الحكم في يد لاعب واحد.
    private static func belotProject(hand: [PlayingCard], player: Player, trumpSuit: Suit, rules: BalootRulesConfiguration) -> Project? {
        guard let king = hand.first(where: { $0.suit == trumpSuit && $0.rank == .king }),
              let queen = hand.first(where: { $0.suit == trumpSuit && $0.rank == .queen })
        else { return nil }
        return Project(kind: .belot, teamID: player.teamID, playerID: player.id,
                       cards: [queen, king], points: rules.belotPoints)
    }

    // MARK: - المفاضلة بين الفريقين

    /// نتيجة حسم المشاريع: ما يُحتسب فعلًا لكل فريق، ومن فاز بالمفاضلة.
    public struct Resolution: Sendable, Equatable {
        /// المشاريع المحتسَبة فعلًا بعد المفاضلة.
        public var awarded: [Project]
        /// المشاريع التي أُلغيت لأن الخصم ملك مشروعًا أقوى.
        public var overruled: [Project]
        /// الفريق الذي كسب المفاضلة، أو `nil` إن لم تكن هناك منافسة أصلًا.
        public var winningTeamID: Team.ID?

        public init(awarded: [Project] = [], overruled: [Project] = [], winningTeamID: Team.ID? = nil) {
            self.awarded = awarded
            self.overruled = overruled
            self.winningTeamID = winningTeamID
        }

        /// مجموع نقاط المشاريع المحتسَبة لكل فريق.
        public func points(for teamID: Team.ID) -> Int {
            awarded.filter { $0.teamID == teamID }.reduce(0) { $0 + $1.points }
        }
    }

    /// يحسم تعارض المشاريع بين الفريقين وفق القاعدة المعتمدة: **الفريق صاحب أقوى مشروع
    /// يأخذ كل مشاريعه، والفريق الآخر لا يأخذ شيئًا** — عدا «البلوت» فيُحتسب دائمًا لصاحبه.
    ///
    /// عند تساوي أقوى مشروعين تمامًا (نفس النوع ونفس النقاط ونفس أعلى ورقة، وهو ممكن
    /// بين نوعين مختلفين) تُلغى مشاريع الفريقين معًا، وهي القاعدة المتعارف عليها في
    /// حالة التعادل بدل ترجيح أحدهما.
    public static func resolve(projects: [Project], teams: [Team]) -> Resolution {
        let exempt = projects.filter(\.isExemptFromComparison)
        let contested = projects.filter { !$0.isExemptFromComparison }

        guard !contested.isEmpty else {
            return Resolution(awarded: exempt, overruled: [], winningTeamID: nil)
        }

        // أقوى مشروع لكل فريق. المرور على `teams` بترتيبها الثابت لا على القاموس،
        // حتى لا تتغيّر النتيجة بين تشغيل وآخر عند التساوي.
        var best: [(teamID: Team.ID, project: Project)] = []
        for team in teams {
            let teamProjects = contested.filter { $0.teamID == team.id }
            guard let strongest = teamProjects.max(by: { $1.isStronger(than: $0) }) else { continue }
            best.append((team.id, strongest))
        }

        guard best.count > 1 else {
            // فريق واحد فقط لديه مشاريع: لا منافسة.
            return Resolution(awarded: exempt + contested, overruled: [], winningTeamID: best.first?.teamID)
        }

        let sorted = best.sorted { $0.project.isStronger(than: $1.project) }
        let top = sorted[0]
        let runnerUp = sorted[1]

        if top.project.comparisonKey == runnerUp.project.comparisonKey {
            // تعادل تام: تسقط مشاريع الطرفين ويبقى البلوت وحده.
            return Resolution(awarded: exempt, overruled: contested, winningTeamID: nil)
        }

        let winners = contested.filter { $0.teamID == top.teamID }
        let losers = contested.filter { $0.teamID != top.teamID }
        return Resolution(awarded: exempt + winners, overruled: losers, winningTeamID: top.teamID)
    }
}
