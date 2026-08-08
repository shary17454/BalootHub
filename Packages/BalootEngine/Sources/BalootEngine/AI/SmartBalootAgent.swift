import Foundation

/// لاعب آلي بسياسة متقدمة تحاكي أساسيات لعب البلوت الجماعي:
///
/// 1. **وعي بالشريك**: يعرف من شريكه (نفس الفريق)، فإن كان الشريك كاسبًا للأكلة
///    بورقة مضمونة "حمّله" النقاط بدل منافسته، ولا يقطع عليه أبدًا.
/// 2. **ذاكرة الأوراق**: يتتبع كل ما لُعب في الأكلات السابقة والحالية، فيعرف إن كانت
///    ورقته "بص" (أعلى ما تبقى من نوعها بيد الآخرين) قبل أن يراهن عليها.
/// 3. **وعي بالمركز**: اللاعب الرابع يرى الأكلة كاملة فيكسبها بأرخص ورقة كافية،
///    أو يحمّل الشريك إن كان كاسبًا.
/// 4. **إدارة الحكم**: يسحب حكم الخصوم عندما يملك أغلبية الحكم، ولا يهدر
///    الولد والتسعة في أكلات رخيصة.
/// 5. **مزايدة تقييمية**: يقيّم اليد لكل نوع حكم محتمل ولصن معًا ويختار الأعلى،
///    بدل عدّ الأوراق فقط.
///
/// السياسة حتمية (بلا عشوائية)، فتبقى قابلة للاختبار والتكرار بنفس المدخلات.
public struct SmartBalootAgent: BalootAgent, Sendable {
    public init() {}

    // MARK: - المزايدة

