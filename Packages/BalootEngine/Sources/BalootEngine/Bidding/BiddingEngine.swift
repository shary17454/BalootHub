import Foundation

/// أسباب رفض فعل متعلق بالمزايدة أو الإعلان.
public enum BiddingError: String, Error, Sendable, Equatable {
    /// المزايدة غير متاحة في المرحلة الحالية.
    case notBiddingStage
    /// المزايدة المطلوبة غير قانونية الآن (مثل شراء حكم بلون غير مسموح).
    case illegalBid
    /// جولة المضاعفة غير مفتوحة.
    case notDoublingStage
    /// هذا اللاعب لا يملك حق المضاعفة الآن.
    case notEligibleToRaise
    /// المستوى المطلوب ليس التصعيد التالي المسموح.
    case invalidMultiplierLevel
    /// المضاعفة مُقفلة أو بلغت سقفها.
    case multiplierClosed
    /// المضاعفات معطّلة في هذه القواعد.
    case multipliersDisabled
    /// القفل غير مسموح في هذه القواعد أو من هذا اللاعب.
    case lockNotAllowed
    /// الإعلان غير متاح في المرحلة الحالية.
    case notDeclaringStage
    /// المشروع المُعلن غير موجود فعلًا في يد اللاعب.
    case undetectedProject
    /// المشروع نفسه أُرسل أكثر من مرة في إعلان واحد أو سبق إعلانه.
    case duplicateProjectDeclaration
    /// أسلوب المزايدة الحالي لا يسمح بهذا الفعل.
    case unsupportedInBiddingStyle
}

/// منطق دورة المزايدة كاملة: الجولتان، المضاعفة، توزيع ما تبقّى، ومرحلة الإعلان.
///
/// مفصول عن ``GameEngine`` لأنه أطول جزء في المحرك وأكثره قواعدَ، لكنه يبقى
/// دالّات نقية تعمل على `inout GameState` فلا يكسر كون المحرك آلة حالة.
enum BiddingEngine {

    // MARK: - التوزيع

    /// يوزّع الأوراق حسب أسلوب المزايدة المختار.
    static func deal(seed: UInt64, state: inout GameState) throws {
        var deck = Deck()
        var generator = SeededGenerator(seed: seed)
        deck.shuffle(using: &generator)

        resetRoundState(&state)

        switch state.rules.biddingStyle {
        case .simple:
            try dealAll(deck: deck, state: &state)
            state.bidding = BiddingState(stage: .firstRound)
            state.phase = .bidding
            state.currentTurnPlayerID = state.firstToActPlayerID

        case .full:
            try dealOpening(deck: deck, state: &state)
            state.phase = .bidding
            state.currentTurnPlayerID = state.firstToActPlayerID
        }
    }

    /// يصفّر كل بقايا الجولة السابقة. بدونه تتراكم أكلات ومشاريع جولة قديمة على
    /// جولة جديدة وُزّعت فوق نفس الحالة — وهو ما يفعله ``GameEngine/replay`` بالضبط.
    private static func resetRoundState(_ state: inout GameState) {
        state.completedTricks = []
        state.currentTrick = nil
        state.teamTrickPoints = [:]
        state.lastRoundResult = nil
        state.mode = nil
        state.trumpSuit = nil
        state.declaredProjects = []
        state.awardedProjects = []
        state.kabootTeamID = nil
        state.undealtCards = []
    }

    /// توزيع الثماني أوراق كاملة (النمط المبسّط).
    private static func dealAll(deck: Deck, state: inout GameState) throws {
        guard state.players.count == 4 else { throw GameEngineError.unknownPlayer }
        let dealtHands = deck.dealEqually()
        var hands: [Player.ID: [PlayingCard]] = [:]
        for (seat, cards) in zip(SeatPosition.allCases, dealtHands) {
            if let player = state.player(at: seat) { hands[player.id] = cards }
        }
        state.hands = hands
        state.originalHands = hands
    }

