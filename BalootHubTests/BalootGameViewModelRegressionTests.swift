import XCTest
import BalootEngine
@testable import BalootHub

/// اختبارات تحرس أخطاءً حقيقية وقعت في `BalootGameViewModel`، اكتُشفت بمراجعة كود
/// شاملة، حتى لا تعود. تستخدم وضع "أربعة أشخاص" (`.localHumans`) عمدًا: كل اللاعبين
/// بشريون من منظور المحرك، فكل فعل يمر متزامنًا عبر `perform(_:)` بلا مهمة آلية
/// غير متزامنة — هذا يجعل السيناريو حتميًا بالكامل وقابلًا للتكرار.
final class BalootGameViewModelRegressionTests: XCTestCase {

    /// يدفع جولة كاملة بالتمرير في الجولتين الأولى والثانية للمزايدة، فتصير دورة
    /// ميتة (بدون شراء) — مسار حتمي 100% لا يعتمد على قوة يد أي لاعب.
    @MainActor
    private func playVoidRound(_ viewModel: BalootGameViewModel) throws {
        for _ in 0..<8 {
            viewModel.revealLocalHumanHand()
            let bid = try XCTUnwrap(viewModel.legalBidsForHuman.first { $0 == .pass })
            viewModel.placeBid(bid)
        }
        XCTAssertEqual(viewModel.state.phase, .finished)
        XCTAssertEqual(viewModel.state.bidding.stage, .voided)
    }

    /// يدفع جولة كاملة بشراء صن، بلا مضاعفات ولا مشاريع، وبلعب أول ورقة شرعية دومًا
    /// حتى النهاية — نتيجة الجولة نفسها غير مهمة هنا، المهم فقط أنها **جولة حقيقية
    /// اشتُريت فيها**، بخلاف الدورة الميتة، لاختبار دوران الموزّع في الحالتين معًا.
    @MainActor
    private func playBoughtRound(_ viewModel: BalootGameViewModel) throws {
        viewModel.revealLocalHumanHand()
        viewModel.placeBid(.sun)

        while viewModel.state.phase != .finished {
            viewModel.revealLocalHumanHand()
            switch viewModel.state.phase {
            case .bidding where viewModel.isShowingHumanMultiplierControls:
                viewModel.passMultiplier()
            case .declaring:
                viewModel.skipDeclaration()
            case .scoring:
                viewModel.finishRoundIfNeeded()
            case .playing:
                let card = try XCTUnwrap(viewModel.legalCardsForHuman.first)
                viewModel.play(card)
            default:
                XCTFail("حالة غير متوقعة: \(viewModel.state.phase)")
                return
            }
        }
    }

    /// **يحرس الخلل الحرج**: كانت لقطة إعادة العرض الابتدائية تُبنى بدور الموزّع
    /// **قبل** دورانه، فتختلف الأوراق الموزَّعة عن اللعب الحي بدءًا من الجولة
    /// الثانية، ويفشل إعادة تطبيق أول فعل مزايدة مسجَّل. النتيجة عمليًا: شاشة
    /// إعادة العرض تسقط بصمت إلى حالة فارغة لكل جولة بعد الأولى.
    @MainActor
    func testReplayInitialStateMatchesLiveDealerAcrossRounds() throws {
        let viewModel = BalootGameViewModel(tableMode: .localHumans, rules: .standard)
        viewModel.deal(seed: 9)
        try playVoidRound(viewModel) // الجولة 1: دورة ميتة، الموزّع يدور داخل المحرك نفسه.

        viewModel.startNextRound()
        let dealerBeforeRound2 = viewModel.state.dealerSeat
        try playBoughtRound(viewModel) // الجولة 2: شراء حقيقي.

        // اللقطة الابتدائية المحفوظة لإعادة عرض الجولة 2 يجب أن تحمل موزّع الجولة 2
        // نفسه (الذي دار فعلًا قبل توزيعها)، لا موزّع الجولة 1 القديم.
        XCTAssertEqual(viewModel.currentRoundReplayInitialState.dealerSeat, dealerBeforeRound2)

        // إعادة تطبيق كل الأفعال المسجَّلة على هذه اللقطة يجب أن تنجح بلا خطأ
        // وتُنتج نفس دور المشتري والنمط اللذين حدثا فعلًا في اللعب الحي — لا حالة
        // فارغة ساقطة بصمت بسبب دور مزايدة مرفوض على مقعد خاطئ.
        let replayed = try GameEngine.replay(
            initialState: viewModel.currentRoundReplayInitialState,
            actions: viewModel.state.actionHistory
        )
        XCTAssertEqual(replayed.bidding.declarerID, viewModel.state.bidding.declarerID)
        XCTAssertEqual(replayed.mode, viewModel.state.mode)
        XCTAssertEqual(replayed.dealerSeat, viewModel.state.dealerSeat)
    }

    /// **يحرس الخلل العالي**: القفل فعل **خارج الدور** بتصميم المحرك (يملكه الفريق
    /// صاحب المضاعفة الحالية، وهو غالبًا ليس صاحب الدور الآن لأن الدور ينتقل للفريق
    /// المقابل فور كل رفع). ربط `lockMultiplier()` بشرط "دور اللاعب البشري الحالي"
    /// كان يجعل الزر يظهر لكنه لا يفعل شيئًا في الحالة الوحيدة التي يظهر فيها.
    @MainActor
    func testLockMultiplierSucceedsWhileOffTurn() throws {
        let viewModel = BalootGameViewModel(tableMode: .localHumans, rules: .standard)
        viewModel.deal(seed: 9)

        viewModel.revealLocalHumanHand()
        viewModel.placeBid(.sun)

        // بعد الشراء يبدأ دور المضاعفة لخصوم المشتري؛ أول من يملك الدور يرفع دبل،
        // فيصبح فريقه صاحب حق القفل على هذا الدبل تحديدًا.
        viewModel.revealLocalHumanHand()
        XCTAssertEqual(viewModel.nextAvailableMultiplier, .double)
        viewModel.raiseMultiplier(to: .double)

        // الدور انتقل الآن لفريق المشتري (الطرف المقابل) لِيَرُدّ (يرفع أو يمرّر)،
        // لكن حق القفل يبقى لصاحب آخر رفع فعلي — أي **ليس** دور اللاعب الحالي.
        // `perform` يُخفي اليد تلقائيًا بعد كل فعل، فحتى لو تجاهلنا فارق الفريق
        // فالتأكيد التالي يبقى صحيحًا لأن لا أحد كاشف يده الآن أصلًا.
        XCTAssertTrue(viewModel.canLockMultiplier)
        XCTAssertFalse(viewModel.canCurrentHumanAct, "القفل هنا يجب أن يكون خارج الدور فعلًا وإلا فالاختبار لا يغطي الحالة المقصودة")

        viewModel.lockMultiplier()

        XCTAssertTrue(viewModel.state.bidding.isLocked, "القفل لم يُطبَّق رغم توفر شرطه")
        XCTAssertFalse(viewModel.canLockMultiplier, "القفل انتهى، يجب ألا يبقى متاحًا")
    }
}
