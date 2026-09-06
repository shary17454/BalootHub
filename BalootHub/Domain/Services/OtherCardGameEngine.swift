import Foundation

struct OtherCardGameCard: Identifiable, Hashable, Comparable {
    enum Suit: String, CaseIterable {
        case spade
        case diamond
        case heart
        case club

        var title: String {
            switch self {
            case .spade: "سبيت"
            case .diamond: "ديمن"
            case .heart: "هاص"
            case .club: "شريا"
            }
        }

        var symbolName: String {
            switch self {
            case .spade: "suit.spade.fill"
            case .diamond: "suit.diamond.fill"
            case .heart: "suit.heart.fill"
            case .club: "suit.club.fill"
            }
        }

        var isRed: Bool { self == .diamond || self == .heart }
    }

    enum Rank: Int, CaseIterable, Comparable {
        case two = 2
        case three = 3
        case four = 4
        case five = 5
        case six = 6
        case seven = 7
        case eight = 8
        case nine = 9
        case ten = 10
        case jack = 11
        case queen = 12
        case king = 13
        case ace = 14

        static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var title: String {
            switch self {
            case .jack: "J"
            case .queen: "Q"
            case .king: "K"
            case .ace: "A"
            default: String(rawValue)
            }
        }
    }

    let suit: Suit
    let rank: Rank

    var id: String { "\(suit.rawValue)-\(rank.rawValue)" }

    static func < (lhs: OtherCardGameCard, rhs: OtherCardGameCard) -> Bool {
        if lhs.suit.rawValue == rhs.suit.rawValue {
            return lhs.rank < rhs.rank
        }
        return lhs.suit.rawValue < rhs.suit.rawValue
    }
}

struct OtherCardGameRules: Equatable {
    enum Mode: Equatable {
        case trickTaking
        case avoidPenalty
        case matchingDiscard
        case fishing
        case pairMatching
        case meldCollection
        case solitaireFoundation
        case pokerShowdown
        case blackjack
        case war
    }

    let slug: String
    let title: String
    let mode: Mode
    let playerCount: Int
    let cardsPerPlayer: Int
    let allowsTrump: Bool
    let penaltySuit: OtherCardGameCard.Suit?
    let setupText: String
    let playText: String
    let scoringText: String

    var goalText: String {
        switch mode {
        case .trickTaking:
            allowsTrump ? "اكسب أكبر عدد من الأكلات مع احترام اللون المطلوب والحكم." : "اكسب أكبر عدد من الأكلات مع احترام اللون المطلوب."
        case .avoidPenalty:
            "تجنب أوراق العقوبة، خصوصًا الهاص والملكات."
        case .matchingDiscard:
            "تخلص من أوراقك بمطابقة الرقم أو النوع، والثمانية ورقة حرة."
        case .fishing:
            "اطلب رتبة من لاعب آخر. إذا لم يجدها، اسحب من الحزمة واجمع الأزواج والمجموعات."
        case .pairMatching:
            "اجمع الأزواج وتخلص منها. الخطر في الورقة الوحيدة التي لا تجد لها زوجًا."
        case .meldCollection:
            "كوّن مجموعات أو سلاسل صحيحة ثم أنزلها لتقليل أوراقك."
        case .solitaireFoundation:
            "ابنِ الأساسات من A إلى K لكل نوع، وحاول إنهاء أوراقك."
        case .pokerShowdown:
            "كوّن أقوى يد ممكنة من أوراقك وأوراق الوسط ثم اكشف النتيجة."
        case .blackjack:
            "اقترب من 21 دون تجاوزها وتغلب على يد الموزع."
        case .war:
            "اكسب المواجهة الأعلى ورقة حتى تنتهي الحزمة."
        }
    }

