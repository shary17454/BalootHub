import Foundation
import Observation
import BalootEngine

/// يربط واجهة شاشة اللعب بمحرك BalootEngine. لا يحتوي أي منطق قواعد؛
/// كل قرار قانوني أو احتساب نقاط يمر عبر المحرك نفسه.
@Observable
@MainActor
final class BalootGameViewModel {
    private(set) var state: GameState
    private(set) var errorMessage: String?

    private let agent: BalootAgent = SimpleBalootAgent()
    private let humanPlayerID: Player.ID

    init(rules: BalootRulesConfiguration = .standard) {
        let initial = GameState.newLocalMatch(rules: rules)
        state = initial
        humanPlayerID = initial.players.first { $0.kind == .human }?.id ?? UUID()
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

    var legalCardsForHuman: [PlayingCard] {
        guard let mode = state.mode else { return [] }
        return LegalMoveValidator.legalCards(hand: humanHand, trick: state.currentTrick, mode: mode, trumpSuit: state.trumpSuit, rules: state.rules)
    }

    func startNewMatch(rules: BalootRulesConfiguration = .standard) {
        state = GameState.newLocalMatch(rules: rules)
        errorMessage = nil
        deal()
    }

    func deal() {
        perform(.dealCards(seed: UInt64.random(in: .min ... .max)))
        advanceAI()
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

    private func advanceAI() {
        do {
            state = try GameEngine.advanceAIPlayers(state: state, agent: agent)
            if state.phase == .scoring {
                finishRoundIfNeeded()
            }
        } catch {
            errorMessage = "حدث خطأ أثناء لعب اللاعبين الآليين."
        }
    }
}
