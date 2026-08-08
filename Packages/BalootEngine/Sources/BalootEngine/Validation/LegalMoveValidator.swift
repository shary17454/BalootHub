import Foundation

/// أخطاء حركة غير قانونية.
public enum IllegalMoveReason: String, Error, Sendable {
    case cardNotInHand
    case mustFollowSuit
    case mustPlayTrumpWhenVoidOfSuit
    case mustOvertrump
    case notPlayersTurn
    case wrongPhase
}

/// يتحقق من قانونية لعب ورقة معيّنة استنادًا إلى قواعد "التلزيم" و"القطع" في البلوت.
public enum LegalMoveValidator {
    /// يُعيد قائمة الأوراق القانونية التي يمكن للاعب لعبها من يده الحالية.
    public static func legalCards(hand: [PlayingCard], trick: Trick?, mode: GameMode, trumpSuit: Suit?, rules: BalootRulesConfiguration) -> [PlayingCard] {
        guard let trick, let requiredSuit = trick.requiredSuit, !trick.isComplete else {
            // اللاعب هو قائد الأكلة: يجوز له لعب أي ورقة.
            return hand
        }

        let sameSuitCards = hand.filter { $0.suit == requiredSuit }

        // يجب التلزيم بنفس نوع الورقة الأولى إن توفر.
        if !sameSuitCards.isEmpty {
            // التعلية داخل نوع الحكم نفسه: إن كان المطلوب هو الحكم وكانت التعلية إلزامية،
            // فلا يُسمح باللعب بحكم أدنى من أعلى حكم مطروح ما دام لدى اللاعب ما يعلوه.
            if mode == .hokum, requiredSuit == trumpSuit, rules.mustOvertrump,
               let highestInTrick = trick.playedCards
                   .filter({ $0.card.suit == trumpSuit })
                   .map({ $0.card.strength(mode: mode, trumpSuit: trumpSuit) })
                   .max() {
                let higher = sameSuitCards.filter {
                    $0.strength(mode: mode, trumpSuit: trumpSuit) > highestInTrick
                }
                if !higher.isEmpty { return higher }
            }
            return sameSuitCards
        }

        // اللاعب لا يملك نفس النوع.
        guard mode == .hokum, let trumpSuit else {
            return hand
        }

        let trumpCards = hand.filter { $0.suit == trumpSuit }
        guard rules.mustTrumpWhenVoid, !trumpCards.isEmpty else {
            return hand
        }

        if rules.mustOvertrump {
            let highestTrumpInTrick = trick.playedCards
                .filter { $0.card.suit == trumpSuit }
                .map { $0.card.strength(mode: mode, trumpSuit: trumpSuit) }
                .max()

            if let highestTrumpInTrick {
                let overtrumpingCards = trumpCards.filter { $0.strength(mode: mode, trumpSuit: trumpSuit) > highestTrumpInTrick }
                if !overtrumpingCards.isEmpty {
                    return overtrumpingCards
                }
            }
        }

        return trumpCards
    }

    /// يتحقق من قانونية لعب ورقة محددة، ويُعيد خطأ موضّحًا عند المخالفة.
    public static func validate(card: PlayingCard, hand: [PlayingCard], trick: Trick?, mode: GameMode, trumpSuit: Suit?, rules: BalootRulesConfiguration) -> Result<Void, IllegalMoveReason> {
        guard hand.contains(card) else {
            return .failure(.cardNotInHand)
        }

        let legal = legalCards(hand: hand, trick: trick, mode: mode, trumpSuit: trumpSuit, rules: rules)
        guard legal.contains(card) else {
            if let trick, let requiredSuit = trick.requiredSuit, hand.contains(where: { $0.suit == requiredSuit }) {
                return .failure(.mustFollowSuit)
            }
            if mode == .hokum, rules.mustOvertrump {
                return .failure(.mustOvertrump)
            }
            return .failure(.mustPlayTrumpWhenVoidOfSuit)
        }
        return .success(())
    }
}
