import Foundation

/// أحد أنواع الأوراق الأربعة في حزمة البلوت (32 ورقة).
public enum Suit: String, CaseIterable, Codable, Sendable, Identifiable {
    case hearts
    case diamonds
    case clubs
    case spades

    public var id: String { rawValue }

    /// ترتيب ثابت للنوع لا يتغيّر بين تشغيلات التطبيق.
    ///
    /// `hashValue` في Swift مبذور عشوائيًا مع كل عملية تشغيل، فلا يصلح أساسًا
    /// لأي حساب يُفترض أن يكون قابلًا لإعادة الإنتاج (مثل بذور محاكاة الوكيل الخبير).
    public var ordinal: Int {
        switch self {
        case .hearts: 0
        case .diamonds: 1
        case .clubs: 2
        case .spades: 3
        }
    }

    /// الرمز المعروض للورقة.
    public var symbol: String {
        switch self {
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        case .spades: "♠"
        }
    }

    /// الاسم العربي لنوع الورقة.
    public var arabicName: String {
        switch self {
        case .hearts: "هارت"
        case .diamonds: "ديناري"
        case .clubs: "كلوب"
        case .spades: "سباتي"
        }
    }

    public var isRed: Bool {
        switch self {
        case .hearts, .diamonds: true
        case .clubs, .spades: false
        }
    }
}
