import Foundation

enum WhatToPlayOptionDisclosure {
    static func badgeText(rank: Int, isRevealed: Bool) -> String {
        guard isRevealed else { return "اختر".localized }
        if rank == 1 { return "الأفضل".localized }
        if rank == 2 { return "ثاني أفضل".localized }
        return "#\(rank)"
    }

    static func accessibilityLabel(
        cardName: String,
        rank: Int,
        isRevealed: Bool,
        expectedImpact: Int? = nil,
        lostExpectedPoints: Int? = nil,
        projectedTeamPoints: Int? = nil,
        lostProjectedTeamPoints: Int? = nil,
        lostProjectedAgainstSecondBestPoints: Int? = nil,
        outcomeTitle: String? = nil,
        expectedImprovement: Int? = nil,
        expectedImprovementSourceTitle: String? = nil,
        isSelected: Bool = false,
        isExpertChoice: Bool = false,
        isBestSimulationResult: Bool = false,
        isSecondBestSimulationResult: Bool = false
    ) -> String {
        guard isRevealed else {
            return "\("ورقة".localized) \(cardName)"
        }

        var parts = [cardName, "\("الترتيب".localized) \(rank)"]
        if isSelected {
            parts.append("اختيارك".localized)
        }
        if isExpertChoice {
            parts.append("الأفضل".localized)
        } else if rank == 2 {
            parts.append("ثاني أفضل".localized)
        }
        if isBestSimulationResult {
            parts.append("أفضل نتيجة محاكاة".localized)
        } else if isSecondBestSimulationResult {
            parts.append("ثاني نتيجة محاكاة".localized)
        }
        if let expectedImpact {
            parts.append("\("أثر القرار".localized) \(WhatToPlayImpactFormatter.accessibilityValue(expectedImpact))")
        }
        if let lostExpectedPoints, lostExpectedPoints > 0 {
            parts.append("\("فارق عن الأفضل".localized) \(lostExpectedPoints)")
        }
        if let projectedTeamPoints {
            parts.append("\("نقاط فريقك بعد المحاكاة".localized) \(projectedTeamPoints)")
        }
        if let lostProjectedTeamPoints, lostProjectedTeamPoints > 0 {
            parts.append("\("نقاط محاكاة ضائعة".localized) \(lostProjectedTeamPoints)")
        }
        if let lostProjectedAgainstSecondBestPoints,
           lostProjectedAgainstSecondBestPoints > 0,
           lostProjectedAgainstSecondBestPoints != lostProjectedTeamPoints {
            parts.append("\("فاقد ثاني محاكاة".localized) \(lostProjectedAgainstSecondBestPoints)")
        }
        if let outcomeTitle {
            parts.append("\("نتيجة القرار".localized) \(outcomeTitle)")
        }
        if let expectedImprovement, expectedImprovement > 0 {
            parts.append("\("تحسن متوقع".localized) +\(expectedImprovement)")
            if let expectedImprovementSourceTitle {
                parts.append("\("مصدر التحسن".localized) \(expectedImprovementSourceTitle)")
            }
        }
        return parts.joined(separator: "، ")
    }
}
