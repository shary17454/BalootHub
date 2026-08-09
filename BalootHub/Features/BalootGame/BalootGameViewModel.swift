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
/// نمط الجولة المسموح به في شاشة اللعب، مشتقًا من عنصر الكتالوج الذي فُتحت منه.
///
/// عناصر الكتالوج "بلوت صن" و"بلوت حكم" تمثّل نمطًا واحدًا محددًا، فلا معنى لأن تعرض
/// للاعب كل خيارات المزايدة كما في "بلوت كلاسيكي". هذا النوع يحمل ذلك القيد إلى الواجهة
/// وإلى المزايدة التلقائية معًا.
enum BalootGameVariant: Equatable {
    /// مزايدة حرة بين صن وكل أنواع الحكم (بلوت كلاسيكي).
    case free
    /// صن فقط — تُختار تلقائيًا دون مزايدة.
    case sunOnly
    /// حكم فقط — يختار اللاعب نوع الحكم لا أكثر.
    case hokumOnly

    init(slug: String) {
        switch slug {
        case "baloot-sun": self = .sunOnly
        case "baloot-hokum": self = .hokumOnly
        default: self = .free
        }
    }

    var allowsSun: Bool { self != .hokumOnly }
    var allowsHokum: Bool { self != .sunOnly }
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

    let variant: BalootGameVariant
    // الوكيل الخبير يحاكي توزيعات محتملة قبل كل ورقة (انظر ``ExpertBalootAgent``).
    // 8 عينات تحافظ على قوة اللعب مع تقليل زمن القرار على أجهزة المستخدمين.
    private let agent: BalootAgent = ExpertBalootAgent(samples: 8)
    private let rules: BalootRulesConfiguration
    /// مهمة أدوار اللاعبين الآليين الجارية، تُلغى قبل بدء غيرها حتى لا تتداخل
    /// جولتان (مثلًا عند الضغط على "جولة جديدة" أثناء لعب الآليين).
    private let aiTask = GameTaskBox()

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
        rules: BalootRulesConfiguration = .standard
    ) {
        let initial = Self.makeInitialState(tableMode: tableMode, rules: rules)
        self.state = initial
        self.variant = variant
        self.tableMode = tableMode
        self.rules = rules
    }

    deinit {
        // بدون هذا تبقى مهمة اللاعبين الآليين تدور بعد إغلاق الشاشة إلى أن تكتشف
        // أن `self` تحرّر، فتُهدر حسابات محاكاة كاملة بلا فائدة.
        aiTask.cancel()
    }

    var activeHumanID: Player.ID? {
        guard let playerID = state.currentTurnPlayerID,
              state.player(id: playerID)?.kind == .human
        else { return state.players.first { $0.kind == .human }?.id }
        return playerID
    }

    var isHumanTurn: Bool {
        state.phase == .bidding || state.phase == .playing
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
        state = Self.makeInitialState(tableMode: tableMode, rules: rules)
        errorMessage = nil
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
        applyForcedModeIfNeeded()
    }

    /// في نمط "صن فقط" لا توجد مزايدة أصلًا، فيُختار النمط تلقائيًا بمجرد التوزيع
    /// بدل ترك اللاعب أمام لوحة مزايدة بخيار واحد.
    private func applyForcedModeIfNeeded() {
        guard variant == .sunOnly,
              state.phase == .bidding,
              activeHumanID == state.currentTurnPlayerID
        else { return }
        chooseMode(.sun, trumpSuit: nil)
    }

    func chooseMode(_ mode: GameMode, trumpSuit: Suit?) {
        guard let activeHumanID else { return }
        perform(.chooseMode(playerID: activeHumanID, mode: mode, trumpSuit: trumpSuit))
        advanceAI()
    }

    func play(_ card: PlayingCard) {
        guard let activeHumanID else { return }
        perform(.playCard(playerID: activeHumanID, card: card))
        advanceAI()
    }

    func clearError() {
        errorMessage = nil
    }

    func finishRoundIfNeeded() {
        guard state.phase == .scoring else { return }
        perform(.finishRound)
    }

    private func perform(_ action: GameAction) {
        do {
            state = try GameEngine.apply(action, to: state)
            errorMessage = nil
        } catch {
            errorMessage = Self.moveErrorMessage
        }
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

    /// هل الدور الحالي للاعب آلي في مرحلة تسمح باللعب؟
    private var isAITurn: Bool {
        guard state.phase == .bidding || state.phase == .playing,
              let playerID = state.currentTurnPlayerID,
              let player = state.player(id: playerID)
        else { return false }
        return player.kind == .ai
    }

    /// فاصل مريح يكفي لمتابعة الورقة دون أن يبدو اللعب بطيئًا.
    private static let aiMoveDelayMilliseconds = 550
}
