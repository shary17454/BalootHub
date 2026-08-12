import SwiftUI

struct BalootEncyclopediaView: View {
    @State private var searchText = ""
    @State private var selectedCategory: BalootGlossaryCategory?

    private var filteredTerms: [BalootGlossaryTerm] {
        let base = BalootEncyclopedia.search(searchText)
        guard let selectedCategory else { return base }
        return base.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            categoryChips

            if filteredTerms.isEmpty {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "لا نتائج مطابقة".localized,
                    message: "جرّب تغيير كلمة البحث أو التصنيف.".localized
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(filteredTerms) { term in
                            termCard(term)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .background(AppColor.background)
        .navigationTitle("موسوعة البلوت".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColor.textSecondary)
            TextField("ابحث عن مصطلح…".localized, text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(AppColor.textSecondary)
                }
                .accessibilityLabel("مسح البحث".localized)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(AppColor.border, lineWidth: 1))
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                glossaryChip(title: "الكل".localized, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(BalootGlossaryCategory.allCases) { category in
                    glossaryChip(title: category.title, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private func glossaryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.subheadline)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .frame(minHeight: 44)
                .background(isSelected ? AppColor.primary : AppColor.surface, in: Capsule())
                .foregroundStyle(isSelected ? AppColor.textOnPrimary : AppColor.textPrimary)
                .overlay(Capsule().stroke(isSelected ? .clear : AppColor.border, lineWidth: 1))
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func termCard(_ term: BalootGlossaryTerm) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(term.term, systemImage: term.category.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)
            Text(term.definition)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textPrimary)
            if let example = term.example {
                Text(example)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(AppSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        BalootEncyclopediaView()
    }
}
