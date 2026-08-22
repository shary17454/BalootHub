import SwiftUI
import BalootEngine

enum WhatToPlayShareCodeMessageStyle: Equatable {
    case neutral
    case success
    case warning
    case error
}

extension WhatToPlayTrainerView {
    var shareCodeImportView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("استيراد موقف".localized, systemImage: "qrcode.viewfinder")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)

            HStack(spacing: AppSpacing.xs) {
                TextField("رمز الموقف".localized, text: $shareCodeInput)
                    .textInputAutocapitalization(.never)
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
                    .foregroundStyle(shareCodeMessageColor(shareCodeMessageStyle))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let shareCodeSimulationAlternativeMessage {
                Label(shareCodeSimulationAlternativeMessage, systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(
                        shareCodeSimulationAlternativeAccessibilityLabel(
                            for: shareCodeSimulationAlternativeMessage
                        )
                    )
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    func loadShareCode() {
        let code = shareCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        guard let extractedCode = WhatToPlayScenarioCode.extractCode(from: code),
              let parsed = WhatToPlayScenarioCode.parse(extractedCode)
        else {
            shareCodeMessage = "رمز الموقف غير صالح.".localized
            shareCodeMessageStyle = .error
            shareCodeSimulationAlternativeMessage = nil
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
        shareCodeMessageStyle = .neutral
        shareCodeSimulationAlternativeMessage = nil

        generationTask = Task { @MainActor in
            do {
                let imported = try await WhatToPlayShareCodeImporter.import(
                    code: extractedCode,
                    existingScenarioCodes: Set(attempts.map(\.scenarioCode))
                )
                guard !Task.isCancelled else { return }
                isApplyingImportedShareCode = true
                seed = parsed.seed
                difficulty = parsed.difficulty
                preferredFocusRaw = parsed.focusKind?.rawValue ?? "auto"
                preferredModeRaw = (parsed.gameMode ?? imported.scenario.state.mode)?.rawValue ?? "auto"
                preferredTrumpSuit = parsed.trumpSuit ?? imported.scenario.state.trumpSuit
                scenario = imported.scenario
                selectedOption = imported.selectedOption
                renderShareImageForCurrentScenario()
                if let attempt = imported.attempt {
                    modelContext.insert(attempt)
                    do {
                        try modelContext.save()
                    } catch {
                        modelContext.rollback()
                        shareCodeMessage = "تم تحميل مراجعة القرار، لكن تعذّر حفظها في الإحصاءات.".localized
                        shareCodeMessageStyle = .warning
                        shareCodeSimulationAlternativeMessage = shareCodeSimulationAlternativeLine(for: imported)
                        shareCodeInput = ""
                        saveTrainerPreferences()
                        Task { @MainActor in
                            isApplyingImportedShareCode = false
                        }
                        isGeneratingScenario = false
                        return
                    }
                }
                shareCodeMessage = imported.statusMessage
                shareCodeMessageStyle = shareCodeMessageStyle(for: imported.statusTone)
                shareCodeSimulationAlternativeMessage = shareCodeSimulationAlternativeLine(for: imported)
                shareCodeInput = ""
                saveTrainerPreferences()
                Task { @MainActor in
                    isApplyingImportedShareCode = false
                }
            } catch WhatToPlayShareCodeImporter.ImportError.invalidCode,
                    WhatToPlayScenarioLoader.ScenarioCodeError.invalidCode,
                    WhatToPlayAttemptFactory.ShareCodeAttemptError.invalidCode {
                guard !Task.isCancelled else { return }
                scenario = nil
                shareCodeMessage = "رمز الموقف غير صالح.".localized
                shareCodeMessageStyle = .error
                shareCodeSimulationAlternativeMessage = nil
                isApplyingImportedShareCode = false
            } catch WhatToPlayShareCodeImporter.ImportError.selectedCardUnavailable,
                    WhatToPlayAttemptFactory.ShareCodeAttemptError.selectedCardUnavailable {
                guard !Task.isCancelled else { return }
                scenario = nil
                shareCodeMessage = "الورقة الموجودة في الرمز لا تنتمي لهذا الموقف.".localized
                shareCodeMessageStyle = .error
                shareCodeSimulationAlternativeMessage = nil
                isApplyingImportedShareCode = false
            } catch {
                guard !Task.isCancelled else { return }
                scenario = nil
                shareCodeMessage = "تعذّر تحميل الموقف من الرمز.".localized
                shareCodeMessageStyle = .error
                shareCodeSimulationAlternativeMessage = nil
                isApplyingImportedShareCode = false
            }
            isGeneratingScenario = false
        }
    }

    func clearShareCodeImportFeedback() {
        shareCodeMessage = nil
        shareCodeMessageStyle = .neutral
        shareCodeSimulationAlternativeMessage = nil
    }

    func shareCodeMessageStyle(
        for tone: WhatToPlayShareCodeImportStatusTone
    ) -> WhatToPlayShareCodeMessageStyle {
        switch tone {
        case .prompt:
            return .neutral
        case .savedReview:
            return .success
        case .duplicateReview:
            return .warning
        }
    }

    func shareCodeSimulationAlternativeLine(
        for result: WhatToPlayShareCodeImportResult
    ) -> String? {
        guard let card = result.secondBestSimulationCard else { return nil }
        var parts = [
            "\("ثاني محاكاة".localized): \(card.accessibilityName)"
        ]
        if let projectedTeamPoints = result.secondBestProjectedTeamPoints {
            parts.append("\("ثاني نتيجة محاكاة".localized): \(projectedTeamPoints)")
        }
        if result.lostProjectedAgainstSecondBestPoints > 0 {
            parts.append("\("فاقد ثاني محاكاة".localized): \(result.lostProjectedAgainstSecondBestPoints)")
        }
        return parts.joined(separator: " · ")
    }

    func shareCodeSimulationAlternativeAccessibilityLabel(
        for line: String
    ) -> String {
        "\("بديل المحاكاة المستورد".localized): \(line.replacingOccurrences(of: " · ", with: "، "))"
    }

    private func shareCodeMessageColor(_ style: WhatToPlayShareCodeMessageStyle) -> Color {
        switch style {
        case .neutral:
            return AppColor.textSecondary
        case .success:
            return AppColor.success
        case .warning:
            return AppColor.warning
        case .error:
            return AppColor.danger
        }
    }
}