    static func rules(for slug: String, title: String) -> OtherCardGameRules {
        func make(
            mode: Mode,
            playerCount: Int = 4,
            cardsPerPlayer: Int,
            allowsTrump: Bool = false,
            penaltySuit: OtherCardGameCard.Suit? = nil,
            setup: String,
            play: String,
            scoring: String
        ) -> OtherCardGameRules {
            OtherCardGameRules(
                slug: slug,
                title: title,
                mode: mode,
                playerCount: playerCount,
                cardsPerPlayer: cardsPerPlayer,
                allowsTrump: allowsTrump,
                penaltySuit: penaltySuit,
                setupText: setup,
                playText: play,
                scoringText: scoring
            )
        }

        return switch slug {
        case "seven-diamonds":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, penaltySuit: .diamond, setup: "سبعة الديمن: ورقة 7 ديمن هي العقوبة الأساسية.", play: "اتبع النوع المطلوب وحاول ألا تكسب الأكلة التي تحمل 7 ديمن.", scoring: "تسجل العقوبة على صاحب أكلة 7 ديمن، والأقل عقوبات يفوز.")
        case "queen-spades":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, penaltySuit: .spade, setup: "بنت السبيت: Q سبيت هي الورقة الأخطر.", play: "اتبع النوع المطلوب وتخلص من بنت السبيت عندما تكون الأكلة للخصم.", scoring: "من يأخذ Q سبيت يتحمل عقوبة كبيرة.")
        case "jack-clubs":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, penaltySuit: .club, setup: "ولد الشريا: J شريا ورقة عقوبة مرصودة.", play: "راقب الشريا العالي قبل رمي ولد الشريا أو إجبار الخصم عليه.", scoring: "تسجل العقوبة على من يأخذ J شريا.")
        case "king-hearts":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, penaltySuit: .heart, setup: "شايب الهاص: K هاص هو هدف العقوبة.", play: "اتبع النوع وتجنب أخذ الأكلة التي تحمل شايب الهاص.", scoring: "من يأخذ K هاص تُضاف عليه عقوبة.")
        case "diamonds-collector":
            make(mode: .trickTaking, cardsPerPlayer: 13, setup: "تجميع الديمن: الديمن مصدر النقاط.", play: "اكسب الأكلات التي تحتوي ديمنًا عندما تستطيع.", scoring: "كل ديمن في أكلاتك يرفع نتيجتك.")
        case "hearts-penalty", "queens-penalty", "no-tricks", "no-hearts-no-queens":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, penaltySuit: .heart, setup: "\(title): نمط تجنب عقوبات.", play: "اتبع النوع المطلوب وتجنب أخذ الأكلات التي تحمل الأوراق المرصودة.", scoring: "الأقل عقوبات بعد نهاية اليد يفوز.")
        case "sahbiya":
            make(mode: .matchingDiscard, cardsPerPlayer: 7, setup: "السحبية: ورقة مفتوحة وحزمة سحب.", play: "طابق الرقم أو النوع، واسحب عندما لا تملك حركة قانونية.", scoring: "من ينهي أوراقه أولًا يفوز.")
        case "sequence", "memory-pairs":
            make(mode: .meldCollection, cardsPerPlayer: 7, setup: "\(title): بناء أزواج أو سلاسل.", play: "العب زوجًا أو سلسلة قانونية، واسحب عندما لا تتوفر حركة.", scoring: "كل تركيب صحيح يمنح نقاطًا، والفوز لمن ينهي أوراقه.")
        case "last-two":
            make(mode: .trickTaking, cardsPerPlayer: 13, setup: "آخر ورقتين: نهاية الجولة لها قيمة خاصة.", play: "اتبع النوع واحتفظ بأوراق السيطرة للأكلات الأخيرة.", scoring: "آخر الأكلات تمنح نقاطًا إضافية أو عقوبة حسب الاتفاق.")
        case "tarneeb":
            make(mode: .trickTaking, cardsPerPlayer: 13, allowsTrump: true, setup: "طرنيب: أربعة لاعبين، الفريقان متقابلان، والحكم يحدد قوة الأكلات.", play: "اتبع النوع المطلوب إن كان عندك. إذا لم تملك النوع تستطيع القطع بالحكم. الهدف كسب الأكلات التي تعهد بها الفريق.", scoring: "تزيد نقاط الفريق بعدد الأكلات، وتخسر الجولة إذا لم تحقق التعهد.")
        case "trex":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, setup: "تركس: أربع مملكات. هذه الطاولة تشغّل نمط العقوبات الأساسي لتتعلم تجنب الأوراق الخطرة.", play: "اتبع النوع المطلوب. حاول التخلص من أوراق العقوبة في الوقت المناسب ولا تأخذ أكلة تحمل هاص أو بنت.", scoring: "الأقل عقوبات هو الأفضل. الهاص والملكات ترفع الخسارة.")
        case "hand":
            make(mode: .meldCollection, cardsPerPlayer: 10, setup: "هاند: الهدف ترتيب اليد إلى مجموعات وسلاسل.", play: "العب ورقة تنتمي لمجموعة رتبة أو سلسلة من نفس النوع، أو اسحب حتى تجد ورقة تساعدك على الإنزال.", scoring: "الفائز من ينهي أوراقه أولًا، وبقية الأوراق تُحسب ضد أصحابها.")
        case "kout-bou-sitta":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, setup: "كوت بو ستة: لعبة أكلات وشراكة، وهذه الطاولة تركّز على تجنب الأكلات المكلفة.", play: "اتبع النوع المطلوب، وخطط متى تأخذ الأكلة ومتى تتركها حسب الأوراق الخطرة.", scoring: "الأوراق الخطرة تزيد العقوبة، والأفضلية للأقل نقاط عقوبة.")
        case "bridge":
            make(mode: .trickTaking, cardsPerPlayer: 13, allowsTrump: true, setup: "بريدج: أربعة لاعبين وشراكة، الحكم يمثل العقد المختار.", play: "اتبع النوع المطلوب. استخدم الحكم لكسب الأكلات عند نفاد النوع، ووازن بين حماية الشريك وتحقيق العقد.", scoring: "كل أكلة تقرّب الفريق من العقد؛ الفشل في تحقيقه يعطي الأفضلية للخصم.")
        case "poker-texas-holdem":
            make(mode: .pokerShowdown, playerCount: 2, cardsPerPlayer: 2, setup: "تكساس هولدم: ورقتان لك وخمس أوراق مشتركة في الوسط.", play: "اضغط اكشف لتقييم أقوى خمس أوراق من يدك وأوراق الوسط ضد الخصم.", scoring: "الأعلى حسب ترتيب البوكر يفوز: زوج، زوجان، ثلاثي، ستريت، فلاش، فل هاوس، رباعي.")
        case "blackjack":
            make(mode: .blackjack, playerCount: 2, cardsPerPlayer: 2, setup: "بلاك جاك: أنت ضد الموزع.", play: "اسحب إذا كان مجموعك منخفضًا، أو توقف إذا اقتربت من 21.", scoring: "من يقترب من 21 دون تجاوزها يفوز.")
        case "rummy", "gin-rummy", "canasta":
            make(mode: .meldCollection, cardsPerPlayer: slug == "canasta" ? 11 : 10, setup: "\(title): لعبة مجموعات وسلاسل.", play: "العب أوراقًا تكوّن ثلاثيات من نفس الرتبة أو سلاسل متتابعة من نفس النوع، واسحب عند عدم وجود حركة مفيدة.", scoring: "الفائز من ينهي يده أو يبقى بأقل نقاط غير منزلة.")
        case "hearts":
            make(mode: .avoidPenalty, cardsPerPlayer: 13, penaltySuit: .heart, setup: "هارتس: تجنب الهاص وبنت السبيت.", play: "اتبع النوع المطلوب ولا تأخذ أكلة فيها هاص إلا إذا كانت خطتك محسوبة.", scoring: "كل هاص عقوبة، وبنت السبيت عقوبة كبيرة.")
        case "spades":
            make(mode: .trickTaking, cardsPerPlayer: 13, allowsTrump: true, setup: "سبيت: السبيت دائمًا حكم.", play: "اتبع النوع المطلوب، وإذا انقطع النوع استخدم السبيت لكسب الأكلة.", scoring: "تحقيق عدد الأكلات المتوقعة أهم من جمع كل شيء.")
        case "whist":
            make(mode: .trickTaking, cardsPerPlayer: 13, setup: "ويست: لعبة أكلات مباشرة بلا مزايدة معقدة.", play: "اتبع النوع المطلوب وحاول قراءة الأوراق الخارجة لاختيار أعلى توقيت للأخذ.", scoring: "كل أكلة تكسبها ترفع نتيجتك.")
        case "euchre":
            make(mode: .trickTaking, cardsPerPlayer: 5, allowsTrump: true, setup: "يوكر: خمس أوراق لكل لاعب وحكم قوي.", play: "اتبع النوع. ركز على أوراق الحكم العالية لأن عدد الأكلات قليل.", scoring: "الأكثر أكلات في اليد القصيرة يفوز.")
        case "solitaire-klondike", "freecell", "spider-solitaire":
            make(mode: .solitaireFoundation, playerCount: 1, cardsPerPlayer: 28, setup: "\(title): ترتيب فردي للأساسات.", play: "ابدأ بالآسات ثم ابنِ كل نوع تصاعديًا. الورقة القانونية ترفع أساس نوعها خطوة واحدة.", scoring: "تفوز عندما تنتقل كل الأوراق إلى الأساسات.")
        case "crazy-eights":
            make(mode: .matchingDiscard, cardsPerPlayer: 7, setup: "الثمانية المجنونة: كرت مفتوح وحزمة سحب.", play: "طابق النوع أو الرقم مع الورقة المفتوحة. رقم 8 حر ويمكن لعبه على أي ورقة.", scoring: "من يتخلص من أوراقه أولًا يفوز.")
        case "old-maid":
            make(mode: .pairMatching, cardsPerPlayer: 7, setup: "العجوز: اجمع الأزواج وتجنب بقاء ورقة وحيدة في يدك.", play: "العب أي زوج من نفس الرتبة. إذا لم يوجد زوج اسحب وانتظر فرصة المطابقة.", scoring: "الفائز من ينهي أزواجه، والخاسر من تبقى معه الورقة الوحيدة.")
        case "go-fish":
            make(mode: .fishing, cardsPerPlayer: 7, setup: "جو فش: اجمع أربع أوراق من نفس الرتبة.", play: "اختر رتبة عندك. إن لم تجد طلبًا ناجحًا اسحب من البحر حتى تكمل مجموعة.", scoring: "كل مجموعة مكتملة من أربع أوراق تمنح نقطة.")
        case "war":
            make(mode: .war, playerCount: 2, cardsPerPlayer: 26, setup: "حرب: الحزمة مقسمة بين لاعبين.", play: "اكشف ورقة؛ الأعلى رتبة يكسب المواجهة.", scoring: "كل مواجهة نقطة، والأكثر نقاطًا عند نهاية الحزمة يفوز.")
        case "president":
            make(mode: .matchingDiscard, cardsPerPlayer: 13, setup: "الرئيس: تخلص من أوراقك قبل الآخرين.", play: "العب ورقة مساوية أو أعلى من الورقة المفتوحة، وابدأ بسلسلة جديدة عند الحاجة.", scoring: "أول من ينهي أوراقه يصبح الرئيس.")
        case "durak":
            make(mode: .trickTaking, cardsPerPlayer: 6, allowsTrump: true, setup: "دوراك: هجوم ودفاع بحكم ظاهر.", play: "اتبع النوع إن أمكن أو استخدم الحكم للدفاع. لا تكدس أوراقًا كثيرة في يدك.", scoring: "آخر لاعب تبقى معه أوراق هو الخاسر.")
        case "pinochle":
            make(mode: .trickTaking, cardsPerPlayer: 12, allowsTrump: true, setup: "بينوكل: أكلات مع مكافآت مجموعات.", play: "اتبع النوع والحكم، وحافظ على التركيبات العالية قبل رميها.", scoring: "الأكلات والمجموعات العالية ترفع النتيجة.")
        case "cribbage":
            make(mode: .meldCollection, playerCount: 2, cardsPerPlayer: 6, setup: "كريبج: كوّن تركيبات مجموعها 15 وأزواجًا وسلاسل.", play: "اختر الأوراق التي تصنع أكبر قيمة تركيبية، ثم تخلص من الأقل فائدة.", scoring: "النقاط من 15، الأزواج، السلاسل، والفلاش.")
        case "skat":
            make(mode: .trickTaking, playerCount: 3, cardsPerPlayer: 10, allowsTrump: true, setup: "سكات: ثلاثة لاعبين، لاعب ضد اثنين وحكم حسب العقد.", play: "اتبع النوع واستخدم الحكم لتحقيق عقد اللاعب المنفرد أو إفشاله.", scoring: "نجاح العقد أو فشله يحدد الفائز.")
        case "belote":
            make(mode: .trickTaking, cardsPerPlayer: 8, allowsTrump: true, setup: "بيلوت: قريبة من البلوت الأوروبي بحكم و8 أوراق.", play: "اتبع النوع، واقطع بالحكم عند الحاجة، واستفد من الشايب والبنت في الحكم.", scoring: "نقاط الأوراق والحكم تحدد الفريق الفائز.")
        case "hokm":
            make(mode: .trickTaking, cardsPerPlayer: 13, allowsTrump: true, setup: "حكم: لاعب يختار نوع الحكم بعد رؤية يده.", play: "اتبع النوع المطلوب. عند نفاد النوع يمكن القطع بالحكم لكسب الأكلة.", scoring: "كل أكلة للفريق، والفريق الذي يحقق المطلوب أولًا يفوز.")
        case "estimation":
            make(mode: .trickTaking, cardsPerPlayer: 13, allowsTrump: true, setup: "استيميشن: كل لاعب يقدّر عدد الأكلات قبل اللعب.", play: "العب لتحقيق تقديرك بدقة، لا أكثر ولا أقل عند القواعد الصارمة.", scoring: "مطابقة التقدير تمنح نقاطًا، والفشل يخصم.")
        case "basra":
            make(mode: .fishing, playerCount: 2, cardsPerPlayer: 4, setup: "بسرة: أوراق على الأرض وتلتقط بالمطابقة أو المجموع.", play: "العب ورقة تلتقط نفس الرتبة أو مجموعًا مناسبًا من أوراق الأرض، وإلا تُضاف للأرض.", scoring: "البسرة واللقطات تزيد النتيجة.")
        default:
            make(mode: .trickTaking, cardsPerPlayer: 13, setup: "\(title): طاولة أكلات قياسية.", play: "اتبع النوع المطلوب وحاول كسب الأكلات المناسبة.", scoring: "الأكثر أكلات يفوز بالجولة.")
        }
    }
}

