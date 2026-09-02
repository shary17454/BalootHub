import StoreKit
import SwiftUI

struct BalootPlusView: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    private var subscriptionStore: SubscriptionStore {
        appEnvironment.subscriptionStore
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                hero
                plansSection
                servicesSection
                reviewReadinessSection
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
        .background(AppColor.background)
        .navigationTitle("بلوت بلس")
        .task { await subscriptionStore.configure() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("بلوت بلس", systemImage: "crown.fill")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.accent)

            Text("اشتراك اختياري يفتح أدوات تدريب وتحليل وتخصيص متقدمة، مع بقاء اللعب الأساسي عادلًا ومتاحًا بلا أفضلية مدفوعة.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)

            if subscriptionStore.isPremiumUnlocked {
                StatusBadge("مفعّل", systemImage: "checkmark.seal.fill", tint: AppColor.success)
            } else {
                StatusBadge("غير مفعّل", systemImage: "lock.fill", tint: AppColor.warning)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(AppColor.border, lineWidth: 1))
    }

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("الأسعار")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            ForEach(subscriptionStore.configuredProducts) { configuredProduct in
                planCard(configuredProduct)
            }

            if let message = subscriptionStore.purchaseState.message {
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, AppSpacing.xxs)
            }

            Button {
                Task { await subscriptionStore.restorePurchases() }
            } label: {
                Label("استعادة المشتريات", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(subscriptionStore.isLoading)
        }
    }

    private func planCard(_ configuredProduct: BalootPlusProduct) -> some View {
        let storeProduct = subscriptionStore.product(for: configuredProduct)
        let price = storeProduct?.displayPrice ?? configuredProduct.recommendedSaudiPrice

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(configuredProduct.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(configuredProduct.periodTitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                Text(price)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.primary)
            }

            Button {
                guard let storeProduct else { return }
                Task { await subscriptionStore.purchase(storeProduct) }
            } label: {
                Label("اشترك الآن", systemImage: "cart.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(storeProduct == nil || subscriptionStore.isLoading || subscriptionStore.isPremiumUnlocked)

            if storeProduct == nil {
                Text("السعر أعلاه هو السعر المقترح. السعر النهائي يظهر من App Store بعد إنشاء المنتج وإتاحته.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(AppColor.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("الخدمات المرتبطة")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            ForEach(BalootPlusFeature.allCases) { feature in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: subscriptionStore.hasAccess(to: feature) ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundStyle(subscriptionStore.hasAccess(to: feature) ? AppColor.success : AppColor.textSecondary)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(feature.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(feature.detail)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.small))
            }
        }
    }

    private var reviewReadinessSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("معلومات المراجعة")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("معرّفات المنتجات المطلوبة في App Store Connect: app.balooThub.ios.plus.monthly و app.balooThub.ios.plus.yearly ضمن مجموعة Baloot Plus. يجب إرفاق لقطة شاشة مراجعة لكل اشتراك قبل إرسال الإصدار.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(AppColor.border, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        BalootPlusView()
    }
    .environment(AppEnvironment())
}
