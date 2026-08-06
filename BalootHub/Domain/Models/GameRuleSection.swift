import Foundation
import SwiftData

/// قسم واحد من أقسام صفحة قواعد اللعبة (الهدف، التوزيع، الاحتساب...).
@Model
final class GameRuleSection {
    var id: UUID
    var title: String
    var body: String
    var order: Int
    var iconName: String
    var game: GameCatalogItem?

    init(id: UUID = UUID(), title: String, body: String, order: Int, iconName: String) {
        self.id = id
        self.title = title
        self.body = body
        self.order = order
        self.iconName = iconName
    }

    /// عنوان القسم بلغة الجهاز الحالية (النص العربي المخزَّن يُستخدم كمفتاح ترجمة).
    var displayTitle: String { title.localized }

    /// نص القسم بلغة الجهاز الحالية.
    var displayBody: String { body.localized }
}
