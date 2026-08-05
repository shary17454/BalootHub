import Foundation

/// قيمة الورقة. حزمة البلوت تحتوي 8 قيم لكل نوع (32 ورقة إجمالًا).
public enum Rank: String, CaseIterable, Codable, Sendable, Identifiable {
    case seven
    case eight
    case nine
    case jack
    case queen
    case king
    case ten
    case ace

    public var id: String { rawValue }

    /// الرمز المختصر المعروض على الورقة.
    public var shortLabel: String {
        switch self {
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        case .ten: "10"
        case .ace: "A"
        }
    }

    /// ترتيب القوة في نمط "صن" (لا يوجد حكم)، من الأضعف إلى الأقوى.
    /// المصدر: نفس الترتيب يطبَّق على كل الأنواع في وضع صن.
    public static let sunOrder: [Rank] = [.seven, .eight, .nine, .jack, .queen, .king, .ten, .ace]

    /// ترتيب القوة في نمط "حكم" للأنواع غير الحكم، من الأضعف إلى الأقوى.
    public static let hokumNonTrumpOrder: [Rank] = [.seven, .eight, .nine, .jack, .queen, .king, .ten, .ace]

    /// ترتيب القوة في نمط "حكم" لنوع الحكم نفسه، من الأضعف إلى الأقوى.
    /// الشايب (J) هو الأقوى، يليه الـ9.
    public static let hokumTrumpOrder: [Rank] = [.seven, .eight, .queen, .king, .ten, .ace, .nine, .jack]

    /// نقاط الورقة في نمط "صن".
    public var sunPoints: Int {
        switch self {
        case .ace: 11
        case .ten: 10
        case .king: 4
        case .queen: 3
        case .jack: 2
        case .nine, .eight, .seven: 0
        }
    }

    /// نقاط الورقة في نمط "حكم" لنوع غير الحكم.
    public var hokumNonTrumpPoints: Int {
        switch self {
        case .ace: 11
        case .ten: 10
        case .king: 4
        case .queen: 3
        case .jack: 2
        case .nine, .eight, .seven: 0
        }
    }

    /// نقاط الورقة في نمط "حكم" لنوع الحكم نفسه (الشايب وبنت الحكم لهما قيمة أعلى).
    public var hokumTrumpPoints: Int {
        switch self {
        case .jack: 20
        case .nine: 14
        case .ace: 11
        case .ten: 10
        case .king: 4
        case .queen: 3
        case .eight, .seven: 0
        }
    }
}