struct OtherCardGamePlayer: Identifiable, Equatable {
    let id: Int
    let name: String
    var hand: [OtherCardGameCard]
    var wonCards: [OtherCardGameCard] = []
    var score: Int = 0
}

struct OtherCardGameTableState {
    let rules: OtherCardGameRules
    var players: [OtherCardGamePlayer]
    var drawPile: [OtherCardGameCard]
    var discardPile: [OtherCardGameCard]
    var currentTrick: [(playerID: Int, card: OtherCardGameCard)]
    var currentPlayerID: Int
    var trumpSuit: OtherCardGameCard.Suit?
    var communityCards: [OtherCardGameCard]
    var foundations: [OtherCardGameCard.Suit: OtherCardGameCard.Rank]
    var completedSets: [OtherCardGameCard.Rank]
    var message: String
    var roundFinished: Bool
    var userStand: Bool

    var user: OtherCardGamePlayer { players[0] }
    var legalCardsForUser: [OtherCardGameCard] {
        OtherCardGameEngine.legalCards(for: user, in: self)
    }
}

enum OtherCardGameEngine {
    static func newGame(slug: String, title: String, seed: UInt64 = 7_341) -> OtherCardGameTableState {
        let rules = OtherCardGameRules.rules(for: slug, title: title)
        var deck = shuffledDeck(seed: seed ^ UInt64(abs(slug.hashStable)))
        let trump = rules.allowsTrump ? deck.first?.suit : nil
        var players: [OtherCardGamePlayer] = (0..<rules.playerCount).map {
            OtherCardGamePlayer(id: $0, name: $0 == 0 ? "أنت" : "لاعب \($0 + 1)", hand: [])
        }

        for cardIndex in 0..<rules.cardsPerPlayer {
            for playerIndex in players.indices where !deck.isEmpty {
                let card = deck.removeFirst()
                players[playerIndex].hand.append(card)
            }
            if cardIndex > 0, rules.mode == .blackjack { break }
        }
        for index in players.indices {
            players[index].hand.sort()
        }

        var discardPile: [OtherCardGameCard] = []
        if (rules.mode == .matchingDiscard || rules.mode == .fishing) && !deck.isEmpty {
            discardPile.append(deck.removeFirst())
        }
        let communityCards: [OtherCardGameCard]
        if rules.mode == .pokerShowdown {
            communityCards = Array(deck.prefix(5))
            deck.removeFirst(min(5, deck.count))
        } else {
            communityCards = []
        }

        return OtherCardGameTableState(
            rules: rules,
            players: players,
            drawPile: deck,
            discardPile: discardPile,
            currentTrick: [],
            currentPlayerID: 0,
            trumpSuit: trump,
            communityCards: communityCards,
            foundations: [:],
            completedSets: [],
            message: rules.goalText,
            roundFinished: false,
            userStand: false
        )
    }

