import SwiftUI
import SwiftData

struct GameDetailsView: View {
    let slug: String

    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [GameCatalogItem]

    init(slug: String) {
        self.slug = slug
        let predicate = #Predicate<GameCatalogItem> { $0.slug == slug }
        _items = Query(filter: predicate)
    }

    private var item: GameCatalogItem? { items.first }

    var body: some View {
        Group {
            if let item {
                content(for: item)
            } else {
                ErrorStateView(message: "تعذّر العثور على هذه اللعبة في الكتالوج.")
            }
        }
        .background(AppColor.background)
        .navigationTitle(item?.arabicTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(for item: GameCatalogItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                heroCard(item)

                Text(item.shortDescription)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)

                infoGrid(item)

                if let howToPlay = item.ruleSection(.howToPlay) {
                    summaryCard(section: howToPlay)
                }
                if let scoring = item.ruleSection(.scoring) {
                    summaryCard(section: scoring)
                }
                if let mistakes = item.ruleSection(.commonMistakes) {
                    summaryCard(section: mistakes)
                }

                actionButtons(item)
            }
            .padding(AppSpacing.md)
        }
    }

    private func heroCard(_ item: GameCatalogItem) -> some View {
        let accent = AppColor.categoryColor(for: item.category)
        return ZStack {
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(LinearGradient(colors: [accent.opacity(0.85), accent], startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: item.iconName)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                Text(item.arabicTitle)
                    .font(AppTypography.title)
                    .foregroundStyle(.white)
                if let englishTitle = item.englishTitle {
                    Text(englishTitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .appShadow(AppShadow.elevated)
        .accessibilityElement(children: .combine)
    }

    private func infoGrid(_ item: GameCatalogItem) -> some View {
        VStack(spacing: AppSpacing.xs) {
            InfoRow(icon: item.category.iconName, title: "النوع", value: item.category.title)
            InfoRow(icon: "person.3.fill", title: "عدد اللاعبين", value: item.playerCountText)
            InfoRow(icon: "chart.bar.fill", title: "مستوى الصعوبة", value: "\(item.difficulty.title) (\(String(repeating: "★", count: item.difficulty.starCount)))")
            InfoRow(icon: "clock.fill", title: "المدة المتوقعة", value: item.estimatedDuration)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func summaryCard(section: GameRuleSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(section.title, systemImage: section.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)
            Text(section.body)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func actionButtons(_ item: GameCatalogItem) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                appEnvironment.navigate(to: .rules(slug: item.slug), tab: appEnvironment.selectedTab)
            } label: {
                Label("عرض القواعد كاملة", systemImage: "book.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.primary)
            .controlSize(.large)

            if item.isPlayable {
                Button {
                    appEnvironment.navigate(to: .balootGamePlay(slug: item.slug), tab: appEnvironment.selectedTab)
                } label: {
                    Label("بدء اللعب", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.category == .balootGame || item.slug == "baloot-scorekeeper" {
                Button {
                    appEnvironment.selectedTab = .scorekeeper
                } label: {
                    Label("فتح مسجل النقاط", systemImage: "list.clipboard.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.accent)
                .controlSize(.large)
            }

            Button {
                item.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                Label(item.isFavorite ? "إزالة من المفضلة" : "إضافة إلى المفضلة", systemImage: item.isFavorite ? "heart.fill" : "heart")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.danger)
            .controlSize(.large)
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        GameDetailsView(slug: "baloot-classic")
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
