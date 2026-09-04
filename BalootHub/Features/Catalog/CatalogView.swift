import SwiftUI
import SwiftData

struct CatalogView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
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

    private let columns = [GridItem(.adaptive(minimum: 165), spacing: AppSpacing.md)]

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(CatalogFilter.allCases) { filter in
                        SelectableChip(title: filter.title, isSelected: selectedFilter == filter) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            }

            if allItems.isEmpty {
                LoadingStateView(message: "جارِ تجهيز الكتالوج…")
                    .frame(maxHeight: .infinity)
            } else if filteredItems.isEmpty {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "لا نتائج مطابقة",
                    message: "جرّب تغيير الفلتر أو كلمة البحث.",
                    actionTitle: searchText.isEmpty ? nil : "مسح البحث",
                    action: { searchText = "" }
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        if usesGroupedLayout {
                            usageGuide
                            ForEach(groupedSections) { section in
                                catalogSection(section)
                            }
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
    }

    private var usageGuide: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("ترتيب المكتبة")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                Text("ابدأ بالبلوت إذا تريد اللعب، واستخدم بقية الأقسام للتدريب أو قراءة القواعد.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(CatalogPresentation.usageGuideItems) { item in
                    usageGuideCard(item)
                }
            }
        }
    }

    private func usageGuideCard(_ item: CatalogUsageGuideItem) -> some View {
        let tint = guideTint(for: item.tintToken)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(item.title, systemImage: item.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(tint)
                .lineLimit(2)
            Text(item.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(tint.opacity(0.28), lineWidth: 1))
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
        Button {
            appEnvironment.openGameDetails(slug: item.slug, from: .catalog)
        } label: {
            GameCardView(item: item, onToggleFavorite: { toggleFavorite(item) })
        }
        .buttonStyle(.plain)
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
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(AppColor.border, lineWidth: 1))
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    private func toggleFavorite(_ item: GameCatalogItem) {
        item.isFavorite.toggle()
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        CatalogView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
