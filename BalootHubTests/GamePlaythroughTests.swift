import XCTest
import BalootEngine
@testable import BalootHub

/// يلعب جولات كاملة عبر المحرك للتحقق من أن الألعاب "تعمل" فعلًا وليس فقط تفتح:
/// توزيع، مزايدة، ثماني أكلات، ثم احتساب نتيجة. أي تعليق أو حركة غير شرعية
/// يظهر هنا بدل أن يكتشفه المستخدم على الطاولة.
final class GamePlaythroughTests: XCTestCase {

    /// يلعب جولة كاملة بنمط محدد، ويعيد الحالة النهائية.
    /// يستخدم نفس المحرك والوكيل اللذين تستخدمهما الشاشة.
    private func playFullRound(mode: GameMode, trumpSuit: Suit?, seed: UInt64) throws -> GameState {
        let agent = SimpleBalootAgent()
        var state = GameState.newLocalMatch()

        state = try GameEngine.apply(.dealCards(seed: seed), to: state)
        XCTAssertEqual(state.phase, .bidding, "بعد التوزيع يجب أن تبدأ المزايدة")

        // كل لاعب يملك 8 أوراق بعد التوزيع.
        for player in state.players {
            XCTAssertEqual(state.hands[player.id]?.count, 8, "\(player.name): لم يستلم 8 أوراق")
        }

        // المستخدم هو صاحب أول دور مزايدة، فيختار النمط المطلوب.
        let humanID = try XCTUnwrap(state.players.first { $0.kind == .human }?.id)
        XCTAssertEqual(state.currentTurnPlayerID, humanID, "الدور الأول للمزايدة ليس للمستخدم")
        state = try GameEngine.apply(.chooseMode(playerID: humanID, mode: mode, trumpSuit: trumpSuit), to: state)

        // يلعب الجميع حتى تنتهي الجولة. الحد الأقصى 32 ورقة (4 لاعبين × 8).
        var guardCounter = 0
        while state.phase == .playing || state.phase == .bidding {
            guardCounter += 1
            XCTAssertLessThan(guardCounter, 200, "الجولة لم تنتهِ — يوجد تعليق في اللعب")

            let currentID = try XCTUnwrap(state.currentTurnPlayerID)
            let player = try XCTUnwrap(state.player(id: currentID))
            let hand = try XCTUnwrap(state.hands[currentID])

            if player.kind == .ai {
                state = try GameEngine.advanceAIPlayers(state: state, agent: agent, maxSteps: 1)
                continue
            }

            // دور المستخدم: يجب أن تتوفر ورقة شرعية واحدة على الأقل، وإلا علقت الشاشة.
            let legal = LegalMoveValidator.legalCards(
                hand: hand,
                trick: state.currentTrick,
                mode: state.mode ?? mode,
                trumpSuit: state.trumpSuit,
                rules: state.rules
            )
            XCTAssertFalse(legal.isEmpty, "المستخدم بلا أي ورقة شرعية — اللعب معلّق")
            state = try GameEngine.apply(.playCard(playerID: currentID, card: legal[0]), to: state)
        }

        if state.phase == .scoring {
            state = try GameEngine.apply(.finishRound, to: state)
        }
        return state
    }

    func testClassicSunRoundPlaysToCompletion() throws {
        let state = try playFullRound(mode: .sun, trumpSuit: nil, seed: 12_345)
        XCTAssertEqual(state.completedTricks.count, 8, "عدد الأكلات ليس 8")
        XCTAssertNotNil(state.lastRoundResult, "لم تُحتسب نتيجة الجولة")
        for player in state.players {
            XCTAssertEqual(state.hands[player.id]?.isEmpty, true, "\(player.name): بقيت أوراق بيده")
        }
    }

