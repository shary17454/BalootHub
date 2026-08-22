import Foundation
import BalootEngine

enum RuleExplanationFormatter {
    static func illegalMoveExplanation(for card: PlayingCard, reason: IllegalMoveReason, trumpSuit: Suit?) -> String {
        "\("لا يمكنك لعب".localized) \(card.accessibilityName): \(illegalMoveExplanation(for: reason, trumpSuit: trumpSuit))"
    }

    static func illegalMoveExplanation(for reason: IllegalMoveReason, trumpSuit: Suit?) -> String {
        switch reason {
        case .mustFollowSuit:
            return "لا يمكنك لعب هذه الورقة لأن لديك ورقة من اللون المطلوب ويجب عليك التلزيم.".localized
        case .mustPlayTrumpWhenVoidOfSuit:
            let suitName = trumpSuit.map { " (\($0.spokenName))" } ?? ""
            return "\("أنت لا تملك اللون المطلوب ويجب عليك القطع بالحكم وفق القاعدة الحالية.".localized)\(suitName)"
        case .mustOvertrump:
            let suitName = trumpSuit.map { " (\($0.spokenName))" } ?? ""
            return "\("يجب أن تعلو على أعلى حكم مطروح ما دام لديك ما يعلوه.".localized)\(suitName)"
        case .cardNotInHand:
            return "هذه الورقة ليست في يدك.".localized
        case .notPlayersTurn:
            return "ليس دورك الآن.".localized
        case .wrongPhase:
            return "لا يمكن لعب ورقة في هذه المرحلة.".localized
        }
    }
}
