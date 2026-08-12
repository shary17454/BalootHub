import SwiftUI
import BalootEngine

struct BalootSandboxView: View {
    @State private var selectedCard: PlayingCard?
    @State private var preview: BalootSandboxPlayPreview?
    @State private var errorMessage: String?

    private let configuration = BalootSandboxView.defaultConfiguration

    private var state: GameState? {
        try? BalootSandbox.makeState(configuration: configuration)
    }

    private var currentHand: [PlayingCard] {
        configuration.handsBySeat[configuration.currentTurnSeat] ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                tableState
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

    private var tableState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("الموقف".localized, systemImage: "tablecells.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                metric("النمط".localized, "\("حكم".localized) \(configuration.trumpSuit?.spokenName ?? "")", icon: "crown.fill")
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

    private func legalCardsText() -> String {
        guard let cards = try? BalootSandbox.legalCards(configuration: configuration), !cards.isEmpty else {
            return "لا يوجد".localized
        }
        return cards.map(\.accessibilityName).joined(separator: "، ")
    }

    private func seatTitle(_ seat: SeatPosition) -> String {
        switch seat {
        case .south: "جنوب".localized
        case .west: "غرب".localized
        case .north: "شمال".localized
        case .east: "شرق".localized
        }
    }

    private static let defaultConfiguration = BalootSandboxConfiguration(
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

#Preview {
    NavigationStack {
        BalootSandboxView()
    }
}
