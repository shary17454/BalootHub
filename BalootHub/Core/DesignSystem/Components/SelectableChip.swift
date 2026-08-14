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
                .background(isSelected ? AppColor.primary : AppColor.surface, in: Capsule())
                .foregroundStyle(isSelected ? AppColor.textOnPrimary : AppColor.textPrimary)
                .overlay(Capsule().stroke(isSelected ? .clear : AppColor.border, lineWidth: 1))
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
