import Foundation
import Observation
import BalootEngine

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

@Observable
@MainActor
final class BalootGameViewModel {
    private(set) var state: GameState
    private(set) var errorMessage: String?

    let variant: BalootGameVariant
    private let agent: BalootAgent = SimpleBalootAgent()
    private let humanPlayerID: Player.ID
    private let rules: BalootRulesConfiguration
    /// مهمة أدوار اللاعبين الآليين الجارية، تُلغى قبل بدء غيرها حتى لا تتداخل
    /// جولتان (مثلًا عند الضغط على "جولة جديدة" أثناء لعب الآليين).
    private var aiTask: Task<Void, Never>?

    init(variant: BalootGameVariant = .free, rules: BalootRulesConfiguration = .standard) {
        let initial = GameState.newLocalMatch(rules: rules)
        self.state = initial
        self.variant = variant
        self.rules = rules
        self.humanPlayerID = initial.players.first { $0.kind == .human }?.id ?? UUID()
    }

    var humanID: Player.ID { humanPlayerID }

    var isHumanTurn: Bool {
        state.phase == .bidding || state.phase == .playing
            ? state.currentTurnPlayerID == humanPlayerID
            : false
    }

    var humanHand: [PlayingCard] {
        (state.hands[humanPlayerID] ?? []).sorted { lhs, rhs in
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

    func startNewMatch() {
        state = GameState.newLocalMatch(rules: rules)
        errorMessage = nil
        deal()
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
              state.currentTurnPlayerID == humanPlayerID
        else { return }
        chooseMode(.sun, trumpSuit: nil)
    }

    func chooseMode(_ mode: GameMode, trumpSuit: Suit?) {
        perform(.chooseMode(playerID: humanPlayerID, mode: mode, trumpSuit: trumpSuit))
        advanceAI()
    }

    func play(_ card: PlayingCard) {
        perform(.playCard(playerID: humanPlayerID, card: card))
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
            errorMessage = "تعذّرت هذه الحركة، حاول مرة أخرى."
        }
    }

    /// يلعب اللاعبون الآليون **ورقة واحدة في كل خطوة** مع فاصل زمني قصير، بدل تنفيذ
    /// كل أدوارهم في إطار واحد. بدون هذا الفاصل تظهر أوراق اللاعبين الثلاثة وتُحسم
    /// الأكلة في نفس اللحظة التي يلعب فيها المستخدم، فلا يرى ما حدث إطلاقًا.
    private func advanceAI() {
        aiTask?.cancel()
        aiTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isAITurn else { break }
                do {
                    self.state = try GameEngine.advanceAIPlayers(state: self.state, agent: self.agent, maxSteps: 1)
                } catch {
                    self.errorMessage = "حدث خطأ أثناء لعب اللاعبين الآليين."
                    return
                }
                if self.state.phase == .scoring {
                    self.finishRoundIfNeeded()
                    return
                }
                try? await Task.sleep(for: .milliseconds(Self.aiMoveDelayMilliseconds))
            }
            // قد تكون الجولة اكتملت بورقة المستخدم الأخيرة دون أي دور آلي بعدها.
            self?.finishRoundIfNeeded()
        }
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
