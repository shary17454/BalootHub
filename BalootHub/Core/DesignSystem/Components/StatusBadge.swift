import SwiftUI

/// شارة نصية صغيرة تُستخدم لعرض النوع أو حالة "متاح للعب"/"قواعد فقط".
/// لا تعتمد على اللون وحده: تحمل أيقونة مصاحبة لدعم "التمييز دون اعتماد على اللون".
struct StatusBadge: View {
    let title: String
    let systemImage: String?
    let tint: Color

    init(_ title: String, systemImage: String? = nil, tint: Color) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
            Text(title)
        }
        .font(AppTypography.badge)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(tint.opacity(0.16), in: Capsule())
        .foregroundStyle(tint)
    }
}

#Preview {
    HStack {
        StatusBadge("بلوت", systemImage: "suit.spade.fill", tint: AppColor.primary)
        StatusBadge("متاح للعب", systemImage: "play.fill", tint: AppColor.success)
        StatusBadge("قواعد فقط", systemImage: "book.fill", tint: AppColor.textSecondary)
    }
    .padding()
}
