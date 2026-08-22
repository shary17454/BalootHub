import XCTest
import BalootEngine
@testable import BalootHub

/// يتحقق من بنية اللعب الجماعي المستقبلية: النقل المجرّد، وحجب أوراق المتفرّج.
final class MultiplayerReadinessTests: XCTestCase {

    private func dealtState(seed: UInt64 = 2_026) throws -> GameState {
        let state = GameState.newLocalMatch(rules: .simpleBidding)
        return try GameEngine.apply(.dealCards(seed: seed), to: state)
    }

    // MARK: - طبقة النقل

    func testLoopbackTransportDeliversActionsInOrder() throws {
        let transport = LocalLoopbackTransport()
        let state = try dealtState()
        let playerID = state.players[0].id
        let card = try XCTUnwrap(state.hands[playerID]?.first)

        try transport.send(.placeBid(playerID: playerID, bid: .sun))
        try transport.send(.playCard(playerID: playerID, card: card))

        let received = transport.drainIncoming()
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.first, .placeBid(playerID: playerID, bid: .sun))
        XCTAssertTrue(transport.drainIncoming().isEmpty, "السحب الثاني لازم يكون فارغًا")
    }

    func testSendingOnClosedTransportThrows() {
        let transport = LocalLoopbackTransport()
        transport.setReady(false)

        XCTAssertThrowsError(try transport.send(.finishRound)) { error in
            XCTAssertEqual(error as? MatchTransportError, .notReady)
        }
    }

    /// أهم خاصية للعب عن بُعد: الجولة تُعاد بناؤها من الأفعال المنقولة وحدها.
    func testStateRebuildsFromTransportedActionsAlone() throws {
        let transport = LocalLoopbackTransport()
        let initial = GameState.newLocalMatch(rules: .simpleBidding)
        var local = initial

        let deal = GameAction.dealCards(seed: 777)
        local = try GameEngine.apply(deal, to: local)
        try transport.send(deal)

        let humanID = try XCTUnwrap(local.players.first { $0.kind == .human }?.id)
        let choose = GameAction.chooseMode(playerID: humanID, mode: .hokum, trumpSuit: .spades)
        local = try GameEngine.apply(choose, to: local)
        try transport.send(choose)

        let remote = try GameEngine.replay(initialState: initial, actions: transport.drainIncoming())

        XCTAssertEqual(remote.phase, local.phase)
        XCTAssertEqual(remote.trumpSuit, local.trumpSuit)
        XCTAssertEqual(remote.hands.mapValues(\.count), local.hands.mapValues(\.count))
    }

    // MARK: - وضع المتفرّج

    func testSpectatorSnapshotHidesEveryHand() throws {
        let state = try dealtState()
        let snapshot = SpectatorFeed.snapshot(of: state)

        XCTAssertTrue(snapshot.state.hands.allSatisfy { $0.value.isEmpty }, "المتفرّج ما يرى أي ورقة")
        XCTAssertTrue(SpectatorFeed.isFullyRedacted(snapshot))
    }

    func testSpectatorSnapshotKeepsPublicCardCounts() throws {
        let state = try dealtState()
        let snapshot = SpectatorFeed.snapshot(of: state)

        XCTAssertEqual(snapshot.handCounts.count, 4)
        XCTAssertTrue(snapshot.handCounts.values.allSatisfy { $0 == 8 }, "عدد الأوراق معلومة عامة على الطاولة")
    }

    func testRevealingOnePlayerLeavesOthersHidden() throws {
        let state = try dealtState()
        let owner = try XCTUnwrap(state.players.first { $0.seat == .south }?.id)
        let snapshot = SpectatorFeed.snapshot(of: state, revealing: owner)

        XCTAssertEqual(snapshot.state.hands[owner]?.count, 8, "صاحب الدور يرى يده")
        for player in state.players where player.id != owner {
            XCTAssertEqual(snapshot.state.hands[player.id]?.isEmpty, true, "\(player.name): يده مكشوفة للمتفرّج")
        }
        XCTAssertTrue(SpectatorFeed.isFullyRedacted(snapshot))
    }

    /// الحجب بالحذف لا بالإخفاء: التوزيع الأصلي والأوراق غير الموزَّعة يكشفان اليد كاملة.
    func testSnapshotDropsOriginalHandsAndUndealtCards() throws {
        let state = try dealtState()
        XCTAssertFalse(state.originalHands.isEmpty, "الحالة الأصلية يفترض تحتوي التوزيع الأول")

        let snapshot = SpectatorFeed.snapshot(of: state, revealing: state.players[0].id)

        XCTAssertTrue(snapshot.state.originalHands.allSatisfy { $0.value.isEmpty })
        XCTAssertTrue(snapshot.state.undealtCards.isEmpty)
    }

    func testSnapshotPreservesPublicRoundInformation() throws {
        let state = try dealtState()
        let snapshot = SpectatorFeed.snapshot(of: state)

        XCTAssertEqual(snapshot.state.phase, state.phase)
        XCTAssertEqual(snapshot.state.players.map(\.id), state.players.map(\.id))
        XCTAssertEqual(snapshot.state.actionHistory, state.actionHistory)
        XCTAssertEqual(snapshot.state.roundNumber, state.roundNumber)
    }

    // MARK: - قائمة الجاهزية

    func testReadinessListHasUniqueIdentifiers() {
        let ids = MultiplayerReadiness.items.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testReadinessListSeparatesDoneFromPending() {
        XCTAssertGreaterThan(MultiplayerReadiness.readyCount, 0, "لازم توثيق ما جُهّز فعلًا")
        XCTAssertTrue(
            MultiplayerReadiness.items.contains { $0.status == .pending },
            "الأونلاين غير مفعّل، فلازم تبقى بنود معلّقة صريحة بدل ادعاء الاكتمال"
        )
    }

    func testGameCenterIsStillPending() {
        let gameCenter = MultiplayerReadiness.items.first { $0.id == "game-center-auth" }
        XCTAssertEqual(gameCenter?.status, .pending, "لا توجد مصادقة Game Center في هذا الإصدار")
    }
}
