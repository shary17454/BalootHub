import SwiftUI
import BalootEngine

struct RoundReplayView: View {
    let initialState: GameState
    let actions: [GameAction]
    let title: String
    let contextText: String?

    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var isPlaying = false
    @State private var speed: ReplayPlaybackSpeed = .normal
    @State private var showAllHands = false

    private var snapshot: GameState {
        (try? GameEngine.replay(initialState: initialState, actions: actions, upTo: step)) ?? initialState
    }

    private var currentAction: GameAction? {
        guard step > 0, actions.indices.contains(step - 1) else { return nil }
        return actions[step - 1]
    }

    init(
        initialState: GameState,
        actions: [GameAction],
        title: String = "إعادة الجولة",
        contextText: String? = nil
    ) {
        self.initialState = initialState
        self.actions = actions
        self.title = title
        self.contextText = contextText
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                progressCard
                replayTable
                replayDetails
                replayTimeline
                controls
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("تم") { dismiss() }
            }
        }
        .task(id: "\(isPlaying)-\(speed.rawValue)") {
            guard isPlaying else { return }
            while isPlaying, step < actions.count, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(speed.delayMilliseconds))
                guard !Task.isCancelled else { return }
                step += 1
            }
            if step >= actions.count {
                isPlaying = false
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label("Replay", systemImage: "clock.arrow.circlepath")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)
                Spacer()
                Text("\(step) / \(actions.count)")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Slider(
                value: Binding(
                    get: { Double(step) },
                    set: {
                        step = min(actions.count, max(0, Int($0.rounded())))
                        if step >= actions.count { isPlaying = false }
                    }
                ),
                in: 0...Double(max(actions.count, 1)),
                step: 1
            )

            Text(actionTitle(currentAction, in: snapshot))
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let contextText {
                Text(contextText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var replayTimeline: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("سجل الإعادة".localized, systemImage: "list.bullet.rectangle.portrait")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                let isCurrent = index == step - 1
                let isCompleted = index < step
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: actionSystemImage(action))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isCurrent ? AppColor.primary : actionTint(action).opacity(isCompleted ? 1 : 0.45))
                        .frame(width: 24, height: 24)
                        .background(
                            (isCurrent ? AppColor.primary : actionTint(action))
                                .opacity(isCurrent ? 0.16 : 0.09),
                            in: Circle()
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(actionTitle(action, in: initialState))
                            .font(AppTypography.caption.weight(isCurrent ? .semibold : .regular))
                            .foregroundStyle(isCompleted ? AppColor.textPrimary : AppColor.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        Text(timelineStatusTitle(index: index))
                            .font(.caption2)
                            .foregroundStyle(isCurrent ? AppColor.primary : AppColor.textSecondary)
                    }

                    Spacer(minLength: AppSpacing.xs)

                    Text("\(index + 1)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(AppSpacing.xs)
                .background(isCurrent ? AppColor.primary.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                .accessibilityElement(children: .combine)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var replayTable: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                seatCard(.north, state: snapshot)
            }
            HStack {
                seatCard(.west, state: snapshot)
                Spacer(minLength: AppSpacing.md)
                trickCards(snapshot)
                Spacer(minLength: AppSpacing.md)
                seatCard(.east, state: snapshot)
            }
            HStack {
                seatCard(.south, state: snapshot)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var replayDetails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            detailRow("المرحلة", phaseTitle(snapshot.phase))
            if let mode = snapshot.mode {
                detailRow("النمط", modeTitle(mode, trumpSuit: snapshot.trumpSuit))
            }
            if snapshot.bidding.multiplier != .none {
                detailRow("المضاعفة", snapshot.bidding.multiplier.arabicName)
            }
            detailRow("الأكلات المكتملة", "\(snapshot.completedTricks.count)")
            if let currentTurn = snapshot.currentTurnPlayerID {
                detailRow("الدور", playerName(currentTurn, in: snapshot))
            }
            if !snapshot.bidding.bids.isEmpty {
                Divider()
                Text("المزايدة")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                ForEach(Array(snapshot.bidding.bids.enumerated()), id: \.offset) { _, record in
                    detailRow(playerName(record.playerID, in: snapshot), bidTitle(record.bid))
                }
            }
            if !snapshot.declaredProjects.isEmpty || !snapshot.awardedProjects.isEmpty {
                Divider()
                projectList(title: "المشاريع المعلنة", projects: snapshot.declaredProjects, state: snapshot)
                projectList(title: "المشاريع المحتسَبة", projects: snapshot.awardedProjects, state: snapshot)
            }
            if let result = snapshot.lastRoundResult {
                Divider()
                ForEach(snapshot.teams) { team in
                    detailRow(team.name, "\(result.teamPoints[team.id] ?? 0)")
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var controls: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Button {
                    isPlaying = false
                    step = previousTrickStep()
                } label: {
                    Image(systemName: "backward.end.fill")
                }
                .disabled(step == 0)

                Button {
                    step = max(0, step - 1)
                    isPlaying = false
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .disabled(step == 0)

                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 34)
                }
                .disabled(actions.isEmpty || step >= actions.count)

                Button {
                    step = min(actions.count, step + 1)
                    isPlaying = false
                } label: {
                    Image(systemName: "chevron.forward")
                }
                .disabled(step >= actions.count)

                Button {
                    isPlaying = false
                    step = nextTrickStep()
                } label: {
                    Image(systemName: "forward.end.fill")
                }
                .disabled(step >= actions.count)
            }
            .buttonStyle(.bordered)

            Picker("السرعة", selection: $speed) {
                ForEach(ReplayPlaybackSpeed.allCases) { speed in
                    Text(speed.title).tag(speed)
                }
            }
            .pickerStyle(.segmented)

            Toggle("إظهار كل الأيدي للتحليل", isOn: $showAllHands)
                .font(AppTypography.caption)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func seatCard(_ seat: SeatPosition, state: GameState) -> some View {
        let player = state.player(at: seat)
        let hand = player.flatMap { state.hands[$0.id] } ?? []
        return VStack(spacing: AppSpacing.xxs) {
            Image(systemName: state.currentTurnPlayerID == player?.id ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle")
                .font(.title2)
                .foregroundStyle(state.currentTurnPlayerID == player?.id ? AppColor.success : AppColor.textSecondary)
            Text(player?.name ?? "")
                .font(AppTypography.caption.weight(.semibold))
                .lineLimit(1)
            Text("\(hand.count) أوراق")
                .font(.caption2)
                .foregroundStyle(AppColor.textSecondary)
            if showAllHands, !hand.isEmpty {
                Text(hand.map(\.displayLabel).joined(separator: " "))
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: 92)
        .frame(minHeight: showAllHands ? 104 : 70)
        .padding(AppSpacing.xs)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func trickCards(_ state: GameState) -> some View {
        let cards = state.currentTrick?.playedCards ?? state.completedTricks.last?.playedCards ?? []
        return VStack(spacing: AppSpacing.xs) {
            if cards.isEmpty {
                Text("لا توجد أوراق على الطاولة")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 42), spacing: AppSpacing.xs)], spacing: AppSpacing.xs) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { _, played in
                        ReplayCardView(card: played.card)
                    }
                }
                if let winnerID = state.completedTricks.last?.winnerPlayerID,
                   state.currentTrick == nil,
                   !cards.isEmpty {
                    Text("الفائز: \(playerName(winnerID, in: state))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.success)
                }
            }
        }
        .frame(width: 132)
        .frame(minHeight: 118)
        .padding(AppSpacing.sm)
        .background(AppColor.background.opacity(0.45), in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func projectList(title: String, projects: [Project], state: GameState) -> some View {
        Group {
            if !projects.isEmpty {
                Text(title)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                ForEach(projects) { project in
                    detailRow(
                        playerName(project.playerID, in: state),
                        "\(project.kind.arabicName) +\(project.points)"
                    )
                }
            }
        }
    }

    private func previousTrickStep() -> Int {
        let currentTricks = snapshot.completedTricks.count
        var best = 0
        guard step > 0 else { return 0 }
        for candidate in 0..<step {
            let candidateState = try? GameEngine.replay(initialState: initialState, actions: actions, upTo: candidate)
            if (candidateState?.completedTricks.count ?? 0) < currentTricks {
                best = candidate
            }
        }
        return best
    }

    private func nextTrickStep() -> Int {
        let currentTricks = snapshot.completedTricks.count
        guard step < actions.count else { return actions.count }
        for candidate in (step + 1)...actions.count {
            let candidateState = try? GameEngine.replay(initialState: initialState, actions: actions, upTo: candidate)
            if (candidateState?.completedTricks.count ?? 0) > currentTricks || candidate == actions.count {
                return candidate
            }
        }
        return actions.count
    }

    private func actionTitle(_ action: GameAction?, in state: GameState) -> String {
        guard let action else { return "بداية الجولة" }
        switch action {
        case .dealCards:
            return "تم توزيع الأوراق"
        case .chooseMode(let playerID, let mode, let trumpSuit):
            return "\(playerName(playerID, in: state)) اختار \(modeTitle(mode, trumpSuit: trumpSuit))"
        case .placeBid(let playerID, let bid):
            return "\(playerName(playerID, in: state)): \(bidTitle(bid))"
        case .raiseMultiplier(let playerID, let level):
            return "\(playerName(playerID, in: state)) طلب \(level.arabicName)"
        case .passMultiplier(let playerID):
            return "\(playerName(playerID, in: state)) قال بس في المضاعفة"
        case .lockMultiplier(let playerID):
            return "\(playerName(playerID, in: state)) قفل المضاعفة"
        case .declareProjects(let playerID, let projects):
            if projects.isEmpty { return "\(playerName(playerID, in: state)) لم يعلن مشروعًا" }
            return "\(playerName(playerID, in: state)) أعلن \(projects.map { $0.kind.arabicName }.joined(separator: "، "))"
        case .playCard(let playerID, let card):
            return "\(playerName(playerID, in: state)) لعب \(card.displayLabel)"
        case .finishRound:
            return "تم احتساب نتيجة الجولة"
        }
    }

    private func timelineStatusTitle(index: Int) -> String {
        if index == step - 1 { return "الحدث الحالي".localized }
        if index < step { return "تم عرضه".localized }
        return "قادم".localized
    }

    private func actionSystemImage(_ action: GameAction) -> String {
        switch action {
        case .dealCards:
            return "rectangle.stack.fill"
        case .chooseMode, .placeBid:
            return "hand.raised.fill"
        case .raiseMultiplier, .passMultiplier, .lockMultiplier:
            return "multiply.circle.fill"
        case .declareProjects:
            return "sparkles"
        case .playCard:
            return "suit.spade.fill"
        case .finishRound:
            return "flag.checkered"
        }
    }

    private func actionTint(_ action: GameAction) -> Color {
        switch action {
        case .dealCards:
            return AppColor.textSecondary
        case .chooseMode, .placeBid:
            return AppColor.primary
        case .raiseMultiplier, .passMultiplier, .lockMultiplier:
            return AppColor.warning
        case .declareProjects:
            return AppColor.accent
        case .playCard:
            return AppColor.success
        case .finishRound:
            return AppColor.primary
        }
    }

    private func playerName(_ id: Player.ID, in state: GameState) -> String {
        state.player(id: id)?.name ?? "لاعب"
    }

    private func phaseTitle(_ phase: GamePhase) -> String {
        switch phase {
        case .setup: "تجهيز"
        case .dealing: "توزيع"
        case .bidding: "مزايدة"
        case .declaring: "إعلان مشاريع"
        case .playing: "لعب"
        case .scoring: "احتساب"
        case .finished: "منتهية"
        }
    }

    private func modeTitle(_ mode: GameMode, trumpSuit: Suit?) -> String {
        switch mode {
        case .sun:
            return "صن"
        case .hokum:
            return trumpSuit.map { "حكم \($0.symbol)" } ?? "حكم"
        }
    }

    private func bidTitle(_ bid: Bid) -> String {
        switch bid {
        case .pass:
            return "بس"
        case .sun:
            return "صن"
        case .hokum(let suit):
            return "حكم \(suit.symbol)"
        }
    }
}

private enum ReplayPlaybackSpeed: String, CaseIterable, Identifiable {
    case slow
    case normal
    case fast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slow: "بطيء"
        case .normal: "عادي"
        case .fast: "سريع"
        }
    }

    var delayMilliseconds: Int {
        switch self {
        case .slow: 1_100
        case .normal: 650
        case .fast: 300
        }
    }
}

private struct ReplayCardView: View {
    let card: PlayingCard

    private var isRed: Bool { card.suit.isRed }

    var body: some View {
        VStack(spacing: 1) {
            Text(card.rank.shortLabel)
                .font(.caption.weight(.bold))
            Text(card.suit.symbol)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(isRed ? AppColor.danger : AppColor.textPrimary)
        .frame(width: 38, height: 50)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.small))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.small).stroke(AppColor.border, lineWidth: 1))
        .accessibilityLabel(card.accessibilityName)
    }
}
