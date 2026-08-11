import Foundation

enum AcademyLevel: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "مبتدئ".localized
        case .intermediate: "متوسط".localized
        case .advanced: "متقدم".localized
        }
    }

    var iconName: String {
        switch self {
        case .beginner: "1.circle.fill"
        case .intermediate: "2.circle.fill"
        case .advanced: "3.circle.fill"
        }
    }
}

struct AcademyOption: Identifiable, Equatable {
    let id: String
    let title: String
    let rationale: String
    let expectedImpact: String
}

struct AcademyLesson: Identifiable, Equatable {
    let id: String
    let level: AcademyLevel
    let title: String
    let explanation: String
    let example: String
    let prompt: String
    let options: [AcademyOption]
    let correctOptionID: String
    let successResult: String
    let failureResult: String

    var correctOption: AcademyOption? {
        options.first { $0.id == correctOptionID }
    }
}

enum BalootAcademyCatalog {
    static let lessons: [AcademyLesson] = [
        beginner(
            id: "beginner-cards",
            title: "التعرف على أوراق البلوت",
            explanation: "البلوت يستخدم 32 ورقة: 7، 8، 9، 10، ولد، بنت، شايب، إكة من كل لون.",
            example: "في الحكم تتغير قوة الأوراق داخل لون الحكم، وفي الصن يبقى الترتيب الطبيعي مختلفًا.",
            prompt: "أمامك ورقة ولد حكم وورقة إكة من لون عادي. أيهما أقوى في أكلة الحكم؟",
            correct: ("trump-jack", "ولد الحكم"),
            wrong: ("plain-ace", "إكة اللون العادي"),
            rationale: "ولد الحكم هو أقوى ورقة في لون الحكم، ويتقدم على الإكة خارج الحكم.",
            impact: "معرفة قوة الحكم تمنع خسارة أكلة حاسمة بورقة ضعيفة."
        ),
        beginner(
            id: "beginner-deal",
            title: "توزيع الأوراق",
            explanation: "كل لاعب ينتهي بثمان أوراق، ويبدأ اللعب بعد اكتمال الشراء وتحديد النمط.",
            example: "إذا لم يشتر أحد تنتهي محاولة الجولة وتُعاد التهيئة حسب قواعد المجلس.",
            prompt: "انتهت المزايدة بدون شراء من أي لاعب. ما التصرف الصحيح؟",
            correct: ("redeal", "إعادة الجولة أو التوزيع حسب القاعدة"),
            wrong: ("force-sun", "إجبار آخر لاعب على صن"),
            rationale: "انتهاء المزايدة بدون شراء لا يخلق مشتريًا افتراضيًا؛ يجب أن تتعامل الحالة مع عدم وجود شراء.",
            impact: "هذا يحافظ على عدالة الجولة ويمنع حالة محرك غير صحيحة."
        ),
        beginner(
            id: "beginner-follow-suit",
            title: "التلزيم",
            explanation: "إذا كان لديك ورقة من اللون المطلوب في بداية الأكلة فيجب لعب نفس اللون.",
            example: "بدأ الخصم بسباتي وأنت تملك سباتي؛ لا تختار ديناري فقط لأنه أعلى نقاطًا.",
            prompt: "بدأت الأكلة بسباتي ولديك سباتي وديناري. ماذا تفعل؟",
            correct: ("follow", "ألعب سباتي"),
            wrong: ("discard", "ألعب ديناري"),
            rationale: "التلزيم واجب عند امتلاك اللون المطلوب.",
            impact: "الالتزام يمنع الحركة غير القانونية ويجعل قرارك قابلًا للتحليل بدقة."
        ),
        beginner(
            id: "beginner-scoring",
            title: "احتساب النقاط",
            explanation: "تجمع نقاط الأوراق التي كسبها الفريق ثم تضيف المشاريع وتطبق المضاعف عند وجوده.",
            example: "100 نقطة أوراق + 20 مشروع = 120، ومع دبل تصبح 240.",
            prompt: "فريقك جمع 80 نقطة أوراق و50 مشروعًا مع دبل. كم النتيجة؟",
            correct: ("260", "260"),
            wrong: ("210", "210"),
            rationale: "المجموع قبل الدبل 130، ثم يضرب كامل المجموع في 2.",
            impact: "الحساب الصحيح يمنع خسارة نقاط بسبب تطبيق المضاعف على جزء من النتيجة فقط."
        ),
        intermediate(
            id: "intermediate-cutting",
            title: "اختيار وقت القطع",
            explanation: "القطع بالحكم قرار تكتيكي؛ ليس كل انقطاع لون يعني أن القطع هو الأفضل.",
            example: "إذا كان شريكك غالبًا كاسب الأكلة، فقد يكون التخلص من ورقة خاسرة أفضل من قطع أكلة له.",
            prompt: "شريكك لعب ورقة عالية والخصم لم يقطع. أنت لا تملك اللون ومعك حكم صغير. ماذا ترجح؟",
            correct: ("protect-partner", "أحافظ على حكمتي وأرمي ورقة خاسرة"),
            wrong: ("cut-small", "أقطع بحكم صغير"),
            rationale: "قطع أكلة شريكك يهدر الحكم وقد ينقل المبادرة للخصم لاحقًا.",
            impact: "حماية الشريك ترفع قيمة الحكم في الأكلات التي تحتاجه فعلًا."
        ),
        intermediate(
            id: "intermediate-memory",
            title: "معرفة الأوراق الخارجة",
            explanation: "ذاكرة الأوراق تساعدك على تقدير هل ورقتك ستفوز أو ستُؤكل.",
            example: "إذا خرجت الإكة والعشرة من لون ما، يصبح الشايب أو البنت أكثر أمانًا حسب الترتيب.",
            prompt: "خرجت أعلى ورقتين من لون غير حكم وبقي لديك ورقة متوسطة من نفس اللون. ما القراءة الأقرب؟",
            correct: ("safer-lead", "قد تصبح بداية آمنة نسبيًا"),
            wrong: ("always-losing", "ستكون خاسرة دائمًا"),
            rationale: "قيمة الورقة تتغير بعد خروج الأوراق الأعلى منها.",
            impact: "العد البسيط يقلل الرمي العشوائي ويزيد فرص كسب أكلات صغيرة."
        ),
        intermediate(
            id: "intermediate-partner",
            title: "حماية الشريك",
            explanation: "قرارك لا يقيم يدك وحدها؛ يجب أن تقرأ إشارة الشريك وقوة أكله.",
            example: "إذا سحب الشريك الحكم مبكرًا فقد يحاول تنظيف الحكم للسيطرة آخر الجولة.",
            prompt: "شريكك بدأ بسحب الحكم وفاز بأول أكلة. ما أفضل دعم غالبًا؟",
            correct: ("continue-trump", "أساعده إذا كان لدي حكم مناسب"),
            wrong: ("break-plan", "أغيّر اللون فورًا بلا سبب"),
            rationale: "استمرار خطة الشريك عندما تظهر قوتها يحافظ على السيطرة.",
            impact: "التنسيق مع الشريك يقلل تضارب القرارات بين الفريق الواحد."
        ),
        advanced(
            id: "advanced-bidding-read",
            title: "قراءة المزايدة",
            explanation: "المزايدة تكشف معلومات عن قوة الألوان وتفضيلات اللاعبين حتى قبل لعب أول ورقة.",
            example: "لاعب اشترى حكم بعد تمرير طويل غالبًا يملك قوة مركزة في لون الحكم لا يدًا متوازنة.",
            prompt: "خصمك اشترى حكم بسرعة في قلوب. ما أول فرضية تكتيكية؟",
            correct: ("heart-strength", "لديه قوة واضحة في القلوب"),
            wrong: ("random-buy", "قراره لا يعطي أي معلومة"),
            rationale: "الشراء المبكر إشارة، ليست يقينًا، لكنها تدخل في قراءة اليد.",
            impact: "استخدام معلومات المزايدة يحسن اختيار البداية والقطع."
        ),
        advanced(
            id: "advanced-sacrifice",
            title: "اختيار التضحية المناسبة",
            explanation: "أحيانًا تخسر أكلة صغيرة عمدًا لتمنع خسارة أكبر أو لتحافظ على ورقة سيطرة.",
            example: "الاحتفاظ بحكم قوي قد يكون أفضل من إنقاذ أكلة قليلة النقاط.",
            prompt: "الأكلة الحالية قليلة النقاط، ومعك حكم قوي قد يحسم أكلة لاحقة. ماذا تفعل غالبًا؟",
            correct: ("save-control", "أحافظ على ورقة السيطرة"),
            wrong: ("win-cheap", "أصرف الحكم القوي الآن"),
            rationale: "قيمة ورقة السيطرة تظهر في توقيت استخدامها، لا في قوتها وحدها.",
            impact: "التضحية المحسوبة ترفع النقاط المتوقعة في نهاية الجولة."
        ),
        advanced(
            id: "advanced-pressure",
            title: "الضغط على الخصم",
            explanation: "الضغط يعني إجبار الخصم على كشف أو صرف أوراق مهمة بتسلسل لعب محسوب.",
            example: "فتح لون تعرف أن الخصم منقطع منه قد يجبره على قطع مبكر أو التخلص من ورقة مهمة.",
            prompt: "تعرف من اللعب أن الخصم غالبًا منقطع من لون معين. ما الاستخدام الأفضل للمعلومة؟",
            correct: ("force-response", "أفتح ذلك اللون عندما يخدم خطة الفريق"),
            wrong: ("ignore-read", "أتجاهل المعلومة وألعب أعلى ورقة فقط"),
            rationale: "المعلومات الناتجة من الأكلات السابقة يجب أن تغير القرار التالي.",
            impact: "الضغط الجيد يحول ذاكرة الأوراق إلى نقاط فعلية."
        )
    ]

