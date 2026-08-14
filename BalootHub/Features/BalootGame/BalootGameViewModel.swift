import Foundation
import Observation
import BalootEngine

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
    private var revealedLocalHumanID: Player.ID?
    private var roundReplayInitialState: GameState
    private var didNotifyRoundFinished = false

    /// يُستدعى مرة واحدة فقط عند انتهاء كل جولة، بعد احتساب ``GameState/awardedProjects``.
    /// الواجهة تستخدمه لحفظ إحصائيات خارج نطاق المحرك (مثل سجل المشاريع) عبر SwiftData،
    /// لأن ``BalootGameViewModel`` نفسه لا يعرف عن `modelContext`.
    var onRoundFinished: ((GameState) -> Void)?

    let variant: BalootGameVariant
    /// مستوى الخصوم الآليين المختار.
    private(set) var aiLevel: AIProfile.Level
    /// شخصية الخصوم الآليين المختارة. تعرضها الواجهة وتستخدمها سياسة المزايدة واللعب.
    private(set) var selectedAIProfile: AIProfile
    /// الخصوم الآليون موزعون حسب المقعد، حتى لا يلعب الثلاثة بالشخصية نفسها.
    private var aiProfilesByPlayerID: [Player.ID: AIProfile]
    private var aiAgentsByPlayerID: [Player.ID: ProfiledBalootAgent]
    private let rules: BalootRulesConfiguration
    /// مهمة أدوار اللاعبين الآليين الجارية، تُلغى قبل بدء غيرها حتى لا تتداخل
    /// جولتان (مثلًا عند الضغط على "جولة جديدة" أثناء لعب الآليين).
    private let aiTask = CancellableTaskBox()
    private let analysisTask = CancellableTaskBox()

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
        let profile = Self.profile(for: aiLevel)
        let initialState = Self.makeInitialState(tableMode: tableMode, rules: playRules)
        let assignments = Self.makeAIAssignments(for: initialState, selectedProfile: profile)
        let configuredState = Self.state(initialState, applyingAIProfiles: assignments.profiles)
        self.state = configuredState
        self.roundReplayInitialState = configuredState
        self.variant = variant
        self.tableMode = tableMode
        self.rules = playRules
        self.aiLevel = profile.level
        self.selectedAIProfile = profile
        self.aiProfilesByPlayerID = assignments.profiles
        self.aiAgentsByPlayerID = assignments.agents
    }

    private static func profile(for level: AIProfile.Level) -> AIProfile {
        AIProfile.roster.first { $0.level == level }
            ?? AIProfile(id: "ai.default", level: level, personality: .balanced, avatarSystemName: "person.fill")
    }

    private static func makeAIAssignments(
        for state: GameState,
        selectedProfile: AIProfile
    ) -> (profiles: [Player.ID: AIProfile], agents: [Player.ID: ProfiledBalootAgent]) {
        var profilePool = [selectedProfile]
        for profile in AIProfile.opponents(for: selectedProfile.level) where !profilePool.contains(profile) {
            profilePool.append(profile)
        }
        if profilePool.count < 3 {
            for profile in AIProfile.roster where profile.level == selectedProfile.level && !profilePool.contains(profile) {
                profilePool.append(profile)
            }
        }

        var profiles: [Player.ID: AIProfile] = [:]
        var agents: [Player.ID: ProfiledBalootAgent] = [:]
        let aiPlayers = state.players.filter { $0.kind == .ai }.sorted { $0.seat.rawValue < $1.seat.rawValue }
        for (index, player) in aiPlayers.enumerated() {
            let profile = profilePool[index % profilePool.count]
            profiles[player.id] = profile
            agents[player.id] = ProfiledBalootAgent(profile: profile)
        }
        return (profiles, agents)
    }

    private static func state(
        _ state: GameState,
        applyingAIProfiles profiles: [Player.ID: AIProfile]
    ) -> GameState {
        var updated = state
        updated.players = updated.players.map { player in
            guard player.kind == .ai, let profile = profiles[player.id] else { return player }
            var renamed = player
            renamed.name = profile.displayName.localized
            return renamed
        }
        return updated
    }

    var selectedAIProfileTitle: String {
        "\(selectedAIProfile.displayName.localized) · \(selectedAIProfile.personalityTitle.localized)"
    }

    var selectedAIProfileDetail: String {
        "\(selectedAIProfile.levelTitle.localized) · \(selectedAIProfile.styleSummary.localized)"
    }

    var selectedAIProfileRiskText: String {
        "\("المخاطرة".localized): \(selectedAIProfile.riskScore)%"
    }

    var selectedAIProfileMultiplierText: String {
        "\("المضاعفة".localized): \(selectedAIProfile.multiplierAggression)%"
    }

    var selectedAIProfileAnalysisText: String {
        "\("التحليل".localized): \(analysisSummary)"
    }

    private var analysisSummary: String {
        let samples = selectedAIProfile.level.monteCarloSamples
        if samples > 0 {
            return String(format: "يحاكي %d احتمالات لكل قرار".localized, samples)
        }
        return selectedAIProfile.level.tracksCardMemory
            ? "يتتبع الأوراق الخارجة بلا محاكاة".localized
            : "يلعب قانونيًا بلا ذاكرة أوراق".localized
    }

    var selectedAIProfileModePreferenceText: String {
        switch selectedAIProfile.preferredMode {
        case .sun?:
            "\("الميل".localized): \("صن".localized)"
        case .hokum?:
            "\("الميل".localized): \("حكم".localized)"
        case nil:
            "\("الميل".localized): \("متوازن".localized)"
        }
    }

    var aiOpponentProfiles: [AIProfile] {
        state.players
            .filter { $0.kind == .ai }
            .sorted { $0.seat.rawValue < $1.seat.rawValue }
            .compactMap { aiProfilesByPlayerID[$0.id] }
    }

    /// يغيّر مستوى الخصوم ويبدأ مباراة جديدة به.
    func setAILevel(_ level: AIProfile.Level) {
        guard aiLevel != level else { return }
        setAIProfile(Self.profile(for: level))
    }

    /// يغيّر الخصم الآلي بشخصيته ومستواه، ثم يبدأ مباراة جديدة بنفس القواعد.
    func setAIProfile(_ profile: AIProfile) {
        guard selectedAIProfile != profile else { return }
        aiTask.cancel()
        selectedAIProfile = profile
        aiLevel = profile.level
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

    var requiresLocalHandoffConfirmation: Bool {
        tableMode == .localHumans && isHumanTurn && revealedLocalHumanID != activeHumanID
    }

    var isLocalHumanHandRevealed: Bool {
        tableMode != .localHumans || (activeHumanID != nil && revealedLocalHumanID == activeHumanID)
    }

    var canCurrentHumanAct: Bool {
        isHumanTurn && isLocalHumanHandRevealed
    }

    var humanHand: [PlayingCard] {
        guard let activeHumanID else { return [] }
        return (state.hands[activeHumanID] ?? []).sorted { lhs, rhs in
            if lhs.suit != rhs.suit { return lhs.suit.rawValue < rhs.suit.rawValue }
            return lhs.strength(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit) < rhs.strength(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit)
        }
    }

    var visibleHumanHand: [PlayingCard] {
        isLocalHumanHandRevealed ? humanHand : []
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

    var moveValidationsForHuman: [MoveValidation] {
        guard canCurrentHumanAct, let activeHumanID else { return [] }
        return GameEngine.moveValidations(for: activeHumanID, state: state)
    }

    var legalCardsForHuman: [PlayingCard] {
        guard canCurrentHumanAct, let activeHumanID else { return [] }
        return GameEngine.legalMoves(for: activeHumanID, state: state).compactMap { action in
            guard case .playCard(_, let card) = action else { return nil }
            return card
        }
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
        revealedLocalHumanID = nil
        state = Self.makeInitialState(tableMode: tableMode, rules: rules)
        rebuildAIAssignments()
        roundReplayInitialState = replayInitialState(from: state)
        errorMessage = nil
        roundAnalysisReport = nil
        didNotifyRoundFinished = false
        deal()
    }

    func startNextRound() {
        guard state.phase == .finished else {
            startNewMatch()
            return
        }
        aiTask.cancel()
        analysisTask.cancel()
        revealedLocalHumanID = nil
        errorMessage = nil
        roundAnalysisReport = nil
        didNotifyRoundFinished = false
        deal()
    }

    func setTableMode(_ newMode: BalootTableMode) {
        guard tableMode != newMode else { return }
        aiTask.cancel()
        tableMode = newMode
        revealedLocalHumanID = nil
        startNewMatch()
    }

    func revealLocalHumanHand() {
        guard tableMode == .localHumans, isHumanTurn, let activeHumanID else { return }
        revealedLocalHumanID = activeHumanID
    }

    func concealLocalHumanHand() {
        guard tableMode == .localHumans else { return }
        revealedLocalHumanID = nil
    }

    private func rebuildAIAssignments() {
        let assignments = Self.makeAIAssignments(for: state, selectedProfile: selectedAIProfile)
        aiProfilesByPlayerID = assignments.profiles
        aiAgentsByPlayerID = assignments.agents
        state = Self.state(state, applyingAIProfiles: assignments.profiles)
    }

    func deal() {
        deal(seed: UInt64.random(in: .min ... .max))
    }

    /// نفس ``deal()`` ببذرة صريحة، لضبط توزيع قابل للتكرار في الاختبارات.
    func deal(seed: UInt64) {
        roundReplayInitialState = replayInitialState(from: state)
        perform(.dealCards(seed: seed))
        advanceAI()
    }

    /// لقطة بداية الجولة التالية لاستخدامها في إعادة العرض، بنفس الموزّع الذي
    /// سيستخدمه `applyDeal` فعليًا. `source.dealerSeat` قد يكون **قبل** الدوران
    /// (لو `source.phase == .finished`)، وكان استخدامه مباشرة يجعل إعادة العرض
    /// تُوزّع الأوراق على مقاعد مختلفة عن اللعب الحي بدءًا من الجولة الثانية،
    /// فتفشل إعادة تطبيق أول فعل مزايدة مسجَّل (دور لاعب مختلف عن المتوقع).
    private func replayInitialState(from source: GameState) -> GameState {
        GameState(
            players: source.players,
            teams: source.teams,
            rules: source.rules,
            dealerSeat: GameEngine.nextDealerSeat(after: source),
            roundNumber: source.roundNumber
        )
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
        guard usesFullBidding, canCurrentHumanAct, let activeHumanID else { return [] }
        return GameEngine.legalBids(for: activeHumanID, state: state)
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
        guard canCurrentHumanAct, let activeHumanID else { return }
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

    /// حركات المضاعفة القانونية للاعب البشري الآن، مصدرها المحرك نفسه.
    private var legalMultiplierActionsForHuman: [LegalMultiplierAction] {
        guard canCurrentHumanAct, let activeHumanID else { return [] }
        return GameEngine.legalMultiplierActions(for: activeHumanID, state: state)
    }

    /// حركات القفل القانونية لأي لاعب بشري يملك المضاعفة الحالية.
    private var legalHumanLockActions: [(playerID: Player.ID, actions: [LegalMultiplierAction])] {
        state.players
            .filter { $0.kind == .human }
            .map { player in
                (player.id, GameEngine.legalMultiplierActions(for: player.id, state: state))
            }
            .filter { $0.actions.contains(.lock) }
    }

    /// درجة التصعيد التالية المتاحة، أو `nil` إن بلغت المضاعفة سقفها أو أُقفلت.
    var nextAvailableMultiplier: Multiplier? {
        legalMultiplierActionsForHuman.compactMap { action -> Multiplier? in
            if case .raise(let level) = action { return level }
            return nil
        }.first
    }

    /// هل يستطيع اللاعب البشري «القفل» الآن؟
    var canLockMultiplier: Bool {
        humanMultiplierLockerID != nil
    }

    private var humanMultiplierLockerID: Player.ID? {
        legalHumanLockActions.first?.playerID
    }

    func raiseMultiplier(to level: Multiplier) {
        guard canCurrentHumanAct, let activeHumanID else { return }
        guard legalMultiplierActionsForHuman.contains(.raise(level)) else { return }
        perform(.raiseMultiplier(playerID: activeHumanID, level: level))
        advanceAI()
    }

    func passMultiplier() {
        guard canCurrentHumanAct, let activeHumanID else { return }
        guard legalMultiplierActionsForHuman.contains(.pass) else { return }
        perform(.passMultiplier(playerID: activeHumanID))
        advanceAI()
    }

    /// القفل حركة **خارج الدور** بتصميم المحرك: يملكه الفريق صاحب المضاعفة
    /// الحالية دائمًا (حتى لو كان الدور الآن للفريق المقابل بانتظار رده)، لا
    /// الفريق صاحب الدور الحالي. لذا لا يصح ربط هذا الفعل بـ`canCurrentHumanAct`
    /// (يشترط دور اللاعب البشري الحالي) — هذا كان يجعل زر القفل يظهر لكنه لا
    /// يفعل شيئًا في الحالة الوحيدة التي يظهر فيها فعلًا. ولا يصح ربطه أيضًا
    /// بإخفاء/كشف اليد في وضع «أربعة أشخاص»: القفل قرار فريق بلا معلومة عن
    /// الأوراق (بخلاف المزايدة واللعب)، فلا حاجة تعرض يد أحد لاتخاذه.
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
        guard canCurrentHumanAct, let activeHumanID, state.phase == .declaring else { return [] }
        return GameEngine.declarableProjects(for: activeHumanID, state: state)
    }

    /// المشاريع المحتسَبة بعد المفاضلة، تُعرض في لوحة النتيجة.
    var awardedProjects: [Project] { state.awardedProjects }

    var canReplayCurrentRound: Bool {
        state.phase == .finished && !state.actionHistory.isEmpty
    }

    var currentRoundReplayInitialState: GameState {
        roundReplayInitialState
    }

    func declareProjects(_ projects: [Project]) {
        guard canCurrentHumanAct, let activeHumanID else { return }
        perform(.declareProjects(playerID: activeHumanID, projects: projects))
        advanceAI()
    }

    func skipDeclaration() {
        declareProjects([])
    }

    func play(_ card: PlayingCard) {
        guard canCurrentHumanAct, let activeHumanID else { return }
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
        guard let reason = moveValidationsForHuman.first(where: { $0.card == card })?.invalidReason
        else { return nil }
        return RuleExplanationFormatter.illegalMoveExplanation(for: card, reason: reason, trumpSuit: state.trumpSuit)
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
            concealLocalHumanHand()
            errorMessage = nil
            scheduleRoundAnalysisIfNeeded()
            notifyRoundFinishedIfNeeded()
        } catch {
            AppLogger.game.error("رفض المحرك فعلًا: \(String(describing: action), privacy: .public) — \(String(describing: error), privacy: .public)")
            errorMessage = Self.moveErrorMessage
        }
    }

    /// يبلّغ ``onRoundFinished`` مرة واحدة بالضبط لكل جولة، بعد أن يحتسب المحرك
    /// ``GameState/awardedProjects`` النهائية في ``GameEngine/applyFinishRound``.
    private func notifyRoundFinishedIfNeeded() {
        guard state.phase == .finished, !didNotifyRoundFinished else { return }
        didNotifyRoundFinished = true
        onRoundFinished?(state)
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
        aiTask.replace(with: Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isAITurn,
                      let playerID = self.state.currentTurnPlayerID,
                      let agent = self.aiAgentsByPlayerID[playerID]
                else { break }

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
                    // مسار مباشر إلى `.finished` بلا مرور بـ`.scoring` ممكن هنا (دورة
                    // ميتة تُغلقها مزايدة آلية)، وهذا الحلقة لا تمر عبر `perform(_:)`
                    // فيفوّت `onRoundFinished` بدونه — لا يضر استدعاؤه هنا في المسار
                    // العادي لأن `didNotifyRoundFinished` يمنع أي تكرار.
                    self.notifyRoundFinishedIfNeeded()
                } catch {
                    AppLogger.game.error("رفض المحرك فعل لاعب آلي: \(String(describing: action), privacy: .public) — \(String(describing: error), privacy: .public)")
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