    /// التوزيع الافتتاحي للنمط الكامل: خمس أوراق لكل لاعب، وورقة مكشوفة، والباقي مؤجَّل.
    private static func dealOpening(deck: Deck, state: inout GameState) throws {
        guard state.players.count == 4 else { throw GameEngineError.unknownPlayer }
        let opening = max(1, min(state.rules.cardsBeforeBidding, 7))
        var cursor = 0
        var hands: [Player.ID: [PlayingCard]] = [:]

        // التوزيع يبدأ من صاحب الدور الأول (يمين الموزّع) بترتيب الأدوار نفسه.
        for player in state.playersInTurnOrder(startingAt: state.dealerSeat.next) {
            hands[player.id] = Array(deck.cards[cursor..<(cursor + opening)])
            cursor += opening
        }

        let upCard = deck.cards[cursor]
        cursor += 1

        state.hands = hands
        // `originalHands` لا تُملأ الآن: اليد لم تكتمل بعد، واكتشاف المشاريع على يد
        // ناقصة كان سيُسقط كل مشروع يعتمد على الأوراق الثلاث الأخيرة.
        state.originalHands = [:]
        state.undealtCards = Array(deck.cards[cursor...])
        state.bidding = BiddingState(stage: .firstRound, upCard: upCard)
    }

    // MARK: - المزايدة

    static func placeBid(playerID: Player.ID, bid: Bid, state: inout GameState) throws {
        guard state.rules.biddingStyle == .full else {
            throw GameEngineError.bidding(.unsupportedInBiddingStyle)
        }
        guard state.phase == .bidding else {
            throw GameEngineError.wrongPhase(expected: .bidding, actual: state.phase)
        }
        guard state.bidding.stage == .firstRound || state.bidding.stage == .secondRound else {
            throw GameEngineError.bidding(.notBiddingStage)
        }
        guard state.player(id: playerID) != nil else { throw GameEngineError.unknownPlayer }
        guard state.currentTurnPlayerID == playerID else { throw GameEngineError.notPlayersTurn }
        guard state.bidding.legalBids(rules: state.rules).contains(bid) else {
            throw GameEngineError.bidding(.illegalBid)
        }

        state.bidding.bids.append(BidRecord(playerID: playerID, bid: bid, round: state.bidding.roundNumber))
        if bid.isBid {
            state.bidding.declarerID = playerID
            state.bidding.mode = bid.mode
            state.bidding.trumpSuit = bid.trumpSuit
            state.bidding.consecutivePasses = 0
        } else {
            state.bidding.consecutivePasses += 1
        }

        try advanceBiddingTurn(state: &state)
    }

    /// ينقل الدور داخل جولة المزايدة، أو يُنهي الجولة إذا تكلّم الجميع.
    private static func advanceBiddingTurn(state: inout GameState) throws {
        let everyoneSpoke = state.bidding.actionsInCurrentRound >= state.players.count
        // شراء الصن لا يعلوه شيء، فلا معنى لإكمال الدورة بعده.
        let sunLocksRound = state.bidding.currentBid?.bid.mode == .sun

        if everyoneSpoke || sunLocksRound {
            try finishBiddingRound(state: &state)
            return
        }

        guard let currentID = state.currentTurnPlayerID,
              let current = state.player(id: currentID),
              let next = TurnManager.nextPlayer(after: current, in: state.players) else {
            throw GameEngineError.unknownPlayer
        }
        state.currentTurnPlayerID = next.id
    }

    /// ينهي جولة مزايدة: ينتقل إلى جولة الأشكال، أو يستقر على شراء، أو يُعلن دورة ميتة.
    private static func finishBiddingRound(state: inout GameState) throws {
        if state.bidding.currentBid != nil {
            try settleBid(state: &state)
            return
        }

        switch state.bidding.stage {
        case .firstRound:
            state.bidding.stage = .secondRound
            state.bidding.consecutivePasses = 0
            state.currentTurnPlayerID = state.firstToActPlayerID
        case .secondRound:
            voidRound(state: &state)
        default:
            throw GameEngineError.bidding(.notBiddingStage)
        }
    }

    /// دورة ميتة: مرّ الأربعة في الجولتين. لا نقاط لأي فريق، وينتقل الموزّع.
    private static func voidRound(state: inout GameState) {
        state.dealerSeat = state.dealerSeat.next
        state.bidding.stage = .voided
        state.mode = nil
        state.trumpSuit = nil
        state.currentTurnPlayerID = nil
        var zeros: [Team.ID: Int] = [:]
        for team in state.teams { zeros[team.id] = 0 }
        state.lastRoundResult = RoundScoreResult(teamPoints: zeros, winningTeamID: nil)
        state.phase = .finished
    }

