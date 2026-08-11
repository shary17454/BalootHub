import SwiftUI

struct DailyChallengesView: View {
    @State private var cadence: ChallengeCadence = .daily
    @AppStorage("completedBalootChallengeIDs") private var completedChallengeIDs = ""

    private var allChallenges: [BalootChallenge] {
        DailyChallengeCenter.challenges()
    }

    private var visibleChallenges: [BalootChallenge] {
        allChallenges.filter { $0.cadence == cadence }
    }

    private var completedSet: Set<String> {
        Set(completedChallengeIDs.split(separator: ",").map(String.init))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                cadencePicker
                ForEach(visibleChallenges) { challenge in
                    challengeCard(challenge)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("تحديات البلوت")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("تحديات Offline", systemImage: "calendar.badge.checkmark")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)
            Text("تتغير التحديات محليًا حسب التاريخ بدون حساب أو خادم، وتجمع بين اللعب والتدريب والحساب.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            StatusBadge("\(completedSet.count) مكتملة", systemImage: "checkmark.seal.fill", tint: AppColor.success)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var cadencePicker: some View {
        Picker("النطاق", selection: $cadence) {
            ForEach(ChallengeCadence.allCases) { cadence in
                Text(cadence.title).tag(cadence)
            }
        }
        .pickerStyle(.segmented)
    }

    private func challengeCard(_ challenge: BalootChallenge) -> some View {
        let isCompleted = completedSet.contains(challenge.id)

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                Image(systemName: challenge.category.iconName)
                    .font(.title2)
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(challenge.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(challenge.detail)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                StatusBadge(challenge.cadence.title, systemImage: nil, tint: AppColor.primary)
            }

            HStack {
                scoreBox(title: "الهدف", value: "\(challenge.targetCount)")
                scoreBox(title: "المكافأة", value: challenge.rewardTitle)
            }

            Button {
                toggleCompletion(challenge.id)
            } label: {
                Label(isCompleted ? "إلغاء الإكمال" : "تحديد كمكتمل", systemImage: isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isCompleted ? AppColor.textSecondary : AppColor.success)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
    }

    private func scoreBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func toggleCompletion(_ challengeID: String) {
        var set = completedSet
        if set.contains(challengeID) {
            set.remove(challengeID)
        } else {
            set.insert(challengeID)
        }
        completedChallengeIDs = set.sorted().joined(separator: ",")
    }
}
