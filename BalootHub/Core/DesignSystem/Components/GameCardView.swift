import SwiftUI

/// بطاقة لعبة قابلة لإعادة الاستخدام في الرئيسية وصفحة الألعاب.
struct GameCardView: View {
    let item: GameCatalogItem
    var onOpenDetails: (() -> Void)?
    var onStartPlaying: (() -> Void)?
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
                .fixedSize(horizontal: false, vertical: true)

            Text(item.displayDescription)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Label(item.displayUseTitle, systemImage: item.isPlayable ? "play.circle.fill" : "info.circle.fill")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(item.isPlayable ? AppColor.success : accentColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.displayUseDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appGlassCard(cornerRadius: AppRadius.small, tint: accentColor)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                StatusBadge(item.category.shortBadgeTitle, systemImage: item.category.iconName, tint: accentColor)
                StatusBadge(
                    item.displayAvailabilityTitle,
                    systemImage: item.availabilityIconName,
                    tint: item.isPlayable ? AppColor.success : (item.isBalootModeReference ? AppColor.accent : AppColor.textSecondary)
                )
            }

            VStack(spacing: AppSpacing.xs) {
                if item.isPlayable, let onStartPlaying {
                    Button(action: onStartPlaying) {
                        Label("ابدأ اللعب".localized, systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.success)
                    .controlSize(.regular)
                    .accessibilityHint("يفتح طاولة اللعب مباشرة".localized)
                }

                if let onOpenDetails {
                    Button(action: onOpenDetails) {
                        Label(item.isPlayable ? "التفاصيل والقواعد".localized : "عرض القواعد".localized, systemImage: "book.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(accentColor)
                    .controlSize(.regular)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appInteractiveGlassCard(cornerRadius: AppRadius.large, tint: accentColor)
        .appShadow(AppShadow.card)
    }
}

#Preview {
    let items = CatalogSeeder.previewItems()
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(items.prefix(4)) { item in
                GameCardView(item: item, onOpenDetails: {}, onStartPlaying: {}, onToggleFavorite: {})
            }
        }
        .padding()
    }
}
