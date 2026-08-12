import Foundation

/// تصنيف حالة نادرة في قواعد البلوت.
enum RareCaseCategory: String, CaseIterable, Identifiable {
    case bidding
    case projects
    case multiplier
    case play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bidding: "مزايدة".localized
        case .projects: "مشاريع".localized
        case .multiplier: "مضاعفات".localized
        case .play: "لعب الأوراق".localized
        }
    }

    var iconName: String {
        switch self {
        case .bidding: "hand.raised.fill"
        case .projects: "rectangle.stack.badge.plus"
        case .multiplier: "multiply.circle.fill"
        case .play: "suit.club.fill"
        }
    }
}

/// حالة نادرة واحدة: سؤال «ماذا لو؟» وحكمها وتفسير مبني على القاعدة الفعلية.
struct RareCaseRuling: Identifiable, Equatable {
    let id: String
    let category: RareCaseCategory
    let question: String
    let ruling: String
    let rationale: String
}

/// مختبر الحالات النادرة: مواقف حدّية نادرة الحدوث في المجلس الحقيقي، حكمها هنا
/// مطابق تمامًا لما يطبّقه BalootEngine (وليس تفسيرًا مستقلًا عنه)، حتى لا يتناقض
/// المرجع مع سلوك اللعب الفعلي داخل التطبيق.
enum RareCaseLibrary {
    static let rulings: [RareCaseRuling] = [
        RareCaseRuling(
            id: "all-pass-twice",
            category: .bidding,
            question: "مرّ اللاعبون الأربعة في الجولة الأولى، ثم مرّوا مرة ثانية في جولة الأشكال. وش يصير؟",
            ruling: "تصير «دورة ميتة»: تُلغى الصكة بالكامل، لا نقاط لأي فريق، ولا مشاريع، ويدور دور الموزّع إلى اللاعب التالي مباشرة.",
            rationale: "لا يوجد مشترٍ فلا يوجد نمط لعب أصلًا، فتُعاد الصكة من الصفر مع موزّع جديد."
        ),
        RareCaseRuling(
            id: "sun-after-hokum",
            category: .bidding,
            question: "لاعب اشترى حكم كبة، وبعده أعلن لاعب آخر صن في نفس الدورة. مين يشتري؟",
            ruling: "الصن يعلو الحكم دائمًا داخل نفس دورة المزايدة، فيأخذ صاحب الصن الشراء فورًا وتُغلق المزايدة.",
            rationale: "قاعدة «الصن فوق الحكم»: لا شيء يعلو الصن، لكن الصن يعلو أي حكم أُعلن قبله في نفس الدورة."
        ),
        RareCaseRuling(
            id: "hokum-wrong-suit-first-round",
            category: .bidding,
            question: "الورقة المكشوفة دينار، ولاعب حاول شراء حكم سباتي في الجولة الأولى. هل يجوز؟",
            ruling: "لا يجوز. الجولة الأولى تقيّد شراء الحكم بشكل الورقة المكشوفة فقط؛ باقي الأشكال تُفتح لاحقًا في جولة الأشكال.",
            rationale: "الجولة الأولى مبنية على الورقة المكشوفة تحديدًا حتى يبقى قرار المزايدة الأول محكومًا بمعلومة مشتركة بين اللاعبين."
        ),
        RareCaseRuling(
            id: "tied-projects",
            category: .projects,
            question: "أعلن فريقان مشروع سرا بنفس النقاط وبنفس أعلى ورقة بالضبط. مين يأخذ النقاط؟",
            ruling: "لا أحد. عند التعادل التام (نفس النوع، نفس النقاط، نفس أعلى ورقة) يُلغى مشروعا الفريقين معًا ولا يُحتسب أي منهما.",
            rationale: "المفاضلة تحتاج فائزًا واضحًا؛ التعادل الكامل يعني عدم وجود أفضلية حقيقية لأي فريق فتُلغى المطالبتان."
        ),
        RareCaseRuling(
            id: "belot-loses-comparison",
            category: .projects,
            question: "فريق عنده بلوت (شايب وبنت الحكم)، لكن الخصم عنده مشروع أربعمية أقوى بكثير. هل يخسر صاحب البلوت نقاط بلوته؟",
            ruling: "لا. البلوت مستثنى من المفاضلة تمامًا؛ يُحتسب لصاحبه دائمًا بغض النظر عن قوة مشروع الخصم.",
            rationale: "البلوت ليس مشروعًا تنافسيًا بين الفريقين مثل السرا والخمسين والمية — هو حق ثابت لمن يملك شايب وبنت الحاكم في يده."
        ),
        RareCaseRuling(
            id: "same-team-two-projects",
            category: .projects,
            question: "لاعبان من نفس الفريق أعلنا مشروعين مختلفين (سرا وخمسين) في نفس الجولة، والخصم ما عنده مشروع. مين يأخذ النقاط؟",
            ruling: "الفريق يأخذ نقاط كل مشاريعه المُعلَنة (السرا والخمسين معًا)، لأن المفاضلة تكون بين أقوى مشروع لكل فريق، لا بين مشاريع نفس الفريق.",
            rationale: "التعارض يحصل بين الفريقين لا داخل الفريق الواحد؛ إعلانات نفس الفريق لا تتنافس مع بعضها."
        ),
        RareCaseRuling(
            id: "escalation-order",
            category: .multiplier,
            question: "بعد الدبل، هل يقدر الفريق الآخر يقفز مباشرة إلى «فور» بدل «ثري»؟",
            ruling: "لا. التصعيد يجب أن يكون بالدرجة التالية بالضبط: دبل → ثري → فور → قهوة. لا يجوز تخطي درجة.",
            rationale: "قاعدة التصعيد المتدرج تمنع القفز المفاجئ في المخاطرة، وتُبقي فرصة الرد متكافئة بين الفريقين في كل درجة."
        ),
        RareCaseRuling(
            id: "lock-ownership",
            category: .multiplier,
            question: "مين يقدر يقفل المضاعفة — أي لاعب، ولا فريق معيّن بالذات؟",
            ruling: "فقط الفريق صاحب آخر تصعيد فعلي (آخر من دبل أو ثري أو فور) يملك حق القفل في تلك اللحظة، وليس أي فريق.",
            rationale: "القفل امتياز لصاحب المبادرة الحالية في التصعيد، حتى لا يقفل فريق تصعيدًا لم يطلبه أصلًا."
        ),
        RareCaseRuling(
            id: "purchasing-team-no-raise",
            category: .multiplier,
            question: "فريق المشتري نفسه — هل يقدر يبدأ الدبل قبل ما يرد الخصم؟",
            ruling: "لا. حق بدء أول تصعيد (الدبل الابتدائي) لفريق الخصم فقط بعد استقرار الشراء، لا لفريق المشتري.",
            rationale: "فريق المشتري هو من حدد النمط أصلًا؛ حق المخاطرة الأول بالمضاعفة يعود لمن سيتحمل مفاجأة الشراء، أي الخصم."
        ),
        RareCaseRuling(
            id: "kaboot-with-declarer-fail",
            category: .play,
            question: "فريق حقق كبوتًا (أخذ الأكلات الثماني) لكنه نفس الفريق الذي فشل في تحقيق أغلبية النقاط بقاعدة «طيّاح المشتري». هل يحتفظ بمكافأة الكبوت؟",
            ruling: "الكبوت يعتمد فقط على أخذ الأكلات الثماني فعليًا، فإذا تحقق يُحتسب لصاحبه بغض النظر عن نتيجة «طيّاح المشتري» المنفصلة عنه.",
            rationale: "الكبوت وطيّاح المشتري قاعدتان مستقلتان: الأولى تكافئ كسح الأكلات، والثانية تُعاقب فريق المشتري الذي لم يحقق أغلبية النقاط رغم شرائه."
        ),
        RareCaseRuling(
            id: "void-suit-inference",
            category: .play,
            question: "لاعب لم يتبع شكلًا مطلوبًا في أكلة سابقة، ثم رجع نفس الشكل لاحقًا. هل يقدر يلعبه؟",
            ruling: "لا. عدم اتباع شكل مطلوب سابقًا معناه أن اللاعب خالٍ منه فعلًا، وهذا استنتاج مؤكد يمنعه من لعب نفس الشكل لاحقًا.",
            rationale: "القاعدة الأساسية تلزم اتباع الشكل المطلوب متى توفّر في اليد؛ إن لم يتبعه اللاعب مرة فهذا دليل قاطع على خلوّه منه طوال الجولة."
        )
    ]

    static func rulings(in category: RareCaseCategory) -> [RareCaseRuling] {
        rulings.filter { $0.category == category }
    }

    static func search(_ query: String) -> [RareCaseRuling] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return rulings }
        return rulings.filter {
            $0.question.localizedCaseInsensitiveContains(trimmed) || $0.ruling.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
