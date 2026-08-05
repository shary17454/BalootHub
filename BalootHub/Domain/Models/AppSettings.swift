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
        case .system: "حسب النظام"
        case .light: "فاتح"
        case .dark: "داكن"
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

    init(
        appearanceMode: AppearanceMode = .system,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        defaultTargetScore: Int = 152,
        enableCoffeeMultiplier: Bool = false,
        confirmBeforeDelete: Bool = true,
        selectedScoreRulePreset: ScoreRulePreset = .standard
    ) {
        self.appearanceModeRaw = appearanceMode.rawValue
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.defaultTargetScore = defaultTargetScore
        self.enableCoffeeMultiplier = enableCoffeeMultiplier
        self.confirmBeforeDelete = confirmBeforeDelete
        self.selectedScoreRulePresetRaw = selectedScoreRulePreset.rawValue
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

    /// الحد المستهدف الافتراضي المسموح به بحدود منطقية (من 50 حتى 1000).
    static let allowedTargetScoreRange = 50...1000
}
