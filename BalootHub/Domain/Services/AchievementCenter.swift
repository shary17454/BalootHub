import Foundation

enum AchievementRarity: String, CaseIterable, Identifiable {
    case bronze
    case silver
    case gold
    case legendary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bronze: "برونزي".localized
        case .silver: "فضي".localized
        case .gold: "ذهبي".localized
        case .legendary: "أسطوري".localized
        }
    }
}

struct LocalAchievement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let requirement: String
    let iconName: String
    let rarity: AchievementRarity
}

enum AchievementCenter {
    static let all: [LocalAchievement] = [
        LocalAchievement(
            id: "first-kaboot",
            title: "أول كبوت",
            detail: "حقق كبوتًا في جولة بلوت.",
            requirement: "يفتح عند تسجيل أو لعب أول كبوت.",
            iconName: "crown.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "sun-king",
            title: "ملك الصن",
            detail: "افز بعدة جولات صن متتالية.",
            requirement: "يفتح عند وصول سلسلة انتصارات الصن إلى 5.",
            iconName: "sun.max.fill",
            rarity: .silver
        ),
        LocalAchievement(
            id: "hokum-sheikh",
            title: "شيخ الحكم",
            detail: "أثبت قوتك في جولات الحكم.",
            requirement: "يفتح عند الفوز بـ10 جولات حكم.",
            iconName: "suit.spade.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "scorekeeper",
            title: "الحاسب",
            detail: "أتقن حساب النتائج بدون أخطاء.",
            requirement: "يفتح عند حل 25 سؤالًا من تحدي حساب النقاط.",
            iconName: "function",
            rarity: .silver
        ),
        LocalAchievement(
            id: "expert-eye",
            title: "عين الخبير".localized,
            detail: "اقرأ مواقف وش تلعب واختر نفس قرار الخبير.".localized,
            requirement: "يفتح عند مطابقة قرار الخبير في 5 مواقف من مدرب وش تلعب.".localized,
            iconName: "eye.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "academy-master",
            title: "إتقان المشاريع",
            detail: "أكمل دروس المشاريع والتكتيك في الأكاديمية.",
            requirement: "يفتح عند إكمال كل دروس الأكاديمية الحالية.",
            iconName: "graduationcap.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "ten-win-streak",
            title: "10 انتصارات متتالية",
            detail: "حافظ على سلسلة انتصارات طويلة.",
            requirement: "يفتح عند تحقيق 10 انتصارات متتالية.",
            iconName: "flame.fill",
            rarity: .legendary
        ),
        LocalAchievement(
            id: "hundred-matches",
            title: "100 مباراة",
            detail: "استمر في اللعب والتدريب.",
            requirement: "يفتح عند لعب أو تسجيل 100 مباراة.",
            iconName: "100.circle.fill",
            rarity: .legendary
        ),
        LocalAchievement(
            id: "expert-slayer",
            title: "الفوز على أعلى AI",
            detail: "اهزم أصعب مستوى ذكاء اصطناعي.",
            requirement: "يفتح عند الفوز على مستوى شيخ البلوت.",
            iconName: "brain.head.profile",
            rarity: .legendary
        )
    ]

    static func unlockedAchievements(from unlockedIDs: Set<String>) -> [LocalAchievement] {
        all.filter { unlockedIDs.contains($0.id) }
    }

    static func earnedAchievementIDs(whatToPlayAttempts: [WhatToPlayAttempt]) -> Set<String> {
        let expertMatches = whatToPlayAttempts.filter(\.isCorrect).count
        return expertMatches >= 5 ? ["expert-eye"] : []
    }
}
