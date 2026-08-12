import Testing
@testable import BalootEngine

@Suite("مختبر البلوت Sandbox")
struct BalootSandboxTests {
    @Test("يبني موقفًا يدويًا قابلًا للتشغيل من المحرك")
    func buildsPlayableManualState() throws {
        let configuration = sandboxConfiguration()

        let state = try BalootSandbox.makeState(configuration: configuration)

        #expect(state.phase == .playing)
        #expect(state.mode == .hokum)
        #expect(state.trumpSuit == .hearts)
        #expect(state.bidding.multiplier == .double)
        #expect(state.currentTurnPlayerID == BalootSandbox.playerID(for: .south))
        #expect(state.currentTrick?.playedCards.count == 3)
        #expect(GameEngine.legalCards(for: BalootSandbox.playerID(for: .south), state: state) == [
            PlayingCard(suit: .hearts, rank: .jack)
        ])
    }

    @Test("تجربة ورقة ممنوعة تعيد سبب الرفض من GameEngine")
    func previewReportsInvalidMoveReason() throws {
        let configuration = sandboxConfiguration()

        let preview = try BalootSandbox.preview(
            playing: PlayingCard(suit: .clubs, rank: .ace),
            configuration: configuration
        )

        #expect(!preview.isLegal)
        #expect(preview.invalidReason == .mustPlayTrumpWhenVoidOfSuit || preview.invalidReason == .mustOvertrump)
        #expect(preview.afterState == nil)
        #expect(preview.legalCards == [PlayingCard(suit: .hearts, rank: .jack)])
    }

    @Test("تجربة ورقة قانونية تكمل الأكلة وتحدد الفائز والنقاط")
    func previewAppliesLegalCardThroughEngine() throws {
        let configuration = sandboxConfiguration()
        let card = PlayingCard(suit: .hearts, rank: .jack)

        let preview = try BalootSandbox.preview(playing: card, configuration: configuration)

        #expect(preview.isLegal)
        #expect(preview.invalidReason == nil)
        #expect(preview.afterState?.completedTricks.count == 1)
        #expect(preview.completedTrickWinnerID == BalootSandbox.playerID(for: .south))
        #expect(preview.completedTrickPoints == 45)
        #expect(preview.afterState?.teamTrickPoints[BalootSandbox.teamID(for: .south)] == 45)
        #expect(preview.expertCard == card)
    }

    @Test("يرفض تكرار ورقة بين اليد والأكلة")
    func rejectsDuplicateCards() throws {
        var configuration = sandboxConfiguration()
        configuration.handsBySeat[.south]?.append(PlayingCard(suit: .spades, rank: .ace))

        #expect(throws: BalootSandboxError.duplicateCard(PlayingCard(suit: .spades, rank: .ace))) {
            try BalootSandbox.makeState(configuration: configuration)
        }
    }

    @Test("يرفض ترتيب أكلة لا يطابق ترتيب المقاعد")
    func rejectsInvalidTrickOrder() throws {
        var configuration = sandboxConfiguration()
        configuration.currentTrickCards = [
            BalootSandboxPlayedCard(seat: .west, card: PlayingCard(suit: .spades, rank: .ace)),
            BalootSandboxPlayedCard(seat: .north, card: PlayingCard(suit: .spades, rank: .king)),
            BalootSandboxPlayedCard(seat: .south, card: PlayingCard(suit: .diamonds, rank: .ten))
        ]

        #expect(throws: BalootSandboxError.currentTrickOrderMismatch(expected: .east, actual: .south)) {
            try BalootSandbox.makeState(configuration: configuration)
        }
    }

    private func sandboxConfiguration() -> BalootSandboxConfiguration {
        BalootSandboxConfiguration(
            mode: .hokum,
            trumpSuit: .hearts,
            multiplier: .double,
            currentTurnSeat: .south,
            handsBySeat: [
                .south: [
                    PlayingCard(suit: .hearts, rank: .jack),
                    PlayingCard(suit: .clubs, rank: .ace)
                ],
                .west: [
                    PlayingCard(suit: .clubs, rank: .seven),
                    PlayingCard(suit: .diamonds, rank: .seven)
                ],
                .north: [
                    PlayingCard(suit: .clubs, rank: .eight),
                    PlayingCard(suit: .diamonds, rank: .eight)
                ],
                .east: [
                    PlayingCard(suit: .clubs, rank: .nine),
                    PlayingCard(suit: .diamonds, rank: .nine)
                ]
            ],
            currentTrickCards: [
                BalootSandboxPlayedCard(seat: .west, card: PlayingCard(suit: .spades, rank: .ace)),
                BalootSandboxPlayedCard(seat: .north, card: PlayingCard(suit: .spades, rank: .king)),
                BalootSandboxPlayedCard(seat: .east, card: PlayingCard(suit: .diamonds, rank: .ten))
            ]
        )
    }
}
