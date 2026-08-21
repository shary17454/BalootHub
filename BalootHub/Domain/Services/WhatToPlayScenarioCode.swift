import Foundation
import BalootEngine

enum WhatToPlayScenarioCode {
    struct Parsed: Equatable {
        let seed: UInt64
        let difficulty: WhatToPlayDifficulty
        let focusKind: WhatToPlayScenarioFocusKind?
        let gameMode: GameMode?
        let trumpSuit: Suit?
        let selectedCard: PlayingCard?
    }

    static func make(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        focusKindRaw: String?,
        gameMode: GameMode? = nil,
        trumpSuit: Suit? = nil,
        selectedCard: PlayingCard?
    ) -> String {
        let focus = focusKindRaw ?? "auto"
        let mode = modeToken(gameMode: gameMode, trumpSuit: trumpSuit)
        let selected = selectedCard.map { "C\($0.suit.ordinal)\($0.rank.ordinal)" } ?? "P"
        return "WTP-\(seed)-\(difficulty.rawValue)-\(focus)-\(mode)-\(selected)"
    }

    static func make(
        for scenario: WhatToPlayScenario,
        selectedOption: WhatToPlayOption?
    ) -> String {
        make(
            seed: scenario.seed,
            difficulty: scenario.difficulty,
            focusKindRaw: scenario.context.focusKind.rawValue,
            gameMode: scenario.state.mode,
            trumpSuit: scenario.state.trumpSuit,
            selectedCard: selectedOption?.card
        )
    }

    static func parse(_ code: String) -> Parsed? {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = normalizedCode.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 5 || parts.count == 6,
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

        let mode: GameMode?
        let trumpSuit: Suit?
        let selectedCardToken: String
        if parts.count == 6 {
            guard let parsedMode = parseModeToken(String(parts[4])) else { return nil }
            mode = parsedMode.gameMode
            trumpSuit = parsedMode.trumpSuit
            selectedCardToken = String(parts[5])
        } else {
            mode = nil
            trumpSuit = nil
            selectedCardToken = String(parts[4])
        }

        guard let selectedCard = parseSelectedCard(selectedCardToken) else { return nil }

        return Parsed(
            seed: seed,
            difficulty: difficulty,
            focusKind: focusKind,
            gameMode: mode,
            trumpSuit: trumpSuit,
            selectedCard: selectedCard
        )
    }

    static func extractCode(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if parse(trimmed) != nil {
            return trimmed
        }
        if let decoded = trimmed.removingPercentEncoding,
           decoded != trimmed,
           parse(decoded) != nil {
            return decoded
        }

        for source in candidateSources(from: text) {
            for candidate in codeCandidates(in: source) where parse(candidate) != nil {
                return candidate
            }
        }

        return nil
    }

    private static func candidateSources(from text: String) -> [String] {
        guard let decoded = text.removingPercentEncoding, decoded != text else {
            return [text]
        }
        return [text, decoded]
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

    private static func modeToken(gameMode: GameMode?, trumpSuit: Suit?) -> String {
        switch gameMode {
        case .sun:
            return "sun"
        case .hokum:
            if let trumpSuit {
                return "hokum.\(trumpSuit.ordinal)"
            } else {
                return "hokum"
            }
        case nil:
            return "auto"
        }
    }

    private static func parseModeToken(_ value: String) -> (gameMode: GameMode?, trumpSuit: Suit?)? {
        if value == "auto" { return (nil, nil) }
        if value == "sun" { return (.sun, nil) }
        if value == "hokum" { return (.hokum, nil) }

        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2,
              parts[0] == "hokum",
              let suitOrdinal = Int(parts[1]),
              let suit = Suit.allCases.first(where: { $0.ordinal == suitOrdinal })
        else { return nil }

        return (.hokum, suit)
    }

    private static func codeCandidates(in text: String) -> [String] {
        let terminators = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "،,:;؟!?()[]{}<>\"'&=#/\\"))
        var candidates: [String] = []
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(of: "WTP-", range: searchRange) {
            let suffix = text[range.lowerBound...]
            var code = ""
            for scalar in suffix.unicodeScalars {
                if terminators.contains(scalar) { break }
                code.unicodeScalars.append(scalar)
            }
            let normalized = code.trimmingCharacters(in: .punctuationCharacters)
            if !normalized.isEmpty {
                candidates.append(normalized)
            }
            searchRange = range.upperBound..<text.endIndex
        }

        return candidates
    }
}
