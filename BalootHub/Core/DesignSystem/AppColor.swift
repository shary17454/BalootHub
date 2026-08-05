import SwiftUI

/// ألوان النظام التصميمي لتطبيق لمّة بلوت. هوية طاولة لعب عصرية وهادئة
/// بدرجات خضراء-كهرمانية، متكيفة تلقائيًا مع الوضع الداكن والفاتح.
enum AppColor {
    static let primary = Color(light: UIColor(red: 0.02, green: 0.42, blue: 0.35, alpha: 1), dark: UIColor(red: 0.16, green: 0.62, blue: 0.52, alpha: 1))
    static let primaryContainer = Color(light: UIColor(red: 0.86, green: 0.94, blue: 0.90, alpha: 1), dark: UIColor(red: 0.08, green: 0.20, blue: 0.17, alpha: 1))
    static let accent = Color(light: UIColor(red: 0.72, green: 0.55, blue: 0.16, alpha: 1), dark: UIColor(red: 0.85, green: 0.68, blue: 0.32, alpha: 1))

    static let background = Color(light: UIColor(red: 0.97, green: 0.97, blue: 0.955, alpha: 1), dark: UIColor(red: 0.07, green: 0.08, blue: 0.08, alpha: 1))
    static let surface = Color(light: .white, dark: UIColor(red: 0.12, green: 0.13, blue: 0.13, alpha: 1))
    static let surfaceElevated = Color(light: UIColor(red: 0.995, green: 0.995, blue: 0.99, alpha: 1), dark: UIColor(red: 0.16, green: 0.17, blue: 0.17, alpha: 1))

    static let textPrimary = Color(light: UIColor(red: 0.09, green: 0.10, blue: 0.10, alpha: 1), dark: UIColor(red: 0.96, green: 0.96, blue: 0.95, alpha: 1))
    static let textSecondary = Color(light: UIColor(red: 0.40, green: 0.42, blue: 0.41, alpha: 1), dark: UIColor(red: 0.70, green: 0.72, blue: 0.70, alpha: 1))
    static let textOnPrimary = Color.white

    static let border = Color(light: UIColor(red: 0.87, green: 0.87, blue: 0.85, alpha: 1), dark: UIColor(red: 0.24, green: 0.25, blue: 0.25, alpha: 1))

    static let success = Color(light: UIColor(red: 0.16, green: 0.55, blue: 0.28, alpha: 1), dark: UIColor(red: 0.36, green: 0.72, blue: 0.46, alpha: 1))
    static let warning = Color(light: UIColor(red: 0.72, green: 0.48, blue: 0.08, alpha: 1), dark: UIColor(red: 0.90, green: 0.68, blue: 0.28, alpha: 1))
    static let danger = Color(light: UIColor(red: 0.72, green: 0.19, blue: 0.16, alpha: 1), dark: UIColor(red: 0.90, green: 0.40, blue: 0.36, alpha: 1))

    /// ألوان تصنيف المحتوى: ألعاب بلوت / أدوات بلوت / ألعاب ورق أخرى.
    static func categoryColor(for category: GameCategory) -> Color {
        switch category {
        case .balootGame: primary
        case .balootTool: accent
        case .otherCardGame: Color(light: UIColor(red: 0.30, green: 0.35, blue: 0.62, alpha: 1), dark: UIColor(red: 0.52, green: 0.57, blue: 0.82, alpha: 1))
        }
    }
}

private extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