    static func legalCards(for player: OtherCardGamePlayer, in state: OtherCardGameTableState) -> [OtherCardGameCard] {
        switch state.rules.mode {
        case .matchingDiscard:
            guard let top = state.discardPile.last else { return player.hand }
            let legal = state.rules.slug == "president"
                ? player.hand.filter { $0.rank.rawValue >= top.rank.rawValue }
                : player.hand.filter { $0.suit == top.suit || $0.rank == top.rank || $0.rank == .eight }
            return legal.isEmpty ? [] : legal
        case .fishing:
            return player.hand.filter { card in
                player.hand.filter { $0.rank == card.rank }.count >= 2 || card.rank == state.discardPile.last?.rank
            }
        case .pairMatching:
            return player.hand.filter { card in
                player.hand.filter { $0.rank == card.rank }.count >= 2
            }
        case .meldCollection:
            return player.hand.filter { card in
                hasRankMeld(card, in: player.hand) || hasSuitRun(card, in: player.hand)
            }
        case .solitaireFoundation:
            return player.hand.filter { card in
                let current = state.foundations[card.suit]
                return current == nil ? card.rank == .ace : card.rank.rawValue == (current?.rawValue ?? 0) + 1
            }
        case .blackjack, .war, .pokerShowdown:
            return player.hand
        case .trickTaking, .avoidPenalty:
            guard let leadSuit = state.currentTrick.first?.card.suit else { return player.hand }
            let matching = player.hand.filter { $0.suit == leadSuit }
            return matching.isEmpty ? player.hand : matching
        }
    }

