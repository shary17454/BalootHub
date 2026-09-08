import SwiftUI

/// شريحة فلترة/تصنيف قابلة للاختيار، تُستخدم في أشرطة الفلاتر الأفقية
/// (الكتالوج، الموسوعة، الحالات النادرة...).
struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.subheadline)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .frame(minHeight: 44)
                .foregroundStyle(isSelected ? AppColor.textOnPrimary : AppColor.textPrimary)
                .appGlassChip(isSelected: isSelected, tint: AppColor.primary)
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    HStack {
        SelectableChip(title: "الكل", isSelected: true) {}
        SelectableChip(title: "المزايدة", isSelected: false) {}
    }
    .padding()
}
