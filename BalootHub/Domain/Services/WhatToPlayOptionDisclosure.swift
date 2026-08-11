import Foundation

enum WhatToPlayOptionDisclosure {
    static func badgeText(rank: Int, isRevealed: Bool) -> String {
        guard isRevealed else { return "اختر".localized }
        return rank == 1 ? "الأفضل".localized : "#\(rank)"
    }

    static func accessibilityLabel(cardName: String, rank: Int, isRevealed: Bool) -> String {
        guard isRevealed else {
            return "\("ورقة".localized) \(cardName)"
        }
        return "\(cardName)، \("الترتيب".localized) \(rank)"
    }
}
