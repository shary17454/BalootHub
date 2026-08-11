import SwiftUI
import SwiftData

struct OfflineTournamentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OfflineTournament.createdAt, order: .reverse) private var tournaments: [OfflineTournament]

    @State private var format: OfflineTournamentFormat = .knockout
    @State private var teamCount = 4
    @State private var title = "بطولة المجلس"

    var body: some View {
        List {
            Section("بطولة جديدة") {
                TextField("اسم البطولة", text: $title)
                Picker("النظام", selection: $format) {
                    ForEach(OfflineTournamentFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                Picker("عدد الفرق", selection: $teamCount) {
                    Text("4 فرق").tag(4)
                    Text("8 فرق").tag(8)
                }
                Button {
                    createTournament()
                } label: {
                    Label("إنشاء جدول البطولة", systemImage: "plus.circle.fill")
                }
            }

            Section("البطولات") {
                if tournaments.isEmpty {
                    EmptyStateView(
                        systemImage: "trophy",
                        title: "لا توجد بطولات",
                        message: "أنشئ بطولة Offline واحفظ جدولها وسجلها محليًا."
                    )
                } else {
                    ForEach(tournaments) { tournament in
                        NavigationLink {
                            OfflineTournamentDetailView(tournament: tournament)
                        } label: {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(tournament.title)
                                    .font(AppTypography.headline)
                                Text("\(tournament.format.title) · \(tournament.teams.count) فرق · \(tournament.matches.count) مباريات")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("بطولات Offline")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createTournament() {
        let tournament = OfflineTournamentPlanner.makeTournament(
            title: title,
            format: format,
            teamCount: teamCount,
            seed: UInt64(Date().timeIntervalSince1970)
        )
        modelContext.insert(tournament)
        try? modelContext.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tournaments[index])
        }
        try? modelContext.save()
    }
}

private struct OfflineTournamentDetailView: View {
    @Bindable var tournament: OfflineTournament
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("الملخص") {
                LabeledContent("النظام", value: tournament.format.title)
                LabeledContent("الحالة", value: tournament.status == .active ? "نشطة" : "منتهية")
                if let championName = tournament.championName {
                    LabeledContent("البطل", value: championName)
                }
            }

            Section("الترتيب") {
                ForEach(Array(OfflineTournamentPlanner.standings(for: tournament).enumerated()), id: \.offset) { index, standing in
                    HStack {
                        Text("\(index + 1)")
                            .foregroundStyle(AppColor.textSecondary)
                        Text(standing.team)
                        Spacer()
                        Text("\(standing.wins) فوز")
                            .foregroundStyle(AppColor.primary)
                    }
                }
            }

            Section("الجدول") {
                ForEach(tournament.matches) { match in
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("الجولة \(match.roundNumber)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        Text("\(match.homeTeam) × \(match.awayTeam)")
                            .font(AppTypography.subheadline.weight(.semibold))
                    }
                }
            }

            if tournament.status == .active {
                Section("إنهاء") {
                    Picker("البطل", selection: Binding(
                        get: { tournament.championName ?? tournament.teams.first ?? "" },
                        set: { tournament.championName = $0 }
                    )) {
                        ForEach(tournament.teams, id: \.self) { team in
                            Text(team).tag(team)
                        }
                    }
                    Button {
                        tournament.finish(champion: tournament.championName ?? tournament.teams.first ?? "")
                        try? modelContext.save()
                    } label: {
                        Label("اعتماد البطل", systemImage: "crown.fill")
                    }
                }
            }
        }
        .navigationTitle(tournament.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
