import Foundation
import BalootEngine

struct Request: Decodable { let op: String; let state: String?; let names: [String]?; let seat: Int?; let index: Int? }
struct Seat: Encodable { let id: UUID; let name: String; let seat: Int; let teamID: UUID; let count: Int }
struct Card: Encodable { let id: UUID; let label: String }
struct Choice: Encodable { let id: Int; let label: String }
struct TableCard: Encodable { let id: UUID; let playerID: UUID; let label: String }
struct Score: Encodable {
    let teamPoints: [String: Int]; let trickPoints: [String: Int]; let projectPoints: [String: Int]
    let winningTeamID: UUID?; let kabootTeamID: UUID?; let didDeclarerFail: Bool; let multiplier: Multiplier
    let awardedProjects: [Project]; let overruledProjects: [Project]
    init(_ result: RoundScoreResult) {
        func keyed(_ points: [UUID: Int]) -> [String: Int] { Dictionary(uniqueKeysWithValues: points.map { ($0.key.uuidString, $0.value) }) }
        teamPoints = keyed(result.teamPoints); trickPoints = keyed(result.trickPoints); projectPoints = keyed(result.projectPoints)
        winningTeamID = result.winningTeamID; kabootTeamID = result.kabootTeamID; didDeclarerFail = result.didDeclarerFail; multiplier = result.multiplier
        awardedProjects = result.awardedProjects; overruledProjects = result.overruledProjects
    }
}
struct View: Encodable {
    let phase: String; let round: Int; let seat: Int; let playerID: UUID; let players: [Seat]
    let hand: [Card]; let turnPlayerID: UUID?; let actions: [Choice]; let mode: String?
    let table: [TableCard]; let completedTricks: Int; let bidding: [String]; let upCard: Card?
    let result: Score?
}
struct Reply: Encodable { let ok: Bool; let state: String?; let view: View?; let error: String? }
enum Invalid: Error { case request }
let encoder = JSONEncoder()
let decoder = JSONDecoder()

func actions(_ state: GameState, _ id: UUID) -> [GameAction] {
    GameEngine.legalBidActions(for: id, state: state)
      + GameEngine.legalMultiplierGameActions(for: id, state: state)
      + GameEngine.legalProjectDeclarationActions(for: id, state: state)
      + GameEngine.legalMoves(for: id, state: state)
}
func view(_ state: GameState, seat: Int) throws -> View {
    guard (0..<4).contains(seat), let player = state.players.first(where: { $0.seat.rawValue == seat }) else { throw Invalid.request }
    let choices = actions(state, player.id)
    return View(phase: state.phase.rawValue, round: state.roundNumber, seat: seat, playerID: player.id,
      players: state.players.sorted { $0.seat.rawValue < $1.seat.rawValue }.map { Seat(id: $0.id, name: $0.name, seat: $0.seat.rawValue, teamID: $0.teamID, count: state.hands[$0.id]?.count ?? 0) },
      hand: (state.hands[player.id] ?? []).map { Card(id: $0.id, label: $0.displayLabel) },
      turnPlayerID: state.currentTurnPlayerID, actions: choices.enumerated().map { Choice(id: $0.offset, label: GameEngine.actionSummary($0.element, state: state)) },
      mode: state.mode?.rawValue, table: (state.currentTrick?.playedCards ?? []).map { TableCard(id: $0.id, playerID: $0.playerID, label: $0.card.displayLabel) }, completedTricks: state.completedTricks.count,
      bidding: GameEngine.biddingTimeline(state: state), upCard: state.bidding.upCard.map { Card(id: $0.id, label: $0.displayLabel) }, result: state.lastRoundResult.map(Score.init))
}
func handle(_ request: Request) throws -> Reply {
    var state: GameState
    if request.op == "new" {
        guard let names = request.names, names.count == 4 else { throw Invalid.request }
        let a = Team(name: "الفريق الأول"), b = Team(name: "الفريق الثاني")
        let players = (0..<4).map { index in Player(name: names[index], kind: .human, seat: SeatPosition(rawValue: index)!, teamID: index % 2 == 0 ? a.id : b.id) }
        state = GameState(players: players, teams: [a,b])
        state = try GameEngine.apply(.dealCards(seed: UInt64.random(in: 1...UInt64.max)), to: state)
    } else {
        guard let data = request.state?.data(using: .utf8) else { throw Invalid.request }
        state = try decoder.decode(GameState.self, from: data)
        if request.op == "apply" {
            guard let seat = request.seat, let player = state.players.first(where: { $0.seat.rawValue == seat }), let index = request.index else { throw Invalid.request }
            let legal = actions(state, player.id)
            guard legal.indices.contains(index) else { throw Invalid.request }
            state = try GameEngine.apply(legal[index], to: state)
            if state.phase == .scoring { state = try GameEngine.apply(.finishRound, to: state) }
        } else if request.op == "next" {
            guard state.phase == .finished else { throw Invalid.request }
            state = try GameEngine.apply(.dealCards(seed: UInt64.random(in: 1...UInt64.max)), to: state)
        } else if request.op != "view" { throw Invalid.request }
    }
    let publicView = try request.seat.map { try view(state, seat: $0) }
    // The full state travels only over the private child-process pipe, never to a client.
    return Reply(ok: true, state: String(data: try encoder.encode(state), encoding: .utf8), view: publicView, error: nil)
}
while let line = readLine() {
    do {
        guard line.utf8.count <= 1_000_000 else { throw Invalid.request }
        let request = try decoder.decode(Request.self, from: Data(line.utf8))
        let data = try encoder.encode(handle(request))
        FileHandle.standardOutput.write(data + Data([10]))
    } catch { FileHandle.standardOutput.write(Data("{\"ok\":false,\"error\":\"invalid_action_or_state\"}\n".utf8)) }
}