    static func playUserCard(_ card: OtherCardGameCard, in state: inout OtherCardGameTableState) {
        guard !state.roundFinished else { return }
        guard state.currentPlayerID == 0 else {
            advanceAI(in: &state)
            return
        }
        guard state.legalCardsForUser.contains(card), let index = state.players[0].hand.firstIndex(of: card) else {
            state.message = "هذه الورقة غير قانونية الآن. يجب اتباع النوع المطلوب أو مطابقة الورقة المفتوحة حسب اللعبة."
            return
        }

        switch state.rules.mode {
        case .matchingDiscard:
            state.discardPile.append(state.players[0].hand.remove(at: index))
            state.message = "لعبت \(card.rank.title) \(card.suit.title)."
            state.currentPlayerID = nextPlayer(after: 0, in: state)
            advanceAI(in: &state)
        case .fishing:
            playFishing(card, playerIndex: 0, in: &state)
            state.currentPlayerID = nextPlayer(after: 0, in: state)
            advanceAI(in: &state)
        case .pairMatching:
            playPair(card, playerIndex: 0, in: &state)
            state.currentPlayerID = nextPlayer(after: 0, in: state)
            advanceAI(in: &state)
        case .meldCollection:
            playMeld(card, playerIndex: 0, in: &state)
        case .solitaireFoundation:
            playFoundation(card, in: &state)
        case .blackjack:
            state.message = "اختر اسحب أو توقف في بلاك جاك."
        case .pokerShowdown:
            resolvePokerShowdown(in: &state)
        case .war:
            resolveWarTurn(in: &state)
        case .trickTaking, .avoidPenalty:
            state.currentTrick.append((0, state.players[0].hand.remove(at: index)))
            state.currentPlayerID = nextPlayer(after: 0, in: state)
            advanceAI(in: &state)
        }

        finishIfNeeded(&state)
    }

    static func drawForUser(in state: inout OtherCardGameTableState) {
        guard !state.drawPile.isEmpty, !state.roundFinished else { return }
        switch state.rules.mode {
        case .matchingDiscard, .fishing, .pairMatching, .meldCollection, .solitaireFoundation:
            let card = state.drawPile.removeFirst()
            state.players[0].hand.append(card)
            state.players[0].hand.sort()
            state.message = "سحبت \(card.rank.title) \(card.suit.title). إذا أصبحت لديك حركة قانونية العبها."
        case .blackjack:
            let card = state.drawPile.removeFirst()
            state.players[0].hand.append(card)
            let value = blackjackValue(state.players[0].hand)
            state.message = value > 21 ? "تجاوزت 21. فاز الموزع." : "مجموعك الآن \(value)."
            if value > 21 { state.roundFinished = true }
        default:
            state.message = "السحب متاح فقط في ألعاب المطابقة وبلاك جاك."
        }
    }

