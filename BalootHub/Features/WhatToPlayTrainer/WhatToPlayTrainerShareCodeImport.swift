import SwiftUI
import BalootEngine

extension WhatToPlayTrainerView {
    var shareCodeImportView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("استيراد موقف".localized, systemImage: "qrcode.viewfinder")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)

            HStack(spacing: AppSpacing.xs) {
                TextField("رمز الموقف".localized, text: $shareCodeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .disabled(isGeneratingScenario)
                    .submitLabel(.done)
                    .onSubmit(loadShareCode)

                Button {
                    loadShareCode()
                } label: {
                    Image(systemName: "arrow.down.doc.fill")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .disabled(
                    isGeneratingScenario ||
                    shareCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .accessibilityLabel("تحميل رمز الموقف".localized)
            }

            if let shareCodeMessage {
                Text(shareCodeMessage)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    func loadShareCode() {
        let code = shareCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        guard let parsed = WhatToPlayScenarioCode.parse(code) else {
            shareCodeMessage = "رمز الموقف غير صالح.".localized
            return
        }

        generationTask?.cancel()
        selectedOption = nil
        errorMessage = nil
        illegalMoveExplanation = nil
        shareImageURL = nil
        isRenderingShareImage = false
        isRetryingCurrentScenario = parsed.selectedCard != nil
        scenario = nil
        isGeneratingScenario = true
        shareCodeMessage = "جارٍ تحميل الموقف من الرمز.".localized

        generationTask = Task {
            do {
                let generated = try await WhatToPlayScenarioLoader.generate(code: code)
                guard !Task.isCancelled else { return }
                isApplyingImportedShareCode = true
                seed = parsed.seed
                difficulty = parsed.difficulty
                preferredFocusRaw = parsed.focusKind?.rawValue ?? "auto"
                preferredModeRaw = "auto"
                preferredTrumpSuit = nil
                scenario = generated
                selectedOption = parsed.selectedCard.flatMap {
                    WhatToPlayTrainer.evaluateChoice(card: $0, in: generated)
                }
                if let attempt = try? await WhatToPlayAttemptFactory.makeAttempt(code: code),
                   !attempts.contains(where: { $0.scenarioCode == attempt.scenarioCode }) {
                    modelContext.insert(attempt)
                    try? modelContext.save()
                }
                shareCodeMessage = selectedOption == nil
                    ? "تم تحميل الموقف. اختر الورقة الأفضل.".localized
                    : "تم تحميل مراجعة القرار وإضافتها للإحصاءات.".localized
                saveTrainerPreferences()
                Task { @MainActor in
                    isApplyingImportedShareCode = false
                }
            } catch WhatToPlayScenarioLoader.ScenarioCodeError.invalidCode,
                    WhatToPlayAttemptFactory.ShareCodeAttemptError.invalidCode {
                guard !Task.isCancelled else { return }
                scenario = nil
                shareCodeMessage = "رمز الموقف غير صالح.".localized
                isApplyingImportedShareCode = false
            } catch WhatToPlayAttemptFactory.ShareCodeAttemptError.selectedCardUnavailable {
                guard !Task.isCancelled else { return }
                scenario = nil
                shareCodeMessage = "الورقة الموجودة في الرمز لا تنتمي لهذا الموقف.".localized
                isApplyingImportedShareCode = false
            } catch {
                guard !Task.isCancelled else { return }
                scenario = nil
                shareCodeMessage = "تعذّر تحميل الموقف من الرمز.".localized
                isApplyingImportedShareCode = false
            }
            isGeneratingScenario = false
        }
    }
}
