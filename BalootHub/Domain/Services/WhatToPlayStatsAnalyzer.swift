import Foundation

struct WhatToPlayStatsSummary: Equatable {
    let attempts: Int
    let correct: Int
    let accuracyPercent: Int
    let currentStreak: Int
    let bestStreak: Int
    let averageExpectedImpact: Int

    static let empty = WhatToPlayStatsSummary(
        attempts: 0,
        correct: 0,
        accuracyPercent: 0,
        currentStreak: 0,
        bestStreak: 0,
        averageExpectedImpact: 0
    )
}

enum WhatToPlayStatsAnalyzer {
    static func summarize(attempts: [WhatToPlayAttempt]) -> WhatToPlayStatsSummary {
        guard !attempts.isEmpty else { return .empty }

        let chronological = attempts.sorted { $0.createdAt < $1.createdAt }
        let correct = chronological.filter(\.isCorrect).count
        let accuracy = Int((Double(correct) / Double(chronological.count) * 100).rounded())
        let impact = chronological.reduce(0) { $0 + $1.expectedImpact }
        let averageImpact = Int((Double(impact) / Double(chronological.count)).rounded())

        var bestStreak = 0
        var running = 0
        for attempt in chronological {
            if attempt.isCorrect {
                running += 1
                bestStreak = max(bestStreak, running)
            } else {
                running = 0
            }
        }

        var currentStreak = 0
        for attempt in chronological.reversed() {
            guard attempt.isCorrect else { break }
            currentStreak += 1
        }

        return WhatToPlayStatsSummary(
            attempts: chronological.count,
            correct: correct,
            accuracyPercent: accuracy,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            averageExpectedImpact: averageImpact
        )
    }

    static func recentAttempts(_ attempts: [WhatToPlayAttempt], limit: Int = 5) -> [WhatToPlayAttempt] {
        guard limit > 0 else { return [] }
        return Array(attempts.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
}
