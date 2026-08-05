import SwiftUI

/// تعريف ظل موحّد يمكن تطبيقه عبر `.appShadow(_:)`.
struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let card = AppShadowStyle(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    static let elevated = AppShadowStyle(color: .black.opacity(0.14), radius: 20, x: 0, y: 8)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