    static func standUser(in state: inout OtherCardGameTableState) {
        guard state.rules.mode == .blackjack, !state.roundFinished else { return }
        state.userStand = true
        while blackjackValue(state.players[1].hand) < 17, !state.drawPile.isEmpty {
            state.players[1].hand.append(state.drawPile.removeFirst())
        }
        let userValue = blackjackValue(state.players[0].hand)
        let dealerValue = blackjackValue(state.players[1].hand)
        if dealerValue > 21 || userValue > dealerValue {
            state.players[0].score += 1
            state.message = "فزت: مجموعك \(userValue)، الموزع \(dealerValue)."
        } else if userValue == dealerValue {
            state.message = "تعادل: \(userValue) لكل طرف."
        } else {
            state.players[1].score += 1
            state.message = "فاز الموزع: مجموعك \(userValue)، الموزع \(dealerValue)."
        }
        state.roundFinished = true
    }

    static func advanceAI(in state: inout OtherCardGameTableState) {
        var guardCounter = 0
        while state.currentPlayerID != 0, !state.roundFinished, guardCounter < 20 {
            guardCounter += 1
            let playerIndex = state.currentPlayerID
            switch state.rules.mode {
            case .matchingDiscard:
                let legal = legalCards(for: state.players[playerIndex], in: state)
                if let card = legal.sorted().first, let handIndex = state.players[playerIndex].hand.firstIndex(of: card) {
                    state.discardPile.append(state.players[playerIndex].hand.remove(at: handIndex))
                    state.message = "\(state.players[playerIndex].name) لعب \(card.rank.title) \(card.suit.title)."
                } else if !state.drawPile.isEmpty {
                    state.players[playerIndex].hand.append(state.drawPile.removeFirst())
                    state.players[playerIndex].hand.sort()
                    state.message = "\(state.players[playerIndex].name) سحب ورقة."
                }
                state.currentPlayerID = nextPlayer(after: playerIndex, in: state)
            case .fishing:
                let legal = legalCards(for: state.players[playerIndex], in: state)
                if let card = legal.sorted().first {
                    playFishing(card, playerIndex: playerIndex, in: &state)
                } else if !state.drawPile.isEmpty {
                    state.players[playerIndex].hand.append(state.drawPile.removeFirst())
                    state.players[playerIndex].hand.sort()
                }
                state.currentPlayerID = nextPlayer(after: playerIndex, in: state)
            case .pairMatching:
                let legal = legalCards(for: state.players[playerIndex], in: state)
                if let card = legal.sorted().first {
                    playPair(card, playerIndex: playerIndex, in: &state)
                } else if !state.drawPile.isEmpty {
                    state.players[playerIndex].hand.append(state.drawPile.removeFirst())
                    state.players[playerIndex].hand.sort()
                }
                state.currentPlayerID = nextPlayer(after: playerIndex, in: state)
            case .meldCollection:
                let legal = legalCards(for: state.players[playerIndex], in: state)
                if let card = legal.sorted().first {
                    playMeld(card, playerIndex: playerIndex, in: &state)
                } else if !state.drawPile.isEmpty {
                    state.players[playerIndex].hand.append(state.drawPile.removeFirst())
                    state.players[playerIndex].hand.sort()
                }
                state.currentPlayerID = nextPlayer(after: playerIndex, in: state)
            case .solitaireFoundation:
                state.currentPlayerID = 0
            case .trickTaking, .avoidPenalty:
                let legal = legalCards(for: state.players[playerIndex], in: state)
                guard let card = aiCard(from: legal, state: state), let handIndex = state.players[playerIndex].hand.firstIndex(of: card) else {
                    state.roundFinished = true
                    break
                }
                state.currentTrick.append((playerIndex, state.players[playerIndex].hand.remove(at: handIndex)))
                if state.currentTrick.count == state.rules.playerCount {
                    resolveTrick(in: &state)
                } else {
                    state.currentPlayerID = nextPlayer(after: playerIndex, in: state)
                }
            case .blackjack, .war, .pokerShowdown:
                state.currentPlayerID = 0
            }
            finishIfNeeded(&state)
        }
    }

    private static func resolveTrick(in state: inout OtherCardGameTableState) {
        guard let winner = trickWinner(in: state) else { return }
        let cards = state.currentTrick.map(\.card)
        state.players[winner].wonCards += cards
        switch state.rules.mode {
        case .avoidPenalty:
            state.players[winner].score += cards.reduce(0) { $0 + penaltyValue(for: $1, rules: state.rules) }
        default:
            state.players[winner].score += 1
        }
        state.currentTrick.removeAll()
        state.currentPlayerID = winner
        state.message = "\(state.players[winner].name) كسب الأكلة."
    }

    private static func resolveWarTurn(in state: inout OtherCardGameTableState) {
        guard !state.players[0].hand.isEmpty, !state.players[1].hand.isEmpty else {
            finishIfNeeded(&state)
            return
        }
        let user = state.players[0].hand.removeFirst()
        let dealer = state.players[1].hand.removeFirst()
        if user.rank >= dealer.rank {
            state.players[0].score += 1
            state.message = "ورقتك \(user.rank.title) أعلى من \(dealer.rank.title)."
        } else {
            state.players[1].score += 1
            state.message = "ورقة الخصم \(dealer.rank.title) أعلى من \(user.rank.title)."
        }
        finishIfNeeded(&state)
    }

