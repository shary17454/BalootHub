import Foundation

/// مجموعة الخيارات المختارة فعليًا لرسم طاولة اللعب.
///
/// نوع قيمي خالص بلا SwiftData ولا SwiftUI، لتسهيل الاختبار وتمريره للواجهات.
struct TableAppearance: Equatable, Sendable {
    var cardFace: CardFaceStyle
    var cardBack: CardBackStyle
    var felt: TableFeltStyle
    var backdrop: TableBackdropStyle
    var avatar: AvatarStyle
    var theme: TableThemeStyle

    static let standard = TableAppearance(
        cardFace: .classic,
        cardBack: .sadu,
        felt: .emerald,
        backdrop: .plain,
        avatar: .person,
        theme: .baloot
    )
}

/// القيم الخام كما تُحفظ في ``AppSettings``.
///
/// فصلها عن نموذج SwiftData يجعل منطق الفتح والتحقق قابلًا للاختبار بلا حاوية بيانات.
struct AppearanceRawSelection: Equatable, Sendable {
    var cardFace: String
    var cardBack: String
    var felt: String
    var backdrop: String
    var avatar: String
    var theme: String

    static let standard = AppearanceRawSelection(
        cardFace: CardFaceStyle.fallback.rawValue,
        cardBack: CardBackStyle.fallback.rawValue,
        felt: TableFeltStyle.fallback.rawValue,
        backdrop: TableBackdropStyle.fallback.rawValue,
        avatar: AvatarStyle.fallback.rawValue,
        theme: TableThemeStyle.fallback.rawValue
    )
}

/// أقسام شاشة التخصيص.
enum AppearanceGroup: String, CaseIterable, Identifiable, Sendable {
    case cardFace
    case cardBack
    case felt
    case backdrop
    case avatar
    case theme

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cardFace: "شكل الورقة".localized
        case .cardBack: "ظهر الورقة".localized
        case .felt: "لبس الطاولة".localized
        case .backdrop: "الخلفية".localized
        case .avatar: "صورة اللاعب".localized
        case .theme: "الثيم".localized
        }
    }

    var symbolName: String {
        switch self {
        case .cardFace: "rectangle.on.rectangle"
        case .cardBack: "rectangle.portrait.pattern.dotted"
        case .felt: "square.grid.3x3.fill"
        case .backdrop: "sparkles"
        case .avatar: "person.crop.circle"
        case .theme: "paintpalette"
        }
    }
}

/// عنصر واحد في شاشة التخصيص، جاهز للعرض بلا أي منطق داخل الواجهة.
struct AppearanceEntry: Identifiable, Equatable, Sendable {
    let id: String
    let group: AppearanceGroup
    let optionRawValue: String
    let title: String
    let detail: String
    let requiredRank: CareerRank
    let isUnlocked: Bool
    let isSelected: Bool

    /// نص سبب القفل، أو `nil` إن كان الخيار مفتوحًا.
    var lockReason: String? {
        guard !isUnlocked else { return nil }
        return String(format: "يُفتح عند رتبة %@".localized, requiredRank.title)
    }
}

/// منطق التخصيص: تحويل القيم المحفوظة لمظهر فعلي، وحساب ما هو مفتوح وما ينتظر التقدّم.
///
/// الفتح يعتمد على ``CareerRank`` وحدها، فلا يوجد أي مسار شراء — أي محتوى إضافي
/// يُكسب باللعب والتدريب فقط.
enum AppearanceCatalog {
    /// يحوّل القيم المحفوظة إلى مظهر صالح، مع إرجاع أي خيار مقفول أو مجهول لقيمته الافتراضية.
    static func resolve(_ raw: AppearanceRawSelection, at rank: CareerRank) -> TableAppearance {
        TableAppearance(
            cardFace: CardFaceStyle.resolve(raw.cardFace, at: rank),
            cardBack: CardBackStyle.resolve(raw.cardBack, at: rank),
            felt: TableFeltStyle.resolve(raw.felt, at: rank),
            backdrop: TableBackdropStyle.resolve(raw.backdrop, at: rank),
            avatar: AvatarStyle.resolve(raw.avatar, at: rank),
            theme: TableThemeStyle.resolve(raw.theme, at: rank)
        )
    }

