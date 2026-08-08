import Foundation

/// لاعب آلي بمستوى متقدم يعتمد **البحث بالمحاكاة** (Determinized Monte Carlo) بدل
/// القواعد الثابتة وحدها.
///
/// المشكلة التي يحلها: البلوت لعبة **معلومات ناقصة** — لا يرى اللاعب أوراق الآخرين.
/// لذا يولّد الوكيل عدة "توزيعات محتملة" لما تبقى من أوراق، يلعب كل توزيعة حتى نهاية
/// الجولة، ثم يختار الورقة التي حققت **أعلى متوسط نقاط** لفريقه عبر كل السيناريوهات.
///
/// التوزيعات المولَّدة تحترم ما استُنتج من اللعب فعلًا:
/// - عدد الأوراق المتبقية بيد كل لاعب.
/// - **الأنواع التي انكشف خلوّها**: من لم يتبع نوعًا مطلوبًا سابقًا لا يُعطى منه ورقة.
///
/// المحاكاة تستخدم ``SmartBalootAgent`` كسياسة لعب داخلية، فالنتيجة "بحث فوق خبرة"
/// لا بحث أعمى. المولّد العشوائي ببذرة ثابتة، فالقرارات قابلة للتكرار والاختبار.
public struct ExpertBalootAgent: BalootAgent, Sendable {
    /// عدد التوزيعات المحتملة التي تُحاكى لكل ورقة مرشحة.
    /// 8 توزيعات توازن بين القوة وسرعة الاستجابة على الجهاز.
    private let samples: Int
    private let policy = SmartBalootAgent()

    public init(samples: Int = 8) {
        self.samples = max(1, samples)
    }

