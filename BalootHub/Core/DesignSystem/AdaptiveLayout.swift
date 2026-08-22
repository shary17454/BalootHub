import SwiftUI

/// يحدّ عرض المحتوى النصي على الشاشات العريضة ويوسّطه.
///
/// على iPad بعرض 13 بوصة يمتد النص من حافة إلى حافة فيصير سطرًا طويلًا يصعب
/// تتبّعه بالعين — وهي المشكلة الأولى التي تظهر عند تشغيل تطبيق مصمَّم للآيفون
/// على iPad بلا تعديل. الحدّ يُطبَّق **فقط** على فئة الحجم الأفقي `regular`،
/// فيبقى الآيفون و«Slide Over» على iPad كما هما تمامًا.
///
/// > لا يُطبَّق على طاولة اللعب: الطاولة تستفيد من كامل العرض عمدًا.
private struct AdaptiveContentWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: horizontalSizeClass == .regular ? maxWidth : .infinity)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// يحدّ عرض المحتوى على الشاشات العريضة (iPad) ويُبقيه في المنتصف.
    /// - Parameter maxWidth: أقصى عرض للمحتوى على فئة الحجم `regular`.
    func adaptiveContentWidth(_ maxWidth: CGFloat = AppLayout.readableContentWidth) -> some View {
        modifier(AdaptiveContentWidth(maxWidth: maxWidth))
    }
}

/// يحدّ ارتفاع المحتوى على الشاشات الطويلة ويوسّطه رأسيًا.
///
/// طاولة اللعب مبنية على `Spacer` بين الأقسام، وهو تصميم يعمل جيدًا على ارتفاع
/// الآيفون لكنه يبعثر العناصر إلى الزوايا على ارتفاع iPad. تحديد الارتفاع يجعل
/// الطاولة كتلة متماسكة في وسط الشاشة بدل أن تتباعد أطرافها.
private struct AdaptiveContentHeight: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let maxHeight: CGFloat

    /// يُطبَّق فقط حين تكون الشاشة واسعة **وطويلة** معًا (iPad بوضع ملء الشاشة).
    private var isRoomy: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    func body(content: Content) -> some View {
        content
            .frame(maxHeight: isRoomy ? maxHeight : .infinity)
            .frame(maxHeight: .infinity)
    }
}

extension View {
    /// يحدّ ارتفاع المحتوى على iPad ويُبقيه متوسّطًا رأسيًا.
    func adaptiveContentHeight(_ maxHeight: CGFloat = AppLayout.compactTableHeight) -> some View {
        modifier(AdaptiveContentHeight(maxHeight: maxHeight))
    }
}

/// مقاسات تخطيط مشتركة تعتمد عليها الشاشات العريضة.
enum AppLayout {
    /// عرض مريح للقراءة يقارب ما توصي به آبل لعمود نص واحد.
    static let readableContentWidth: CGFloat = 700

    /// عرض أوسع قليلًا للشبكات والبطاقات التي تحتمل عمودين.
    static let wideContentWidth: CGFloat = 900

    /// أقصى ارتفاع لطاولة اللعب على الشاشات الطويلة، قريب من ارتفاع آيفون كبير.
    static let compactTableHeight: CGFloat = 880
}
