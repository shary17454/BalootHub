import SwiftUI
import SwiftData

struct RulesView: View {
    let slug: String

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
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        disclaimer

                        ForEach(item.sortedRules) { section in
                            RuleSectionCard(section: section)
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .navigationTitle("قواعد \(item.displayTitle)")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ErrorStateView(message: "تعذّر العثور على قواعد هذه اللعبة.")
            }
        }
        .background(AppColor.background)
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppColor.warning)
            Text("قد تختلف بعض التفاصيل بين المجالس والبطولات، ويمكن تعديل إعدادات التسجيل لتناسب القواعد المعتمدة لديكم.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }
}

private struct RuleSectionCard: View {
    let section: GameRuleSection

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(section.displayTitle, systemImage: section.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)
            Text(section.displayBody)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        RulesView(slug: "baloot-hokum")
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