    public func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?) {
        // تقييم صن: الآسات والعشرات هي مصدر الأكلات، والأنواع الطويلة تسند بعضها.
        var sunScore = 0
        for card in hand {
            switch card.rank {
            case .ace: sunScore += 11
            case .ten: sunScore += 7
            case .king: sunScore += 3
            case .queen: sunScore += 1
            default: break
            }
        }

        // تقييم كل نوع كحكم: الولد أثمن ورقة، ثم التسعة، ويهم طول الحكم وآسات الأنواع الجانبية.
        var bestHokum: (suit: Suit, score: Int)?
        for suit in Suit.allCases {
            let trumps = hand.filter { $0.suit == suit }
            guard trumps.count >= 3 else { continue }

            var score = trumps.count * 4
            if trumps.contains(where: { $0.rank == .jack }) { score += 13 }
            if trumps.contains(where: { $0.rank == .nine }) { score += 8 }
            if trumps.contains(where: { $0.rank == .ace }) { score += 4 }
            // آسات الأنواع الجانبية أكلات شبه مضمونة بعد سحب الحكم.
            for side in Suit.allCases where side != suit {
                let sideCards = hand.filter { $0.suit == side }
                if sideCards.contains(where: { $0.rank == .ace }) { score += 5 }
                // نوع جانبي فارغ أو وحيد = فرصة قطع مبكرة.
                if sideCards.count <= 1 { score += 3 }
            }
            if let current = bestHokum {
                if score > current.score { bestHokum = (suit, score) }
            } else {
                bestHokum = (suit, score)
            }
        }

        if let hokum = bestHokum, hokum.score > sunScore + 4 {
            return (.hokum, hokum.suit)
        }
        return (.sun, nil)
    }

    // MARK: - اللعب

    public func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard {
        guard let fallback = legalCards.first else { return Self.fallbackCard(hand: hand) }
        guard let mode = state.mode, let myID = state.currentTurnPlayerID else { return fallback }
        let trumpSuit = state.trumpSuit
        let memory = CardMemory(state: state, myHand: hand)

        guard let trick = state.currentTrick, !trick.playedCards.isEmpty else {
            return lead(legalCards: legalCards, mode: mode, trumpSuit: trumpSuit, memory: memory)
        }

        let isLast = trick.playedCards.count == 3
        let winning = currentWinner(of: trick, mode: mode, trumpSuit: trumpSuit)

        if let winning, isPartner(winning.playerID, of: myID, in: state) {
            let partnerCard = winning.card
            // الشريك كاسب: لا نقطع عليه أبدًا. نحمّله النقاط إن كانت ورقته مضمونة
            // (نحن الأخير، أو ورقته بص لا يعلوه إلا حكم لم يعد موجودًا).
            let partnerSecure = isLast || memory.isBoss(partnerCard, mode: mode, trumpSuit: trumpSuit)
            if partnerSecure {
                return highestPointCard(in: legalCards, mode: mode, trumpSuit: trumpSuit)
            }
            // ورقة الشريك غير مضمونة وخلفنا خصم: نعزز بأعلى ورقة إن كانت بصًّا،
            // وإلا نمرر أرخص ورقة ونترك القرار له.
            if let boss = bossCard(in: legalCards, mode: mode, trumpSuit: trumpSuit, memory: memory) {
                return boss
            }
            return cheapestCard(in: legalCards, mode: mode, trumpSuit: trumpSuit)
        }

        // الخصم كاسب حاليًا: نحاول الكسب.
        let bestStrength = winning.map { effectiveStrength($0.card, mode: mode, trumpSuit: trumpSuit) } ?? -1
        let winners = legalCards.filter { effectiveStrength($0, mode: mode, trumpSuit: trumpSuit) > bestStrength }

        if let cheapWinner = weakestByRank(in: winners, mode: mode, trumpSuit: trumpSuit) {
            if isLast {
                // الأخير يرى كل شيء: يكسب بأرخص ورقة كافية.
                return cheapWinner
            }
            // لسنا الأخير: نكسب بورقة بص مضمونة إن وُجدت (لن يعلوها أحد)،
            // وإلا بأرخص كاسبة — مع تجنّب إهدار كبار الحكم على أكلة فقيرة النقاط.
            if let boss = winners.first(where: { memory.isBoss($0, mode: mode, trumpSuit: trumpSuit) }) {
                return boss
            }
            let trickPoints = trick.playedCards.reduce(0) { $0 + $1.card.points(mode: mode, trumpSuit: trumpSuit) }
            let isBigTrump = mode == .hokum && cheapWinner.suit == trumpSuit && (cheapWinner.rank == .jack || cheapWinner.rank == .nine)
            if isBigTrump && trickPoints < 8, legalCards.count > winners.count {
                // الأكلة رخيصة وأرخص كاسبة هي ولد/تسعة الحكم: نحتفظ بها لأكلة أثمن.
                return cheapestCard(in: legalCards.filter { !winners.contains($0) }, mode: mode, trumpSuit: trumpSuit)
            }
            return cheapWinner
        }

        // لا نستطيع الكسب: نتخلص من أرخص ورقة (وأقلها نقاطًا) محتفظين بالبصوص.
        return cheapestCard(in: legalCards, mode: mode, trumpSuit: trumpSuit)
    }

    // MARK: - قيادة الأكلة

    private func lead(legalCards: [PlayingCard], mode: GameMode, trumpSuit: Suit?, memory: CardMemory) -> PlayingCard {
        // في حكم: إن كنا نملك أغلبية ما تبقى من الحكم نسحبه لتجريد الخصوم.
        if mode == .hokum, let trumpSuit {
            let myTrumps = legalCards.filter { $0.suit == trumpSuit }
            let outsideTrumps = memory.unseenCount(of: trumpSuit)
            if !myTrumps.isEmpty, outsideTrumps > 0, myTrumps.count > outsideTrumps,
               let bossTrump = myTrumps.first(where: { memory.isBoss($0, mode: mode, trumpSuit: trumpSuit) }) {
                return bossTrump
            }
        }
        // نقود بورقة بص من نوع جانبي إن وُجدت (أكلة شبه مضمونة).
        let sideCards = legalCards.filter { mode == .sun || $0.suit != trumpSuit }
        if let boss = bossCard(in: sideCards, mode: mode, trumpSuit: trumpSuit, memory: memory) {
            return boss
        }
        if let boss = bossCard(in: legalCards, mode: mode, trumpSuit: trumpSuit, memory: memory) {
            return boss
        }
        // لا بصوص: نقود بأرخص ورقة ونحفظ القوة لاحقًا.
        return cheapestCard(in: legalCards, mode: mode, trumpSuit: trumpSuit)
    }

    // MARK: - أدوات مساعدة

    private func currentWinner(of trick: Trick, mode: GameMode, trumpSuit: Suit?) -> PlayedCard? {
        guard let required = trick.requiredSuit else { return trick.playedCards.first }
        let hasTrump = mode == .hokum && trumpSuit != nil && trick.playedCards.contains { $0.card.suit == trumpSuit }
        let eligible = trick.playedCards.filter {
            hasTrump ? $0.card.suit == trumpSuit : $0.card.suit == required
        }
        return eligible.max {
            $0.card.strength(mode: mode, trumpSuit: trumpSuit) < $1.card.strength(mode: mode, trumpSuit: trumpSuit)
        }
    }

    private func isPartner(_ other: Player.ID, of mine: Player.ID, in state: GameState) -> Bool {
        guard other != mine,
              let a = state.player(id: mine), let b = state.player(id: other) else { return false }
        return a.teamID == b.teamID
    }

    private func bossCard(in cards: [PlayingCard], mode: GameMode, trumpSuit: Suit?, memory: CardMemory) -> PlayingCard? {
        cards.first { memory.isBoss($0, mode: mode, trumpSuit: trumpSuit) }
    }

    private func highestPointCard(in cards: [PlayingCard], mode: GameMode, trumpSuit: Suit?) -> PlayingCard {
        cards.max {
            ($0.points(mode: mode, trumpSuit: trumpSuit), $0.strength(mode: mode, trumpSuit: trumpSuit))
                < ($1.points(mode: mode, trumpSuit: trumpSuit), $1.strength(mode: mode, trumpSuit: trumpSuit))
        } ?? Self.fallbackCard(hand: cards)
    }

    private func cheapestCard(in cards: [PlayingCard], mode: GameMode, trumpSuit: Suit?) -> PlayingCard {
        cards.min {
            ($0.points(mode: mode, trumpSuit: trumpSuit), $0.strength(mode: mode, trumpSuit: trumpSuit))
                < ($1.points(mode: mode, trumpSuit: trumpSuit), $1.strength(mode: mode, trumpSuit: trumpSuit))
        } ?? Self.fallbackCard(hand: cards)
    }

    private func rankValue(_ card: PlayingCard, mode: GameMode, trumpSuit: Suit?) -> Int {
        card.strength(mode: mode, trumpSuit: trumpSuit)
    }

    /// أضعف ورقة بالقوة (لا بالنقاط) ضمن مجموعة، أو `nil` إن كانت المجموعة فارغة.
    private func weakestByRank(in cards: [PlayingCard], mode: GameMode, trumpSuit: Suit?) -> PlayingCard? {
        cards.min { rankValue($0, mode: mode, trumpSuit: trumpSuit) < rankValue($1, mode: mode, trumpSuit: trumpSuit) }
    }

    private func effectiveStrength(_ card: PlayingCard, mode: GameMode, trumpSuit: Suit?) -> Int {
        let base = card.strength(mode: mode, trumpSuit: trumpSuit)
        return (mode == .hokum && card.suit == trumpSuit) ? base + 100 : base
    }
}

