import SwiftUI

/// حالة فارغة عامة قابلة لإعادة الاستخدام في كل الشاشات.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityHidden(true)
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.primary)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// حالة تحميل عامة.
struct LoadingStateView: View {
    var message: String = "جارِ التحميل…"

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(AppColor.primary)
            Text(message)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// حالة خطأ عامة مع زر إعادة محاولة اختياري.
struct ErrorStateView: View {
    let message: String
    var retryTitle: String = "إعادة المحاولة"
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.danger)
                .accessibilityHidden(true)
            Text("حدث خطأ")
                .font(AppTypography.headline)
            Text(message)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button(retryTitle, action: retry)
                    .buttonStyle(.bordered)
                    .tint(AppColor.danger)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        EmptyStateView(systemImage: "magnifyingglass", title: "لا نتائج", message: "جرّب كلمات بحث أخرى", actionTitle: "مسح البحث", action: {})
        LoadingStateView()
        ErrorStateView(message: "تعذّر تحميل البيانات", retry: {})
    }
}
