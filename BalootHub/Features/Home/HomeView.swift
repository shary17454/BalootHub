import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \GameCatalogItem.sortOrder) private var allItems: [GameCatalogItem]
    @Query(filter: #Predicate<ScoreSession> { $0.statusRaw == "active" }, sort: \ScoreSession.updatedAt, order: .reverse)
    private var activeSessions: [ScoreSession]

    @State private var searchText = ""

    private var lastActiveSession: ScoreSession? { activeSessions.first }

    private var searchResults: [GameCatalogItem] {
        CatalogSearch.apply(filter: .all, query: searchText, to: allItems)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                QuickSearchField(text: $searchText)

                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResultsSection
                } else {
                    if let lastActiveSession {
                        continueSessionCard(lastActiveSession)
                    }

                    if allItems.isEmpty {
                        LoadingStateView(message: "جارِ تجهيز الكتالوج…")
                    } else {
                        catalogSection(title: GameCategory.balootGame.title, items: allItems.filter { $0.category == .balootGame })
                        catalogSection(title: GameCategory.balootTool.title, items: allItems.filter { $0.category == .balootTool })
                        catalogSection(title: GameCategory.otherCardGame.title, items: allItems.filter { $0.category == .otherCardGame })

                        let favorites = allItems.filter(\.isFavorite)
                        if !favorites.isEmpty {
                            catalogSection(title: "المفضلة", items: favorites)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
        .background(AppColor.background)
        .navigationTitle("البلوت")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            Image("BalootMajlisHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.08), .black.opacity(0.64)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("أهلًا بك في البلوت")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(.white)
                Text("لعبة البلوت بصنها وحكمها وأدواتها في مكان واحد")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(AppSpacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("صورة مجلس بلوت مع أوراق لعب وقهوة عربية")
    }

    private func continueSessionCard(_ session: ScoreSession) -> some View {
        Button {
            appEnvironment.openScorekeeperSession(id: session.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("متابعة آخر جلسة")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textOnPrimary.opacity(0.85))
                    Text("\(session.teamOneName) ضد \(session.teamTwoName)")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textOnPrimary)
                }
                Spacer()
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColor.textOnPrimary)
            }
            .padding(AppSpacing.md)
            .background(AppColor.primary, in: RoundedRectangle(cornerRadius: AppRadius.large))
        }
        .accessibilityLabel("متابعة آخر جلسة، \(session.teamOneName) ضد \(session.teamTwoName)")
    }

    private func catalogSection(title: String, items: [GameCatalogItem]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            if items.isEmpty {
                Text("لا توجد عناصر بعد في هذا القسم.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            } else if horizontalSizeClass == .regular {
                // على الشاشات العريضة يملأ العرضُ شبكةً تلتف تلقائيًا. الشريط الأفقي
                // ببطاقات ثابتة العرض كان يترك فراغًا كبيرًا في قسم فيه بطاقة واحدة،
                // لأن 220 نقطة تملأ شاشة الآيفون ولا تملأ ربع شاشة iPad.
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220), spacing: AppSpacing.md)],
                    spacing: AppSpacing.md
                ) {
                    ForEach(items) { item in
                        catalogCard(item)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(items) { item in
                            catalogCard(item)
                                .frame(width: 220)
                        }
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }
            }
        }
    }

    private func catalogCard(_ item: GameCatalogItem) -> some View {
        Button {
            appEnvironment.openGameDetails(slug: item.slug, from: .home)
        } label: {
            GameCardView(item: item, onToggleFavorite: { toggleFavorite(item) })
        }
        .buttonStyle(.plain)
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("نتائج البحث")
                .font(AppTypography.title)
            if searchResults.isEmpty {
                EmptyStateView(systemImage: "magnifyingglass", title: "لا نتائج", message: "جرّب كلمة بحث أخرى مثل اسم اللعبة أو نوعها.")
            } else {
                ForEach(searchResults) { item in
                    Button {
                        appEnvironment.openGameDetails(slug: item.slug, from: .home)
                    } label: {
                        GameCardView(item: item, onToggleFavorite: { toggleFavorite(item) })
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggleFavorite(_ item: GameCatalogItem) {
        item.isFavorite.toggle()
        try? modelContext.save()
    }
}

private struct QuickSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColor.textSecondary)
            TextField("ابحث عن لعبة أو أداة…", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.textSecondary)
                }
                .accessibilityLabel("مسح البحث")
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(AppColor.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
