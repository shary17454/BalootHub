import Foundation

/// تصنيف مصطلح موسوعة البلوت.
enum BalootGlossaryCategory: String, CaseIterable, Identifiable {
    case bidding
    case multiplier
    case project
    case scoring
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bidding: "المزايدة".localized
        case .multiplier: "المضاعفات".localized
        case .project: "المشاريع".localized
        case .scoring: "الاحتساب".localized
        case .general: "عام".localized
        }
    }

    var iconName: String {
        switch self {
        case .bidding: "hand.raised.fill"
        case .multiplier: "multiply.circle.fill"
        case .project: "rectangle.stack.badge.plus"
        case .scoring: "number"
        case .general: "book.fill"
        }
    }
}

/// مصطلح واحد في موسوعة البلوت، مع تعريفه ومثال عملي عند الحاجة.
struct BalootGlossaryTerm: Identifiable, Equatable {
    let id: String
    let category: BalootGlossaryCategory
    let term: String
    let definition: String
    let example: String?
}

/// موسوعة مصطلحات البلوت: مرجع للقراءة فقط، محتواه أصلي وثابت داخل التطبيق
/// (لا يعتمد على مصدر خارجي)، ومبني على نفس المفاهيم المطبَّقة في BalootEngine.
enum BalootEncyclopedia {
    static let terms: [BalootGlossaryTerm] = [
        BalootGlossaryTerm(
            id: "sun",
            category: .bidding,
            term: "صن",
            definition: "نمط لعب بلا ورقة حكم؛ يفوز في كل أكلة أعلى ورقة من نوع الشكل المطلوب، والأورطة (الحاكم) لا قيمة خاصة له.",
            example: "لو اشترى لاعب صن، أعلى ورقة من نوع أول ورقة تُلعب في الأكلة تأخذها، ولا يوجد شكل يعلو الأشكال الأخرى."
        ),
        BalootGlossaryTerm(
            id: "hokum",
            category: .bidding,
            term: "حكم",
            definition: "نمط لعب فيه شكل واحد (الحاكم) أوراقه تعلو كل الأشكال الأخرى، وترتيب قوته يختلف عن باقي الأشكال (العقد أقوى ورقة).",
            example: "لو اشترى لاعب حكم سباتي، فأي ورقة سباتي تأخذ الأكلة من أي شكل آخر، حتى لو كان أضعف سباتي."
        ),
        BalootGlossaryTerm(
            id: "up-card",
            category: .bidding,
            term: "الورقة المكشوفة",
            definition: "أول ورقة تُكشف بعد التوزيع الأول في نمط المزايدة الكاملة؛ تحدد الجولة الأولى أي شكل يمكن الشراء فيه حكمًا.",
            example: "لو كانت الورقة المكشوفة دينار، فلا يجوز شراء حكم دينار في الجولة الأولى فقط لغير نفس الشكل."
        ),
        BalootGlossaryTerm(
            id: "ashkal-round",
            category: .bidding,
            term: "جولة الأشكال",
            definition: "الجولة الثانية من المزايدة إذا مرّ اللاعبون الأربعة في الجولة الأولى؛ يجوز فيها شراء حكم بأي شكل عدا شكل الورقة المكشوفة.",
            example: "لو مرّ الجميع على الورقة المكشوفة (دينار)، يفتح المجال في جولة الأشكال لشراء حكم سباتي أو بستوني أو كبة."
        ),
        BalootGlossaryTerm(
            id: "sun-over-hokum",
            category: .bidding,
            term: "الصن فوق الحكم",
            definition: "قاعدة أولوية داخل نفس دورة المزايدة: أي إعلان صن يعلو أي إعلان حكم سابق ويُغلق الشراء فورًا، ولا شيء يعلو الصن.",
            example: "لو أعلن لاعب حكم ثم أعلن التالي صن، يأخذ الصن الشراء مباشرة ولا تُستكمل المزايدة."
        ),
        BalootGlossaryTerm(
            id: "void-round",
            category: .bidding,
            term: "الدورة الميتة",
            definition: "إذا مرّ اللاعبون الأربعة في الجولتين الأولى والثانية بلا شراء، تُلغى الجولة بالكامل: لا نقاط لأي فريق، ويدور دور الموزّع للاعب التالي.",
            example: "أربعة تمريرات في الجولة الأولى ثم أربعة أخرى في جولة الأشكال تعني عدم لعب هذه الصكة إطلاقًا."
        ),
        BalootGlossaryTerm(
            id: "double",
            category: .multiplier,
            term: "دبل",
            definition: "أول تصعيد لمضاعف نتيجة الجولة، يطلبه فريق الخصم بعد استقرار الشراء، ويُضاعف نقاط الجولة النهائية بمعامل القواعد المختارة.",
            example: "لو ضاعف خصوم المشتري بـ«دبل» وخسر المشتري الجولة، تُضرب نقاط الخصوم بمعامل الدبل المحدد في قواعد المجلس."
        ),
        BalootGlossaryTerm(
            id: "triple",
            category: .multiplier,
            term: "ثري",
            definition: "التصعيد الثاني بعد الدبل، يعود حق طلبه لفريق المشتري بعد أن يدبل الخصم.",
            example: "بعد دبل الخصوم، يمكن لفريق المشتري الرد بـ«ثري» بدل قبول الدبل أو تمريره."
        ),
        BalootGlossaryTerm(
            id: "quadruple",
            category: .multiplier,
            term: "فور",
            definition: "التصعيد الثالث بعد الثري، ويستمر التبادل بين الفريقين طالما بقي التصعيد بدرجة واحدة تحديدًا في كل مرة.",
            example: "لا يجوز القفز من دبل إلى فور مباشرة؛ لازم يمر التصعيد بالثري أولًا."
        ),
        BalootGlossaryTerm(
            id: "gahwa",
            category: .multiplier,
            term: "قهوة",
            definition: "أعلى تصعيد متعارف عليه قبل القفل، يضاعف نتيجة الجولة بأكبر معامل بين درجات المضاعفة.",
            example: "الوصول إلى قهوة يعني أن الجولة أصبحت عالية المخاطرة لكلا الفريقين."
        ),
        BalootGlossaryTerm(
            id: "lock",
            category: .multiplier,
            term: "قفل",
            definition: "إنهاء التصعيد نهائيًا عند درجة معينة؛ لا يجوز لصاحب الحق الحالي إلا صاحب المضاعفة الأخيرة استخدامه لإغلاق الباب أمام أي رد.",
            example: "بعد أن يضاعف فريق بـ«دبل»، يمكنه أن يقفل مباشرة بدل انتظار رد الفريق الآخر."
        ),
        BalootGlossaryTerm(
            id: "kaboot",
            category: .scoring,
            term: "الكبوت",
            definition: "أن يأخذ فريق واحد الأكلات الثماني كلها في الجولة، فيحصل على مكافأة كبوت إضافية فوق نقاط الأوراق العادية.",
            example: "لو فاز فريق بكل الأكلات الثماني دون أن يأخذ الخصم أي أكلة، يُسجَّل كبوت لصالحه."
        ),
        BalootGlossaryTerm(
            id: "tayyah",
            category: .scoring,
            term: "طيّاح المشتري",
            definition: "قاعدة اختيارية تلزم فريق المشتري بتحقيق أغلبية النقاط في الجولة، وإلا تنتقل كل نقاط الجولة (والمشاريع) إلى الخصم.",
            example: "لو اشترى فريق حكمًا لكنه لم يحقق أغلبية النقاط، تذهب كل نقاط الجولة للخصم رغم أنه لم يشترِ."
        ),
        BalootGlossaryTerm(
            id: "sira",
            category: .project,
            term: "سرا",
            definition: "مشروع من ثلاث أوراق متتالية من نفس الشكل، أضعف مشاريع التتابع من حيث الأولوية عند المفاضلة.",
            example: "8-9-10 من نفس الشكل في يد لاعب واحد يُشكّل سرا."
        ),
        BalootGlossaryTerm(
            id: "fifty",
            category: .project,
            term: "خمسين",
            definition: "مشروع من أربع أوراق متتالية من نفس الشكل، وقيمته أعلى من السرا عند المفاضلة بين الفريقين.",
            example: "7-8-9-10 من نفس الشكل مشروع خمسين."
        ),
        BalootGlossaryTerm(
            id: "meya",
            category: .project,
            term: "مية",
            definition: "مشروع من خمس أوراق متتالية فأكثر من نفس الشكل، أو أربع أوراق من نفس القيمة (شايب أو بنت أو ولد أو عشرة).",
            example: "أربعة ولدان (جاكات) في يد واحد يُحتسبان مية بنفس قيمة الخمس المتتالية."
        ),
        BalootGlossaryTerm(
            id: "four-hundred",
            category: .project,
            term: "أربعمية",
            definition: "مشروع أربعة آسات في يد واحدة، أعلى المشاريع قيمة، ويُلغى في بعض قواعد المجالس (مثل النمط التنافسي).",
            example: "امتلاك آس الأشكال الأربعة كلها في نفس اليد يُحتسب أربعمية."
        ),
        BalootGlossaryTerm(
            id: "balot-project",
            category: .project,
            term: "البلوت (المشروع)",
            definition: "امتلاك شايب وبنت شكل الحكم معًا في نفس اليد، ولا يدخل في المفاضلة مع مشاريع الخصم؛ يُحتسب دائمًا لصاحبه.",
            example: "حتى لو كان مشروع الخصم أقوى، يبقى صاحب شايب وبنت الحكم آخذًا لنقاط البلوت."
        ),
        BalootGlossaryTerm(
            id: "project-clash",
            category: .project,
            term: "تعارض المشاريع",
            definition: "عندما يُعلن الفريقان مشاريع في نفس الجولة، يقارَن أقوى مشروع من كل فريق فقط، ويأخذ الفريق الأقوى كل مشاريعه (عدا البلوت)، بينما يخسر الفريق الآخر مشاريعه كاملة.",
            example: "لو أعلن فريق سرا وأعلن الخصم خمسين، يأخذ صاحب الخمسين نقاط مشروعه، ويخسر صاحب السرا مشروعه بالكامل."
        ),
        BalootGlossaryTerm(
            id: "trump",
            category: .general,
            term: "الحاكم",
            definition: "شكل الحكم المختار عند الشراء؛ أوراقه تعلو كل الأشكال الأخرى بغض النظر عن ترتيبها الطبيعي.",
            example: "في حكم كبة، أضعف ورقة كبة (السبعة) تأخذ أي ورقة من شكل آخر."
        )
    ]

    static func terms(in category: BalootGlossaryCategory) -> [BalootGlossaryTerm] {
        terms.filter { $0.category == category }
    }

    static func search(_ query: String) -> [BalootGlossaryTerm] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return terms }
        return terms.filter {
            $0.term.localizedCaseInsensitiveContains(trimmed) || $0.definition.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
