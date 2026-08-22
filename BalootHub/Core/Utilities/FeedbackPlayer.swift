import AudioToolbox
import Foundation
import UIKit

/// حدث يستحق ردّ فعل صوتيًا أو لمسيًا داخل شاشة اللعب.
enum FeedbackEvent: String, CaseIterable, Sendable {
    case cardPlayed
    case invalidMove
    case bidPlaced
    case multiplierRaised
    case projectDeclared
    case trickWon
    case trickLost
    case kaboot
    case roundFinished
    case matchWon

    /// نوع الاهتزاز المناسب للحدث.
    var haptic: HapticKind {
        switch self {
        case .cardPlayed: .light
        case .invalidMove: .error
        case .bidPlaced: .medium
        case .multiplierRaised: .rigid
        case .projectDeclared: .success
        case .trickWon: .medium
        case .trickLost: .light
        case .kaboot: .success
        case .roundFinished: .medium
        case .matchWon: .success
        }
    }

    /// معرّف صوت النظام المستخدم للحدث.
    ///
    /// التطبيق لا يشحن أي ملف صوتي: كل الأصوات من أصوات واجهة iOS الجاهزة عبر
    /// `AudioServicesPlaySystemSound` (واجهة عامة)، فلا يزيد حجم الحزمة ولا يحتاج
    /// أصولًا خارجية ولا تراخيص صوت.
    var systemSoundID: SystemSoundID {
        switch self {
        case .cardPlayed: 1104      // نقرة خفيفة
        case .invalidMove: 1053     // رفض
        case .bidPlaced: 1105
        case .multiplierRaised: 1113
        case .projectDeclared: 1057 // رنّة قصيرة
        case .trickWon: 1103
        case .trickLost: 1104
        case .kaboot: 1025          // نغمة احتفال قصيرة
        case .roundFinished: 1114
        case .matchWon: 1025
        }
    }

    /// أحداث "كبيرة" تستحق مؤثرًا بصريًا احتفاليًا فوق الطاولة.
    var deservesCelebration: Bool {
        switch self {
        case .kaboot, .projectDeclared, .matchWon: true
        default: false
        }
    }
}

/// نوع الاهتزاز اللمسي.
enum HapticKind: Sendable {
    case light
    case medium
    case rigid
    case success
    case warning
    case error
}

/// مشغّل الصوت والاهتزاز.
///
/// يقرأ حالته من إعدادات التطبيق مرة واحدة عبر ``sync(soundEnabled:hapticsEnabled:)``
/// بدل تمرير `AppSettings` لكل استدعاء، حتى يبقى مستقلًا عن SwiftData وقابلًا
/// للاستخدام من أي شاشة.
@MainActor
final class FeedbackPlayer {
    static let shared = FeedbackPlayer()

    private(set) var isSoundEnabled = true
    private(set) var isHapticsEnabled = true

    /// يُستخدم في الاختبارات لتعطيل التشغيل الفعلي مع بقاء الحساب قابلًا للفحص.
    var isMuted = false

    private(set) var lastEvent: FeedbackEvent?

    private init() {}

    func sync(soundEnabled: Bool, hapticsEnabled: Bool) {
        isSoundEnabled = soundEnabled
        isHapticsEnabled = hapticsEnabled
    }

    func play(_ event: FeedbackEvent) {
        lastEvent = event
        guard !isMuted else { return }
        if isSoundEnabled {
            AudioServicesPlaySystemSound(event.systemSoundID)
        }
        if isHapticsEnabled {
            fire(event.haptic)
        }
    }

    private func fire(_ kind: HapticKind) {
        switch kind {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
