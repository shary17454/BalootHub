import SwiftUI
import Combine

private struct OnlineSeat: Decodable, Identifiable, Sendable {
    let seat: Int
    let name: String
    let ready: Bool
    var id: Int { seat }
}
private struct OnlineCard: Decodable, Identifiable, Sendable { let id: String; let label: String }
private struct OnlineChoice: Decodable, Identifiable, Sendable { let id: Int; let label: String }
private struct OnlineTableCard: Decodable, Identifiable, Sendable { let id: String; let playerID: String; let label: String }
private struct OnlinePlayer: Decodable, Identifiable, Sendable {
    let id: String; let name: String; let seat: Int; let teamID: String; let count: Int
}
private struct OnlineScore: Decodable, Sendable { let teamPoints: [String: Int] }
private struct OnlineGame: Decodable, Sendable {
    let phase: String; let round: Int; let playerID: String; let players: [OnlinePlayer]
    let hand: [OnlineCard]; let turnPlayerID: String?; let actions: [OnlineChoice]
    let completedTricks: Int; let bidding: [String]; let table: [OnlineTableCard]; let result: OnlineScore?
}
private struct OnlineRoom: Decodable, Sendable {
    let code: String; let token: String?; let revision: Int; let seat: Int
    let started: Bool; let host: Bool; let players: [OnlineSeat]; let game: OnlineGame?
}

@MainActor
private final class OnlineBalootModel: ObservableObject {
    @Published var room: OnlineRoom?
    @Published var error: String?
    @Published var busy = false
    private var token: String?
    private let base = URL(string: "https://romantic-creation-production-019c.up.railway.app")!
    private let session = URLSession(configuration: .ephemeral)

    private func request(_ path: String, body: [String: String]? = nil, raw: Data? = nil) async throws -> Data {
        var request = URLRequest(url: base.appendingPathComponent(path))
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if body != nil || raw != nil {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try raw ?? JSONEncoder().encode(body ?? [:])
        }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(response.statusCode) else {
            if [404, 410].contains(response.statusCode) { room = nil; token = nil }
            if response.statusCode == 409 { throw OnlineError.message("تغيّرت حالة الغرفة أو لم يجهز اللاعبون الأربعة بعد، حدّث المحاولة") }
            if response.statusCode == 429 { throw OnlineError.message("طلبات كثيرة، انتظر قليلًا ثم حاول") }
            throw OnlineError.message("تعذر تنفيذ الطلب، تحقق من الغرفة والدور والاتصال")
        }
        return data
    }
    private enum OnlineError: LocalizedError {
        case message(String)
        var errorDescription: String? { if case let .message(text) = self { return text }; return nil }
    }
    private func update(_ data: Data) throws {
        let next = try JSONDecoder().decode(OnlineRoom.self, from: data)
        if let newToken = next.token { token = newToken }
        room = next
    }
    func enter(name: String, code: String?) async {
        guard !busy else { return }; busy = true; error = nil; defer { busy = false }
        do {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw OnlineError.message("اكتب اسمًا مستعارًا") }
            let path: String
            if let code {
                let value = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                guard value.count == 8, value.allSatisfy({ "0123456789ABCDEF".contains($0) }) else { throw OnlineError.message("رمز الغرفة ثمانية أحرف وأرقام") }
                path = "v1/rooms/\(value)/join"
            } else { path = "v1/rooms" }
            try update(await request(path, body: ["name": trimmed]))
        } catch { self.error = error.localizedDescription }
    }
    func refresh() async {
        guard let room, !busy else { return }
        do { try update(await request("v1/rooms/\(room.code)")); error = nil }
        catch is CancellationError { }
        catch let failure as URLError where failure.code == .cancelled { }
        catch { self.error = error.localizedDescription }
    }
    func action(_ op: String, index: Int? = nil) async {
        guard let room, !busy else { return }; busy = true; error = nil; defer { busy = false }
        do {
            var body: [String: Any] = ["revision": room.revision]
            if op == "ready" { body["ready"] = !(room.players.first { $0.seat == room.seat }?.ready ?? false) }
            if let index { body["index"] = index }
            let data = try await request("v1/rooms/\(room.code)/\(op)", raw: JSONSerialization.data(withJSONObject: body))
            if op == "leave" { self.room = nil; token = nil } else { try update(data) }
        } catch { self.error = error.localizedDescription }
    }
}

