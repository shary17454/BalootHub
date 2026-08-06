import Foundation

extension String {
    /// يبحث عن ترجمة هذا النص العربي (نص المصدر) داخل كتالوج السلاسل النصية
    /// عند التشغيل، حتى لو أتى النص من متغيّر ديناميكي بدل سلسلة حرفية مباشرة
    /// في Text(...) — وهي الحالة الشائعة لخصائص enum المحسوبة مثل title/subtitle.
    var localized: String {
        String(localized: String.LocalizationValue(self))
    }
}
