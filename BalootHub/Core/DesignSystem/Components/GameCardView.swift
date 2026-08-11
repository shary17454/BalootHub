import SwiftUI

/// بطاقة لعبة قابلة لإعادة الاستخدام في الرئيسية وصفحة الألعاب.
struct GameCardView: View {
    let item: GameCatalogItem
    var onToggleFavorite: (() -> Void)?

    private var accentColor: Color { AppColor.categoryColor(for: item.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .fill(accentColor.opacity(0.16))
                        .frame(width: 52, height: 52)
                    Image(systemName: item.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .accessibilityHidden(true)

                Spacer()

                if let onToggleFavorite {
                    Button(action: onToggleFavorite) {
                        Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(item.isFavorite ? AppColor.danger : AppColor.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(item.isFavorite ? "إزالة من المفضلة" : "إضافة إلى المفضلة")
                }
            }

            Text(item.displayTitle)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            Text(item.displayDescription)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.xs) {
                StatusBadge(item.category.shortBadgeTitle, systemImage: item.category.iconName, tint: accentColor)
                StatusBadge(
                    item.displayAvailabilityTitle,
                    systemImage: item.availabilityIconName,
                    tint: item.isPlayable ? AppColor.success : (item.isBalootModeReference ? AppColor.accent : AppColor.textSecondary)
                )
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .appShadow(AppShadow.card)
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.displayTitle)، \(item.category.title)، \(item.displayAvailabilityTitle)")
        .accessibilityHint("اضغط مرتين لعرض التفاصيل والقواعد")
    }
}

#Preview {
    let items = CatalogSeeder.previewItems()
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(items.prefix(4)) { item in
                GameCardView(item: item, onToggleFavorite: {})
            }
        }
        .padding()
    }
}