    /// بعد استقرار الشراء: إما فتح جولة المضاعفة، أو المضي مباشرة للتوزيع والإعلان.
    private static func settleBid(state: inout GameState) throws {
        guard let mode = state.bidding.mode else { throw GameEngineError.bidding(.illegalBid) }

        let multipliersApply = state.rules.multipliersEnabled
            && (mode == .hokum || state.rules.multiplierAllowedInSun)

        if multipliersApply, let firstOpponent = firstEligibleRaiser(state: state) {
            state.bidding.stage = .doubling
            state.bidding.doublingPasses = 0
            state.currentTurnPlayerID = firstOpponent
        } else {
            try completeBidding(state: &state)
        }
    }

    // MARK: - المضاعفة

    /// الفريق الذي يملك حق التصعيد الآن: خصوم المشتري ابتداءً، ثم الفريق المقابل
    /// لصاحب آخر مضاعفة (فلا يضاعف فريق على نفسه).
    static func eligibleRaisingTeamID(state: GameState) -> Team.ID? {
        guard let declaringTeam = state.declaringTeamID else { return nil }
        guard let requester = state.bidding.multiplierRequesterTeamID else {
            return state.opposingTeamID(of: declaringTeam)
        }
        return state.opposingTeamID(of: requester)
    }

    /// حركات المضاعفة القانونية للاعب محدد الآن.
    ///
    /// تعكس هذه الدالة شروط `raiseMultiplier` و`passMultiplier` و`lockMultiplier`
    /// نفسها، لكنها لا تغيّر الحالة ولا ترمي أخطاء، لتستخدمها الواجهة والـAI قبل
    /// محاولة تطبيق الفعل.
    static func legalMultiplierActions(for playerID: Player.ID, state: GameState) -> [LegalMultiplierAction] {
        guard state.rules.multipliersEnabled,
              state.phase == .bidding,
              state.bidding.stage == .doubling,
              let player = state.player(id: playerID)
        else { return [] }

        var actions: [LegalMultiplierAction] = []

        if state.currentTurnPlayerID == playerID,
           player.teamID == eligibleRaisingTeamID(state: state) {
            actions.append(.pass)

            if !state.bidding.isLocked,
               let next = state.bidding.multiplier.next,
               next <= state.rules.maximumMultiplier {
                actions.append(.raise(next))
            }
        }

        if state.rules.lockEnabled,
           !state.bidding.isLocked,
           state.bidding.multiplier != .none,
           player.teamID == state.bidding.multiplierRequesterTeamID {
            actions.append(.lock)
        }

        return actions
    }

    private static func firstEligibleRaiser(state: GameState) -> Player.ID? {
        guard let teamID = eligibleRaisingTeamID(state: state),
              let declarer = state.declarer else { return nil }
        return state.playersInTurnOrder(startingAt: declarer.seat.next)
            .first { $0.teamID == teamID }?.id
    }

    static func raiseMultiplier(playerID: Player.ID, level: Multiplier, state: inout GameState) throws {
        try validateDoublingTurn(playerID: playerID, state: state)
        guard !state.bidding.isLocked else { throw GameEngineError.bidding(.multiplierClosed) }
        guard let next = state.bidding.multiplier.next, next <= state.rules.maximumMultiplier else {
            throw GameEngineError.bidding(.multiplierClosed)
        }
        guard level == next else { throw GameEngineError.bidding(.invalidMultiplierLevel) }
        guard let player = state.player(id: playerID) else { throw GameEngineError.unknownPlayer }
        guard player.teamID == eligibleRaisingTeamID(state: state) else {
            throw GameEngineError.bidding(.notEligibleToRaise)
        }

        state.bidding.multiplier = level
        state.bidding.multiplierRequesterTeamID = player.teamID
        state.bidding.doublingPasses = 0

        // بلوغ السقف يُنهي التصعيد فورًا: لا يوجد ما يُصعَّد إليه.
        if state.bidding.multiplier.next == nil || state.bidding.multiplier >= state.rules.maximumMultiplier {
            try completeBidding(state: &state)
            return
        }
        try passDoublingTurn(state: &state)
    }

    static func passMultiplier(playerID: Player.ID, state: inout GameState) throws {
        try validateDoublingTurn(playerID: playerID, state: state)
        guard let player = state.player(id: playerID),
              player.teamID == eligibleRaisingTeamID(state: state) else {
            throw GameEngineError.bidding(.notEligibleToRaise)
        }
        state.bidding.doublingPasses += 1

        // مرّ لاعبا الفريق صاحب الحق ⇒ لا مضاعفة إضافية.
        if state.bidding.doublingPasses >= 2 {
            try completeBidding(state: &state)
            return
        }
        try passDoublingTurn(state: &state)
    }

