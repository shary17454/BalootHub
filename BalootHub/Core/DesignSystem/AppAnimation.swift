import SwiftUI

/// حركات موحدة، مع نسخة مخفَّفة تُستخدم تلقائيًا عند تفعيل "تقليل الحركة".
enum AppAnimation {
    static func standard(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.25)
    }

    static func spring(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)
    }

    static func cardDeal(reduceMotion: Bool, delay: Double) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.3).delay(delay)
    }
}
