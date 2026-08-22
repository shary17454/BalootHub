import SwiftUI
import SwiftData
import BalootEngine

/// شاشة تخصيص شكل الطاولة: أشكال الأوراق وظهرها ولبس الطاولة والخلفية والأفاتار والثيم.
///
/// كل نمط يُرسم بالكود، ويُفتح بالتقدّم في المسار المهني وحده — لا يوجد أي شراء.
struct AppearanceStudioView: View {
    var body: some View {
        CareerProgressContainer { summary in
            AppearanceStudioContent(rank: summary.rank, xp: summary.xp)
        }
    }
}

private struct AppearanceStudioContent: View {
    let rank: CareerRank
    let xp: Int

    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]
    @State private var lockedNotice: AppearanceEntry?

    private var settings: AppSettings? { settingsList.first }

    private var selection: TableAppearance {
        AppearanceCatalog.resolve(settings?.appearanceSelection ?? .standard, at: rank)
    }

    var body: some View {
        Group {
            if settings != nil {
                content
            } else {
                LoadingStateView(message: "جارِ تحضير الإعدادات…")
            }
        }
        .navigationTitle("تخصيص الطاولة".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task { ensureSettings() }
        .alert(item: $lockedNotice) { entry in
            Alert(
                title: Text(entry.title),
                message: Text(entry.lockReason ?? ""),
                dismissButton: .default(Text("تمام".localized))
            )
        }
    }

    private func ensureSettings() {
        guard settingsList.isEmpty else { return }
        SettingsRepository.ensureSettingsExist(context: modelContext)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                livePreview
                progressCard
                ForEach(AppearanceGroup.allCases) { group in
                    groupSection(group)
                }
                effectsSection
                upcomingSection
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
    }

    // MARK: - المعاينة الحية

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("معاينة".localized)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)

            ZStack {
                TableBackdrop(style: selection.backdrop, theme: selection.theme)
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))

                TableFeltSurface(style: selection.felt)
                    .padding(AppSpacing.md)
                    .frame(height: 190)

                VStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(0..<4, id: \.self) { seat in
                            SeatAvatarView(
                                name: Self.previewNames[seat],
                                seatIndex: seat,
                                style: selection.avatar,
                                theme: selection.theme,
                                isCurrentTurn: seat == 0
                            )
                        }
                    }

                    HStack(spacing: AppSpacing.xs) {
                        ForEach(Self.previewCards) { card in
                            PlayingCardFaceView(card: card, style: selection.cardFace)
                        }
                        PlayingCardBackView(style: selection.cardBack)
                    }
                }
            }
            .frame(height: 190)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("معاينة شكل الطاولة الحالي".localized)
        }
    }

    private static let previewNames = ["أنت".localized, "شمال".localized, "شريكك".localized, "يمين".localized]

    private static let previewCards: [PlayingCard] = [
        PlayingCard(suit: .spades, rank: .ace),
        PlayingCard(suit: .hearts, rank: .ten),
        PlayingCard(suit: .diamonds, rank: .jack)
    ]

    // MARK: - التقدّم

    private var progressCard: some View {
        let progress = AppearanceCatalog.unlockProgress(at: rank)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Label(rank.title, systemImage: "rosette")
                    .font(AppTypography.headline)
                    .foregroundStyle(selection.theme.accentColor)
                Spacer()
                Text("\(xp) XP")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Text(String(format: "فتحت %d من %d نمطًا".localized, progress.unlocked, progress.total))
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            ProgressView(value: Double(progress.unlocked), total: Double(max(progress.total, 1)))
                .tint(selection.theme.accentColor)
            Text("كل الأنماط تُكسب باللعب والتدريب وحدهما.".localized)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    // MARK: - الأقسام

    private func groupSection(_ group: AppearanceGroup) -> some View {
        let entries = AppearanceCatalog.entries(for: group, selection: selection, rank: rank)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(group.title, systemImage: group.symbolName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(entries) { entry in
                        optionTile(entry)
                    }
                }
                .padding(.vertical, AppSpacing.xxs)
            }
        }
    }

    private func optionTile(_ entry: AppearanceEntry) -> some View {
        Button {
            select(entry)
        } label: {
            VStack(spacing: AppSpacing.xs) {
                tilePreview(entry)
                    .frame(width: 76, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
                    .overlay(alignment: .topTrailing) {
                        if !entry.isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .padding(4)
                                .background(.ultraThinMaterial, in: Circle())
                                .padding(2)
                        }
                    }

                Text(entry.title)
                    .font(AppTypography.caption)
                    .foregroundStyle(entry.isUnlocked ? AppColor.textPrimary : AppColor.textSecondary)
                    .lineLimit(1)
            }
            .padding(AppSpacing.xs)
            .frame(width: 96)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(entry.isSelected ? selection.theme.accentColor.opacity(0.16) : AppColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(entry.isSelected ? selection.theme.accentColor : AppColor.border, lineWidth: entry.isSelected ? 2 : 1)
            )
            .opacity(entry.isUnlocked ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(entry))
        .accessibilityAddTraits(entry.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func accessibilityLabel(_ entry: AppearanceEntry) -> String {
        var parts = [entry.group.title, entry.title]
        if let reason = entry.lockReason { parts.append(reason) }
        return parts.joined(separator: "، ")
    }

    /// معاينة مصغّرة تعرض النمط نفسه لا مجرد اسمه.
    @ViewBuilder
    private func tilePreview(_ entry: AppearanceEntry) -> some View {
        switch entry.group {
        case .cardFace:
            let style = CardFaceStyle(rawValue: entry.optionRawValue) ?? .classic
            ZStack {
                AppColor.surfaceElevated
                PlayingCardFaceView(card: PlayingCard(suit: .hearts, rank: .ten), style: style)
                    .scaleEffect(0.85)
            }
        case .cardBack:
            let style = CardBackStyle(rawValue: entry.optionRawValue) ?? .sadu
            ZStack {
                AppColor.surfaceElevated
                PlayingCardBackView(style: style).scaleEffect(0.85)
            }
        case .felt:
            let style = TableFeltStyle(rawValue: entry.optionRawValue) ?? .emerald
            TableFeltSurface(style: style)
        case .backdrop:
            let style = TableBackdropStyle(rawValue: entry.optionRawValue) ?? .plain
            TableBackdrop(style: style, theme: selection.theme)
        case .avatar:
            let style = AvatarStyle(rawValue: entry.optionRawValue) ?? .person
            ZStack {
                AppColor.surfaceElevated
                SeatAvatarView(name: "سعد".localized, seatIndex: 0, style: style, theme: selection.theme)
            }
        case .theme:
            let style = TableThemeStyle(rawValue: entry.optionRawValue) ?? .baloot
            LinearGradient(
                colors: [style.accentColor, style.accentColor.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - المؤثرات

    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("المؤثرات".localized, systemImage: "wand.and.stars")
                .font(AppTypography.headline)
            Toggle("مؤثرات المشاريع والكبوت".localized, isOn: celebrationBinding)
            Text("تُطفأ تلقائيًا إذا فعّلت \"تقليل الحركة\" في إعدادات النظام.".localized)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var celebrationBinding: Binding<Bool> {
        Binding(
            get: { settings?.celebrationEffectsEnabled ?? true },
            set: { newValue in
                settings?.celebrationEffectsEnabled = newValue
                try? modelContext.save()
            }
        )
    }

    // MARK: - القادم

    @ViewBuilder
    private var upcomingSection: some View {
        let upcoming = AppearanceCatalog.upcomingUnlocks(at: rank)
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("ينتظرك في الرتبة القادمة".localized, systemImage: "sparkles")
                    .font(AppTypography.headline)
                ForEach(upcoming) { entry in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Image(systemName: entry.group.symbolName)
                            .foregroundStyle(AppColor.textSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.group.title) · \(entry.title)")
                                .font(AppTypography.body)
                            Text(entry.detail)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
    }

    // MARK: - الاختيار

    private func select(_ entry: AppearanceEntry) {
        guard let settings else { return }
        guard let updated = AppearanceCatalog.apply(entry: entry, to: settings.appearanceSelection) else {
            lockedNotice = entry
            FeedbackPlayer.shared.play(.invalidMove)
            return
        }
        settings.appearanceSelection = updated
        try? modelContext.save()
        FeedbackPlayer.shared.play(.cardPlayed)
    }
}

#Preview {
    NavigationStack {
        AppearanceStudioView()
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
