import SwiftUI

struct RareCaseLibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: RareCaseCategory?

    private var filteredRulings: [RareCaseRuling] {
        let base = RareCaseLibrary.search(searchText)
        guard let selectedCategory else { return base }
        return base.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            categoryChips

            if filteredRulings.isEmpty {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "لا نتائج مطابقة".localized,
                    message: "جرّب تغيير كلمة البحث أو التصنيف.".localized
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(filteredRulings) { ruling in
                            rulingCard(ruling)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .background(AppColor.background)
        .navigationTitle("حالات نادرة".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColor.textSecondary)
            TextField("ابحث في الحالات…".localized, text: $searchText)
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
                SelectableChip(title: "الكل".localized, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(RareCaseCategory.allCases) { category in
                    SelectableChip(title: category.title, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private func rulingCard(_ ruling: RareCaseRuling) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(ruling.question, systemImage: "questionmark.circle.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("الحكم".localized)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                Text(ruling.ruling)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("السبب".localized)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                Text(ruling.rationale)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        RareCaseLibraryView()
    }
}
