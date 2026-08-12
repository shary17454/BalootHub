import SwiftUI
import SwiftData
import BalootEngine

struct DailyChallengesView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var attempts: [WhatToPlayAttempt]
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

    private var effectiveCompletedSet: Set<String> {
        let automatic = allChallenges
            .filter { DailyChallengeCenter.progress(for: $0, attempts: attempts)?.isComplete == true }
            .map(\.id)
        return completedSet.union(automatic)
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
            StatusBadge("\(effectiveCompletedSet.count) مكتملة", systemImage: "checkmark.seal.fill", tint: AppColor.success)
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
        let progress = DailyChallengeCenter.progress(for: challenge, attempts: attempts)
        let whatToPlayProgress = DailyChallengeCenter.whatToPlayProgress(for: challenge, attempts: attempts)
        let isAutomaticallyCompleted = progress?.isComplete == true
        let isCompleted = completedSet.contains(challenge.id) || isAutomaticallyCompleted

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
                if let progress {
                    scoreBox(title: "التقدم".localized, value: "\(progress.completedCount)/\(progress.targetCount)")
                }
            }

            if let progress {
                ProgressView(value: Double(progress.completedCount), total: Double(max(progress.targetCount, 1)))
                    .tint(progress.isComplete ? AppColor.success : AppColor.primary)
                    .accessibilityLabel("تقدم التحدي".localized)
                    .accessibilityValue("\(progress.completedCount) \("من".localized) \(progress.targetCount)")
            }

            if let seed = challenge.whatToPlaySeed,
               let difficulty = challenge.whatToPlayDifficulty,
               let focusKind = challenge.whatToPlayFocusKind {
                let nextSeed = whatToPlayProgress?.nextSeed ?? seed
                HStack {
                    scoreBox(title: "موقف اليوم".localized, value: "\(nextSeed)")
                    scoreBox(title: "المستوى", value: difficultyTitle(difficulty))
                    scoreBox(title: "التركيز", value: focusTitle(focusKind))
                }

                Button {
                    appEnvironment.navigate(
                        to: .whatToPlayTrainer(seed: nextSeed, difficulty: difficulty, focusKind: focusKind),
                        tab: appEnvironment.selectedTab
                    )
                } label: {
                    Label((progress?.completedCount ?? 0) > 0 ? "متابعة مواقف اليوم".localized : "فتح موقف اليوم".localized, systemImage: "brain.head.profile")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColor.primary)
            }

            if isAutomaticallyCompleted {
                Label("مكتمل من التدريب".localized, systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .foregroundStyle(AppColor.success)
                    .background(AppColor.success.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
            } else {
                Button {
                    toggleCompletion(challenge.id)
                } label: {
                    Label(isCompleted ? "إلغاء الإكمال" : "تحديد كمكتمل", systemImage: isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isCompleted ? AppColor.textSecondary : AppColor.success)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
    }

    private func difficultyTitle(_ difficulty: WhatToPlayDifficulty) -> String {
        switch difficulty {
        case .easy: "سهل".localized
        case .medium: "متوسط".localized
        case .hard: "صعب".localized
        }
    }

    private func focusTitle(_ focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead: "افتتاح الأكلة".localized
        case .followSuit: "اتباع اللون".localized
        case .trumpPressure: "ضغط الحكم".localized
        case .narrowChoice: "خيارات محدودة".localized
        }
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
