import SwiftUI
import SwiftData
import UIKit
import BalootEngine

struct GameDetailsView: View {
    let slug: String

    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [GameCatalogItem]

    init(slug: String) {
        self.slug = slug
        let predicate = #Predicate<GameCatalogItem> { $0.slug == slug }
        _items = Query(filter: predicate)
    }

    private var item: GameCatalogItem? { items.first }

    var body: some View {
        Group {
            if let item {
                content(for: item)
            } else {
                ErrorStateView(message: "تعذّر العثور على هذه اللعبة في الكتالوج.")
            }
        }
        .background(AppColor.background)
        .navigationTitle(item?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(for item: GameCatalogItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                heroCard(item)

                Text(item.displayDescription)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)

                infoGrid(item)

                if let howToPlay = item.ruleSection(.howToPlay) {
                    summaryCard(section: howToPlay)
                }
                if let scoring = item.ruleSection(.scoring) {
                    summaryCard(section: scoring)
                }
                if let mistakes = item.ruleSection(.commonMistakes) {
                    summaryCard(section: mistakes)
                }

                actionButtons(item)
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
    }

    private func heroCard(_ item: GameCatalogItem) -> some View {
        let accent = AppColor.categoryColor(for: item.category)
        return ZStack {
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(LinearGradient(colors: [accent.opacity(0.85), accent], startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: item.iconName)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                Text(item.displayTitle)
                    .font(AppTypography.title)
                    .foregroundStyle(.white)
                if let englishTitle = item.englishTitle {
                    Text(englishTitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .appShadow(AppShadow.elevated)
        .accessibilityElement(children: .combine)
    }

    private func infoGrid(_ item: GameCatalogItem) -> some View {
        VStack(spacing: AppSpacing.xs) {
            InfoRow(icon: item.category.iconName, title: "النوع", value: item.category.title)
            InfoRow(icon: "person.3.fill", title: "عدد اللاعبين", value: item.displayPlayerCount)
            InfoRow(icon: "chart.bar.fill", title: "مستوى الصعوبة", value: "\(item.difficulty.title) (\(String(repeating: "★", count: item.difficulty.starCount)))")
            InfoRow(icon: "clock.fill", title: "المدة المتوقعة", value: item.displayDuration)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func summaryCard(section: GameRuleSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(section.displayTitle, systemImage: section.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)
            Text(section.displayBody)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func actionButtons(_ item: GameCatalogItem) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                appEnvironment.navigate(to: .rules(slug: item.slug), tab: appEnvironment.selectedTab)
            } label: {
                Label("عرض القواعد كاملة", systemImage: "book.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.primary)
            .controlSize(.large)

            if item.slug == "hand-analyzer" {
                Button {
                    appEnvironment.navigate(to: .handAnalyzer, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح أداة التحليل", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-training" {
                Button {
                    appEnvironment.navigate(to: .balootAcademy(), tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح الأكاديمية", systemImage: "graduationcap.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "what-to-play-trainer" {
                Button {
                    appEnvironment.navigate(to: .whatToPlayTrainer(), tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح المدرب", systemImage: "brain.head.profile")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "score-calculation-challenge" {
                Button {
                    appEnvironment.navigate(to: .scoringQuiz, tab: appEnvironment.selectedTab)
                } label: {
                    Label("بدء التحدي", systemImage: "function")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "daily-baloot-challenges" {
                Button {
                    appEnvironment.navigate(to: .dailyChallenges, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح التحديات", systemImage: "calendar.badge.checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-achievements" {
                Button {
                    appEnvironment.navigate(to: .achievements, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح الإنجازات", systemImage: "trophy.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-career-mode" {
                Button {
                    appEnvironment.navigate(to: .careerMode, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح المسيرة".localized, systemImage: "flag.checkered")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "offline-tournaments" {
                Button {
                    appEnvironment.navigate(to: .offlineTournaments, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح البطولات", systemImage: "trophy.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-sandbox" {
                Button {
                    appEnvironment.navigate(to: .balootSandbox, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح المختبر".localized, systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-encyclopedia" {
                Button {
                    appEnvironment.navigate(to: .balootEncyclopedia, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح الموسوعة".localized, systemImage: "book.closed.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-rare-cases" {
                Button {
                    appEnvironment.navigate(to: .rareCaseLibrary, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح الحالات النادرة".localized, systemImage: "questionmark.folder.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.isPlayable {
                Button {
                    appEnvironment.navigate(to: .balootGamePlay(slug: item.slug), tab: appEnvironment.selectedTab)
                } label: {
                    Label("بدء اللعب", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.isBalootModeReference {
                Button {
                    appEnvironment.navigate(to: .balootGamePlay(slug: "baloot-classic"), tab: appEnvironment.selectedTab)
                } label: {
                    Label("العب البلوت الكامل: صن وحكم في نفس الطاولة", systemImage: "suit.spade.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.category == .balootGame || item.slug == "baloot-scorekeeper" {
                Button {
                    appEnvironment.selectedTab = .scorekeeper
                } label: {
                    Label("فتح مسجل النقاط", systemImage: "list.clipboard.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.accent)
                .controlSize(.large)
            }

            Button {
                item.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                Label(item.isFavorite ? "إزالة من المفضلة" : "إضافة إلى المفضلة", systemImage: item.isFavorite ? "heart.fill" : "heart")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.danger)
            .controlSize(.large)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title.localized, systemImage: icon)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        GameDetailsView(slug: "baloot-classic")
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
