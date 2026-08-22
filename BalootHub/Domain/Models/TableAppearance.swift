import Foundation

/// خيار تخصيص واحد لمظهر الطاولة (شكل ورقة، ظهر ورقة، لبس الطاولة، خلفية، أفاتار، ثيم).
///
/// كل الأنماط تُرسم بالكود عبر أشكال وتدرّجات SwiftUI ولا تعتمد على أي ملف صورة،
/// فلا تزيد حجم التطبيق ولا تحتاج أصولًا خارجية.
///
/// الفتح مرتبط **بالتقدّم في المسار المهني فقط** (``CareerRank``) — لا يوجد أي شراء
/// أو مقابل مادي، تطبيقًا لشرط "فتح محتوى غير Pay-to-Win".
protocol AppearanceOption: RawRepresentable, Identifiable, Hashable where RawValue == String {
    /// الخيار المستخدم إذا كانت القيمة المحفوظة غير معروفة أو غير مفتوحة بعد.
    static var fallback: Self { get }
    var title: String { get }
    var detail: String { get }
    var requiredRank: CareerRank { get }
}

extension AppearanceOption {
    var id: String { rawValue }

    /// هل هذا الخيار متاح من أول تشغيل بلا أي تقدّم؟
    var isFreeFromStart: Bool { requiredRank == .newcomer }

    func isUnlocked(at rank: CareerRank) -> Bool {
        rank.requiredXP >= requiredRank.requiredXP
    }
}

extension AppearanceOption where Self: CaseIterable {
    static func unlocked(at rank: CareerRank) -> [Self] {
        Array(allCases).filter { $0.isUnlocked(at: rank) }
    }

    static func locked(at rank: CareerRank) -> [Self] {
        Array(allCases).filter { !$0.isUnlocked(at: rank) }
    }

    /// يحوّل قيمة محفوظة إلى خيار صالح.
    ///
    /// يرجع ``fallback`` إذا كانت القيمة غير معروفة (نمط أُزيل في نسخة لاحقة) أو
    /// كانت لنمط لم يُفتح بعد — حتى لا تعلق واجهة اللعب على نمط لا يملكه اللاعب.
    static func resolve(_ rawValue: String, at rank: CareerRank) -> Self {
        guard let option = Self(rawValue: rawValue), option.isUnlocked(at: rank) else {
            return fallback
        }
        return option
    }
}

// MARK: - وجه الورقة

/// شكل رسم وجه الورقة (الرقم والرمز).
enum CardFaceStyle: String, CaseIterable, AppearanceOption {
    /// رمز وسط ورقم أعلى — الشكل الأصلي للتطبيق.
    case classic
    /// أرقام عريضة كبيرة تُقرأ من بعيد، مناسب لطاولة المجلس.
    case bold
    /// أرقام عربية-هندية (٧ ٨ ٩ ١٠) بطابع تراثي.
    case heritage
    /// حرف ورمز صغيران في الزاوية بلا زخرفة.
    case minimal

    static var fallback: CardFaceStyle { .classic }

    var title: String {
        switch self {
        case .classic: "كلاسيكي".localized
        case .bold: "عريض".localized
        case .heritage: "تراثي".localized
        case .minimal: "بسيط".localized
        }
    }

    var detail: String {
        switch self {
        case .classic: "رقم فوق ورمز تحت، الشكل المعتاد للتطبيق.".localized
        case .bold: "أرقام كبيرة تُقرأ بسهولة من بعد الذراع.".localized
        case .heritage: "أرقام عربية-هندية بطابع المجالس القديمة.".localized
        case .minimal: "زاوية واحدة بلا زخرفة، أهدأ شكل ممكن.".localized
        }
    }

    /// هل تُعرض قيمة الورقة بالأرقام العربية-الهندية؟
    var usesArabicIndicDigits: Bool { self == .heritage }

    var requiredRank: CareerRank {
        switch self {
        case .classic, .minimal: .newcomer
        case .bold: .majlisRegular
        case .heritage: .tableReader
        }
    }
}

// MARK: - ظهر الورقة

/// نقش ظهر الورقة المخفية (أوراق الخصوم وشاشة تمرير الجهاز).
enum CardBackStyle: String, CaseIterable, AppearanceOption {
    /// خطوط سدو أفقية متناوبة.
    case sadu
    /// شبكة معيّنات كلاسيكية.
    case diamondGrid
    /// تدرّج ليلي هادئ بنجمة واحدة.
    case night
    /// سعف نخيل مبسّط.
    case palm

    static var fallback: CardBackStyle { .sadu }

    var title: String {
        switch self {
        case .sadu: "سدو".localized
        case .diamondGrid: "معيّنات".localized
        case .night: "ليل".localized
        case .palm: "نخيل".localized
        }
    }

    var detail: String {
        switch self {
        case .sadu: "خطوط سدو متناوبة بلون الطاولة.".localized
        case .diamondGrid: "شبكة معيّنات كلاسيكية مثل أوراق اللعب المعروفة.".localized
        case .night: "تدرّج ليلي هادئ.".localized
        case .palm: "سعف نخيل مبسّط.".localized
        }
    }

