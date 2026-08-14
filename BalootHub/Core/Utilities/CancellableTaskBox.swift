import Foundation

/// يحفظ مهمة `Task` قابلة للاستبدال والإلغاء، حتى لا تتزاحم مهمتان (مثل جولتَي
/// لاعبين آليين متتاليتين، أو تحليلين للجولة) على نفس الحالة في آنٍ واحد.
///
/// `@unchecked Sendable` آمن هنا لأن كل مستخدمي هذا النوع في التطبيق يحصرون
/// النداء عليه بسياق عزل واحد (فئة `@MainActor`)، فلا يوجد وصول متزامن فعلي
/// رغم غياب فحص المترجم الصارم على هدف التطبيق نفسه (بخلاف حزمة BalootEngine).
final class CancellableTaskBox: @unchecked Sendable {
    private var task: Task<Void, Never>?

    func replace(with newTask: Task<Void, Never>) {
        task?.cancel()
        task = newTask
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
