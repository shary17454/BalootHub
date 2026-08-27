import Foundation
import BalootEngine

enum WhatToPlayScenarioCode {
    struct Parsed: Equatable, Sendable {
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
              matchesToken(String(parts[0]), "WTP"),
              let seed = UInt64(parts[1]),
              let difficulty = difficultyToken(String(parts[2]))
        else { return nil }

        let focusKind: WhatToPlayScenarioFocusKind?
        if matchesToken(String(parts[3]), "auto") {
            focusKind = nil
        } else if let parsedFocus = focusToken(String(parts[3])) {
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
            if let candidate = firstCode(in: source, where: { parse($0) != nil }) {
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
        if matchesToken(value, "auto") { return (nil, nil) }
        if matchesToken(value, "sun") { return (.sun, nil) }
        if matchesToken(value, "hokum") { return (.hokum, nil) }

        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2,
              matchesToken(String(parts[0]), "hokum"),
              let suitOrdinal = Int(parts[1]),
              let suit = Suit.allCases.first(where: { $0.ordinal == suitOrdinal })
        else { return nil }

        return (.hokum, suit)
    }

    private static func matchesToken(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.caseInsensitive]) == .orderedSame
    }

    private static func difficultyToken(_ value: String) -> WhatToPlayDifficulty? {
        WhatToPlayDifficulty.allCases.first { difficulty in
            matchesToken(difficulty.rawValue, value)
        }
    }

    private static func focusToken(_ value: String) -> WhatToPlayScenarioFocusKind? {
        WhatToPlayScenarioFocusKind.allCases.first { focusKind in
            matchesToken(focusKind.rawValue, value)
        }
    }

    /// أقصى طول لرمز موقف صالح.
    ///
    /// أطول صياغة ممكنة: `WTP-` + بذرة `UInt64` (٢٠ رقمًا) + أطول صعوبة (`medium`)
    /// + أطول نوع موقف (`trumpPressure`) + أطول نمط (`hokum.3`) + أطول ورقة (`C37`)
    /// مع فواصلها = ٥٨ محرفًا. السقف هنا أكثر من الضعف احتياطًا لأي رمز أطول لاحقًا،
    /// ومع ذلك يبقى ثابتًا صغيرًا لا يعتمد على طول النص الملصوق إطلاقًا.
    private static let maxCandidateLength = 128

    /// محارف إنهاء الرمز، تُبنى مرة واحدة لا عند كل استدعاء.
    private static let codeTerminators = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: "،,:;؟!?()[]{}<>\"'&=#/\\"))

    /// يبحث عن أول رمز موقف صالح داخل نص حر (رسالة مشاركة أو محتوى حافظة).
    ///
    /// **لماذا سقف الطول ولماذا الخروج المبكر:** النسخة السابقة كانت تمسح *بقية النص
    /// كاملًا* عند كل مطابقة لـ`WTP-` بحثًا عن محرف إنهاء، ثم تبني قائمة المرشحات كلها
    /// قبل فحص أيٍّ منها. على نص بلا محارف إنهاء (نص مُرمَّز، أو لصق طويل بلا مسافات)
    /// يصير المسح **تربيعيًا**: قيس فعليًا ١٠٫٥ ثانية عند ٣٢ ألف محرف و٤٠٫٧ ثانية عند
    /// ٦٤ ألفًا. وبما أن ``extractCode(from:)`` تُستدعى من `loadShareCode()` على
    /// الـ`MainActor` قبل أي `Task`، كان ذلك يجمّد الواجهة حتى يقتل حارسُ النظام التطبيق.
    /// السقف يجعل تكلفة كل مطابقة ثابتة، والخروج المبكر يوقف المسح عند أول رمز صالح.
    ///
    /// القصّ عند السقف لا يُضيّع أي رمز صحيح: الرمز الصالح لا يتجاوز ٥٨ محرفًا أصلًا،
    /// وأي سلسلة أطول من ذلك ما كانت لتُحلَّل بنجاح في النسخة السابقة كذلك.
    private static func firstCode(in text: String, where isValid: (String) -> Bool) -> String? {
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(of: "WTP-", range: searchRange) {
            // نافذة محدودة الطول بدل بقية النص: هذا ما يكسر النمو التربيعي.
            let limit = text.index(
                range.lowerBound,
                offsetBy: maxCandidateLength,
                limitedBy: text.endIndex
            ) ?? text.endIndex
            let window = text[range.lowerBound..<limit].unicodeScalars
            // تقطيعة واحدة بدل `append` لكل محرف — الإلحاق المتكرر على
            // `unicodeScalars` كان يستهلك وحده أضعاف زمن البحث نفسه.
            let stop = window.firstIndex(where: { codeTerminators.contains($0) }) ?? window.endIndex
            let normalized = String(window[window.startIndex..<stop])
                .trimmingCharacters(in: .punctuationCharacters)
            if !normalized.isEmpty, isValid(normalized) {
                return normalized
            }
            searchRange = range.upperBound..<text.endIndex
        }

        return nil
    }
}
