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

struct AcademyProgressSummary: Equatable {
    let completedLessonIDs: Set<String>
    let completedCount: Int
    let totalLessons: Int
    let completionPercent: Int

    var isComplete: Bool {
        completedCount >= totalLessons && totalLessons > 0
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
            id: "beginner-ordering",
            title: "ترتيب الأوراق",
            explanation: "ترتيب يدك حسب اللون والقوة يساعدك على رؤية الحكم، المشاريع، والأوراق الخاسرة بسرعة.",
            example: "ضع أوراق كل لون معًا، ثم لاحظ إن كان عندك تسلسل أو أوراق حكم عالية قبل اتخاذ قرار الشراء.",
            prompt: "يدك مبعثرة وفيها ثلاث أوراق متتالية من نفس اللون. ما أول خطوة صحيحة؟",
            correct: ("sort-by-suit", "أرتب اليد حسب الألوان والقوة"),
            wrong: ("play-memory", "أحفظها كما جاءت من التوزيع"),
            rationale: "الترتيب يكشف المشاريع وقوة الألوان ويقلل نسيان ورقة مهمة.",
            impact: "رؤية اليد بوضوح ترفع جودة المزايدة وتقلل أخطاء أول أكلة."
        ),
        beginner(
            id: "beginner-sun-hokum",
            title: "الصن والحكم",
            explanation: "الصن يعتمد قوة الأوراق العالية دون لون حكم، أما الحكم فيجعل لونًا واحدًا أقوى من بقية الألوان.",
            example: "ولد الحكم أقوى من إكة الحكم، لكن في الصن تكون الإكة أعلى من الولد حسب ترتيب الصن.",
            prompt: "يدك فيها حكم قوي بلون واحد وأوراق عادية في باقي الألوان. أي نمط ترجح؟",
            correct: ("choose-hokum", "أفكر في شراء حكم"),
            wrong: ("force-sun", "أشتري صن دائمًا"),
            rationale: "قوة لون واحد مركزة غالبًا تناسب الحكم أكثر من الصن.",
            impact: "اختيار النمط المناسب يحول قوة اليد إلى أكلات فعلية بدل إهدارها."
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
            id: "beginner-cutting",
            title: "القطع",
            explanation: "إذا لم تملك اللون المطلوب، قد تلزمك قاعدة المجلس بالقطع بالحكم عندما يكون ذلك متاحًا.",
            example: "بدأت الأكلة بديناري، ولا تملك ديناري، ومعك حكم؛ في قواعد كثيرة يجب أن تقطع بدل رمي لون عادي.",
            prompt: "لا تملك اللون المطلوب ومعك حكم صغير. ما القرار القانوني غالبًا؟",
            correct: ("cut-with-trump", "أقطع بالحكم"),
            wrong: ("discard-any", "أرمي أي لون بلا اعتبار"),
            rationale: "القطع ليس اختيارًا جماليًا؛ في قواعد الحكم قد يكون واجبًا عند انقطاع اللون.",
            impact: "فهم القطع يمنع الحركة غير القانونية ويشرح لماذا تُمنع بعض الأوراق."
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
            id: "intermediate-read-play",
            title: "قراءة اللعب",
            explanation: "كل ورقة تُلعب تعطي معلومة: هل اللاعب مجبر، هل يملك اللون، وهل يحاول حماية شريكه.",
            example: "خصمك رمى ورقة صغيرة من لون مطلوب رغم وجود نقاط على الطاولة؛ غالبًا لا يريد دفع ورقة أعلى.",
            prompt: "لاعب تبع اللون بورقة صغيرة جدًا في أكلة عليها نقاط. ما القراءة الأقرب؟",
            correct: ("limited-strength", "غالبًا لا يملك قوة مناسبة في ذلك اللون"),
            wrong: ("no-information", "لا توجد أي معلومة"),
            rationale: "طريقة التلزيم وحجم الورقة يكشفان جزءًا من توزيع القوة.",
            impact: "قراءة اللعب تساعدك على اختيار اللون التالي بدل اللعب بشكل معزول."
        ),
        intermediate(
            id: "intermediate-pull-trump",
            title: "سحب الحكم",
            explanation: "سحب الحكم يعني لعب الحكم لإجبار الخصوم على صرف حكمهم وتقليل خطر القطع لاحقًا.",
            example: "إذا كنت المشتري ومعك حكم قوي متتابع، فقد تبدأ بسحب الحكم لتأمين ألوانك الجانبية.",
            prompt: "أنت المشتري ومعك ولد وتسعة حكم وأوراق جانبية قوية. ما الخطة الأقرب؟",
            correct: ("pull-trump", "أسحب الحكم مبكرًا"),
            wrong: ("ignore-trump", "أترك الحكم تمامًا وأبدأ بلون ضعيف"),
            rationale: "تنظيف الحكم يقلل قدرة الخصوم على قطع أكلاتك المهمة.",
            impact: "السحب الصحيح يحول الحكم القوي إلى سيطرة لا إلى أكلة واحدة فقط."
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
        intermediate(
            id: "intermediate-opening-lead",
            title: "اختيار بداية الأكلة",
            explanation: "بداية الأكلة تحدد شكل ردود اللاعبين، لذلك لا تبدأ بأعلى ورقة دائمًا دون هدف.",
            example: "افتتاح لون طويل لديك قد يكشف الانقطاعات ويجهز أكلة لاحقة، بينما افتتاح ورقة نقاط بلا حماية قد يطعم الخصم.",
            prompt: "لديك لون طويل بلا نقاط كثيرة ولون قصير فيه عشرة. أي افتتاح أكثر أمانًا غالبًا؟",
            correct: ("lead-long-safe", "أبدأ باللون الطويل الآمن"),
            wrong: ("lead-exposed-ten", "أبدأ بالعشرة المكشوفة"),
            rationale: "الافتتاح الآمن يجمع معلومات دون رمي نقاط سهلة.",
            impact: "اختيار البداية الصحيح يحمي النقاط ويكشف توزيع الخصوم."
        ),
        intermediate(
            id: "intermediate-opponent-read",
            title: "قراءة تصرفات الخصم",
            explanation: "تكرار تمرير لون أو قطع مبكر يكشف أين يضع الخصم قوته أو ضعفه.",
            example: "خصم يقطع أول فرصة غالبًا يريد نقل الدور أو يخاف من استمرار ذلك اللون.",
            prompt: "خصمك قطع مبكرًا بلون الحكم بدل التخلص من ورقة عادية. ماذا تستنتج؟",
            correct: ("trump-pressure", "يمكن الضغط عليه بإدارة الحكم واللون المقطوع"),
            wrong: ("ignore-cut", "لا أغير خطتي أبدًا"),
            rationale: "القطع المبكر إشارة لتوزيع اليد وقلق الخصم من لون معين.",
            impact: "تحويل تصرفات الخصم إلى خطة يزيد فرص تعطيل شراءه."
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
            id: "advanced-card-counting",
            title: "عد الأوراق",
            explanation: "عد الأوراق يعني متابعة ما خرج من كل لون وما بقي من الأوراق العالية والحكم.",
            example: "إذا خرجت أغلب أوراق الحكم وبقي لديك حكم متوسط، فقد يصبح ورقة سيطرة في نهاية الجولة.",
            prompt: "خرج ولد وتسعة وإكة الحكم، وبقي معك حكم متوسط. ما القراءة؟",
            correct: ("late-control", "قد يصبح مهمًا آخر الجولة"),
            wrong: ("always-useless", "لم يعد له أي قيمة"),
            rationale: "قيمة الورقة تتغير بعد معرفة ما خرج وما بقي.",
            impact: "عد الأوراق يحسن قرارات التضحية والسيطرة في آخر الأكلات."
        ),
        advanced(
            id: "advanced-deduction",
            title: "الاستنتاج من الأوراق الملعوبة",
            explanation: "الاستنتاج يربط الورقة التي لعبها الخصم بما كان يستطيع لعبه قانونيًا.",
            example: "إذا لم يتبع اللون مع أن التلزيم واجب، فأنت تعرف أنه منقطع من ذلك اللون.",
            prompt: "بدأت بسباتي والخصم رمى حكمًا. ما الاستنتاج القانوني الأقوى؟",
            correct: ("void-suit", "غالبًا لا يملك سباتي"),
            wrong: ("has-many-spades", "غالبًا يملك سباتي كثيرًا"),
            rationale: "عدم اتباع اللون تحت قاعدة التلزيم دليل قوي على الانقطاع.",
            impact: "الاستنتاج الصحيح يحدد متى تعيد فتح اللون أو تتجنبه."
        ),
        advanced(
            id: "advanced-probability",
            title: "حساب الاحتمالات",
            explanation: "لا تعرف كل الأوراق، لكن يمكنك تقدير الاحتمال من عدد الأوراق المجهولة وما ظهر على الطاولة.",
            example: "إذا لم يخرج من لونك إلا ورقتان وبقيت أوراق كثيرة مجهولة، فاحتمال القطع أو الأكل أعلى.",
            prompt: "تريد لعب عشرة من لون لم يخرج منه إلا قليل. ماذا تفعل قبل اللعب؟",
            correct: ("estimate-risk", "أقدر خطر الأكل أو القطع"),
            wrong: ("assume-safe", "أفترض أنها آمنة دائمًا"),
            rationale: "الاحتمال يساعدك على التفريق بين مخاطرة مقبولة ومخاطرة مجانية.",
            impact: "التقدير الاحتمالي يقلل خسارة النقاط العالية في أكلات غير محمية."
        ),
        advanced(
            id: "advanced-hand-management",
            title: "إدارة اليد",
            explanation: "إدارة اليد تعني ترتيب استخدام القوة والضعف عبر الجولة، لا صرف أقوى الأوراق فورًا.",
            example: "قد تؤخر ورقة سيطرة حتى تسحب أوراق الخصوم التي تهددها.",
            prompt: "معك ورقة سيطرة وحيدة وأوراق خاسرة. ما الخطة الأفضل غالبًا؟",
            correct: ("time-control", "أختار توقيت ورقة السيطرة بعناية"),
            wrong: ("spend-now", "أصرفها فورًا بلا هدف"),
            rationale: "القوة في البلوت مرتبطة بالتوقيت ومعلومة الأوراق الخارجة.",
            impact: "إدارة اليد الجيدة تجعل الورقة القوية تكسب أكثر من أكلة أو تحمي نقاطًا."
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
        ),
        advanced(
            id: "advanced-mode-strategy",
            title: "استراتيجيات الصن والحكم",
            explanation: "استراتيجية الصن تركز على الأوراق العالية وتجنب إطعام الخصم، أما الحكم فيضيف سحب الحكم والقطع والسيطرة باللون.",
            example: "في الصن قد تحفظ الإكة والعشرة، وفي الحكم قد تبدأ بسحب الحكم إذا كانت يدك قادرة على السيطرة.",
            prompt: "اشتريت حكمًا ومعك حكم قوي وألوان جانبية جيدة. ما الفارق الاستراتيجي عن الصن؟",
            correct: ("control-trump", "أستخدم الحكم للسيطرة وفتح الألوان الجانبية"),
            wrong: ("play-like-sun", "ألعب كأن الحكم غير موجود"),
            rationale: "الحكم يغير قيمة كل ورقة داخل اللون المختار وخطة الأكلات التالية.",
            impact: "تمييز خطة الصن عن الحكم يمنع استخدام نمط قوي بطريقة خاطئة."
        )
    ]

    static func lessons(for level: AcademyLevel) -> [AcademyLesson] {
        lessons.filter { $0.level == level }
    }

    static func lesson(id: String) -> AcademyLesson? {
        lessons.first { $0.id == id }
    }

    static func progressSummary(
        progress: [AcademyLessonProgress],
        legacyCompletedLessonIDs: Set<String> = []
    ) -> AcademyProgressSummary {
        let validLessonIDs = Set(lessons.map(\.id))
        let completed = Set(progress.map(\.lessonID))
            .union(legacyCompletedLessonIDs)
            .intersection(validLessonIDs)
        let total = lessons.count
        let percent = total == 0
            ? 0
            : Int((Double(completed.count) / Double(total) * 100).rounded())

        return AcademyProgressSummary(
            completedLessonIDs: completed,
            completedCount: completed.count,
            totalLessons: total,
            completionPercent: percent
        )
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