struct OnlineBalootView: View {
    @StateObject private var model = OnlineBalootModel()
    @State private var name = ""
    @State private var code = ""
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            if let room = model.room {
                Section("الغرفة \(room.code)") {
                    ShareLink(item: room.code) { Label("مشاركة رمز الغرفة", systemImage: "square.and.arrow.up") }
                    ForEach(room.players) { player in
                        Text("\(player.seat + 1)  \(player.name.isEmpty ? "مقعد شاغر" : player.name) \(player.ready ? "✓" : "")")
                    }
                    if !room.started {
                        Button("تغيير الجاهزية") { Task { await model.action("ready") } }
                        if room.host { Button("بدء المباراة") { Task { await model.action("start") } } }
                    }
                }
                if let game = room.game {
                    Section("الجولة \(game.round) — الأكلات \(game.completedTricks) من ٨") {
                        if let player = game.players.first(where: { $0.id == game.turnPlayerID }) { Text("الدور: \(player.name)") }
                        ForEach(game.players) { Text("\($0.name): \($0.count) ورقة") }
                        ForEach(Array(game.bidding.enumerated()), id: \.offset) { Text($0.element) }
                    }
                    Section("أوراقك") {
                        ScrollView(.horizontal) {
                            HStack { ForEach(game.hand) { card in Text(card.label).padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8)) } }
                        }
                    }
                    Section("أوراق الطاولة") {
                        ForEach(game.table) { card in
                            Text("\(game.players.first { $0.id == card.playerID }?.name ?? "لاعب"): \(card.label)")
                        }
                    }
                    if !game.actions.isEmpty {
                        Section("الحركات المتاحة حسب قواعد البلوت") {
                            ForEach(game.actions) { choice in Button(choice.label) { Task { await model.action("action", index: choice.id) } } }
                        }
                    }
                    if let result = game.result {
                        Section("نتيجة الجولة") {
                            ForEach(result.teamPoints.keys.sorted(), id: \.self) { team in
                                let members = game.players.filter { $0.teamID == team }.map(\.name).joined(separator: " و ")
                                Text("\(members): \(result.teamPoints[team] ?? 0)")
                            }
                            if room.host { Button("الجولة التالية") { Task { await model.action("next") } } }
                        }
                    }
                }
                Section {
                    Button("تحديث") { Task { await model.refresh() } }
                    Button("مغادرة الغرفة", role: .destructive) { Task { await model.action("leave") } }
                    Text("مغادرة مباراة جارية تغلق الغرفة للجميع، تبقى جلستك محفوظة في الذاكرة عند انقطاع الشبكة ما دامت هذه الشاشة مفتوحة")
                }
            } else {
                Section("اللعب مع ثلاثة أصدقاء") {
                    TextField("اسم مستعار", text: $name).textContentType(.nickname)
                    Button("إنشاء غرفة خاصة") { Task { await model.enter(name: name, code: nil) } }
                    TextField("رمز الغرفة", text: $code).textInputAutocapitalization(.characters).autocorrectionDisabled()
                    Button("الانضمام إلى غرفة") { Task { await model.enter(name: name, code: code) } }
                }
                Section("الخصوصية") {
                    Text("عند إنشاء غرفة أو الانضمام ترسل الخدمة الاسم المستعار وحركات اللعب إلى الخادم لإدارة المباراة، لا ترسل أوراق خصومك إلى جهازك ولا تستخدم الميكروفون، الغرف مؤقتة وتنتهي بعد الخمول، اللعب المحلي متاح دون اتصال")
                }
            }
            if let error = model.error { Section { Text(error).foregroundStyle(.red) } }
            if model.busy { ProgressView("جارٍ الاتصال") }
        }
        .disabled(model.busy)
        .navigationTitle("بلوت عبر الإنترنت")
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await model.refresh()
                do { try await Task.sleep(for: .seconds(2)) } catch { break }
            }
        }
    }
}
