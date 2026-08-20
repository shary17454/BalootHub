import SwiftUI
import SwiftData

/// الحاوية الرئيسية: شريط تبويب سفلي بخمس وجهات، كل واحدة بمسار تنقّل مستقل.
struct RootTabView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        @Bindable var appEnvironment = appEnvironment

        TabView(selection: $appEnvironment.selectedTab) {
            NavigationStack(path: $appEnvironment.homePath) {
                HomeView()
                    .navigationDestination(for: AppRoute.self, destination: destinationView)
            }
            .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.iconName) }
            .tag(AppTab.home)

            NavigationStack(path: $appEnvironment.catalogPath) {
                CatalogView()
                    .navigationDestination(for: AppRoute.self, destination: destinationView)
            }
            .tabItem { Label(AppTab.catalog.title, systemImage: AppTab.catalog.iconName) }
            .tag(AppTab.catalog)

            NavigationStack(path: $appEnvironment.scorekeeperPath) {
                ScorekeeperHomeView()
                    .navigationDestination(for: AppRoute.self, destination: destinationView)
            }
            .tabItem { Label(AppTab.scorekeeper.title, systemImage: AppTab.scorekeeper.iconName) }
            .tag(AppTab.scorekeeper)

            NavigationStack(path: $appEnvironment.historyPath) {
                MatchHistoryView()
                    .navigationDestination(for: AppRoute.self, destination: destinationView)
            }
            .tabItem { Label(AppTab.history.title, systemImage: AppTab.history.iconName) }
            .tag(AppTab.history)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.iconName) }
            .tag(AppTab.settings)
        }
        .tint(AppColor.primary)
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch settings?.appearanceMode ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .gameDetails(let slug):
            GameDetailsView(slug: slug)
        case .rules(let slug):
            RulesView(slug: slug)
        case .scorekeeperSession(let id):
            ScorekeeperSessionView(sessionID: id)
        case .scorekeeperNewSession:
            NewScorekeeperSessionView()
        case .balootGamePlay(let slug):
            BalootGamePlayView(slug: slug)
        case .balootAcademy(let lessonID):
            BalootAcademyView(initialLessonID: lessonID)
        case .handAnalyzer:
            HandAnalyzerView()
        case .whatToPlayTrainer(let seed, let seedBase, let difficulty, let focusKind, let gameMode, let targetCount):
            WhatToPlayTrainerView(
                seed: seed,
                seedBase: seedBase,
                difficulty: difficulty,
                preferredFocus: focusKind,
                preferredMode: gameMode,
                targetCount: targetCount
            )
        case .scoringQuiz:
            ScoringQuizView()
        case .dailyChallenges:
            DailyChallengesView()
        case .achievements:
            AchievementsView()
        case .careerMode:
            CareerModeView()
        case .offlineTournaments:
            OfflineTournamentsView()
        case .balootSandbox:
            BalootSandboxView()
        case .trainingIntro:
            RulesView(slug: "baloot-training")
        case .balootEncyclopedia:
            BalootEncyclopediaView()
        case .rareCaseLibrary:
            RareCaseLibraryView()
        }
    }
}
