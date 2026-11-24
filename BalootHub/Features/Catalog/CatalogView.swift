import SwiftUI
import SwiftData

struct CatalogView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameCatalogItem.sortOrder) private var allItems: [GameCatalogItem]

    @State private var searchText = ""
    @State private var selectedFilter: CatalogFilter = .all

    private var filteredItems: [GameCatalogItem] {
        CatalogSearch.apply(filter: selectedFilter, query: searchText, to: allItems)
    }

    private var groupedSections: [CatalogPresentationSection] {
        CatalogPresentation.catalogSections(from: filteredItems)
    }

    private var usesGroupedLayout: Bool {
        selectedFilter == .all && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 260), spacing: AppSpacing.md)]
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            Menu {
                Picker("تصفية المكتبة", selection: $selectedFilter) {
                    ForEach(CatalogFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } label: {
                Label(selectedFilter.title, systemImage: "line.3.horizontal.decrease.circle")
                    .font(AppTypography.subheadline)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.md)
            }
            .accessibilityLabel("تصفية المكتبة")
            .accessibilityValue(selectedFilter.title)
            .accessibilityIdentifier("catalogFilter")

            if allItems.isEmpty {
                LoadingStateView(message: "جارِ تجهيز الكتالوج…")
                    .frame(maxHeight: .infinity)
            } else if filteredItems.isEmpty {
                emptyResults
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        if usesGroupedLayout {
                            ForEach(groupedSections) { section in
                                catalogSection(section)
                            }
                            usageGuide
                        } else {
                            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                                ForEach(filteredItems) { item in
                                    catalogCard(item)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .adaptiveContentWidth()
                }
            }
        }
        .background(AppColor.background)
        .navigationTitle("المكتبة")
        .appGlassNavigationChrome()
    }

    private var emptyResults: some View {
        let showsEmptyFavorites = selectedFilter == .favorites && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return EmptyStateView(
            systemImage: showsEmptyFavorites ? "heart" : "magnifyingglass",
            title: showsEmptyFavorites ? "لا توجد مفضلة بعد" : "لا نتائج مطابقة",
            message: showsEmptyFavorites ? "أضف لعبة أو أداة إلى المفضلة من بطاقتها." : "جرّب كلمة بحث أخرى أو غيّر التصفية.",
            actionTitle: "عرض كل العناصر",
            action: {
                searchText = ""
                selectedFilter = .all
            }
        )
    }

    private var usageGuide: some View {
        DisclosureGroup("دليل أقسام المكتبة") {
            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(CatalogPresentation.usageGuideItems) { item in
                    usageGuideCard(item)
                }
            }
            .padding(.top, AppSpacing.sm)
        }
        .font(AppTypography.headline)
    }

    private func usageGuideCard(_ item: CatalogUsageGuideItem) -> some View {
        let tint = guideTint(for: item.tintToken)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(item.title, systemImage: item.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(AppSpacing.md)
        .appGlassCard(cornerRadius: AppRadius.medium, tint: tint)
        .accessibilityElement(children: .combine)
    }

    private func guideTint(for token: String) -> Color {
        switch token {
        case "success": AppColor.success
        case "accent": AppColor.accent
        case "primary": AppColor.primary
        default: AppColor.textSecondary
        }
    }

    private func catalogSection(_ section: CatalogPresentationSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(section.title)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(section.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(section.items) { item in
                    catalogCard(item)
                }
            }
        }
    }

    private func catalogCard(_ item: GameCatalogItem) -> some View {
        GameCardView(
            item: item,
            onOpenDetails: { appEnvironment.openGameDetails(slug: item.slug, from: .catalog) },
            onStartPlaying: item.isPlayable ? { startPlaying(item) } : nil,
            onToggleFavorite: { toggleFavorite(item) }
        )
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColor.textSecondary)
            TextField("ابحث في كل الألعاب والأدوات…", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(AppColor.textSecondary)
                }
                .accessibilityLabel("مسح البحث")
            }
        }
        .padding(AppSpacing.sm)
        .appGlassCard(cornerRadius: AppRadius.medium)
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    private func toggleFavorite(_ item: GameCatalogItem) {
        item.isFavorite.toggle()
        try? modelContext.save()
    }

    private func startPlaying(_ item: GameCatalogItem) {
        if item.category == .otherCardGame {
            appEnvironment.navigate(to: .otherCardGamePlay(slug: item.slug), tab: .catalog)
        } else {
            appEnvironment.navigate(to: .balootGamePlay(slug: item.slug), tab: .catalog)
        }
    }
}

#Preview {
    NavigationStack {
        CatalogView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