    static func lockMultiplier(playerID: Player.ID, state: inout GameState) throws {
        try validateLock(playerID: playerID, state: state)
        guard state.rules.lockEnabled else { throw GameEngineError.bidding(.lockNotAllowed) }
        // القفل يقوله من يملك المضاعفة الحالية ليمنع تصعيد الخصم عليها،
        // فلا معنى له قبل وجود مضاعفة أصلًا.
        guard state.bidding.multiplier != .none else { throw GameEngineError.bidding(.lockNotAllowed) }
        guard let player = state.player(id: playerID),
              player.teamID == state.bidding.multiplierRequesterTeamID else {
            throw GameEngineError.bidding(.lockNotAllowed)
        }
        state.bidding.isLocked = true
        try completeBidding(state: &state)
    }

    /// القفل ليس تصعيدًا من الفريق صاحب الدور الحالي، بل فعل جانبي للفريق الذي
    /// يملك المضاعفة القائمة. بعد الدبل ينتقل حق التصعيد للفريق المقابل، ولو اشترطنا
    /// `currentTurnPlayerID` هنا فلن يستطيع صاحب الدبل قفله أبدًا.
    private static func validateLock(playerID: Player.ID, state: GameState) throws {
        guard state.rules.multipliersEnabled else { throw GameEngineError.bidding(.multipliersDisabled) }
        guard state.phase == .bidding else {
            throw GameEngineError.wrongPhase(expected: .bidding, actual: state.phase)
        }
        guard state.bidding.stage == .doubling else { throw GameEngineError.bidding(.notDoublingStage) }
        guard state.player(id: playerID) != nil else { throw GameEngineError.unknownPlayer }
    }

    private static func validateDoublingTurn(playerID: Player.ID, state: GameState) throws {
        guard state.rules.multipliersEnabled else { throw GameEngineError.bidding(.multipliersDisabled) }
        guard state.phase == .bidding else {
            throw GameEngineError.wrongPhase(expected: .bidding, actual: state.phase)
        }
        guard state.bidding.stage == .doubling else { throw GameEngineError.bidding(.notDoublingStage) }
        guard state.player(id: playerID) != nil else { throw GameEngineError.unknownPlayer }
        guard state.currentTurnPlayerID == playerID else { throw GameEngineError.notPlayersTurn }
    }

    /// ينقل دور المضاعفة إلى اللاعب التالي من الفريق صاحب الحق.
    private static func passDoublingTurn(state: inout GameState) throws {
        guard let teamID = eligibleRaisingTeamID(state: state),
              let currentID = state.currentTurnPlayerID,
              let current = state.player(id: currentID) else {
            try completeBidding(state: &state)
            return
        }
        let candidates = state.playersInTurnOrder(startingAt: current.seat.next)
            .filter { $0.teamID == teamID }
        guard let next = candidates.first else {
            try completeBidding(state: &state)
            return
        }
        state.currentTurnPlayerID = next.id
    }

    // MARK: - إنهاء المزايدة

    /// يثبّت نتيجة المزايدة، يوزّع الأوراق المتبقية، ثم يفتح مرحلة الإعلان أو اللعب.
    static func completeBidding(state: inout GameState) throws {
        guard let mode = state.bidding.mode, let declarer = state.declarer else {
            throw GameEngineError.bidding(.illegalBid)
        }

        state.bidding.stage = .completed
        state.mode = mode
        state.trumpSuit = state.bidding.trumpSuit

        try dealRemainingCards(to: declarer, state: &state)
        state.originalHands = state.hands

        try openDeclarationOrPlay(state: &state)
    }

    /// يسلّم الأوراق المتبقية: المشتري يأخذ الورقة المكشوفة وما يكمل يده، والبقية بالتساوي.
    private static func dealRemainingCards(to declarer: Player, state: inout GameState) throws {
        guard !state.undealtCards.isEmpty else { return }

        var pool = state.undealtCards
        if let upCard = state.bidding.upCard {
            state.hands[declarer.id, default: []].append(upCard)
        }

        let target = Deck.fullCount / state.players.count
        // الترتيب ثابت (من يمين الموزّع) فيبقى التوزيع نفسه عند إعادة التشغيل.
        for player in state.playersInTurnOrder(startingAt: state.dealerSeat.next) {
            let missing = target - (state.hands[player.id]?.count ?? 0)
            guard missing > 0 else { continue }
            guard pool.count >= missing else { throw GameEngineError.unknownPlayer }
            state.hands[player.id, default: []].append(contentsOf: pool.prefix(missing))
            pool.removeFirst(missing)
        }

        state.undealtCards = pool
    }

