import Foundation
import Testing
@testable import BalootEngine

// MARK: - أدوات

private func card(_ suit: Suit, _ rank: Rank) -> PlayingCard { PlayingCard(suit: suit, rank: rank) }

private struct TestTable {
    let teamA = Team(name: "أ")
    let teamB = Team(name: "ب")
    let south: Player
    let west: Player
    let north: Player
    let east: Player

    init() {
        south = Player(name: "جنوب", kind: .human, seat: .south, teamID: teamA.id)
        west = Player(name: "غرب", kind: .ai, seat: .west, teamID: teamB.id)
        north = Player(name: "شمال", kind: .ai, seat: .north, teamID: teamA.id)
        east = Player(name: "شرق", kind: .ai, seat: .east, teamID: teamB.id)
    }

    var players: [Player] { [south, west, north, east] }
    var teams: [Team] { [teamA, teamB] }
}

// MARK: - اكتشاف المشاريع

@Suite("اكتشاف المشاريع")
struct ProjectDetectionTests {
    private let table = TestTable()

    @Test("ثلاث أوراق متتالية من نوع واحد = سرا بعشرين نقطة")
    func threeInSequenceIsSira() {
        let hand = [card(.hearts, .seven), card(.hearts, .eight), card(.hearts, .nine),
                    card(.spades, .ace), card(.clubs, .ten)]
        let projects = ProjectDetector.detect(hand: hand, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)

        #expect(projects.count == 1)
        #expect(projects.first?.kind == .sira)
        #expect(projects.first?.points == 20)
    }

    @Test("التسلسل الطبيعي يضع العشرة بين التسعة والشايب")
    func sequenceUsesNaturalOrderNotPlayStrength() {
        // 9-10-J تسلسل طبيعي صحيح، رغم أن العشرة أقوى من الشايب في اللعب.
        let hand = [card(.clubs, .nine), card(.clubs, .ten), card(.clubs, .jack)]
        let projects = ProjectDetector.detect(hand: hand, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)

        #expect(projects.count == 1)
        #expect(projects.first?.kind == .sira)
    }

    @Test("أربع متتالية = خمسين، وخمس = مية، ولا تُقسَّم إلى مشاريع أصغر")
    func longerSequencesDoNotSplit() {
        let four = [card(.spades, .eight), card(.spades, .nine), card(.spades, .ten), card(.spades, .jack)]
        let fourProjects = ProjectDetector.detect(hand: four, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(fourProjects.count == 1)
        #expect(fourProjects.first?.kind == .fifty)
        #expect(fourProjects.first?.points == 50)

        let five = four + [card(.spades, .queen)]
        let fiveProjects = ProjectDetector.detect(hand: five, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(fiveProjects.count == 1)
        #expect(fiveProjects.first?.kind == .hundred)
        #expect(fiveProjects.first?.points == 100)
    }

    @Test("تسلسلان منفصلان في نوعين يُحتسبان معًا")
    func twoSeparateSequencesBothCount() {
        let hand = [card(.hearts, .seven), card(.hearts, .eight), card(.hearts, .nine),
                    card(.clubs, .queen), card(.clubs, .king), card(.clubs, .ace)]
        let projects = ProjectDetector.detect(hand: hand, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(projects.count == 2)
        let allSira = projects.allSatisfy { $0.kind == .sira }
        #expect(allSira)
    }

    @Test("أربعة آسات = أربعمية")
    func fourAcesIsFourHundred() {
        let hand = Suit.allCases.map { card($0, .ace) }
        let projects = ProjectDetector.detect(hand: hand, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)

        #expect(projects.contains { $0.kind == .fourHundred && $0.points == 400 })
    }

    @Test("معرّف مشروع نفس القيمة حتمي ولا يتأثر بترتيب اليد")
    func sameRankProjectIDIsStableAcrossHandOrder() throws {
        let ordered = Suit.allCases.map { card($0, .ace) }
        let shuffled = [card(.spades, .ace), card(.clubs, .ace), card(.hearts, .ace), card(.diamonds, .ace)]

        let first = try #require(ProjectDetector.detect(
            hand: ordered,
            player: table.south,
            mode: .sun,
            trumpSuit: nil,
            rules: .standard
        ).first { $0.kind == .fourHundred })
        let second = try #require(ProjectDetector.detect(
            hand: shuffled,
            player: table.south,
            mode: .sun,
            trumpSuit: nil,
            rules: .standard
        ).first { $0.kind == .fourHundred })

