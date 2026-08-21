import Foundation

/// حالة دورة المزايدة كاملة. جزء من ``GameState`` فتُسجَّل وتُعاد مع الجولة في الـReplay.
///
/// دورة المزايدة المعتمدة (النمط الكامل ``BiddingStyle/full``):
///
/// 1. **الجولة الأولى** — تُكشف ورقة واحدة (الورقة المكشوفة). يبدأ اللاعب على يمين
///    الموزّع، وأمام كل لاعب ثلاثة خيارات: «حكم» على **لون الورقة المكشوفة تحديدًا**،
///    أو «صن»، أو «بس». أول شراء يُنهي الجولة.
/// 2. **جولة الأشكال** — إن مرّ الأربعة، تبدأ جولة ثانية يجوز فيها شراء الحكم على
///    **أي لون عدا لون الورقة المكشوفة**، أو شراء صن.
/// 3. **المضاعفة** — بعد الشراء، لخصوم المشتري حق طلب «دبل»، ولفريق المشتري حق
///    التصعيد (ثري ← فور ← قهوة)، ويجوز «القفل» لإنهاء التصعيد.
/// 4. **الدورة الميتة** — إن مرّ الأربعة في الجولتين معًا فلا شراء، وتُلغى الجولة
///    وتُعاد بلا نقاط لأي فريق مع انتقال الموزّع.
public struct BiddingState: Codable, Sendable, Equatable {
    /// المرحلة الحالية داخل دورة المزايدة.
    public enum Stage: String, Codable, Sendable, Equatable {
        /// الجولة الأولى على لون الورقة المكشوفة.
        case firstRound
        /// جولة «الأشكال»: أي لون عدا لون الورقة المكشوفة.
        case secondRound
        /// جولة المضاعفة بعد استقرار الشراء.
        case doubling
        /// انتهت المزايدة بشراء مستقر.
        case completed
        /// مرّ الجميع في الجولتين: دورة ميتة تُعاد بلا نقاط.
        case voided
    }

    public var stage: Stage
    /// الورقة المكشوفة التي تُزايَد عليها في الجولة الأولى.
    public var upCard: PlayingCard?
    /// كل المزايدات بالترتيب الذي جرت به.
    public var bids: [BidRecord]
    /// اللاعب المشتري (صاحب الشراء)، أو `nil` إن لم يشترِ أحد بعد.
    public var declarerID: Player.ID?
    /// النمط المشترى.
    public var mode: GameMode?
    /// لون الحكم المشترى.
    public var trumpSuit: Suit?
    /// المضاعف المستقر للجولة.
    public var multiplier: Multiplier
    /// الفريق الذي طلب المضاعفة الحالية (يحدد من له حق التصعيد التالي).
    public var multiplierRequesterTeamID: Team.ID?
    /// هل أُقفلت المضاعفة فلا تصعيد بعدها؟
    public var isLocked: Bool
    /// عدد التمريرات المتتالية في جولة المزايدة الحالية.
    public var consecutivePasses: Int
    /// عدد التمريرات المتتالية في جولة المضاعفة.
    public var doublingPasses: Int

    public init(
        stage: Stage = .firstRound,
        upCard: PlayingCard? = nil,
        bids: [BidRecord] = [],
        declarerID: Player.ID? = nil,
        mode: GameMode? = nil,
        trumpSuit: Suit? = nil,
        multiplier: Multiplier = .none,
        multiplierRequesterTeamID: Team.ID? = nil,
        isLocked: Bool = false,
        consecutivePasses: Int = 0,
        doublingPasses: Int = 0
    ) {
        self.stage = stage
        self.upCard = upCard
        self.bids = bids
        self.declarerID = declarerID
        self.mode = mode
        self.trumpSuit = trumpSuit
        self.multiplier = multiplier
        self.multiplierRequesterTeamID = multiplierRequesterTeamID
        self.isLocked = isLocked
        self.consecutivePasses = consecutivePasses
        self.doublingPasses = doublingPasses
    }

    /// رقم جولة المزايدة الحالية (1 أو 2)، ويُستخدم في تسجيل ``BidRecord``.
    public var roundNumber: Int {
        switch stage {
        case .firstRound: 1
        case .secondRound: 2
        case .doubling, .completed, .voided: 2
        }
    }

    /// هل انتهت المزايدة (بشراء أو بدورة ميتة)؟
    public var isSettled: Bool {
        stage == .completed || stage == .voided
    }

    /// آخر شراء قائم في جولة المزايدة الحالية، أو `nil` إن لم يشترِ أحد بعد.
    public var currentBid: BidRecord? {
        bids.last { $0.round == roundNumber && $0.bid.isBid }
    }

    /// عدد اللاعبين الذين تكلّموا في جولة المزايدة الحالية.
    public var actionsInCurrentRound: Int {
        bids.count { $0.round == roundNumber }
    }

    /// المزايدات القانونية المتاحة للاعب في المرحلة الحالية.
    ///
    /// مصدر حقيقة واحد تستخدمه الواجهة والوكلاء الآليون والاختبارات معًا، فلا يمكن
    /// أن تعرض الواجهة خيارًا يرفضه المحرك.
    ///
    /// قاعدة «صن فوق حكم» مطبَّقة هنا: من اشترى حكمًا يجوز أن يُشترى فوقه صن، ولا
    /// يجوز أن يُشترى فوق الصن شيء.
    public func legalBids(rules: BalootRulesConfiguration) -> [Bid] {
        switch stage {
        case .firstRound:
            guard let upCard else { return [.pass] }
            if let bidRecord = currentBid {
                return bidRecord.bid.mode == .hokum && rules.sunAllowedInFirstRound ? [.pass, .sun] : [.pass]
            }
            var options: [Bid] = [.pass, .hokum(suit: upCard.suit)]
            if rules.sunAllowedInFirstRound { options.append(.sun) }
            return options

        case .secondRound:
            if let bidRecord = currentBid {
                return bidRecord.bid.mode == .hokum ? [.pass, .sun] : [.pass]
            }
            let excluded = upCard?.suit
            return [.pass, .sun] + Suit.allCases
                .filter { $0 != excluded }
                .map { Bid.hokum(suit: $0) }

        case .doubling, .completed, .voided:
            return []
        }
    }
}
