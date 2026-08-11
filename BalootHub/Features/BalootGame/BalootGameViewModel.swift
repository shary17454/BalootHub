import Foundation
import Observation
import BalootEngine

private final class GameTaskBox: @unchecked Sendable {
    private var task: Task<Void, Never>?

    func replace(with newTask: Task<Void, Never>) {
        task?.cancel()
        task = newTask
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

/// يربط واجهة شاشة اللعب بمحرك BalootEngine. لا يحتوي أي منطق قواعد؛
/// كل قرار قانوني أو احتساب نقاط يمر عبر المحرك نفسه.
/// نمط الجولة المسموح به في شاشة اللعب.
///
/// اللعب الواقعي يدخل من لعبة بلوت واحدة، ثم تحدد المزايدة هل الجولة صن أو حكم.
/// تبقى الحالات المقيدة هنا للتوافق مع أي رابط قديم، لكنها لا تُستخدم كمدخلات
/// كتالوج قابلة للعب.
enum BalootGameVariant: Equatable {
    /// مزايدة حرة بين صن وكل أنواع الحكم (بلوت كلاسيكي).
    case free

    init(slug: String) {
        self = .free
    }
}

enum BalootTableMode: String, CaseIterable, Identifiable {
    case versusAI
    case localHumans

    var id: String { rawValue }

    var title: String {
        switch self {
        case .versusAI: "ضد الذكاء".localized
        case .localHumans: "أربعة أشخاص".localized
        }
    }

    var subtitle: String {
        switch self {
        case .versusAI: "أنت وثلاثة لاعبين آليين".localized
        case .localHumans: "تمرير الجهاز بين اللاعبين".localized
        }
    }

    var systemImage: String {
        switch self {
        case .versusAI: "cpu.fill"
        case .localHumans: "person.4.fill"
        }
    }
}

@Observable
@MainActor
final class BalootGameViewModel {
    private(set) var state: GameState
    private(set) var errorMessage: String?
    private(set) var tableMode: BalootTableMode
    private(set) var roundAnalysisReport: RoundAnalysisReport?

    let variant: BalootGameVariant
    /// مستوى الخصوم الآليين المختار.
    private(set) var aiLevel: AIProfile.Level
    // الخصم مبني على ``AIProfile`` فيختلف تفكيره بالمستوى والشخصية، لا بأخطاء عشوائية.
    private var agent: BalootAgent
    private let rules: BalootRulesConfiguration
    /// مهمة أدوار اللاعبين الآليين الجارية، تُلغى قبل بدء غيرها حتى لا تتداخل
    /// جولتان (مثلًا عند الضغط على "جولة جديدة" أثناء لعب الآليين).
    private let aiTask = GameTaskBox()
    private let analysisTask = GameTaskBox()

    /// أسماء اللاعبين والفريقين مترجمة حسب لغة الجهاز، بدل الأسماء العربية
    /// المثبّتة داخل المحرك.
    private static func localizedNames(for tableMode: BalootTableMode) -> GameState.LocalMatchNames {
        let westName: String
        let northName: String
        let eastName: String
        switch tableMode {
        case .versusAI:
            westName = "آلي غرب".localized
            northName = "آلي شمال".localized
            eastName = "آلي شرق".localized
        case .localHumans:
            westName = "غرب".localized
            northName = "شمال".localized
            eastName = "شرق".localized
        }

        return GameState.LocalMatchNames(
            human: "أنت".localized,
            teamOurs: "فريقنا".localized,
            teamOpponent: "الخصم".localized,
            aiWest: westName,
            aiNorth: northName,
            aiEast: eastName
        )
    }

    init(
        variant: BalootGameVariant = .free,
        tableMode: BalootTableMode = .versusAI,
        rules: BalootRulesConfiguration = .standard,
        aiLevel: AIProfile.Level = .expert
    ) {
        let playRules = Self.playRules(from: rules)
        self.state = Self.makeInitialState(tableMode: tableMode, rules: playRules)
        self.variant = variant
        self.tableMode = tableMode
        self.rules = playRules
        self.aiLevel = aiLevel
        self.agent = ProfiledBalootAgent(profile: Self.profile(for: aiLevel))
    }

    private static func profile(for level: AIProfile.Level) -> AIProfile {
        AIProfile.roster.first { $0.level == level }
            ?? AIProfile(id: "ai.default", level: level, personality: .balanced, avatarSystemName: "person.fill")
    }

    /// يغيّر مستوى الخصوم ويبدأ مباراة جديدة به.
    func setAILevel(_ level: AIProfile.Level) {
        guard aiLevel != level else { return }
        aiTask.cancel()
        aiLevel = level
        agent = ProfiledBalootAgent(profile: Self.profile(for: level))
        startNewMatch()
    }

    deinit {
        // بدون هذا تبقى مهمة اللاعبين الآليين تدور بعد إغلاق الشاشة إلى أن تكتشف
        // أن `self` تحرّر، فتُهدر حسابات محاكاة كاملة بلا فائدة.
        aiTask.cancel()
        analysisTask.cancel()
    }

    var activeHumanID: Player.ID? {
        guard let playerID = state.currentTurnPlayerID,
              state.player(id: playerID)?.kind == .human
        else { return state.players.first { $0.kind == .human }?.id }
        return playerID
    }

    /// المراحل التي ينتظر فيها المحرك قرارًا من صاحب الدور.
    private static let interactivePhases: Set<GamePhase> = [.bidding, .declaring, .playing]

    var isHumanTurn: Bool {
        Self.interactivePhases.contains(state.phase)
            ? activeHumanID == state.currentTurnPlayerID
            : false
    }

    var currentTurnPlayerName: String {
        guard let playerID = state.currentTurnPlayerID,
              let player = state.player(id: playerID)
        else { return "" }
        return player.name
    }

    var humanHand: [PlayingCard] {
        guard let activeHumanID else { return [] }
        return (state.hands[activeHumanID] ?? []).sorted { lhs, rhs in
            if lhs.suit != rhs.suit { return lhs.suit.rawValue < rhs.suit.rawValue }
            return lhs.strength(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit) < rhs.strength(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit)
        }
    }

    /// الأوراق التي تُعرض في منطقة الأكلة.
    ///
    /// المحرك يمسح `currentTrick` فور اكتمال الأكلة الرابعة وينقلها إلى `completedTricks`،
    /// فلو اعتمدت الواجهة على `currentTrick` وحده لاختفت الأوراق الأربع في نفس اللحظة
    /// ولما عرف اللاعب من فاز بالأكلة. لذا تُعرض آخر أكلة مكتملة إلى أن تبدأ التالية فعليًا.
    var trickOnTable: [PlayedCard] {
        if let current = state.currentTrick, !current.playedCards.isEmpty {
            return current.playedCards
        }
        return state.completedTricks.last?.playedCards ?? []
    }

    /// هل ما يُعرض حاليًا أكلة محسومة (لا أكلة جارية)؟ تستخدمه الواجهة لإظهار الفائز.
    var isShowingResolvedTrick: Bool {
        (state.currentTrick?.playedCards.isEmpty ?? true) && !state.completedTricks.isEmpty
    }

    /// اسم الفريق الفائز بآخر أكلة محسومة، إن وُجد.
    var lastTrickWinnerName: String? {
        guard isShowingResolvedTrick,
              let winnerID = state.completedTricks.last?.winnerPlayerID,
              let winner = state.player(id: winnerID)
        else { return nil }
        return winner.name
    }

    var legalCardsForHuman: [PlayingCard] {
        guard let mode = state.mode else { return [] }
        return LegalMoveValidator.legalCards(hand: humanHand, trick: state.currentTrick, mode: mode, trumpSuit: state.trumpSuit, rules: state.rules)
    }

    /// مجموعة الأوراق القانونية للبحث السريع من الواجهة.
    ///
    /// كانت الواجهة تستدعي ``legalCardsForHuman`` داخل حلقة الأوراق، فيُعاد فرز اليد
    /// وحساب القانونية ثمان مرات في كل إعادة رسم. تُحسب هنا مرة واحدة، والبحث في
    /// `Set` ثابت الزمن.
    var legalCardIDsForHuman: Set<PlayingCard> {
        Set(legalCardsForHuman)
    }

    func startNewMatch() {
        aiTask.cancel()
        analysisTask.cancel()
        state = Self.makeInitialState(tableMode: tableMode, rules: rules)
        errorMessage = nil
        roundAnalysisReport = nil
        deal()
    }

    func setTableMode(_ newMode: BalootTableMode) {
        guard tableMode != newMode else { return }
        aiTask.cancel()
        tableMode = newMode
        startNewMatch()
    }

    func deal() {
        perform(.dealCards(seed: UInt64.random(in: .min ... .max)))
        advanceAI()
    }

    func chooseMode(_ mode: GameMode, trumpSuit: Suit?) {
        guard let activeHumanID else { return }
        perform(.chooseMode(playerID: activeHumanID, mode: mode, trumpSuit: trumpSuit))
        advanceAI()
    }

    // MARK: - دورة المزايدة الكاملة

    /// هل تستخدم هذه الجولة دورة المزايدة الحقيقية؟
    var usesFullBidding: Bool { state.rules.biddingStyle == .full }

    var biddingStage: BiddingState.Stage { state.bidding.stage }

    /// الورقة المكشوفة التي تُزايَد عليها في الجولة الأولى.
    var upCard: PlayingCard? { state.bidding.upCard }

    /// المزايدات المتاحة للاعب البشري الآن — مصدرها المحرك نفسه، فلا تعرض الواجهة
    /// خيارًا يرفضه المحرك بعد الضغط عليه.
    var legalBidsForHuman: [Bid] {
        guard usesFullBidding, state.phase == .bidding, isHumanTurn else { return [] }
        return state.bidding.legalBids(rules: state.rules)
    }

    /// سجل المزايدات مقرونًا بأسماء أصحابها للعرض.
    var bidHistory: [(playerName: String, bid: Bid)] {
        state.bidding.bids.map { record in
            (state.player(id: record.playerID)?.name ?? "", record.bid)
        }
    }

    var declarerName: String? {
        state.declarer?.name
    }

    var currentMultiplier: Multiplier { state.bidding.multiplier }

    func placeBid(_ bid: Bid) {
        guard let activeHumanID else { return }
        perform(.placeBid(playerID: activeHumanID, bid: bid))
        advanceAI()
    }

    // MARK: - المضاعفة

    var isAwaitingHumanMultiplierDecision: Bool {
        state.phase == .bidding && state.bidding.stage == .doubling && isHumanTurn
    }

    var isShowingHumanMultiplierControls: Bool {
        isAwaitingHumanMultiplierDecision || canLockMultiplier
    }

    /// درجة التصعيد التالية المتاحة، أو `nil` إن بلغت المضاعفة سقفها أو أُقفلت.
    var nextAvailableMultiplier: Multiplier? {
        guard !state.bidding.isLocked,
              let next = state.bidding.multiplier.next,
              next <= state.rules.maximumMultiplier else { return nil }
        return next
    }

    /// هل يستطيع اللاعب البشري «القفل» الآن؟
    var canLockMultiplier: Bool {
        guard state.phase == .bidding, state.bidding.stage == .doubling,
              state.rules.lockEnabled, state.bidding.multiplier != .none,
              humanMultiplierLockerID != nil else { return false }
        return true
    }

    private var humanMultiplierLockerID: Player.ID? {
        guard let requesterTeamID = state.bidding.multiplierRequesterTeamID else { return nil }
        return state.players.first { player in
            player.kind == .human && player.teamID == requesterTeamID
        }?.id
    }

    func raiseMultiplier(to level: Multiplier) {
        guard let activeHumanID else { return }
        perform(.raiseMultiplier(playerID: activeHumanID, level: level))
        advanceAI()
    }

    func passMultiplier() {
        guard let activeHumanID else { return }
        perform(.passMultiplier(playerID: activeHumanID))
        advanceAI()
    }

    func lockMultiplier() {
        guard let playerID = humanMultiplierLockerID else { return }
        perform(.lockMultiplier(playerID: playerID))
        advanceAI()
    }

    // MARK: - إعلان المشاريع

    var isAwaitingHumanDeclaration: Bool {
        state.phase == .declaring && isHumanTurn
    }

    /// المشاريع الموجودة فعلًا في يد اللاعب البشري والقابلة للإعلان.
    var declarableProjectsForHuman: [Project] {
        guard let activeHumanID, state.phase == .declaring else { return [] }
        return GameEngine.declarableProjects(for: activeHumanID, state: state)
    }

    /// المشاريع المحتسَبة بعد المفاضلة، تُعرض في لوحة النتيجة.
    var awardedProjects: [Project] { state.awardedProjects }

    var canReplayCurrentRound: Bool {
        state.phase == .finished && !state.actionHistory.isEmpty
    }

    var currentRoundReplayInitialState: GameState {
        GameState(
            players: state.players,
            teams: state.teams,
            rules: state.rules,
            dealerSeat: state.dealerSeat,
            roundNumber: state.roundNumber
        )
    }

    func declareProjects(_ projects: [Project]) {
        guard let activeHumanID else { return }
        perform(.declareProjects(playerID: activeHumanID, projects: projects))
        advanceAI()
    }

    func skipDeclaration() {
        declareProjects([])
    }

    func play(_ card: PlayingCard) {
        guard let activeHumanID else { return }
        perform(.playCard(playerID: activeHumanID, card: card))
        advanceAI()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - مساعد القواعد أثناء اللعب

    /// يشرح **لماذا** لا يمكن لعب ورقة معيّنة، بدل تجاهل الضغطة بصمت.
    ///
    /// التفسير مشتق من ``LegalMoveValidator`` عبر المحرك، فهو نفس السبب الذي يرفض به
    /// المحرك الحركة حرفيًا — لا شرحًا موازيًا قد يتناقض معه عند تغيير القواعد.
    func explanation(forPlaying card: PlayingCard) -> String? {
        guard let activeHumanID,
              let reason = GameEngine.invalidMoveReason(playerID: activeHumanID, card: card, state: state)
        else { return nil }
        return RuleExplanationFormatter.illegalMoveExplanation(for: reason, trumpSuit: state.trumpSuit)
    }

    /// يعرض تفسير المنع للاعب. تستدعيها الواجهة عند الضغط على ورقة غير قانونية.
    func explainIllegalMove(_ card: PlayingCard) {
        errorMessage = explanation(forPlaying: card) ?? Self.moveErrorMessage
    }

    func finishRoundIfNeeded() {
        guard state.phase == .scoring else { return }
        perform(.finishRound)
    }

    private func perform(_ action: GameAction) {
        do {
            state = try GameEngine.apply(action, to: state)
            errorMessage = nil
            scheduleRoundAnalysisIfNeeded()
        } catch {
            errorMessage = Self.moveErrorMessage
        }
    }

    private func scheduleRoundAnalysisIfNeeded() {
        guard state.phase == .finished,
              roundAnalysisReport == nil,
              let playerID = state.players.first(where: { $0.kind == .human })?.id,
              state.actionHistory.contains(where: {
                  if case .playCard(let actorID, _) = $0 { return actorID == playerID }
                  return false
              })
        else { return }

        let snapshot = state
        analysisTask.replace(with: Task { [weak self] in
            let report = await Task.detached(priority: .utility) {
                try? RoundAnalyzer.analyze(finalState: snapshot, playerID: playerID, difficulty: .medium)
            }.value

            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.roundAnalysisReport = report
            }
        })
    }

    // رسائل الخطأ تُمرَّر إلى `Text(String)` الذي لا يترجم تلقائيًا (بخلاف السلاسل
    // الحرفية داخل `Text`)، فتُترجم هنا صراحةً عبر `.localized`.
    private static var moveErrorMessage: String { "تعذّرت هذه الحركة، حاول مرة أخرى.".localized }
    private static var aiErrorMessage: String { "حدث خطأ أثناء لعب اللاعبين الآليين.".localized }

    private static func makeInitialState(tableMode: BalootTableMode, rules: BalootRulesConfiguration) -> GameState {
        switch tableMode {
        case .versusAI:
            return GameState.newLocalMatch(names: localizedNames(for: tableMode), rules: rules)
        case .localHumans:
            return GameState.newLocalHumanMatch(names: localizedNames(for: tableMode), rules: rules)
        }
    }

    /// شاشة اللعب دائمًا تمثّل لعبة البلوت الواقعية الواحدة: مزايدة كاملة ينتج عنها
    /// صن أو حكم. يبقى `simpleBidding` متاحًا للمحرك والدروس والاختبارات فقط، لا كطريقة
    /// لعب نهائية تفصل الصن والحكم إلى اختيار مباشر.
    private static func playRules(from rules: BalootRulesConfiguration) -> BalootRulesConfiguration {
        var playRules = rules
        playRules.biddingStyle = .full
        playRules.cardsBeforeBidding = max(1, min(playRules.cardsBeforeBidding, 7))
        return playRules
    }

    /// يلعب اللاعبون الآليون **ورقة واحدة في كل خطوة** مع فاصل زمني قصير، بدل تنفيذ
    /// كل أدوارهم في إطار واحد. بدون هذا الفاصل تظهر أوراق اللاعبين الثلاثة وتُحسم
    /// الأكلة في نفس اللحظة التي يلعب فيها المستخدم، فلا يرى ما حدث إطلاقًا.
    ///
    /// اختيار الورقة نفسه يُحسب على خيط خلفي عبر ``GameEngine/nextAIAction(state:agent:)``:
    /// ``ExpertBalootAgent`` بحث بالمحاكاة يستغرق زمنًا محسوسًا، وحسابه على خيط الواجهة
    /// كان يُجمّدها قبل كل نقلة آلية. التطبيق على الحالة يبقى على `@MainActor`.
    private func advanceAI() {
        aiTask.cancel()
        let agent = self.agent
        aiTask.replace(with: Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isAITurn else { break }

                let snapshot = self.state
                let action = await Task.detached(priority: .userInitiated) {
                    GameEngine.nextAIAction(state: snapshot, agent: agent)
                }.value

                // الحالة قد تكون تغيّرت أثناء الحساب (جولة جديدة مثلًا)، فنتوقف بدل
                // تطبيق فعل محسوب على حالة قديمة.
                guard !Task.isCancelled, let action else { break }

                do {
                    self.state = try GameEngine.apply(action, to: self.state)
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = Self.aiErrorMessage
                    return
                }

                if self.state.phase == .scoring {
                    self.finishRoundIfNeeded()
                    return
                }
                try? await Task.sleep(for: .milliseconds(Self.aiMoveDelayMilliseconds))
            }
            // قد تكون الجولة اكتملت بورقة المستخدم الأخيرة دون أي دور آلي بعدها.
            if !Task.isCancelled { self?.finishRoundIfNeeded() }
        })
    }

    /// هل الدور الحالي للاعب آلي في مرحلة تسمح بالقرار؟
    ///
    /// مرحلة الإعلان مشمولة: بدونها كانت الجولة تتجمّد عند أول لاعب آلي عليه أن
    /// يُعلن مشاريعه، فلا يتقدم أحد ولا تظهر أي رسالة.
    private var isAITurn: Bool {
        guard Self.interactivePhases.contains(state.phase),
              let playerID = state.currentTurnPlayerID,
              let player = state.player(id: playerID)
        else { return false }
        return player.kind == .ai
    }

    /// فاصل مريح يكفي لمتابعة الورقة دون أن يبدو اللعب بطيئًا.
    private static let aiMoveDelayMilliseconds = 550
}