        #expect(first.cards == second.cards)
        #expect(first.id == second.id)
    }

    @Test("أربعة شياب = مية، وأربع تسعات لا مشروع لها")
    func fourOfAKindRules() {
        let kings = Suit.allCases.map { card($0, .king) }
        let kingProjects = ProjectDetector.detect(hand: kings, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(kingProjects.contains { $0.kind == .hundredSameRank && $0.points == 100 })

        let nines = Suit.allCases.map { card($0, .nine) }
        let nineProjects = ProjectDetector.detect(hand: nines, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(nineProjects.isEmpty)
    }

    @Test("البلوت يُكتشف في الحكم فقط ولنوع الحكم تحديدًا")
    func belotOnlyInHokumTrumpSuit() {
        let hand = [card(.spades, .king), card(.spades, .queen), card(.hearts, .seven)]

        let inHokum = ProjectDetector.detect(hand: hand, player: table.south, mode: .hokum, trumpSuit: .spades, rules: .standard)
        #expect(inHokum.contains { $0.kind == .belot && $0.points == 20 })

        let wrongTrump = ProjectDetector.detect(hand: hand, player: table.south, mode: .hokum, trumpSuit: .hearts, rules: .standard)
        #expect(!wrongTrump.contains { $0.kind == .belot })

        let inSun = ProjectDetector.detect(hand: hand, player: table.south, mode: .sun, trumpSuit: nil, rules: .standard)
        #expect(!inSun.contains { $0.kind == .belot })
    }

    @Test("تعطيل المشاريع من القواعد يُلغي اكتشافها كلها")
    func disablingProjectsSuppressesDetection() {
        var rules = BalootRulesConfiguration.standard
        rules.projectsEnabled = false
        let hand = Suit.allCases.map { card($0, .ace) }
        #expect(ProjectDetector.detect(hand: hand, player: table.south, mode: .sun, trumpSuit: nil, rules: rules).isEmpty)
    }
}

// MARK: - المفاضلة بين الفريقين

@Suite("مفاضلة المشاريع بين الفريقين")
struct ProjectResolutionTests {
    private let table = TestTable()

    private func project(_ kind: Project.Kind, points: Int, player: Player, cards: [PlayingCard]) -> Project {
        Project(kind: kind, teamID: player.teamID, playerID: player.id, cards: cards, points: points)
    }

    @Test("الفريق صاحب أقوى مشروع يأخذ كل مشاريعه والخصم لا يأخذ شيئًا")
    func strongestProjectTakesAll() {
        let mine = project(.fifty, points: 50, player: table.south,
                           cards: [card(.hearts, .seven), card(.hearts, .eight), card(.hearts, .nine), card(.hearts, .ten)])
        let alsoMine = project(.sira, points: 20, player: table.north,
                               cards: [card(.clubs, .queen), card(.clubs, .king), card(.clubs, .ace)])
        let theirs = project(.sira, points: 20, player: table.west,
                             cards: [card(.spades, .seven), card(.spades, .eight), card(.spades, .nine)])

        let resolution = ProjectDetector.resolve(projects: [mine, alsoMine, theirs], teams: table.teams)

        #expect(resolution.winningTeamID == table.teamA.id)
        #expect(resolution.points(for: table.teamA.id) == 70)
        #expect(resolution.points(for: table.teamB.id) == 0)
        #expect(resolution.overruled.contains(theirs))
    }

    @Test("عند تساوي أقوى مشروعين تسقط مشاريع الفريقين معًا")
    func exactTieCancelsBothTeams() {
        let cards: [PlayingCard] = [card(.hearts, .seven), card(.hearts, .eight), card(.hearts, .nine)]
        let mine = project(.sira, points: 20, player: table.south, cards: cards)
        let theirs = project(.sira, points: 20, player: table.west, cards: cards)

        let resolution = ProjectDetector.resolve(projects: [mine, theirs], teams: table.teams)

        #expect(resolution.winningTeamID == nil)
        #expect(resolution.awarded.isEmpty)
        #expect(resolution.overruled.count == 2)
    }

    @Test("البلوت يُحتسب دائمًا حتى لو ملك الخصم مشروعًا أقوى")
    func belotIsExemptFromComparison() {
        let belot = project(.belot, points: 20, player: table.south, cards: [card(.spades, .queen), card(.spades, .king)])
        let bigOpponentProject = project(.fourHundred, points: 400, player: table.west,
                                         cards: Suit.allCases.map { card($0, .ace) })

        let resolution = ProjectDetector.resolve(projects: [belot, bigOpponentProject], teams: table.teams)

        #expect(resolution.points(for: table.teamA.id) == 20)
        #expect(resolution.points(for: table.teamB.id) == 400)
    }

    @Test("أعلى ورقة تفض التعادل بين مشروعين من نفس النوع والنقاط")
    func topCardBreaksTie() {
        let low = project(.sira, points: 20, player: table.south,
                          cards: [card(.hearts, .seven), card(.hearts, .eight), card(.hearts, .nine)])
        let high = project(.sira, points: 20, player: table.west,
                           cards: [card(.clubs, .queen), card(.clubs, .king), card(.clubs, .ace)])

        let resolution = ProjectDetector.resolve(projects: [low, high], teams: table.teams)
        #expect(resolution.winningTeamID == table.teamB.id)
    }
}

// MARK: - المشاريع داخل النتيجة

@Suite("المشاريع والكبوت في نتيجة الجولة")
struct ProjectScoringTests {
    private let table = TestTable()

    /// يبني ثماني أكلات يفوز بها لاعب واحد كاملة (كبوت).
    private func sweepTricks(winner: Player) -> [Trick] {
        (0..<8).map { index in
            var trick = Trick(leaderSeat: winner.seat)
            trick.playedCards = [PlayedCard(playerID: winner.id, card: card(.hearts, Rank.allCases[index]))]
            trick.winnerPlayerID = winner.id
            return trick
        }
    }

    @Test("أخذ الأكلات الثماني يُكتشف ككبوت ويمنح المكافأة")
    func kabootDetectedAndAwarded() {
        var rules = BalootRulesConfiguration.standard
        rules.declarerMustWinMajority = false
        rules.projectsEnabled = false

        let tricks = sweepTricks(winner: table.south)
        let result = ScoreCalculator.finalRoundScore(
            completedTricks: tricks, originalHands: [:], players: table.players, teams: table.teams,
            mode: .hokum, trumpSuit: .spades, rules: rules, declaredProjects: []
        )

        #expect(result.kabootTeamID == table.teamA.id)
        #expect((result.teamPoints[table.teamA.id] ?? 0) >= rules.kabootBonusHokum)
    }

    @Test("لا كبوت إذا فاز الفريقان بأكلات")
    func noKabootWhenTricksAreSplit() {
        var tricks = sweepTricks(winner: table.south)
        tricks[3].winnerPlayerID = table.west.id

        #expect(ScoreCalculator.detectKaboot(completedTricks: tricks, players: table.players) == nil)
    }

    @Test("المشاريع الموجودة لا تُحتسب عند اشتراط الإعلان حتى يعلنها اللاعب")
    func declarationRequiredScoresOnlyDeclaredProjects() throws {
        var rules = BalootRulesConfiguration.standard
        rules.declarerMustWinMajority = false
        rules.kabootEnabled = false

        let originalHands = [
            table.south.id: [
                card(.hearts, .seven),
                card(.hearts, .eight),
                card(.hearts, .nine)
            ]
        ]
        let project = try #require(ProjectDetector.detect(
            hand: originalHands[table.south.id] ?? [],
            player: table.south,
            mode: .sun,
            trumpSuit: nil,
            rules: rules
        ).first)

        let undeclared = ScoreCalculator.finalRoundScore(
            completedTricks: [],
            originalHands: originalHands,
            players: table.players,
            teams: table.teams,
            mode: .sun,
            trumpSuit: nil,
            rules: rules,
            declaredProjects: []
        )
        #expect(undeclared.projectPoints[table.teamA.id] == 0)
        #expect(undeclared.awardedProjects.isEmpty)

        let declared = ScoreCalculator.finalRoundScore(
            completedTricks: [],
            originalHands: originalHands,
            players: table.players,
            teams: table.teams,
            mode: .sun,
            trumpSuit: nil,
            rules: rules,
            declaredProjects: [project]
        )
        #expect(declared.projectPoints[table.teamA.id] == 20)
        #expect(declared.awardedProjects == [project])

        let automatic = ScoreCalculator.finalRoundScore(
            completedTricks: [],
            originalHands: originalHands,
            players: table.players,
            teams: table.teams,
            mode: .sun,
            trumpSuit: nil,
            rules: rules,
            declaredProjects: nil
        )
        #expect(automatic.projectPoints[table.teamA.id] == 20)
        #expect(automatic.awardedProjects == [project])
    }

    @Test("طياح المشتري ينقل كل نقاط الجولة إلى الخصم")
    func failedDeclarerLosesEverything() {
        var rules = BalootRulesConfiguration.standard
        rules.projectsEnabled = false
        rules.kabootEnabled = false

        // الخصم (فريق ب) يأخذ كل الأكلات، والمشتري فريق أ.
        let tricks = sweepTricks(winner: table.west)
        let result = ScoreCalculator.finalRoundScore(
            completedTricks: tricks, originalHands: [:], players: table.players, teams: table.teams,
            mode: .hokum, trumpSuit: .spades, rules: rules,
            declaredProjects: [], declaringTeamID: table.teamA.id
        )

        #expect(result.didDeclarerFail)
        #expect(result.teamPoints[table.teamA.id] == 0)
        #expect((result.teamPoints[table.teamB.id] ?? 0) > 0)
    }

    @Test("تعطيل قاعدة الطياح يُبقي النقاط مقسّمة كما هي")
    func disablingMajorityRuleKeepsSplit() {
        var rules = BalootRulesConfiguration.standard
        rules.projectsEnabled = false
        rules.kabootEnabled = false
        rules.declarerMustWinMajority = false

        let tricks = sweepTricks(winner: table.west)
        let result = ScoreCalculator.finalRoundScore(
            completedTricks: tricks, originalHands: [:], players: table.players, teams: table.teams,
            mode: .hokum, trumpSuit: .spades, rules: rules,
            declaredProjects: [], declaringTeamID: table.teamA.id
        )

        #expect(!result.didDeclarerFail)
    }
}
