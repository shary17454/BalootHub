import Foundation
import BalootEngine

enum WhatToPlayScenarioCode {
    struct Parsed: Equatable {
        let seed: UInt64
        let difficulty: WhatToPlayDifficulty
        let focusKind: WhatToPlayScenarioFocusKind?
        let selectedCard: PlayingCard?
    }

    static func make(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        focusKindRaw: String?,
        selectedCard: PlayingCard?
    ) -> String {
        let focus = focusKindRaw ?? "auto"
        let selected = selectedCard.map { "-C\($0.suit.ordinal)\($0.rank.ordinal)" } ?? "-P"
        return "WTP-\(seed)-\(difficulty.rawValue)-\(focus)\(selected)"
    }

    static func make(
        for scenario: WhatToPlayScenario,
        selectedOption: WhatToPlayOption?
    ) -> String {
        make(
            seed: scenario.seed,
            difficulty: scenario.difficulty,
            focusKindRaw: scenario.context.focusKind.rawValue,
            selectedCard: selectedOption?.card
        )
    }

    static func parse(_ code: String) -> Parsed? {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = normalizedCode.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 5,
              parts[0] == "WTP",
              let seed = UInt64(parts[1]),
              let difficulty = WhatToPlayDifficulty(rawValue: String(parts[2]))
        else { return nil }

        let focusKind: WhatToPlayScenarioFocusKind?
        if parts[3] == "auto" {
            focusKind = nil
        } else if let parsedFocus = WhatToPlayScenarioFocusKind(rawValue: String(parts[3])) {
            focusKind = parsedFocus
        } else {
            return nil
        }

        guard let selectedCard = parseSelectedCard(String(parts[4])) else { return nil }

        return Parsed(
            seed: seed,
            difficulty: difficulty,
            focusKind: focusKind,
            selectedCard: selectedCard
        )
    }

    static func extractCode(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if parse(trimmed) != nil {
            return trimmed
        }

        guard let start = text.range(of: "WTP-")?.lowerBound else { return nil }
        let suffix = text[start...]
        var code = ""
        let terminators = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "،,:;؟!?()[]{}<>\"'"))

        for scalar in suffix.unicodeScalars {
            if terminators.contains(scalar) { break }
            code.unicodeScalars.append(scalar)
        }

        let normalized = code.trimmingCharacters(in: .punctuationCharacters)
        return parse(normalized) == nil ? nil : normalized
    }

    private static func parseSelectedCard(_ value: String) -> PlayingCard?? {
        if value == "P" { return .some(nil) }
        guard value.first == "C" else { return nil }
        let ordinals = value.dropFirst()
        guard ordinals.count >= 2,
              let suitOrdinal = ordinals.first?.wholeNumberValue,
              let rankOrdinal = Int(String(ordinals.dropFirst())),
              let suit = Suit.allCases.first(where: { $0.ordinal == suitOrdinal }),
              let rank = Rank.allCases.first(where: { $0.ordinal == rankOrdinal })
        else { return nil }
        return .some(PlayingCard(suit: suit, rank: rank))
    }
}