    /// يفتح مرحلة إعلان المشاريع، أو يبدأ اللعب مباشرة إن كان الإعلان غير مطلوب.
    static func openDeclarationOrPlay(state: inout GameState) throws {
        guard let leaderID = state.firstToActPlayerID, let leader = state.player(id: leaderID) else {
            throw GameEngineError.unknownPlayer
        }

        if state.rules.projectsEnabled && state.rules.projectsRequireDeclaration {
            state.phase = .declaring
            state.currentTurnPlayerID = leaderID
            return
        }

        // الإعلان غير مطلوب: تُحتسب كل المشاريع المكتشفة تلقائيًا.
        if state.rules.projectsEnabled {
            state.declaredProjects = allDetectedProjects(state: state)
        }
        startPlay(leader: leader, state: &state)
    }

    /// كل المشاريع المكتشفة في أيدي اللاعبين الأربعة.
    static func allDetectedProjects(state: GameState) -> [Project] {
        guard let mode = state.mode else { return [] }
        return state.players.flatMap { player in
            ProjectDetector.detect(
                hand: state.originalHands[player.id] ?? [],
                player: player,
                mode: mode,
                trumpSuit: state.trumpSuit,
                rules: state.rules
            )
        }
    }

    private static func startPlay(leader: Player, state: inout GameState) {
        state.phase = .playing
        state.currentTrick = Trick(leaderSeat: leader.seat)
        state.currentTurnPlayerID = leader.id
    }

    // MARK: - الإعلان

    /// المشاريع التي يستطيع لاعب معيّن إعلانها فعلًا.
    public static func declarableProjects(for playerID: Player.ID, state: GameState) -> [Project] {
        guard state.rules.projectsEnabled, let mode = state.mode,
              let player = state.player(id: playerID) else { return [] }
        return ProjectDetector.detect(
            hand: state.originalHands[playerID] ?? [],
            player: player,
            mode: mode,
            trumpSuit: state.trumpSuit,
            rules: state.rules
        )
    }

    static func declareProjects(playerID: Player.ID, projects: [Project], state: inout GameState) throws {
        guard state.phase == .declaring else {
            throw GameEngineError.wrongPhase(expected: .declaring, actual: state.phase)
        }
        guard state.player(id: playerID) != nil else { throw GameEngineError.unknownPlayer }
        guard state.currentTurnPlayerID == playerID else { throw GameEngineError.notPlayersTurn }

        // لا يُعلَن إلا ما هو موجود فعلًا: الإعلان الكاذب يُرفض بدل أن يُصدَّق ويُحتسب.
        let available = declarableProjects(for: playerID, state: state)
        for project in projects where !available.contains(project) {
            throw GameEngineError.bidding(.undetectedProject)
        }
        guard Set(projects).count == projects.count else {
            throw GameEngineError.bidding(.duplicateProjectDeclaration)
        }
        guard !projects.contains(where: { state.declaredProjects.contains($0) }) else {
            throw GameEngineError.bidding(.duplicateProjectDeclaration)
        }

        state.declaredProjects.append(contentsOf: projects)

        // الإعلان يمر بترتيب الأدوار مرة واحدة ابتداءً من صاحب الدور الأول، فموقع
        // اللاعب في هذا الترتيب يكفي لمعرفة هل انتهت الجولة — بلا عدّاد منفصل يمكن
        // أن يفقد تزامنه مع الحالة عند إعادة التشغيل.
        let order = state.playersInTurnOrder(startingAt: state.dealerSeat.next)
        guard let index = order.firstIndex(where: { $0.id == playerID }) else {
            throw GameEngineError.unknownPlayer
        }

        if index == order.count - 1 {
            guard let leaderID = state.firstToActPlayerID, let leader = state.player(id: leaderID) else {
                throw GameEngineError.unknownPlayer
            }
            startPlay(leader: leader, state: &state)
        } else {
            state.currentTurnPlayerID = order[index + 1].id
        }
    }
}
