import SwiftUI
import SwiftData

struct AchievementsView: View {
    @AppStorage("unlockedBalootAchievementIDs") private var unlockedAchievementIDs = ""
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var whatToPlayAttempts: [WhatToPlayAttempt]

    private var unlockedSet: Set<String> {
        Set(unlockedAchievementIDs.split(separator: ",").map(String.init))
            .union(AchievementCenter.earnedAchievementIDs(whatToPlayAttempts: whatToPlayAttempts))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                ForEach(AchievementCenter.all) { achievement in
                    achievementCard(achievement)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("الإنجازات والألقاب")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("إنجازات محلية", systemImage: "trophy.fill")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)
            Text("نظام ألقاب يعمل دون إنترنت، ومصمم ليُربط لاحقًا بـ Game Center عند إضافة التكامل.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            StatusBadge("\(unlockedSet.count)/\(AchievementCenter.all.count)", systemImage: "checkmark.seal.fill", tint: AppColor.success)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func achievementCard(_ achievement: LocalAchievement) -> some View {
        let isUnlocked = unlockedSet.contains(achievement.id)

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? AppColor.warning : AppColor.textSecondary)
                    .frame(width: 36, height: 36)
                    .background((isUnlocked ? AppColor.warning : AppColor.textSecondary).opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(achievement.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        StatusBadge(achievement.rarity.title, tint: rarityTint(achievement.rarity))
                    }
                    Text(achievement.detail)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(achievement.requirement)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Button {
                toggle(achievement.id)
            } label: {
                Label(isUnlocked ? "مفتوح" : "تجربة الفتح المحلي", systemImage: isUnlocked ? "lock.open.fill" : "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isUnlocked ? AppColor.success : AppColor.primary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
    }

    private func rarityTint(_ rarity: AchievementRarity) -> Color {
        switch rarity {
        case .bronze: AppColor.accent
        case .silver: AppColor.textSecondary
        case .gold: AppColor.warning
        case .legendary: AppColor.danger
        }
    }

    private func toggle(_ achievementID: String) {
        var set = unlockedSet
        if set.contains(achievementID) {
            set.remove(achievementID)
        } else {
            set.insert(achievementID)
        }
        unlockedAchievementIDs = set.sorted().joined(separator: ",")
    }
}
