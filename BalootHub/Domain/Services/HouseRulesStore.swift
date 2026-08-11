import Foundation
import BalootEngine

struct HouseRulesPreset: Codable, Equatable {
    var name: String
    var rules: BalootRulesConfiguration

    static let standard = HouseRulesPreset(name: "القواعد القياسية", rules: .standard)
    static let tournament = HouseRulesPreset(name: "قواعد بطولة", rules: .tournament)
    static let majlis = HouseRulesPreset(name: "قواعد مجلسي", rules: .standard)
}

enum HouseRulesStore {
    static let storageKey = "balootHouseRulesPresetJSON"

    static func load(from defaults: UserDefaults = .standard) -> HouseRulesPreset {
        guard let data = defaults.data(forKey: storageKey) else { return .standard }
        return (try? JSONDecoder().decode(HouseRulesPreset.self, from: data)) ?? .standard
    }

    static func save(_ preset: HouseRulesPreset, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(preset) else { return }
        defaults.set(data, forKey: storageKey)
    }

    static func currentRules(from defaults: UserDefaults = .standard) -> BalootRulesConfiguration {
        load(from: defaults).rules
    }

    static func preset(named name: String, basedOn base: BalootRulesConfiguration) -> HouseRulesPreset {
        HouseRulesPreset(name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "قواعد مجلسي" : name, rules: base)
    }
}
