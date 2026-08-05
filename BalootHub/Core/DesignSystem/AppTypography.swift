import SwiftUI

/// أنماط النصوص الموحدة، مبنية على أنماط SwiftUI الديناميكية لدعم Dynamic Type تلقائيًا.
enum AppTypography {
    static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body)
    static let subheadline = Font.system(.subheadline)
    static let caption = Font.system(.caption)
    static let badge = Font.system(.caption2).weight(.semibold)
}
