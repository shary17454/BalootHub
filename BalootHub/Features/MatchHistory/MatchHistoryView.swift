import SwiftUI
import SwiftData

struct MatchHistoryView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScoreSession.updatedAt, order: .reverse) private var sessions: [ScoreSession]
    @Query private var settingsList: [AppSettings]

    @State private var sessionPendingDelete: ScoreSession?
    @State private var isPresentingDeleteConfirm = false

    // تجنّب إنشاء كائن `@Model` مؤقت في كل تقييم للواجهة.
    private var confirmBeforeDelete: Bool { settingsList.first?.confirmBeforeDelete ?? true }

    private var activeSessions: [ScoreSession] { sessions.filter { $0.status == .active } }
    private var finishedSessions: [ScoreSession] { sessions.filter { $0.status == .finished } }

    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyStateView(
                    systemImage: "clock.arrow.circlepath",
                    title: "لا يوجد سجل بعد",
                    message: "ستظهر هنا كل جلسات تسجيل البلوت النشطة والمنتهية."
                )
            } else {
                List {
                    Section {
                        NavigationLink {
                            PlayerStatsView()
                        } label: {
                            Label("أسلوب لعبك", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }

                    if !activeSessions.isEmpty {
                        Section("جلسات نشطة") {
                            ForEach(activeSessions) { session in
                                row(for: session)
                            }
                        }
                    }
                    if !finishedSessions.isEmpty {
                        Section("جلسات منتهية") {
                            ForEach(finishedSessions) { session in
                                row(for: session)
                            }
                        }
                    }
                }
            }
        }
        .background(AppColor.background)
        .navigationTitle("السجل")
        .confirmationDialog("هل تريد حذف هذه الجلسة نهائيًا؟", isPresented: $isPresentingDeleteConfirm, titleVisibility: .visible) {
            Button("حذف", role: .destructive) {
                if let sessionPendingDelete {
                    modelContext.delete(sessionPendingDelete)
                    try? modelContext.save()
                }
            }
            Button("إلغاء", role: .cancel) {}
        }
    }

    private func row(for session: ScoreSession) -> some View {
        Button {
            appEnvironment.openScorekeeperSession(id: session.id, tab: .history)
        } label: {
            SessionSummaryRow(session: session)
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button(role: .destructive) {
                sessionPendingDelete = session
                if confirmBeforeDelete {
                    isPresentingDeleteConfirm = true
                } else {
                    modelContext.delete(session)
                    try? modelContext.save()
                }
            } label: {
                Label("حذف", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MatchHistoryView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