    static func lessons(for level: AcademyLevel) -> [AcademyLesson] {
        lessons.filter { $0.level == level }
    }

    private static func beginner(
        id: String,
        title: String,
        explanation: String,
        example: String,
        prompt: String,
        correct: (String, String),
        wrong: (String, String),
        rationale: String,
        impact: String
    ) -> AcademyLesson {
        makeLesson(
            id: id,
            level: .beginner,
            title: title,
            explanation: explanation,
            example: example,
            prompt: prompt,
            correct: correct,
            wrong: wrong,
            rationale: rationale,
            impact: impact
        )
    }

    private static func intermediate(
        id: String,
        title: String,
        explanation: String,
        example: String,
        prompt: String,
        correct: (String, String),
        wrong: (String, String),
        rationale: String,
        impact: String
    ) -> AcademyLesson {
        makeLesson(
            id: id,
            level: .intermediate,
            title: title,
            explanation: explanation,
            example: example,
            prompt: prompt,
            correct: correct,
            wrong: wrong,
            rationale: rationale,
            impact: impact
        )
    }

    private static func advanced(
        id: String,
        title: String,
        explanation: String,
        example: String,
        prompt: String,
        correct: (String, String),
        wrong: (String, String),
        rationale: String,
        impact: String
    ) -> AcademyLesson {
        makeLesson(
            id: id,
            level: .advanced,
            title: title,
            explanation: explanation,
            example: example,
            prompt: prompt,
            correct: correct,
            wrong: wrong,
            rationale: rationale,
            impact: impact
        )
    }

    private static func makeLesson(
        id: String,
        level: AcademyLevel,
        title: String,
        explanation: String,
        example: String,
        prompt: String,
        correct: (String, String),
        wrong: (String, String),
        rationale: String,
        impact: String
    ) -> AcademyLesson {
        AcademyLesson(
            id: id,
            level: level,
            title: title,
            explanation: explanation,
            example: example,
            prompt: prompt,
            options: [
                AcademyOption(id: correct.0, title: correct.1, rationale: rationale, expectedImpact: impact),
                AcademyOption(id: wrong.0, title: wrong.1, rationale: "هذا القرار يترك قاعدة أو قراءة مهمة بلا استخدام.".localized, expectedImpact: "يزيد احتمال خسارة الأكلة أو ضياع نقاط سهلة.".localized)
            ],
            correctOptionID: correct.0,
            successResult: "قرار صحيح. انتقل للدرس التالي بعد قراءة السبب.".localized,
            failureResult: "راجع المثال ثم جرّب قراءة الموقف مرة أخرى.".localized
        )
    }
}
