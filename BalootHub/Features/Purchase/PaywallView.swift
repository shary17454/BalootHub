import SwiftUI
import StoreKit

/// شاشة فتح اللعبة الكاملة بدفعة واحدة (شراء غير مستهلك، بلا إعلانات إطلاقًا لا قبل الشراء ولا بعده).
struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "suit.spade.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(AppColor.primary)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.xs) {
                Text("افتح اللعبة الكاملة")
                    .font(AppTypography.title)
                Text("دفعة واحدة فقط، بلا اشتراكات وبلا إعلانات إطلاقًا")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                featureRow(icon: "suit.club.fill", text: "لعب بلوت كامل ضد لاعبين آليين")
                featureRow(icon: "nosign", text: "بلا إعلانات نهائيًا، الآن ومستقبلًا")
                featureRow(icon: "checkmark.seal.fill", text: "دفعة واحدة تملك بها اللعبة للأبد")
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))

            Spacer()

            if let message = purchaseManager.errorMessage {
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.danger)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await purchaseManager.purchase() }
            } label: {
                HStack {
                    if purchaseManager.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(purchaseButtonTitle)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.primary)
            .controlSize(.large)
            .disabled(purchaseManager.product == nil || purchaseManager.isLoading)

            Button("استعادة المشتريات") {
                Task { await purchaseManager.restorePurchases() }
            }
            .font(AppTypography.subheadline)
            .disabled(purchaseManager.isLoading)

            Button("لاحقًا") { dismiss() }
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.lg)
        .background(AppColor.background)
        .task {
            if purchaseManager.product == nil {
                await purchaseManager.loadProduct()
            }
        }
    }

    private var purchaseButtonTitle: String {
        if let product = purchaseManager.product {
            "فتح اللعبة الكاملة — \(product.displayPrice)"
        } else {
            "فتح اللعبة الكاملة"
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.primary)
                .frame(width: 24)
            Text(text)
                .font(AppTypography.subheadline)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseManager())
}