    // المزايدة تعتمد تقييم اليد نفسه المستخدم في الوكيل الذكي.
    public func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?) {
        policy.chooseMode(hand: hand, state: state)
    }

    public func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard {
        guard let fallback = legalCards.first else { return Self.fallbackCard(hand: hand) }
        // ورقة واحدة ⇒ لا قرار. وفي المراحل غير اللعب نرجع للسياسة المباشرة.
        guard legalCards.count > 1, state.phase == .playing else { return fallback }
        guard let myID = state.currentTurnPlayerID,
              let myTeamID = state.player(id: myID)?.teamID
        else { return policy.chooseCard(hand: hand, legalCards: legalCards, state: state) }

        let unseen = unseenCards(state: state, myHand: hand)
        let voids = discoveredVoids(state: state)

        var bestCard = fallback
        var bestAverage = -Double.infinity

        for candidate in legalCards {
            var total = 0
            var completed = 0
            for sampleIndex in 0..<samples {
                // بذرة مشتقة من موضع اللعب والورقة المرشحة: عشوائية متنوعة لكنها حتمية.
                var rng = SeededGenerator(seed: seed(for: candidate, state: state, sample: sampleIndex))
                guard let determinized = determinize(state: state, myID: myID, myHand: hand,
                                                    unseen: unseen, voids: voids, using: &rng)
                else { continue }
                guard let afterPlay = try? GameEngine.apply(.playCard(playerID: myID, card: candidate), to: determinized)
                else { continue }
                total += playout(from: afterPlay, myTeamID: myTeamID)
                completed += 1
            }
            guard completed > 0 else { continue }
            let average = Double(total) / Double(completed)
            if average > bestAverage {
                bestAverage = average
                bestCard = candidate
            }
        }

        // لو تعذّرت كل المحاكاة (حالة نادرة) نرجع لقرار السياسة المباشرة.
        return bestAverage == -.infinity
            ? policy.chooseCard(hand: hand, legalCards: legalCards, state: state)
            : bestCard
    }

    // MARK: - المحاكاة

    /// يكمل الجولة بسياسة الوكيل الذكي لكل اللاعبين، ويعيد نقاط فريقي في النهاية.
    private func playout(from state: GameState, myTeamID: Team.ID) -> Int {
        var current = state
        var steps = 0
        while current.phase == .playing, steps < 40 {
            steps += 1
            guard let playerID = current.currentTurnPlayerID,
                  let hand = current.hands[playerID], !hand.isEmpty else { break }
            let legal = LegalMoveValidator.legalCards(
                hand: hand, trick: current.currentTrick,
                mode: current.mode ?? .sun, trumpSuit: current.trumpSuit, rules: current.rules
            )
            guard !legal.isEmpty else { break }
            let card = policy.chooseCard(hand: hand, legalCards: legal, state: current)
            guard let next = try? GameEngine.apply(.playCard(playerID: playerID, card: card), to: current) else { break }
            current = next
        }
        if current.phase == .scoring, let finished = try? GameEngine.apply(.finishRound, to: current) {
            current = finished
        }
        return current.lastRoundResult?.teamPoints[myTeamID] ?? current.teamTrickPoints[myTeamID] ?? 0
    }

    /// يوزّع الأوراق غير المرئية على بقية اللاعبين بأعداد صحيحة ومع احترام الأنواع المنكشف خلوّها.
    private func determinize(
        state: GameState, myID: Player.ID, myHand: [PlayingCard],
        unseen: [PlayingCard], voids: [Player.ID: Set<Suit>],
        using rng: inout SeededGenerator
    ) -> GameState? {
        let others = state.players.map(\.id).filter { $0 != myID }
        var needed: [Player.ID: Int] = [:]
        for id in others { needed[id] = state.hands[id]?.count ?? 0 }
        guard needed.values.reduce(0, +) == unseen.count else { return nil }

        // نوزّع الأوراق الأكثر تقييدًا أولًا (أقل عدد لاعبين مؤهلين) لتقليل الانسداد.
        var pool = unseen.shuffled(using: &rng)
        pool.sort { lhs, rhs in
            let l = others.count { !(voids[$0]?.contains(lhs.suit) ?? false) }
            let r = others.count { !(voids[$0]?.contains(rhs.suit) ?? false) }
            return l < r
        }

        var assigned: [Player.ID: [PlayingCard]] = [:]
        for id in others { assigned[id] = [] }

        for card in pool {
            let eligible = others.filter { id in
                (assigned[id]?.count ?? 0) < (needed[id] ?? 0)
                    && !(voids[id]?.contains(card.suit) ?? false)
            }
            // لو انسدّ التوزيع بسبب قيود الخلوّ، نتجاهل القيد لهذه الورقة بدل إسقاط العيّنة.
            let target = eligible.randomElement(using: &rng)
                ?? others.filter { (assigned[$0]?.count ?? 0) < (needed[$0] ?? 0) }.randomElement(using: &rng)
            guard let target else { return nil }
            assigned[target, default: []].append(card)
        }

        var determinized = state
        determinized.hands[myID] = myHand
        for id in others { determinized.hands[id] = assigned[id] ?? [] }
        return determinized
    }

    // MARK: - الاستنتاج من اللعب السابق

    /// كل الأوراق التي لم يرها هذا اللاعب: الحزمة كاملة ناقص يده وناقص كل ما لُعب.
    ///
    /// المقارنة تتم على ``PlayingCard`` مباشرة لأن تساويها وتجزئتها معرّفان على
    /// (النوع + القيمة)، فلا حاجة لبناء مفاتيح نصية في مسار يُستدعى آلاف المرات
    /// داخل المحاكاة.
    private func unseenCards(state: GameState, myHand: [PlayingCard]) -> [PlayingCard] {
        var seen = Set(myHand)
        for trick in state.completedTricks {
            for played in trick.playedCards { seen.insert(played.card) }
        }
        for played in state.currentTrick?.playedCards ?? [] { seen.insert(played.card) }

        var result: [PlayingCard] = []
        result.reserveCapacity(Deck.fullCount - seen.count)
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = PlayingCard(suit: suit, rank: rank)
                if !seen.contains(card) { result.append(card) }
            }
        }
        return result
    }

    /// من لم يتبع النوع المطلوب في أكلة سابقة فهو خالٍ منه — معلومة مؤكدة تُقيّد التوزيع.
    private func discoveredVoids(state: GameState) -> [Player.ID: Set<Suit>] {
        var voids: [Player.ID: Set<Suit>] = [:]
        var tricks = state.completedTricks
        if let current = state.currentTrick { tricks.append(current) }

        for trick in tricks {
            guard let required = trick.requiredSuit else { continue }
            for played in trick.playedCards where played.card.suit != required {
                voids[played.playerID, default: []].insert(required)
            }
        }
        return voids
    }

    /// بذرة حتمية مشتقة من موضع اللعب الحالي، فلا تتكرر نفس المحاكاة بين المرشحين.
    ///
    /// تعتمد على ``Suit/ordinal`` و``Rank/ordinal`` لا على `hashValue`: قيم التجزئة
    /// في Swift مبذورة عشوائيًا مع كل تشغيل، فاستخدامها هنا كان يجعل قرارات الوكيل
    /// تختلف بين تشغيل وآخر بنفس المدخلات — عكس ما يوثّقه النوع تمامًا.
    private func seed(for card: PlayingCard, state: GameState, sample: Int) -> UInt64 {
        var value: UInt64 = 0x9E37_79B9_7F4A_7C15
        value ^= UInt64(state.completedTricks.count &* 31)
        value ^= UInt64((state.currentTrick?.playedCards.count ?? 0) &* 131)
        value ^= UInt64(card.suit.ordinal) &<< 8
        value ^= UInt64(card.rank.ordinal) &<< 12
        value ^= UInt64(sample &* 7_919) &<< 16
        return value | 1
    }
}
