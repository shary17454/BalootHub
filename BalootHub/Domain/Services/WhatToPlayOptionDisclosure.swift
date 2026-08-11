import Foundation

enum WhatToPlayOptionDisclosure {
    static func badgeText(rank: Int, isRevealed: Bool) -> String {
        guard isRevealed else { return "اختر".localized }
        return rank == 1 ? "الأفضل".localized : "#\(rank)"
    }

    static func accessibilityLabel(
        cardName: String,
        rank: Int,
        isRevealed: Bool,
        isSelected: Bool = false,
        isExpertChoice: Bool = false
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
        }
        return parts.joined(separator: "، ")
    }
}
