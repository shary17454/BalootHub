import SwiftUI
import BalootEngine

struct BalootSandboxView: View {
    @State private var configuration = BalootSandbox.defaultConfiguration
    @State private var selectedCard: PlayingCard?
    @State private var preview: BalootSandboxPlayPreview?
    @State private var errorMessage: String?

    private var state: GameState? {
        try? BalootSandbox.makeState(configuration: configuration)
    }

    private var currentHand: [PlayingCard] {
        sorted(configuration.handsBySeat[configuration.currentTurnSeat] ?? [])
    }

    private var cardsUnavailableOutsideCurrentHand: Set<PlayingCard> {
        var used = Set(configuration.currentTrickCards.map(\.card))
        for seat in SeatPosition.allCases where seat != configuration.currentTurnSeat {
            used.formUnion(configuration.handsBySeat[seat] ?? [])
        }
        return used
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                sandboxControls
                tableState
                handEditor
                handPicker
                if let preview {
                    resultCard(preview)
                }
                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("مختبر البلوت".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Baloot Sandbox".localized, systemImage: "slider.horizontal.3")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)
            Text("موقف حكم جاهز للتجربة: الأكلة شبه مكتملة ودورك الآن. اختر ورقة وشاهد هل يقبلها المحرك وماذا يحدث بعدها.".localized)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var sandboxControls: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("إعدادات المختبر".localized, systemImage: "slider.horizontal.3")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            Picker("النمط".localized, selection: modeBinding) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Text(mode.arabicName.localized).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if configuration.mode == .hokum {
                Picker("لون الحكم".localized, selection: trumpSuitBinding) {
                    ForEach(Suit.allCases) { suit in
                        Text("\(suit.symbol) \(suit.spokenName)").tag(suit)
                    }
                }
            }

            Picker("المضاعف".localized, selection: multiplierBinding) {
                ForEach(Multiplier.allCases, id: \.self) { multiplier in
                    Text(multiplier.arabicName.localized).tag(multiplier)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var tableState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("الموقف".localized, systemImage: "tablecells.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                metric("النمط".localized, modeText, icon: "crown.fill")
                metric("المضاعف".localized, configuration.multiplier.arabicName.localized, icon: "multiply.circle.fill")
                metric("الدور".localized, seatTitle(configuration.currentTurnSeat), icon: "person.crop.circle.badge.checkmark")
                metric("الأوراق القانونية".localized, legalCardsText(), icon: "checkmark.seal.fill")
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("الأكلة الحالية".localized)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                ForEach(configuration.currentTrickCards, id: \.card) { played in
                    InfoRow(
                        icon: "suit.spade.fill",
                        title: seatTitle(played.seat),
                        value: played.card.accessibilityName
                    )
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var handEditor: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("يد اللاعب الحالي".localized, systemImage: "rectangle.stack.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)
                Spacer()
                Text("\(currentHand.count) / 8")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(currentHand.isEmpty ? AppColor.danger : AppColor.textSecondary)
            }

            if currentHand.isEmpty {
                Text("اختر ورقة واحدة على الأقل حتى يستطيع المحرك تجربة الحركة.".localized)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(currentHand) { card in
                            SandboxMiniCard(card: card, isSelected: true)
                                .onTapGesture { toggleHandCard(card) }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("تعديل اليد".localized)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)

                ForEach(Suit.allCases) { suit in
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(suit.spokenName)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 4), spacing: AppSpacing.xs) {
                            ForEach(Rank.allCases) { rank in
                                let card = PlayingCard(suit: suit, rank: rank)
                                let selected = currentHand.contains(card)
                                let unavailable = cardsUnavailableOutsideCurrentHand.contains(card)
                                let full = !selected && currentHand.count >= 8
                                Button {
                                    toggleHandCard(card)
                                } label: {
                                    SandboxMiniCard(card: card, isSelected: selected)
                                }
                                .buttonStyle(.plain)
                                .disabled(unavailable || full)
                                .opacity(unavailable || full ? 0.35 : 1)
                                .accessibilityLabel(cardAccessibilityLabel(card, selected: selected, unavailable: unavailable))
                            }
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var handPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("جرّب ورقة".localized, systemImage: "hand.tap.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            ForEach(currentHand) { card in
                Button {
                    play(card)
                } label: {
                    HStack {
                        Text(card.accessibilityName)
                            .font(AppTypography.subheadline.weight(.semibold))
                        Spacer()
                        if selectedCard == card {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.success)
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func resultCard(_ preview: BalootSandboxPlayPreview) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(
                preview.isLegal ? "الورقة قانونية".localized : "الورقة ممنوعة".localized,
                systemImage: preview.isLegal ? "checkmark.seal.fill" : "xmark.octagon.fill"
            )
            .font(AppTypography.headline)
            .foregroundStyle(preview.isLegal ? AppColor.success : AppColor.danger)

            InfoRow(icon: "rectangle.portrait", title: "اختيارك".localized, value: preview.selectedCard.accessibilityName)
            if let expertCard = preview.expertCard {
                InfoRow(icon: "brain.head.profile", title: "اختيار الخبير".localized, value: expertCard.accessibilityName)
            }
            if let reason = preview.invalidReason {
                Text(RuleExplanationFormatter.illegalMoveExplanation(for: preview.selectedCard, reason: reason, trumpSuit: configuration.trumpSuit))
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if let winnerID = preview.completedTrickWinnerID,
                   let winner = preview.afterState?.player(id: winnerID) {
                    InfoRow(icon: "crown.fill", title: "الفائز بالأكلة".localized, value: winner.name)
                }
                if let points = preview.completedTrickPoints {
                    InfoRow(icon: "sum", title: "نقاط الأكلة".localized, value: "\(points)")
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func metric(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Label(title.localized, systemImage: icon)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func play(_ card: PlayingCard) {
        selectedCard = card
        errorMessage = nil
        do {
            preview = try BalootSandbox.preview(playing: card, configuration: configuration)
        } catch {
            preview = nil
            errorMessage = String(format: "تعذّر تشغيل الموقف: %@".localized, error.localizedDescription)
        }
    }

    private var modeBinding: Binding<GameMode> {
        Binding(
            get: { configuration.mode },
            set: { mode in
                resetPreview()
                configuration.mode = mode
                configuration.trumpSuit = mode == .hokum ? (configuration.trumpSuit ?? .hearts) : nil
            }
        )
    }

    private var trumpSuitBinding: Binding<Suit> {
        Binding(
            get: { configuration.trumpSuit ?? .hearts },
            set: { suit in
                resetPreview()
                configuration.trumpSuit = suit
            }
        )
    }

    private var multiplierBinding: Binding<Multiplier> {
        Binding(
            get: { configuration.multiplier },
            set: { multiplier in
                resetPreview()
                configuration.multiplier = multiplier
            }
        )
    }

    private var modeText: String {
        switch configuration.mode {
        case .sun:
            return "صن".localized
        case .hokum:
            return "\("حكم".localized) \(configuration.trumpSuit?.spokenName ?? "")"
        }
    }

    private func resetPreview() {
        selectedCard = nil
        preview = nil
        errorMessage = nil
    }

    private func toggleHandCard(_ card: PlayingCard) {
        resetPreview()
        var hand = configuration.handsBySeat[configuration.currentTurnSeat] ?? []
        if hand.contains(card) {
            hand.removeAll { $0 == card }
        } else if hand.count < 8 && !cardsUnavailableOutsideCurrentHand.contains(card) {
            hand.append(card)
        }
        configuration.handsBySeat[configuration.currentTurnSeat] = sorted(hand)
    }

    private func cardAccessibilityLabel(_ card: PlayingCard, selected: Bool, unavailable: Bool) -> String {
        if unavailable {
            return "\(card.accessibilityName)، \("مستخدمة في الموقف".localized)"
        }
        if selected {
            return "\(card.accessibilityName)، \("مختارة".localized)"
        }
        return card.accessibilityName
    }

    private func legalCardsText() -> String {
        guard let cards = try? BalootSandbox.legalCards(configuration: configuration), !cards.isEmpty else {
            return "لا يوجد".localized
        }
        return cards.map(\.accessibilityName).joined(separator: "، ")
    }

    private func sorted(_ cards: [PlayingCard]) -> [PlayingCard] {
        cards.sorted {
            if $0.suit.ordinal != $1.suit.ordinal { return $0.suit.ordinal < $1.suit.ordinal }
            return $0.rank.sequenceOrder < $1.rank.sequenceOrder
        }
    }

    private func seatTitle(_ seat: SeatPosition) -> String {
        switch seat {
        case .south: "جنوب".localized
        case .west: "غرب".localized
        case .north: "شمال".localized
        case .east: "شرق".localized
        }
    }
}

private struct SandboxMiniCard: View {
    let card: PlayingCard
    let isSelected: Bool

    private var isRed: Bool { card.suit.isRed }

    var body: some View {
        VStack(spacing: 2) {
            Text(card.rank.shortLabel)
                .font(.system(.caption, design: .rounded).weight(.bold))
            Image(systemName: symbolName)
                .font(.caption2)
        }
        .foregroundStyle(isRed ? AppColor.danger : AppColor.textPrimary)
        .minimumScaleFactor(0.7)
        .frame(minWidth: 44, minHeight: 54)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.small))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.small)
                .stroke(isSelected ? AppColor.primary : AppColor.border, lineWidth: isSelected ? 2 : 1)
        }
        .accessibilityLabel(card.accessibilityName)
    }

    private var symbolName: String {
        switch card.suit {
        case .hearts: "suit.heart.fill"
        case .diamonds: "suit.diamond.fill"
        case .clubs: "suit.club.fill"
        case .spades: "suit.spade.fill"
        }
    }
}

#Preview {
    NavigationStack {
        BalootSandboxView()
    }
}
