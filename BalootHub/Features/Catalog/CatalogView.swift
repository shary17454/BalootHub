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
                    LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                        ForEach(filteredItems) { item in
                            Button {
                                appEnvironment.openGameDetails(slug: item.slug, from: .catalog)
                            } label: {
                                GameCardView(item: item, onToggleFavorite: { toggleFavorite(item) })
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppSpacing.md)
                    .adaptiveContentWidth()
                }
            }
        }
        .background(AppColor.background)
        .navigationTitle("الألعاب")
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
