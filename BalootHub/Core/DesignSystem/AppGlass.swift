import SwiftUI

/// طبقة مظهر زجاجية موحدة لكل واجهات التطبيق.
///
/// تستخدم Liquid Glass عند البناء على SDK الحديثة، وترجع إلى مواد SwiftUI
/// القياسية على الأنظمة الأقدم حتى يبقى التطبيق قابلًا للتشغيل بثبات.
enum AppGlass {
    static let cardStroke = Color.white.opacity(0.20)
    static let subtleStroke = Color.white.opacity(0.14)
    static let darkStroke = Color.black.opacity(0.08)
}

extension View {
    func appGlassCard(cornerRadius: CGFloat = AppRadius.large, tint: Color? = nil) -> some View {
        modifier(AppGlassCardModifier(cornerRadius: cornerRadius, tint: tint, isInteractive: false))
    }

    func appInteractiveGlassCard(cornerRadius: CGFloat = AppRadius.large, tint: Color? = nil) -> some View {
        modifier(AppGlassCardModifier(cornerRadius: cornerRadius, tint: tint, isInteractive: true))
    }

    func appGlassChip(isSelected: Bool, tint: Color = AppColor.primary) -> some View {
        modifier(AppGlassChipModifier(isSelected: isSelected, tint: tint))
    }

    func appGlassNavigationChrome() -> some View {
        modifier(AppGlassNavigationChromeModifier())
    }
}

private struct AppGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let isInteractive: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(.regularMaterial, in: shape)
            .overlay {
                shape
                    .fill((tint ?? AppColor.primary).opacity(0.05))
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppGlass.cardStroke, AppColor.border.opacity(0.42), AppGlass.darkStroke],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            .modifier(AppLiquidGlassModifier(cornerRadius: cornerRadius, tint: tint, isInteractive: isInteractive))
    }
}

private struct AppGlassChipModifier: ViewModifier {
    let isSelected: Bool
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(isSelected ? tint.opacity(0.30) : AppColor.surface.opacity(0.42), in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? tint.opacity(0.62) : AppGlass.subtleStroke, lineWidth: 1))
            .modifier(AppLiquidGlassModifier(cornerRadius: AppRadius.pill, tint: isSelected ? tint : nil, isInteractive: true))
    }
}

private struct AppGlassNavigationChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.regularMaterial, for: .navigationBar)
            .toolbarBackground(.regularMaterial, for: .tabBar)
            .toolbarColorScheme(nil, for: .navigationBar)
            .toolbarColorScheme(nil, for: .tabBar)
    }
}

private struct AppLiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let isInteractive: Bool

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular.tint(tint).interactive(isInteractive),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            content
        }
        #else
        content
        #endif
    }
}