    /// يحوّل القيم المحفوظة إلى مظهر صالح **بلا فحص الفتح**.
    ///
    /// تُستخدم في شاشة اللعب: القيمة لا تُحفظ أصلًا إلا عبر ``apply(entry:to:)`` التي
    /// ترفض المقفول، فلا داعي لتشغيل استعلامات المسار المهني الثمانية داخل شاشة
    /// اللعب لمجرد إعادة التحقق. الفحص هنا يقتصر على صلاحية القيمة نفسها، حتى لا
    /// ينكسر العرض إذا أُزيل نمط في نسخة لاحقة.
    static func resolveTrusted(_ raw: AppearanceRawSelection) -> TableAppearance {
        TableAppearance(
            cardFace: CardFaceStyle(rawValue: raw.cardFace) ?? .fallback,
            cardBack: CardBackStyle(rawValue: raw.cardBack) ?? .fallback,
            felt: TableFeltStyle(rawValue: raw.felt) ?? .fallback,
            backdrop: TableBackdropStyle(rawValue: raw.backdrop) ?? .fallback,
            avatar: AvatarStyle(rawValue: raw.avatar) ?? .fallback,
            theme: TableThemeStyle(rawValue: raw.theme) ?? .fallback
        )
    }

    /// كل عناصر قسم واحد مرتّبة: المفتوح أولًا ثم المقفول حسب الرتبة المطلوبة.
    static func entries(
        for group: AppearanceGroup,
        selection: TableAppearance,
        rank: CareerRank
    ) -> [AppearanceEntry] {
        switch group {
        case .cardFace: build(CardFaceStyle.self, group: group, selected: selection.cardFace, rank: rank)
        case .cardBack: build(CardBackStyle.self, group: group, selected: selection.cardBack, rank: rank)
        case .felt: build(TableFeltStyle.self, group: group, selected: selection.felt, rank: rank)
        case .backdrop: build(TableBackdropStyle.self, group: group, selected: selection.backdrop, rank: rank)
        case .avatar: build(AvatarStyle.self, group: group, selected: selection.avatar, rank: rank)
        case .theme: build(TableThemeStyle.self, group: group, selected: selection.theme, rank: rank)
        }
    }

    /// كل العناصر في كل الأقسام.
    static func allEntries(selection: TableAppearance, rank: CareerRank) -> [AppearanceEntry] {
        AppearanceGroup.allCases.flatMap { entries(for: $0, selection: selection, rank: rank) }
    }

    /// عدد الأنماط المفتوحة من إجمالي الأنماط — يُعرض كمؤشر تقدّم.
    static func unlockProgress(at rank: CareerRank) -> (unlocked: Int, total: Int) {
        let all = allEntries(selection: .standard, rank: rank)
        return (all.filter(\.isUnlocked).count, all.count)
    }

    /// الأنماط التي ستُفتح عند بلوغ الرتبة التالية مباشرة، لعرضها كحافز واضح.
    static func upcomingUnlocks(at rank: CareerRank) -> [AppearanceEntry] {
        guard let next = CareerRank.allCases.first(where: { $0.requiredXP > rank.requiredXP }) else {
            return []
        }
        return allEntries(selection: .standard, rank: next)
            .filter { $0.isUnlocked && $0.requiredRank.requiredXP > rank.requiredXP }
    }

    /// يطبّق اختيارًا جديدًا على القيم الخام إن كان مفتوحًا، ويرجع `nil` إن كان مقفولًا.
    ///
    /// إرجاع `nil` بدل تعديل صامت يجعل الواجهة قادرة على تنبيه اللاعب بدل ابتلاع الضغطة.
    static func apply(
        entry: AppearanceEntry,
        to raw: AppearanceRawSelection
    ) -> AppearanceRawSelection? {
        guard entry.isUnlocked else { return nil }
        var updated = raw
        switch entry.group {
        case .cardFace: updated.cardFace = entry.optionRawValue
        case .cardBack: updated.cardBack = entry.optionRawValue
        case .felt: updated.felt = entry.optionRawValue
        case .backdrop: updated.backdrop = entry.optionRawValue
        case .avatar: updated.avatar = entry.optionRawValue
        case .theme: updated.theme = entry.optionRawValue
        }
        return updated
    }

    private static func build<Option: AppearanceOption & CaseIterable>(
        _ type: Option.Type,
        group: AppearanceGroup,
        selected: Option,
        rank: CareerRank
    ) -> [AppearanceEntry] {
        Array(Option.allCases)
            .map { option in
                AppearanceEntry(
                    id: "\(group.rawValue).\(option.rawValue)",
                    group: group,
                    optionRawValue: option.rawValue,
                    title: option.title,
                    detail: option.detail,
                    requiredRank: option.requiredRank,
                    isUnlocked: option.isUnlocked(at: rank),
                    isSelected: option == selected
                )
            }
            .sorted { lhs, rhs in
                if lhs.isUnlocked != rhs.isUnlocked { return lhs.isUnlocked }
                return lhs.requiredRank.requiredXP < rhs.requiredRank.requiredXP
            }
    }
}