    func testHokumRoundPlaysToCompletionForEverySuit() throws {
        for suit in Suit.allCases {
            let state = try playFullRound(mode: .hokum, trumpSuit: suit, seed: 999)
            XCTAssertEqual(state.completedTricks.count, 8, "حكم \(suit): عدد الأكلات ليس 8")
            XCTAssertNotNil(state.lastRoundResult, "حكم \(suit): لم تُحتسب النتيجة")
        }
    }

    /// يلعب بعدة توزيعات مختلفة للتأكد من عدم وجود توزيعة تُعلّق اللعب.
    func testManyDealsAllCompleteWithoutDeadlock() throws {
        for seed in stride(from: UInt64(1), through: 25, by: 1) {
            let state = try playFullRound(mode: .sun, trumpSuit: nil, seed: seed)
            XCTAssertEqual(state.completedTricks.count, 8, "التوزيعة \(seed) لم تكتمل")
        }
    }

    /// كل أكلة يجب أن يكون لها فائز محدد، وإلا اختل احتساب النقاط.
    func testEveryTrickHasAResolvedWinner() throws {
        let state = try playFullRound(mode: .hokum, trumpSuit: .spades, seed: 777)
        for (index, trick) in state.completedTricks.enumerated() {
            XCTAssertNotNil(trick.winnerPlayerID, "الأكلة \(index + 1) بلا فائز")
            XCTAssertEqual(trick.playedCards.count, 4, "الأكلة \(index + 1) ناقصة أوراق")
        }
    }

    /// مجموع نقاط الجولة يجب أن يطابق ما تنص عليه قواعد البلوت.
    ///
    /// المجموع النهائي ليس نقاط الأوراق وحدها:
    /// - **حكم**: 152 نقطة أوراق + 10 لآخر أكلة = 162، ويُضاف 20 لكل مشروع "بلوت"
    ///   (ملك وبنت الحكم في يد واحدة)، فيكون المجموع 162 أو 182 حسب التوزيعة.
    /// - **صن**: 120 نقطة أوراق + 10 لآخر أكلة = 130، تُضاعف ×2 حسب العُرف المعتمد ⇒ 260.
    ///
    /// كانت مكافأة آخر أكلة تُطبَّق في صن فقط، فكان مجموع جولة الحكم 152 بدل 162.
    func testRoundTotalsMatchBalootRules() throws {
        for suit in Suit.allCases {
            let hokum = try playFullRound(mode: .hokum, trumpSuit: suit, seed: 4_242)
            let total = hokum.lastRoundResult?.teamPoints.values.reduce(0, +) ?? 0
            // 162 نقطة جولة + (0 أو 20 أو 40) من مشاريع البلوت المكتشفة.
            XCTAssertTrue([162, 182, 202].contains(total),
                          "حكم \(suit): المجموع \(total) لا يطابق 162 + مضاعفات مشروع البلوت")
            XCTAssertEqual((total - 162) % 20, 0, "حكم \(suit): الفائض ليس من مضاعفات 20")
        }

        let sun = try playFullRound(mode: .sun, trumpSuit: nil, seed: 4_242)
        let sunTotal = sun.lastRoundResult?.teamPoints.values.reduce(0, +) ?? 0
        // لا توجد مشاريع بلوت في صن (لا يوجد نوع حكم)، فالمجموع ثابت.
        XCTAssertEqual(sunTotal, 260, "مجموع جولة الصن يجب أن يكون 130 × 2")
    }

    /// مشروع البلوت يُحتسب في حكم فقط ولا يُحتسب في صن إطلاقًا،
    /// لأن الشرط هو امتلاك ملك وبنت **نوع الحكم** ولا حكم في الصن.
    func testBelotProjectAppliesOnlyInHokum() throws {
        for seed in stride(from: UInt64(100), through: 110, by: 1) {
            let sun = try playFullRound(mode: .sun, trumpSuit: nil, seed: seed)
            let total = sun.lastRoundResult?.teamPoints.values.reduce(0, +) ?? 0
            XCTAssertEqual(total, 260, "التوزيعة \(seed): ظهرت نقاط مشروع في جولة صن")
        }
    }
}