    var requiredRank: CareerRank {
        switch self {
        case .sadu, .diamondGrid: .newcomer
        case .night: .majlisRegular
        case .palm: .tournamentPlayer
        }
    }
}

// MARK: - لبس الطاولة

/// لون سطح الطاولة الذي تُلعب عليه الأوراق.
enum TableFeltStyle: String, CaseIterable, AppearanceOption {
    case emerald
    case sand
    case maroon
    case midnight

    static var fallback: TableFeltStyle { .emerald }

    var title: String {
        switch self {
        case .emerald: "أخضر المجلس".localized
        case .sand: "رملي".localized
        case .maroon: "عنّابي".localized
        case .midnight: "ليلي".localized
        }
    }

    var detail: String {
        switch self {
        case .emerald: "الأخضر المعتاد لطاولات البلوت.".localized
        case .sand: "رمليّ فاتح مريح للعين في الإضاءة القوية.".localized
        case .maroon: "عنّابي داكن بطابع المجالس.".localized
        case .midnight: "كحليّ داكن يناسب اللعب ليلًا.".localized
        }
    }

    var requiredRank: CareerRank {
        switch self {
        case .emerald, .midnight: .newcomer
        case .sand: .majlisRegular
        case .maroon: .tableReader
        }
    }
}

// MARK: - خلفية الشاشة

/// معالجة خلفية شاشة اللعب خلف الطاولة.
enum TableBackdropStyle: String, CaseIterable, AppearanceOption {
    /// لون خلفية التطبيق بلا أي إضافة.
    case plain
    /// هالة ضوء خفيفة حول مركز الطاولة.
    case glow
    /// شريط سدو على الحافتين.
    case saduFrame
    /// نقاط خفيفة كأنها سماء ليل.
    case stars

    static var fallback: TableBackdropStyle { .plain }

    var title: String {
        switch self {
        case .plain: "سادة".localized
        case .glow: "هالة".localized
        case .saduFrame: "إطار سدو".localized
        case .stars: "نجوم".localized
        }
    }

    var detail: String {
        switch self {
        case .plain: "بلا أي إضافة خلف الطاولة.".localized
        case .glow: "هالة ضوء خفيفة تُبرز مركز الطاولة.".localized
        case .saduFrame: "شريطا سدو على حافتي الشاشة.".localized
        case .stars: "نقاط خفيفة كسماء ليل صافية.".localized
        }
    }

    var requiredRank: CareerRank {
        switch self {
        case .plain, .glow: .newcomer
        case .saduFrame: .tableReader
        case .stars: .tournamentPlayer
        }
    }
}

// MARK: - الأفاتار

/// شكل صورة اللاعب في المقاعد الأربعة.
enum AvatarStyle: String, CaseIterable, AppearanceOption {
    /// أيقونة شخص موحّدة لكل المقاعد.
    case person
    /// أول حرف من اسم اللاعب.
    case initials
    /// رمز مختلف لكل مقعد من رموز الجزيرة (صقر، دلة، نخلة، خيمة).
    case heritage
    /// أشكال هندسية بألوان مختلفة لكل مقعد.
    case geometric

    static var fallback: AvatarStyle { .person }

    var title: String {
        switch self {
        case .person: "أيقونة".localized
        case .initials: "الحرف الأول".localized
        case .heritage: "رموز تراثية".localized
        case .geometric: "أشكال هندسية".localized
        }
    }

    var detail: String {
        switch self {
        case .person: "أيقونة شخص موحّدة لكل المقاعد.".localized
        case .initials: "أول حرف من اسم كل لاعب.".localized
        case .heritage: "صقر ودلّة ونخلة وخيمة، رمز لكل مقعد.".localized
        case .geometric: "شكل هندسي بلون مختلف لكل مقعد.".localized
        }
    }

    var requiredRank: CareerRank {
        switch self {
        case .person, .initials: .newcomer
        case .geometric: .majlisRegular
        case .heritage: .tableReader
        }
    }
}

// MARK: - الثيم

/// لون الهوية الذي يصبغ الأزرار والإبرازات داخل شاشة اللعب.
enum TableThemeStyle: String, CaseIterable, AppearanceOption {
    case baloot
    case desert
    case coffee
    case pearl

    static var fallback: TableThemeStyle { .baloot }

    var title: String {
        switch self {
        case .baloot: "هوية البلوت".localized
        case .desert: "صحراوي".localized
        case .coffee: "قهوة".localized
        case .pearl: "لؤلؤي".localized
        }
    }

    var detail: String {
        switch self {
        case .baloot: "الأخضر والكهرماني، هوية التطبيق الأساسية.".localized
        case .desert: "درجات رملية ذهبية.".localized
        case .coffee: "بنّي القهوة العربية.".localized
        case .pearl: "أزرق فاتح هادئ.".localized
        }
    }

    var requiredRank: CareerRank {
        switch self {
        case .baloot: .newcomer
        case .desert: .majlisRegular
        case .coffee: .tournamentPlayer
        case .pearl: .balootSheikh
        }
    }
}