/// ذاكرة أوراق الجولة: تحسب ما لم يُرَ بعد (بيد الخصوم والشريك) لتحديد "البصوص".
private struct CardMemory {
    /// الأوراق غير المرئية: كل الحزمة ناقص يدي وناقص كل ما لُعب.
    let unseen: [PlayingCard]

    /// المقارنة على ``PlayingCard`` مباشرة (تساويها معرّف على النوع + القيمة)
    /// بدل مفاتيح نصية: هذه البنية تُبنى مع كل قرار ورقة، وداخل محاكاة
    /// ``ExpertBalootAgent`` تُبنى آلاف المرات لكل نقلة واحدة.
    init(state: GameState, myHand: [PlayingCard]) {
        var seen = Set(myHand)
        for trick in state.completedTricks {
            for played in trick.playedCards { seen.insert(played.card) }
        }
        if let current = state.currentTrick {
            for played in current.playedCards { seen.insert(played.card) }
        }
        var remaining: [PlayingCard] = []
        remaining.reserveCapacity(Deck.fullCount - seen.count)
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = PlayingCard(suit: suit, rank: rank)
                if !seen.contains(card) { remaining.append(card) }
            }
        }
        unseen = remaining
    }

    /// هل الورقة "بص": لا توجد ورقة غير مرئية من نفس نوعها أقوى منها؟
    /// (في حكم، البص الجانبي يظل عرضة للقطع — تُعالَج تلك الحالة لدى المستدعي.)
    func isBoss(_ card: PlayingCard, mode: GameMode, trumpSuit: Suit?) -> Bool {
        let myStrength = card.strength(mode: mode, trumpSuit: trumpSuit)
        return !unseen.contains {
            $0.suit == card.suit && $0.strength(mode: mode, trumpSuit: trumpSuit) > myStrength
        }
    }

    /// عدد الأوراق غير المرئية من نوع معيّن.
    func unseenCount(of suit: Suit) -> Int {
        unseen.count { $0.suit == suit }
    }
}
