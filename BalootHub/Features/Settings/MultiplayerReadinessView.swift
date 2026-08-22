import SwiftUI

/// شاشة توضّح حالة التطبيق تجاه اللعب الجماعي عن بُعد ووضع المتفرّج.
///
/// شاشة قراءة فقط عمدًا: هذا الإصدار لا يفتح أي اتصال شبكة، والغرض توثيق ما
/// أصبح جاهزًا في البنية وما يبقى مطلوبًا قبل تفعيل الميزة فعليًا.
struct MultiplayerReadinessView: View {
    var body: some View {
        List {
            Section {
                Text("هذا الإصدار يعمل بالكامل دون إنترنت ولا يفتح أي اتصال شبكة. البنود التالية توضّح ما جهّزناه في البنية استعدادًا للعب الجماعي لاحقًا.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Section("جاهز في البنية") {
                ForEach(MultiplayerReadiness.items.filter { $0.status == .ready }) { item in
                    row(item)
                }
            }

            Section("يحتاج عملًا قبل التفعيل") {
                ForEach(MultiplayerReadiness.items.filter { $0.status == .pending }) { item in
                    row(item)
                }
            }
        }
        .navigationTitle("اللعب الجماعي")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ item: MultiplayerReadinessItem) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: item.status == .ready ? "checkmark.seal.fill" : "clock.badge.exclamationmark")
                .foregroundStyle(item.status == .ready ? AppColor.success : AppColor.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                Text(item.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title)، \(item.status.title)")
    }
}

#Preview {
    NavigationStack {
        MultiplayerReadinessView()
    }
}