    private static func finishIfNeeded(_ state: inout OtherCardGameTableState) {
        switch state.rules.mode {
        case .matchingDiscard, .fishing, .pairMatching, .meldCollection:
            if let winner = state.players.first(where: { $0.hand.isEmpty }) {
                state.roundFinished = true
                state.message = "\(winner.name) أنهى أوراقه وفاز بالجولة."
            }
        case .solitaireFoundation:
            if state.players[0].hand.isEmpty {
                state.roundFinished = true
                state.message = "اكتملت الأساسات وفزت بجولة \(state.rules.title)."
            }
        case .trickTaking, .avoidPenalty:
            if state.players.allSatisfy({ $0.hand.isEmpty }) && state.currentTrick.isEmpty {
                state.roundFinished = true
                let winner = state.rules.mode == .avoidPenalty
                    ? state.players.min { $0.score < $1.score }
                    : state.players.max { $0.score < $1.score }
                if let winner {
                    state.message = "\(winner.name) فاز بالجولة."
                }
            }
        case .blackjack:
            break
        case .pokerShowdown:
            break
        case .war:
            if state.players[0].hand.isEmpty || state.players[1].hand.isEmpty {
                state.roundFinished = true
                state.message = state.players[0].score >= state.players[1].score ? "فزت بجولة الحرب." : "فاز الخصم بجولة الحرب."
            }
        }
    }

    private static func trickWinner(in state: OtherCardGameTableState) -> Int? {
        guard let lead = state.currentTrick.first else { return nil }
        return state.currentTrick.max { lhs, rhs in
            trickStrength(lhs.card, leadSuit: lead.card.suit, trumpSuit: state.trumpSuit) <
                trickStrength(rhs.card, leadSuit: lead.card.suit, trumpSuit: state.trumpSuit)
        }?.playerID
    }

    private static func trickStrength(_ card: OtherCardGameCard, leadSuit: OtherCardGameCard.Suit, trumpSuit: OtherCardGameCard.Suit?) -> Int {
        let base = card.rank.rawValue
        if let trumpSuit, card.suit == trumpSuit { return 200 + base }
        if card.suit == leadSuit { return 100 + base }
        return base
    }

    private static func penaltyValue(for card: OtherCardGameCard, rules: OtherCardGameRules) -> Int {
        switch rules.slug {
        case "seven-diamonds":
            card.suit == .diamond && card.rank == .seven ? 10 : 0
        case "queen-spades":
            card.suit == .spade && card.rank == .queen ? 13 : 0
        case "jack-clubs":
            card.suit == .club && card.rank == .jack ? 8 : 0
        case "king-hearts":
            card.suit == .heart && card.rank == .king ? 8 : 0
        case "queens-penalty":
            card.rank == .queen ? (card.suit == .spade ? 13 : 5) : 0
        case "no-tricks":
            1
        case "no-hearts-no-queens":
            (card.suit == .heart ? 1 : 0) + (card.rank == .queen ? 5 : 0)
        default:
            ((card.suit == rules.penaltySuit) ? 1 : 0) + (card.rank == .queen ? 5 : 0)
        }
    }

    private static func aiCard(from cards: [OtherCardGameCard], state: OtherCardGameTableState) -> OtherCardGameCard? {
        switch state.rules.mode {
        case .avoidPenalty:
            cards.sorted().first
        default:
            cards.sorted().first
        }
    }

    private static func playFishing(_ card: OtherCardGameCard, playerIndex: Int, in state: inout OtherCardGameTableState) {
        let matchingIndices = state.players[playerIndex].hand.indices.filter { state.players[playerIndex].hand[$0].rank == card.rank }
        guard matchingIndices.count >= 2 || state.discardPile.last?.rank == card.rank else { return }
        let removed = removeCards(rank: card.rank, maxCount: matchingIndices.count >= 2 ? 2 : 1, from: &state.players[playerIndex].hand)
        state.players[playerIndex].wonCards += removed
        if removed.count >= 2 || state.players[playerIndex].wonCards.filter({ $0.rank == card.rank }).count >= 4 {
            state.players[playerIndex].score += 1
            state.completedSets.append(card.rank)
        }
        state.message = "\(state.players[playerIndex].name) جمع \(card.rank.title)."
    }

    private static func playPair(_ card: OtherCardGameCard, playerIndex: Int, in state: inout OtherCardGameTableState) {
        let removed = removeCards(rank: card.rank, maxCount: 2, from: &state.players[playerIndex].hand)
        state.players[playerIndex].wonCards += removed
        state.players[playerIndex].score += removed.count == 2 ? 1 : 0
        state.message = "\(state.players[playerIndex].name) أنزل زوج \(card.rank.title)."
    }

    private static func playMeld(_ card: OtherCardGameCard, playerIndex: Int, in state: inout OtherCardGameTableState) {
        if hasRankMeld(card, in: state.players[playerIndex].hand) {
            let removed = removeCards(rank: card.rank, maxCount: 3, from: &state.players[playerIndex].hand)
            state.players[playerIndex].wonCards += removed
            state.players[playerIndex].score += 3
            state.message = "\(state.players[playerIndex].name) أنزل مجموعة \(card.rank.title)."
        } else if let run = suitRun(containing: card, in: state.players[playerIndex].hand) {
            for runCard in run {
                if let index = state.players[playerIndex].hand.firstIndex(of: runCard) {
                    state.players[playerIndex].wonCards.append(state.players[playerIndex].hand.remove(at: index))
                }
            }
            state.players[playerIndex].score += run.count
            state.message = "\(state.players[playerIndex].name) أنزل سلسلة \(card.suit.title)."
        }
        state.players[playerIndex].hand.sort()
    }

