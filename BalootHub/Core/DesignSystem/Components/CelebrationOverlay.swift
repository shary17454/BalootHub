import SwiftUI

/// نوع المؤثر الاحتفالي الذي يظهر فوق الطاولة.
enum CelebrationKind: Equatable, Identifiable, Sendable {
    /// إعلان مشروع (سرا · خمسين · مية · أربعمية · بلوت).
    case project(title: String, points: Int)
    /// كبوت: أخذ الأكلات الثماني كاملة.
    case kaboot(teamName: String)
    /// حسم المباراة.
    case matchWin(teamName: String)

    var id: String {
        switch self {
        case .project(let title, let points): "project-\(title)-\(points)"
        case .kaboot(let team): "kaboot-\(team)"
        case .matchWin(let team): "match-\(team)"
        }
    }

    var headline: String {
        switch self {
        case .project(let title, _): title
        case .kaboot: "كبوت!".localized
        case .matchWin(let team): String(format: "فاز %@".localized, team)
        }
    }

    var subline: String {
        switch self {
        case .project(_, let points): String(format: "%d نقطة".localized, points)
        case .kaboot(let team): String(format: "%@ أخذ الأكلات الثماني".localized, team)
        case .matchWin: "انتهت المباراة".localized
        }
    }

    var symbolName: String {
        switch self {
        case .project: "sparkles"
        case .kaboot: "crown.fill"
        case .matchWin: "trophy.fill"
        }
    }

    var tint: Color {
        switch self {
        case .project: AppColor.accent
        case .kaboot: AppColor.warning
        case .matchWin: AppColor.success
        }
    }

    /// مدة بقاء المؤثر على الشاشة بالثواني.
    var duration: Double {
        switch self {
        case .project: 1.4
        case .kaboot, .matchWin: 2.0
        }
    }
}

/// مؤثر احتفالي قصير فوق الطاولة عند المشاريع والكبوت وحسم المباراة.
///
/// لا يعترض اللمس (`allowsHitTesting(false)`) حتى لا يعطّل اللعب، ويحترم "تقليل
/// الحركة": عند تفعيلها لا يُعرض المؤثر أصلًا من شاشة اللعب.
struct CelebrationOverlay: View {
    let kind: CelebrationKind
    var onFinished: () -> Void = {}

    @State private var isVisible = false

    /// زوايا انتشار الرموز حول المركز — ثابتة حتى لا تتغيّر مع كل إعادة رسم.
    private static let burstAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]

    var body: some View {
        ZStack {
            burst
            card
        }
        .allowsHitTesting(false)
        .task {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                isVisible = true
            }
            try? await Task.sleep(for: .seconds(kind.duration))
            withAnimation(.easeOut(duration: 0.25)) {
                isVisible = false
            }
            try? await Task.sleep(for: .milliseconds(260))
            onFinished()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.headline)، \(kind.subline)")
    }

    private var burst: some View {
        ForEach(Array(Self.burstAngles.enumerated()), id: \.offset) { index, angle in
            Image(systemName: kind.symbolName)
                .font(.system(size: index.isMultiple(of: 2) ? 18 : 12))
                .foregroundStyle(kind.tint)
                .offset(
                    x: isVisible ? cos(angle * .pi / 180) * 104 : 0,
                    y: isVisible ? sin(angle * .pi / 180) * 104 : 0
                )
                .opacity(isVisible ? 0 : 0.9)
                .animation(.easeOut(duration: kind.duration * 0.8), value: isVisible)
        }
    }

    private var card: some View {
        VStack(spacing: AppSpacing.xxs) {
            Image(systemName: kind.symbolName)
                .font(.largeTitle)
                .foregroundStyle(kind.tint)
            Text(kind.headline)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Text(kind.subline)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(kind.tint.opacity(0.6), lineWidth: 2)
        )
        .scaleEffect(isVisible ? 1 : 0.6)
        .opacity(isVisible ? 1 : 0)
    }
}

#Preview {
    ZStack {
        AppColor.background.ignoresSafeArea()
        CelebrationOverlay(kind: .kaboot(teamName: "فريقنا"))
    }
}
