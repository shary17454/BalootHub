import Foundation
import SwiftData

/// وضع المظهر المختار من الإعدادات.
enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "حسب النظام".localized
        case .light: "فاتح".localized
        case .dark: "داكن".localized
        }
    }
}

/// إعدادات التطبيق. نموذج وحيد (Singleton) يُنشأ تلقائيًا عند أول تشغيل.
@Model
final class AppSettings {
    var appearanceModeRaw: String
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var defaultTargetScore: Int
    var enableCoffeeMultiplier: Bool
    var confirmBeforeDelete: Bool
    var selectedScoreRulePresetRaw: String

    /// خيارات تخصيص الطاولة.
    ///
    /// أُضيفت بقيم افتراضية **مضمّنة في التعريف** (لا في المُهيّئ فقط) لأن SwiftData
    /// يحتاج قيمة افتراضية على مستوى الخاصية حتى تمرّ الترقية التلقائية على قواعد
    /// البيانات الموجودة مسبقًا بدل أن تفشل بخاصية إلزامية بلا قيمة.
    var cardFaceStyleRaw: String = CardFaceStyle.fallback.rawValue
    var cardBackStyleRaw: String = CardBackStyle.fallback.rawValue
    var tableFeltStyleRaw: String = TableFeltStyle.fallback.rawValue
    var tableBackdropStyleRaw: String = TableBackdropStyle.fallback.rawValue
    var avatarStyleRaw: String = AvatarStyle.fallback.rawValue
    var tableThemeStyleRaw: String = TableThemeStyle.fallback.rawValue

    /// مؤثرات الاحتفال عند المشاريع والكبوت. منفصلة عن "تقليل الحركة" في النظام:
    /// إطفاء النظام للحركة يُلغيها دائمًا، وهذا المفتاح يسمح بإطفائها يدويًا كذلك.
    var celebrationEffectsEnabled: Bool = true

    init(
        appearanceMode: AppearanceMode = .system,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        defaultTargetScore: Int = 152,
        enableCoffeeMultiplier: Bool = false,
        confirmBeforeDelete: Bool = true,
        selectedScoreRulePreset: ScoreRulePreset = .standard,
        appearance: AppearanceRawSelection = .standard,
        celebrationEffectsEnabled: Bool = true
    ) {
        self.appearanceModeRaw = appearanceMode.rawValue
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.defaultTargetScore = defaultTargetScore
        self.enableCoffeeMultiplier = enableCoffeeMultiplier
        self.confirmBeforeDelete = confirmBeforeDelete
        self.selectedScoreRulePresetRaw = selectedScoreRulePreset.rawValue
        self.cardFaceStyleRaw = appearance.cardFace
        self.cardBackStyleRaw = appearance.cardBack
        self.tableFeltStyleRaw = appearance.felt
        self.tableBackdropStyleRaw = appearance.backdrop
        self.avatarStyleRaw = appearance.avatar
        self.tableThemeStyleRaw = appearance.theme
        self.celebrationEffectsEnabled = celebrationEffectsEnabled
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    var selectedScoreRulePreset: ScoreRulePreset {
        get { ScoreRulePreset(rawValue: selectedScoreRulePresetRaw) ?? .standard }
        set { selectedScoreRulePresetRaw = newValue.rawValue }
    }

    var scoreRules: ScoreRules {
        .from(preset: selectedScoreRulePreset, coffeeEnabled: enableCoffeeMultiplier)
    }

    /// القيم الخام لخيارات التخصيص، للقراءة والكتابة دفعة واحدة.
    var appearanceSelection: AppearanceRawSelection {
        get {
            AppearanceRawSelection(
                cardFace: cardFaceStyleRaw,
                cardBack: cardBackStyleRaw,
                felt: tableFeltStyleRaw,
                backdrop: tableBackdropStyleRaw,
                avatar: avatarStyleRaw,
                theme: tableThemeStyleRaw
            )
        }
        set {
            cardFaceStyleRaw = newValue.cardFace
            cardBackStyleRaw = newValue.cardBack
            tableFeltStyleRaw = newValue.felt
            tableBackdropStyleRaw = newValue.backdrop
            avatarStyleRaw = newValue.avatar
            tableThemeStyleRaw = newValue.theme
        }
    }

    /// المظهر الفعلي بعد التحقق من الفتح حسب الرتبة الحالية.
    func tableAppearance(at rank: CareerRank) -> TableAppearance {
        AppearanceCatalog.resolve(appearanceSelection, at: rank)
    }

    /// الحد المستهدف الافتراضي المسموح به بحدود منطقية (من 50 حتى 1000).
    static let allowedTargetScoreRange = 50...1000
}
