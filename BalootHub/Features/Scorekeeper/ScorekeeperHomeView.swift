import SwiftUI
import SwiftData

struct ScorekeeperHomeView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Query(filter: #Predicate<ScoreSession> { $0.statusRaw == "active" }, sort: \ScoreSession.updatedAt, order: .reverse)
    private var activeSessions: [ScoreSession]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("تسجيل البلوت")
                        .font(AppTypography.largeTitle)
                    Text("سجّل جلسة بلوت جديدة، أو تابع جلسة قائمة")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Button {
                    appEnvironment.navigate(to: .scorekeeperNewSession, tab: .scorekeeper)
                } label: {
                    Label("بدء جلسة جديدة", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)

                if activeSessions.isEmpty {
                    EmptyStateView(
                        systemImage: "list.clipboard",
                        title: "لا توجد جلسات نشطة",
                        message: "ابدأ جلسة جديدة لتسجيل نتائج جولات صن وحكم أولًا بأول."
                    )
                } else {
                    Text("الجلسات النشطة")
                        .font(AppTypography.title)
                    ForEach(activeSessions) { session in
                        Button {
                            appEnvironment.openScorekeeperSession(id: session.id)
                        } label: {
                            SessionSummaryRow(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("تسجيل البلوت")
    }
}

struct SessionSummaryRow: View {
    let session: ScoreSession
    @Query private var settingsList: [AppSettings]
    private var rules: ScoreRules { (settingsList.first ?? AppSettings()).scoreRules }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("\(session.teamOneName) ضد \(session.teamTwoName)")
                    .font(AppTypography.headline)
                Text("\(session.rounds.count) صكة · الهدف \(session.targetScore)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(session.teamOneTotal(rules: rules))")
                    .font(AppTypography.headline)
                Text("\(session.teamTwoTotal(rules: rules))")
                    .font(AppTypography.headline)
            }
            Image(systemName: "chevron.left")
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ScorekeeperHomeView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