    private static func playFoundation(_ card: OtherCardGameCard, in state: inout OtherCardGameTableState) {
        guard let index = state.players[0].hand.firstIndex(of: card) else { return }
        state.players[0].hand.remove(at: index)
        state.foundations[card.suit] = card.rank
        state.players[0].score += 1
        state.message = "رفعت \(card.rank.title) \(card.suit.title) إلى الأساس."
    }

    private static func resolvePokerShowdown(in state: inout OtherCardGameTableState) {
        let userScore = pokerScore(cards: state.players[0].hand + state.communityCards)
        let opponentScore = pokerScore(cards: state.players[1].hand + state.communityCards)
        if userScore >= opponentScore {
            state.players[0].score += 1
            state.message = "فزت بكشف البوكر. تقييم يدك \(userScore)، الخصم \(opponentScore)."
        } else {
            state.players[1].score += 1
            state.message = "خسرت كشف البوكر. تقييم يدك \(userScore)، الخصم \(opponentScore)."
        }
        state.roundFinished = true
    }

    private static func hasRankMeld(_ card: OtherCardGameCard, in hand: [OtherCardGameCard]) -> Bool {
        hand.filter { $0.rank == card.rank }.count >= 3
    }

    private static func hasSuitRun(_ card: OtherCardGameCard, in hand: [OtherCardGameCard]) -> Bool {
        suitRun(containing: card, in: hand) != nil
    }

    private static func suitRun(containing card: OtherCardGameCard, in hand: [OtherCardGameCard]) -> [OtherCardGameCard]? {
        let suited = hand.filter { $0.suit == card.suit }.sorted()
        for windowStart in suited.indices {
            var run = [suited[windowStart]]
            for candidate in suited.dropFirst(windowStart + 1) {
                if candidate.rank.rawValue == (run.last?.rank.rawValue ?? 0) + 1 {
                    run.append(candidate)
                    if run.count >= 3, run.contains(card) {
                        return run
                    }
                } else if candidate.rank.rawValue > (run.last?.rank.rawValue ?? 0) + 1 {
                    run = [candidate]
                }
            }
        }
        return nil
    }

    private static func removeCards(rank: OtherCardGameCard.Rank, maxCount: Int, from hand: inout [OtherCardGameCard]) -> [OtherCardGameCard] {
        var removed: [OtherCardGameCard] = []
        while removed.count < maxCount, let index = hand.firstIndex(where: { $0.rank == rank }) {
            removed.append(hand.remove(at: index))
        }
        return removed
    }

    private static func pokerScore(cards: [OtherCardGameCard]) -> Int {
        let ranks = Dictionary(grouping: cards, by: \.rank).mapValues(\.count)
        let suits = Dictionary(grouping: cards, by: \.suit).mapValues(\.count)
        let counts = ranks.values.sorted(by: >)
        let isFlush = suits.values.contains { $0 >= 5 }
        let sortedRanks = Set(cards.map { $0.rank.rawValue }).sorted()
        let isStraight = containsStraight(sortedRanks)
        if isStraight && isFlush { return 800 }
        if counts.first == 4 { return 700 }
        if counts.first == 3 && counts.dropFirst().first == 2 { return 600 }
        if isFlush { return 500 }
        if isStraight { return 400 }
        if counts.first == 3 { return 300 }
        if counts.prefix(2).allSatisfy({ $0 == 2 }) { return 200 }
        if counts.first == 2 { return 100 }
        return cards.map(\.rank.rawValue).max() ?? 0
    }

    private static func containsStraight(_ sortedRanks: [Int]) -> Bool {
        guard sortedRanks.count >= 5 else { return false }
        for index in 0...(sortedRanks.count - 5) {
            let slice = sortedRanks[index..<(index + 5)]
            if let first = slice.first, let last = slice.last, last - first == 4 {
                return true
            }
        }
        return Set(sortedRanks).isSuperset(of: [14, 2, 3, 4, 5])
    }

    private static func nextPlayer(after playerID: Int, in state: OtherCardGameTableState) -> Int {
        (playerID + 1) % state.players.count
    }

    private static func blackjackValue(_ cards: [OtherCardGameCard]) -> Int {
        var total = 0
        var aces = 0
        for card in cards {
            switch card.rank {
            case .jack, .queen, .king:
                total += 10
            case .ace:
                total += 11
                aces += 1
            default:
                total += card.rank.rawValue
            }
        }
        while total > 21, aces > 0 {
            total -= 10
            aces -= 1
        }
        return total
    }

    private static func shuffledDeck(seed: UInt64) -> [OtherCardGameCard] {
        var generator = StableRandom(seed: seed)
        var deck = OtherCardGameCard.Suit.allCases.flatMap { suit in
            OtherCardGameCard.Rank.allCases.map { rank in
                OtherCardGameCard(suit: suit, rank: rank)
            }
        }
        for index in deck.indices.reversed() {
            let target = Int(generator.next() % UInt64(index + 1))
            deck.swapAt(index, target)
        }
        return deck
    }
}

private struct StableRandom {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private extension String {
    var hashStable: Int {
        unicodeScalars.reduce(0) { partial, scalar in
            ((partial &* 31) &+ Int(scalar.value)) & 0x7fff_ffff
        }
    }
}
