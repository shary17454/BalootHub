import Foundation
import SwiftData

/// يزرع كتالوج الألعاب والأنماط في قاعدة البيانات المحلية عند أول تشغيل فقط.
/// كل المحتوى هنا أصلي، وليس منسوخًا من أي تطبيق أو مصدر آخر.
enum CatalogSeeder {
    static func seedIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<GameCatalogItem>()
        let existingItems = (try? context.fetch(descriptor)) ?? []
        var existingBySlug: [String: GameCatalogItem] = [:]
        for item in existingItems {
            existingBySlug[item.slug] = item
        }
        var didChange = false

        for definition in Self.allDefinitions {
            if let existing = existingBySlug[definition.slug] {
                definition.apply(to: existing)
                didChange = true
            } else {
                let item = definition.makeItem()
                context.insert(item)
                didChange = true
            }
        }

        if didChange {
            try? context.save()
        }
    }

    /// يبني بيانات معاينة داخل الذاكرة (تُستخدم في SwiftUI Previews فقط، منفصلة عن بيانات الإنتاج).
    static func previewItems() -> [GameCatalogItem] {
        allDefinitions.map { $0.makeItem() }
    }
}

/// وصف بيانات لعبة واحدة قبل تحويلها إلى نموذج SwiftData.
private struct GameDefinition {
    let slug: String
    let arabicTitle: String
    let englishTitle: String?
    let shortDescription: String
    let category: GameCategory
    let playerCountText: String
    let difficulty: Difficulty
    let estimatedDuration: String
    let iconName: String
    let accentToken: String
    let isPlayable: Bool
    let sortOrder: Int
    let sections: [StandardRuleSectionKind: String]

    func makeItem() -> GameCatalogItem {
        let item = GameCatalogItem(
            slug: slug,
            arabicTitle: arabicTitle,
            englishTitle: englishTitle,
            shortDescription: shortDescription,
            category: category,
            playerCountText: playerCountText,
            difficulty: difficulty,
            estimatedDuration: estimatedDuration,
            iconName: iconName,
            accentToken: accentToken,
            isPlayable: isPlayable,
            sortOrder: sortOrder
        )
        apply(to: item)
        return item
    }

    /// يحدّث العناصر المزروعة سابقًا بدون المساس بالمفضلة أو تاريخ الإنشاء.
    ///
    /// مهم تحديدًا لأن صن وحكم كانا يظهران في نسخ قديمة كمدخلين مستقلين، بينما
    /// الواقع أن اللعب يدخل من بلوت واحد وتحدد المزايدة هل الجولة صن أو حكم.
    func apply(to item: GameCatalogItem) {
        item.arabicTitle = arabicTitle
        item.englishTitle = englishTitle
        item.shortDescription = shortDescription
        item.category = category
        item.playerCountText = playerCountText
        item.difficulty = difficulty
        item.estimatedDuration = estimatedDuration
        item.iconName = iconName
        item.accentToken = accentToken
        item.isPlayable = isPlayable
        item.sortOrder = sortOrder

        for kind in StandardRuleSectionKind.allCases {
            let body = sections[kind] ?? "سيُضاف هذا القسم قريبًا."
            if let section = item.ruleSection(kind) {
                section.title = kind.title
                section.body = body
                section.order = kind.order
                section.iconName = kind.iconName
            } else {
                let section = GameRuleSection(title: kind.title, body: body, order: kind.order, iconName: kind.iconName)
                section.game = item
                item.rules.append(section)
            }
        }
    }
}

/// تعريف مختصر للعبة ورق مرجعية. يحافظ على اكتمال أقسام القواعد العشرة بدون
/// تكرار طويل لكل لعبة، ويمنع أن يظهر للمستخدم عنصر باسم فقط أو وصف ناقص.
private struct CardGameReferenceDefinition {
    let slug: String
    let arabicTitle: String
    let englishTitle: String
    let shortDescription: String
    let playerCountText: String
    let difficulty: Difficulty
    let estimatedDuration: String
    let iconName: String
    let sortOrder: Int
    let objective: String
    let setup: String
    let dealing: String
    let cardRanking: String
    let howToPlay: String
    let scoring: String
    let roundEnd: String
    let commonMistakes: String

    var gameDefinition: GameDefinition {
        GameDefinition(
            slug: slug,
            arabicTitle: arabicTitle,
            englishTitle: englishTitle,
            shortDescription: shortDescription,
            category: .otherCardGame,
            playerCountText: playerCountText,
            difficulty: difficulty,
            estimatedDuration: estimatedDuration,
            iconName: iconName,
            accentToken: "otherGames",
            isPlayable: true,
            sortOrder: sortOrder,
            sections: [
                .objective: objective,
                .playerCount: playerCountText,
                .setup: setup,
                .dealing: dealing,
                .cardRanking: cardRanking,
                .howToPlay: howToPlay,
                .scoring: scoring,
                .projects: "لا تستخدم هذه اللعبة مشاريع البلوت. إن وُجدت مكافآت أو مضاعفات محلية في بعض المجالس، فيجب الاتفاق عليها قبل بدء اللعب.",
                .roundEnd: roundEnd,
                .commonMistakes: commonMistakes
            ]
        )
    }
}

private extension CatalogSeeder {
    static let allDefinitions: [GameDefinition] = [
        // MARK: - ألعاب البلوت

        GameDefinition(
            slug: "baloot-classic",
            arabicTitle: "بلوت كلاسيكي",
            englishTitle: "Classic Baloot",
            shortDescription: "اللعبة الأساسية بأنماطها المختلطة: صن وحكم في نفس الجلسة، مع مزايدة حرة بين اللاعبين.",
            category: .balootGame,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .intermediate,
            estimatedDuration: "20–35 دقيقة للجلسة الواحدة",
            iconName: "suit.spade.fill",
            accentToken: "primary",
            isPlayable: true,
            sortOrder: 0,
            sections: [
                .objective: "الوصول بفريقك إلى نقاط الهدف المتفق عليه (152 نقطة افتراضيًا) قبل الفريق الآخر، عبر الفوز بأكبر عدد ممكن من الأكلات في كل جولة.",
                .playerCount: "أربعة لاعبين ثابتون في فريقين من لاعبين، يجلس شريكا كل فريق متقابلين على الطاولة.",
                .setup: "تُستخدم حزمة من 32 ورقة (من 7 حتى الآس). يُحدَّد الموزّع الأول بالاتفاق أو بالقرعة، ثم يدور التوزيع بالتناوب.",
                .dealing: "يوزَّع 8 أوراق لكل لاعب على دفعات (مثل 3-2-3 أو 5-3)، ثم تبدأ مرحلة المزايدة قبل رؤية بقية الأوراق أحيانًا حسب عادة المجلس.",
                .cardRanking: "في صن: الآس أعلى ثم 10 ثم K ثم Q ثم J ثم 9 ثم 8 ثم 7. في حكم: الولد (J) هو الأقوى في نوع الحكم يليه 9 ثم A ثم 10 ثم K ثم Q ثم 8 ثم 7، بينما بقية الأنواع تُرتَّب كما في صن.",
                .howToPlay: "يبدأ اللاعب الذي على يمين الموزّع، ويجب على بقية اللاعبين اتّباع نفس نوع الورقة الأولى إن توفر لديهم. في نمط حكم، من لا يملك النوع المطلوب ويملك حكمًا يجب أن يقطع به. يفوز بالأكلة صاحب أعلى ورقة من النوع المطلوب أو أعلى حكم.",
                .scoring: "تُجمع نقاط الأوراق التي يفوز بها كل فريق عبر الأكلات. في حكم يكون مجموع نقاط الجولة 162 نقطة (152 من الأوراق + 10 لآخر أكلة)، وفي صن 130 نقطة (تُضاعف عادة إلى 260 عند احتسابها ضمن هدف المباراة).",
                .projects: "أبرز مشروع متفق عليه هو \"البلوت\": امتلاك شايب وبنت نوع الحكم معًا، ويُضيف 20 نقطة لصاحبه. مشاريع أخرى مثل السرا والخمسين والمية تحتاج اتفاقًا مسبقًا بين اللاعبين لاعتمادها.",
                .roundEnd: "تنتهي الجولة بعد لعب كل الأوراق الثماني (8 أكلات)، ثم تُحسب النقاط ويبدأ توزيع جديد حتى يبلغ أحد الفريقين الهدف.",
                .commonMistakes: "أشهر الأخطاء: نسيان التلزيم بنفس النوع، القطع بحكم أضعف من اللازم، والإعلان عن مشروع غير مكتمل الشروط."
            ]
        ),
        GameDefinition(
            slug: "baloot-sun",
            arabicTitle: "مرجع الصن",
            englishTitle: "Baloot – Sun",
            shortDescription: "شرح نمط الصن داخل لعبة البلوت الواحدة؛ لا يُفتح كلعبة منفصلة بل يُشترى أثناء المزايدة.",
            category: .balootTool,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .beginner,
            estimatedDuration: "15–20 دقيقة للجولة",
            iconName: "sun.max.fill",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 32,
            sections: [
                .objective: "الفوز بأكبر عدد من نقاط الأوراق خلال الجولة دون وجود نوع حكم يفضَّل على البقية.",
                .playerCount: "أربعة لاعبين في فريقين متقابلين، كما في البلوت الكلاسيكي.",
                .setup: "نفس حزمة الـ32 ورقة، ويُختار نمط \"صن\" في مرحلة المزايدة بدل اختيار نوع حكم.",
                .dealing: "توزيع الأوراق مطابق للبلوت الكلاسيكي: 8 أوراق لكل لاعب.",
                .cardRanking: "كل الأنواع الأربعة تُرتَّب بنفس الترتيب: A أعلى، يليه 10، K، Q، J، 9، 8، 7 (الأضعف).",
                .howToPlay: "يجب اتّباع نفس نوع الورقة الأولى في كل أكلة إن توفر لدى اللاعب؛ لا يوجد إلزام بالقطع لأنه لا يوجد نوع حكم.",
                .scoring: "مجموع نقاط الأوراق في الجولة 120 نقطة، ويُضاف لها 10 نقاط لفريق آخر أكلة فيصبح المجموع 130، وتُضاعف عادة (×2) لتصبح 260 عند احتسابها ضمن هدف المباراة.",
                .projects: "نفس مشاريع البلوت العامة قابلة للاتفاق عليها، باستثناء \"البلوت\" (شايب وبنت الحكم) لأنه لا يوجد نوع حكم في هذا النمط.",
                .roundEnd: "تنتهي الجولة بعد لعب الأكلات الثماني وتُجمع النقاط لكل فريق.",
                .commonMistakes: "الخطأ الأكثر شيوعًا هو التعامل مع صن وكأن فيها نوعًا مفضّلًا، أو نسيان أن الآس هو الأقوى دائمًا هنا."
            ]
        ),
        GameDefinition(
            slug: "baloot-hokum",
            arabicTitle: "مرجع الحكم",
            englishTitle: "Baloot – Hokum",
            shortDescription: "شرح نمط الحكم داخل لعبة البلوت الواحدة؛ يحدده اللاعب المشتري ولونه أثناء دورة المزايدة.",
            category: .balootTool,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .intermediate,
            estimatedDuration: "15–20 دقيقة للجولة",
            iconName: "crown.fill",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 33,
            sections: [
                .objective: "جمع أكبر عدد من نقاط الأوراق باستخدام نوع الحكم المُختار للتفوق حتى عند عدم امتلاك النوع المطلوب.",
                .playerCount: "أربعة لاعبين في فريقين متقابلين.",
                .setup: "يختار اللاعب الفائز بالمزايدة نوعًا واحدًا من الأنواع الأربعة ليكون \"الحكم\" لهذه الجولة.",
                .dealing: "8 أوراق لكل لاعب، مطابق لبقية أنماط البلوت.",
                .cardRanking: "في نوع الحكم فقط: الولد (J) أقوى ورقة، يليه 9، ثم A، 10، K، Q، 8، 7. بقية الأنواع الثلاثة تُرتَّب كما في صن (A الأعلى وحتى 7 الأضعف).",
                .howToPlay: "يجب اتّباع نفس النوع المطلوب إن توفر. من لا يملكه ويملك ورقة حكم يجب أن يقطع بها ليفوز بالأكلة مؤقتًا، وإلا يجوز له التخلص من أي ورقة.",
                .scoring: "مجموع نقاط جولة الحكم 162 نقطة: 152 نقطة أوراق (62 من نوع الحكم و30 من كل نوع آخر) + 10 نقاط لآخر أكلة.",
                .projects: "\"البلوت\" (شايب وبنت نوع الحكم معًا في يد واحدة) يضيف 20 نقطة لصاحبه، وهو المشروع المعتمد افتراضيًا في هذا التطبيق.",
                .roundEnd: "تنتهي الجولة بعد الأكلات الثماني، وتُحتسب نقاط كل فريق وتُضاف إلى إجمالي الجلسة.",
                .commonMistakes: "أشهر الأخطاء: القطع بحكم ضعيف بلا داعٍ، ونسيان أن بعض المجالس تُلزم بالتعلية (القطع بحكم أعلى) — وهو إعداد قابل للتفعيل من إعدادات التسجيل."
            ]
        ),
        GameDefinition(
            slug: "baloot-projects",
            arabicTitle: "بلوت مشاريع",
            englishTitle: "Baloot – Projects",
            shortDescription: "نمط يركّز على إعلان \"المشاريع\" (تتابعات وتكرارات في اليد) كمصدر إضافي للنقاط قبل بدء اللعب.",
            category: .balootTool,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .advanced,
            estimatedDuration: "20–30 دقيقة للجولة",
            iconName: "star.circle.fill",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 34,
            sections: [
                .objective: "تعظيم نقاط الفريق عبر إعلان المشاريع الصحيحة إضافة إلى نقاط الأكلات المعتادة.",
                .playerCount: "أربعة لاعبين في فريقين متقابلين.",
                .setup: "بعد التوزيع، يفحص كل لاعب يده بحثًا عن مشاريع محتملة قبل أن تبدأ الأكلات.",
                .dealing: "8 أوراق لكل لاعب، مطابق لبقية أنماط البلوت.",
                .cardRanking: "يتبع ترتيب صن أو حكم حسب النمط المُختار لهذه الجولة (المشاريع تُضاف فوقه ولا تُغيّره).",
                .howToPlay: "يُعلن اللاعب مشروعه (إن وُجد) في وقت مبكر من الجولة حسب عادة المجلس، ثم يستمر اللعب بشكل طبيعي باتباع النوع المطلوب أو القطع بالحكم.",
                .scoring: "تُضاف نقاط المشاريع المعلَنة والصحيحة إلى نقاط الأكلات المعتادة للجولة.",
                .projects: "أشهر المشاريع: السرا (ثلاث أوراق متتابعة من نفس النوع)، الخمسين (أربع متتابعة)، المية (أربع أوراق من نفس الرتبة)، إضافة إلى البلوت. القيم الدقيقة تختلف بين المجالس، لذا تُترك قابلة للاتفاق قبل اللعب.",
                .roundEnd: "تنتهي الجولة كالمعتاد بعد الأكلات الثماني مع إضافة قيمة المشاريع الصحيحة للنتيجة.",
                .commonMistakes: "إعلان مشروع غير مكتمل الشروط، أو الخلط بين قيم المشاريع المختلفة بين المجالس."
            ]
        ),
        GameDefinition(
            slug: "baloot-double",
            arabicTitle: "بلوت دبل",
            englishTitle: "Baloot – Double",
            shortDescription: "نمط يعتمد على مضاعفة الرهان أثناء المزايدة (دبل، ثري، فور) قبل بدء اللعب، لرفع قيمة الجولة.",
            category: .balootTool,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .advanced,
            estimatedDuration: "15–25 دقيقة للجولة",
            iconName: "multiply.circle.fill",
            accentToken: "warning",
            isPlayable: false,
            sortOrder: 36,
            sections: [
                .objective: "رفع قيمة نتيجة الجولة عبر تحدّي الفريق الخصم بمضاعفة الرهان قبل بدء اللعب، مع تحمّل مخاطرة أعلى عند الخسارة.",
                .playerCount: "أربعة لاعبين في فريقين متقابلين.",
                .setup: "بعد اختيار نمط الجولة (صن أو حكم)، يجوز لأي فريق أن \"يدبل\" ليضاعف قيمة الجولة، ويجوز للفريق الآخر الرد بمضاعفة أعلى (ثري ثم فور).",
                .dealing: "8 أوراق لكل لاعب، مطابق لبقية أنماط البلوت.",
                .cardRanking: "يتبع ترتيب صن أو حكم حسب النمط المُختار لهذه الجولة.",
                .howToPlay: "يُلعب بنفس قواعد اتّباع النوع أو القطع بالحكم، لكن نتيجة الجولة كاملة تُضرب بالمضاعف المتفق عليه قبل اللعب.",
                .scoring: "النتيجة النهائية = نقاط الجولة (أكلات + مشاريع) × المضاعف المُعلَن (دبل ×2، ثري ×3، فور ×4 في الصيغة القياسية لهذا التطبيق، وقابلة للتغيير من الإعدادات).",
                .projects: "المشاريع المعتادة (كالبلوت) تُحتسب أولًا، ثم يُطبَّق المضاعف على المجموع الكلي.",
                .roundEnd: "تنتهي الجولة كالمعتاد بعد الأكلات الثماني، وتُطبَّق المضاعفة على النتيجة النهائية قبل إضافتها لإجمالي الجلسة.",
                .commonMistakes: "الدبل دون تقييم حقيقي لقوة اليد، أو نسيان تسجيل المضاعف الصحيح في مسجّل النقاط."
            ]
        ),
        GameDefinition(
            slug: "baloot-ashkal",
            arabicTitle: "بلوت أشكال",
            englishTitle: "Baloot – Ashkal",
            shortDescription: "حالة مزايدة معروفة في البلوت تُعامل مثل الصن، لكن الشراكة ومَن يأخذ الورقة المكشوفة تختلف حسب موقع اللاعب.",
            category: .balootTool,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .advanced,
            estimatedDuration: "ضمن مزايدة الجولة",
            iconName: "arrow.triangle.branch",
            accentToken: "warning",
            isPlayable: false,
            sortOrder: 37,
            sections: [
                .objective: "إتقان متى يظهر خيار \"أشكال\" في المزايدة، وكيف يغيّر مَن يأخذ الورقة المكشوفة دون أن يغيّر طبيعة اللعب لاحقًا.",
                .playerCount: "أربعة لاعبين في فريقين، ويظهر الحكم على صحة الأشكل بحسب ترتيب الجلوس حول الموزّع.",
                .setup: "يظهر أشكال عادة في الدور الأول من المزايدة عندما يمر اللاعبون السابقون، ويكون متاحًا للاعبين المتأخرين في الدور بحسب عرف القاعدة المعتمدة.",
                .dealing: "يعتمد على وجود ورقة مكشوفة في بداية التوزيع؛ عند قبول أشكال لا يأخذها المزايد نفسه غالبًا، بل يأخذها شريكه حسب الصيغة المتداولة.",
                .cardRanking: "يلعب أشكال كصن: لا يوجد نوع حكم، وترتيب كل الأنواع A ثم 10 ثم K ثم Q ثم J ثم 9 ثم 8 ثم 7.",
                .howToPlay: "بعد حسم المزايدة تُستكمل الجولة مثل الصن: التلزيم بالنوع واجب إن توفر، ولا يوجد قطع بحكم.",
                .scoring: "تُحتسب نقاط الجولة كصن: 120 نقطة أوراق + 10 لآخر أكلة = 130، ثم تُضاعف عادة عند إضافتها للنتيجة.",
                .projects: "تُعامل المشاريع مثل الصن؛ لا يوجد مشروع البلوت المرتبط بالحكم لأنه لا يوجد نوع حكم.",
                .roundEnd: "تنتهي الجولة بعد ثماني أكلات وتُضاف النتيجة للفريق الفائز وفق قواعد الصن المتفق عليها.",
                .commonMistakes: "اعتبار أشكال نوعًا مستقلًا بقواعد لعب مختلفة؛ الصحيح أنه حالة مزايدة تؤدي غالبًا إلى لعب صن مع أثر خاص على أخذ الورقة المكشوفة."
            ]
        ),
        GameDefinition(
            slug: "baloot-gahwa-lock",
            arabicTitle: "قهوة وقفل الحكم",
            englishTitle: "Gahwa and Locked Hokum",
            shortDescription: "مرجع لمضاعفة القهوة وحالة قفل الحكم بعد الدبل، وهي من أشهر تفاصيل المجالس المتقدمة.",
            category: .balootTool,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .advanced,
            estimatedDuration: "ضمن مزايدة الجولة",
            iconName: "lock.shield.fill",
            accentToken: "warning",
            isPlayable: false,
            sortOrder: 38,
            sections: [
                .objective: "فهم متى تتحول الجولة إلى مخاطرة عالية عبر الدبل والثري والفور والقهوة، ومتى يصبح الحكم مقفلًا بقيود إضافية.",
                .playerCount: "أربعة لاعبين في فريقين. إعلان القهوة أو القفل يؤثر على الفريقين معًا لا على لاعب منفرد.",
                .setup: "تبدأ من جولة حكم غالبًا بعد إعلان مضاعفات متتالية. تختلف ألفاظ القبول والرد بين المجالس، لذلك يجب الاتفاق عليها قبل اللعب.",
                .dealing: "لا تغيّر القهوة أو القفل توزيع الأوراق؛ التغيير في قيمة الجولة وقيود قيادة الحكم.",
                .cardRanking: "يبقى ترتيب الحكم كما هو: J ثم 9 ثم A ثم 10 ثم K ثم Q ثم 8 ثم 7 في نوع الحكم، وبقية الأنواع كالصن.",
                .howToPlay: "في الحكم المقفل قد يُمنع اللاعب من بدء الأكلة بورقة حكم ما دام يملك غير الحكم، إلا إذا اتُفق على خلاف ذلك.",
                .scoring: "الدبل والثري والفور تضاعف نتيجة الجولة حسب صيغة المجلس. القهوة في كثير من المجالس تعني أن الفائز بالجولة يكسب الصكة كاملة أو تُعامل كمضاعف خاص، والتطبيق يتيح تفعيلها في إعدادات التسجيل.",
                .projects: "تُحتسب المشاريع قبل تطبيق المضاعف وفق الصيغة المتفق عليها، مع التنبيه أن بعض المجالس لا تضاعف المشاريع بعد حد معين.",
                .roundEnd: "عند نهاية الأكلات تُحدَّد الجهة الفائزة ثم تُطبّق نتيجة القهوة/القفل على إجمالي الجلسة.",
                .commonMistakes: "إعلان القهوة دون اتفاق مسبق على معناها: هل هي فوز بالصكة، أم مضاعف عددي، أم شرط خاص للحكم المقفل."
            ]
        ),
        GameDefinition(
            slug: "baloot-kaboot",
            arabicTitle: "بلوت كبوت",
            englishTitle: "Baloot – Kaboot",
            shortDescription: "حالة تفوق نادرة عندما يأخذ فريق واحد كل الأكلات الثماني في الجولة، ولها احتساب خاص في كثير من الصيغ.",
            category: .balootTool,
            playerCountText: "4 لاعبين (فريقان متقابلان)",
            difficulty: .advanced,
            estimatedDuration: "نهاية جولة واحدة",
            iconName: "flag.checkered.2.crossed",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 39,
            sections: [
                .objective: "شرح معنى الكبوت وكيف يختلف احتسابه عن الفوز العادي بالجولة.",
                .playerCount: "أربعة لاعبين في فريقين؛ الكبوت يُنسب للفريق الذي يأخذ كل الأكلات.",
                .setup: "لا يحتاج إعدادًا خاصًا، بل يظهر كنتيجة لجولة صن أو حكم بعد انتهاء اللعب.",
                .dealing: "التوزيع عادي: 8 أوراق لكل لاعب.",
                .cardRanking: "يتبع ترتيب النمط المختار: صن بلا حكم، أو حكم بنوع مفضّل.",
                .howToPlay: "إذا فاز فريق واحد بكل الأكلات الثماني ولم يأخذ الخصم أي أكلة، تُسجَّل الحالة ككبوت بدل احتساب الجولة كفوز عادي فقط.",
                .scoring: "قيمة الكبوت تختلف بين الصيغ؛ الشائع أن له نتيجة أعلى من الجولة العادية، وقد تتأثر بالدبل أو المشاريع. لذلك يوضحه التطبيق كمرجع ويترك التسجيل اليدوي حسب اتفاق المجلس.",
                .projects: "مشاريع الفريق الفائز قد تُضاف حسب الصيغة، أما مشاريع فريق لم يأخذ أي أكلة فقد لا تُحتسب في بعض القواعد.",
                .roundEnd: "تُعلن حالة الكبوت عند نهاية الأكلة الثامنة إذا كانت كل الأكلات لفريق واحد.",
                .commonMistakes: "خلط الكبوت بالفوز بفارق كبير؛ الكبوت يتطلب أخذ كل الأكلات، وليس مجرد جمع أغلب النقاط."
            ]
        ),

        // MARK: - أدوات البلوت

        GameDefinition(
            slug: "baloot-training",
            arabicTitle: "بلوت تدريب",
            englishTitle: "Baloot Training",
            shortDescription: "أكاديمية تفاعلية تقسم تعلم البلوت إلى مبتدئ ومتوسط ومتقدم مع مواقف عملية وشرح للقرار.",
            category: .balootTool,
            playerCountText: "لاعب واحد (أكاديمية تفاعلية)",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة للتدريب",
            iconName: "graduationcap.fill",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 10,
            sections: [
                .objective: "تحويل التعلم من قراءة ثابتة إلى تدريب عملي: شرح، مثال، موقف، اختيار، نتيجة، ثم تفسير سبب صحة أو خطأ القرار.",
                .playerCount: "مخصصة للتعلّم الفردي، وتستخدم قرارات قريبة من مواقف اللعب الحقيقية.",
                .setup: "اختر مستوى الدروس ثم اختر الدرس المطلوب، ولا تحتاج اتصال إنترنت أو حساب خارجي.",
                .dealing: "تشمل دروس المبتدئ توزيع الأوراق، التعرف على الورق، وترتيب القوة في الصن والحكم.",
                .cardRanking: "تربط الأكاديمية ترتيب الورق بقرارات فعلية مثل التلزيم، القطع، وسحب الحكم.",
                .howToPlay: "تبدأ من القواعد الأساسية ثم تنتقل إلى قراءة اللعب، ذاكرة الأوراق، حماية الشريك، والضغط على الخصم.",
                .scoring: "تشرح الحساب والمشاريع والمضاعفات من خلال أمثلة وتحديات مرتبطة بمسجل النقاط.",
                .projects: "تؤسس لفهم المشاريع وفرص الإعلان عنها قبل التوسع في نظام المشاريع الكامل داخل المحرك.",
                .roundEnd: "تربط نهاية الجولة بتحليل القرارات والتعلم من الأخطاء بدل الاكتفاء بعرض الفائز.",
                .commonMistakes: "تعرض أخطاء عملية مثل قطع أكلة الشريك، تجاهل التلزيم، أو صرف ورقة سيطرة في توقيت ضعيف."
            ]
        ),
        GameDefinition(
            slug: "score-calculation-challenge",
            arabicTitle: "تحدي حساب النقاط",
            englishTitle: "Scoring Challenge",
            shortDescription: "اختبار تفاعلي لتدريب حساب نتائج البلوت مع الصن والحكم والمشاريع والمضاعفات.",
            category: .balootTool,
            playerCountText: "لاعب واحد (تدريب تفاعلي)",
            difficulty: .intermediate,
            estimatedDuration: "3–5 دقائق للتحدي",
            iconName: "function",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 13,
            sections: [
                .objective: "إتقان طريقة جمع نقاط الأوراق والمشاريع والمضاعفات يدويًا دون أخطاء.",
                .playerCount: "تحدي فردي يولّد أسئلة حسابية محلية بثلاث مستويات صعوبة.",
                .setup: "اختر مستوى الصعوبة، احسب نتيجة الفريق المطلوب، ثم أدخل الإجابة قبل انتهاء المؤقت.",
                .dealing: "غير منطبق على هذه الصفحة المرجعية.",
                .cardRanking: "تعرض جدول نقاط كل ورقة في نمطي صن وحكم جنبًا إلى جنب لسهولة المقارنة.",
                .howToPlay: "يعرض التحدي نقاط الفريقين والمشاريع والمضاعف، ثم يطلب نتيجة فريق محدد ويشرح طريقة الحساب بعد الإجابة.",
                .scoring: "مجموع حكم = 162، ومجموع صن الأساسي = 130 (يُضاعف عادة إلى 260). القيم قابلة للتخصيص من إعدادات التسجيل حسب عرف المجلس.",
                .projects: "تلخّص قيم المشاريع الشائعة وتنبّه إلى أنها قد تختلف بين المجالس.",
                .roundEnd: "توضّح كيف تُضاف نتيجة الجولة إلى إجمالي الجلسة في مسجّل تسجيل البلوت.",
                .commonMistakes: "أخطاء الجمع اليدوي الشائعة، ونسيان تطبيق المضاعف على المجموع الكامل بدل جزء منه فقط."
            ]
        ),
        GameDefinition(
            slug: "hand-analyzer",
            arabicTitle: "حلّل يدي",
            englishTitle: "Analyze My Hand",
            shortDescription: "أداة تدريبية لإدخال أوراقك يدويًا والحصول على توصية شراء: بس، صن، أو حكم مع أفضل لون ومشاريع اليد.",
            category: .balootTool,
            playerCountText: "لاعب واحد (تحليل يد)",
            difficulty: .intermediate,
            estimatedDuration: "دقيقة واحدة لكل يد",
            iconName: "wand.and.stars",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 12,
            sections: [
                .objective: "مساعدة اللاعب على فهم قوة يده قبل الشراء: هل يمر، يشتري صن، أو يختار حكمًا بلون محدد.",
                .playerCount: "الأداة فردية، لكنها تحلل يد لاعب واحد ضمن منطق جولة بلوت كاملة.",
                .setup: "اختر ثماني أوراق يدويًا من حزمة البلوت. لا تستخدم الأداة الكاميرا ولا تحتاج أي صلاحية خصوصية.",
                .dealing: "لا توزّع الأداة أوراقًا عشوائية؛ المستخدم يدخل اليد التي يريد تحليلها كما يراها على الطاولة.",
                .cardRanking: "يعتمد التحليل على ترتيب الصن والحكم نفسه المستخدم في محرك BalootEngine، لا على ترتيب بصري مستقل.",
                .howToPlay: "بعد اختيار 8 أوراق يعرض التطبيق تقييم الصن، أفضل حكم، المشاريع المكتشفة، وثقة التوصية.",
                .scoring: "تدخل قيمة المشاريع المكتشفة في قوة التوصية، لكن القرار لا يعتمد على المشاريع وحدها إذا كانت اليد ضعيفة في الأكلات.",
                .projects: "تُكتشف المشاريع بواسطة ProjectDetector نفسه: سرا، خمسين، مية، أربعمية، والبلوت عند وجود حكم مناسب.",
                .roundEnd: "يمكن مسح اليد وإدخال موقف جديد فورًا، أو استخدام النتيجة كمرجع قبل اتخاذ قرار الشراء في جلسة حقيقية.",
                .commonMistakes: "الاعتماد على مشروع صغير فقط للشراء، أو اختيار حكم بلون قصير لا يملك سيطرة كافية على الأكلات."
            ]
        ),
        GameDefinition(
            slug: "what-to-play-trainer",
            arabicTitle: "وش تلعب؟",
            englishTitle: "What Should I Play?",
            shortDescription: "مدرب مواقف يعرض يدًا حقيقية من جولة بلوت ويقارن اختيارك بقرار Expert AI مع تفسير الأثر المتوقع.",
            category: .balootTool,
            playerCountText: "لاعب واحد (تدريب موقف)",
            difficulty: .advanced,
            estimatedDuration: "دقيقة إلى دقيقتين لكل موقف",
            iconName: "brain.head.profile",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 11,
            sections: [
                .objective: "تدريب اللاعب على اختيار أفضل ورقة في موقف لعب فعلي بدل حفظ القواعد نظريًا فقط.",
                .playerCount: "الأداة فردية، لكنها تولد موقفًا من طاولة بلوت كاملة تضم لاعبًا بشريًا وثلاثة وكلاء ذكاء اصطناعي.",
                .setup: "اختر مستوى الصعوبة ثم أنشئ موقفًا. يستخدم التطبيق بذرة محلية لتوليد جولة قابلة للتكرار دون إنترنت.",
                .dealing: "الموقف يبدأ من توزيع حقيقي داخل BalootEngine، ثم يتقدم الذكاء الاصطناعي حتى يصل الدور إلى اللاعب البشري.",
                .cardRanking: "كل خيار معروض هو ورقة قانونية حسب LegalMoveValidator وترتيب صن/حكم المعتمد في المحرك.",
                .howToPlay: "اختر ورقة من الخيارات القانونية. بعدها يعرض التطبيق ترتيب اختيارك، ورقة الخبير، ثاني أفضل خيار عند وجوده، وتفسير القرار.",
                .scoring: "الأثر المتوقع يقدّر ربح أو خسارة نقاط الأكلة الحالية، ويستخدم ExpertBalootAgent لترجيح القرار الأفضل.",
                .projects: "الموقف يركز على قرار لعب الورقة، لكنه يأتي من حالة جولة كاملة؛ إذا كانت هناك مشاريع أو مضاعفات معلنة فهي محفوظة داخل GameState وReplay.",
                .roundEnd: "يمكن توليد موقف جديد مباشرة، ويظل كل موقف قابلًا للإعادة من نفس البذرة والصعوبة لاختبارات Replay.",
                .commonMistakes: "اختيار ورقة ثمينة في أكلة خاسرة، أو فتح الحكم مبكرًا بلا حاجة، أو تجاهل أن خيارًا أقل نقاطًا قد يحمي يد الشريك."
            ]
        ),
        GameDefinition(
            slug: "baloot-sandbox",
            arabicTitle: "مختبر البلوت",
            englishTitle: "Baloot Sandbox",
            shortDescription: "مختبر تدريبي يبني موقف بلوت يدويًا ويجرب الورقة عبر BalootEngine لشرح القانونية والفائز والنقاط.",
            category: .balootTool,
            playerCountText: "لاعب واحد (محاكاة موقف)",
            difficulty: .advanced,
            estimatedDuration: "دقيقة إلى ثلاث دقائق لكل موقف",
            iconName: "slider.horizontal.3",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 14,
            sections: [
                .objective: "تمكين اللاعب من تجربة سؤال: ماذا يحدث لو لعبت هذه الورقة؟ من داخل محرك البلوت نفسه.",
                .playerCount: "الأداة فردية، لكنها تبني طاولة بأربعة مقاعد وفريقين حتى تبقى القواعد مطابقة للعبة.",
                .setup: "تبدأ النسخة الحالية من موقف حكم جاهز وقابل للتوسيع إلى إدخال كامل للأوراق والأدوار والمشاريع.",
                .dealing: "لا توزع الأداة أوراقًا عشوائية؛ بل تستخدم توزيعًا محددًا داخل GameState حتى تكون النتيجة قابلة لإعادة الاختبار.",
                .cardRanking: "كل تجربة تمر عبر LegalMoveValidator وScoreCalculator، لذلك ترتيب الصن والحكم مطابق للعب الحقيقي.",
                .howToPlay: "اختر ورقة من يد اللاعب الحالي، وسيعرض المختبر هل الحركة قانونية، سبب الرفض إن وُجد، أو فائز الأكلة ونقاطها.",
                .scoring: "نقاط الأكلة والمضاعف والمشاريع تُحمل داخل حالة Sandbox، ويحتسب المحرك أثر الورقة دون منطق واجهة جانبي.",
                .projects: "تدعم طبقة المحرك إدخال مشاريع معلنة يدويًا، ويمكن ربطها بواجهة تحرير كاملة في مرحلة لاحقة.",
                .roundEnd: "الهدف ليس إنهاء مباراة كاملة، بل اختبار موقف محدد ثم مقارنة أثر البدائل قبل تطبيقها في تدريب أو Replay.",
                .commonMistakes: "اعتبار المختبر لعبة مستقلة عن المحرك، أو السماح بحركة لا يقبلها LegalMoveValidator في الجولة الحقيقية."
            ]
        ),
        GameDefinition(
            slug: "daily-baloot-challenges",
            arabicTitle: "تحديات البلوت",
            englishTitle: "Baloot Challenges",
            shortDescription: "تحديات يومية وأسبوعية تعمل دون إنترنت وتجمع بين اللعب، الحساب، الأكاديمية، ومواقف وش تلعب.",
            category: .balootTool,
            playerCountText: "لاعب واحد (تحديات محلية)",
            difficulty: .intermediate,
            estimatedDuration: "5–15 دقيقة يوميًا",
            iconName: "calendar.badge.checkmark",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 21,
            sections: [
                .objective: "تقديم أهداف تدريب قصيرة ومتجددة تساعد اللاعب على ممارسة البلوت بانتظام دون الحاجة إلى اتصال أو خادم.",
                .playerCount: "التحديات فردية، لكنها تحيل اللاعب إلى اللعب ضد الذكاء أو أدوات التدريب الموجودة داخل التطبيق.",
                .setup: "تُولّد التحديات محليًا من تاريخ اليوم أو الأسبوع باستخدام Seed حتمي، لذلك يمكن اختبارها وإعادتها.",
                .dealing: "بعض التحديات تطلب لعب جولة حقيقية، وبعضها يرتبط بالأكاديمية أو تحدي الحساب أو مدرب وش تلعب.",
                .cardRanking: "أي تحدٍ يتضمن قرار لعب أو تدريب تكتيكي يعتمد على نفس ترتيب الصن والحكم المستخدم في المحرك.",
                .howToPlay: "ابدأ تحديات اليوم أو الأسبوع، نفذ الهدف المطلوب، ثم علّم التحدي كمكتمل لحفظ تقدمك المحلي.",
                .scoring: "تعرض البطاقة هدفًا عدديًا وتقدمًا تدريبيًا محليًا، ولا تمنح أفضلية داخل اللعب.",
                .projects: "يمكن لاحقًا إضافة تحديات مشاريع وكبوت عندما يكتمل منطق المشاريع والمضاعفات داخل BalootEngine.",
                .roundEnd: "تتجدد التحديات اليومية مع تغير التاريخ، وتبقى الأسبوعية ثابتة داخل نفس أسبوع التقويم.",
                .commonMistakes: "الخلط بين التحدي اليومي والأسبوعي، أو اعتبار التحدي أفضلية قوة داخل اللعب بدل تدريب اختياري."
            ]
        ),
        GameDefinition(
            slug: "baloot-achievements",
            arabicTitle: "الإنجازات والألقاب",
            englishTitle: "Achievements and Titles",
            shortDescription: "نظام ألقاب وإنجازات محلي للتقدم في البلوت، قابل للربط لاحقًا بـ Game Center.",
            category: .balootTool,
            playerCountText: "لاعب واحد (تقدم محلي)",
            difficulty: .beginner,
            estimatedDuration: "يتقدم مع الاستخدام",
            iconName: "trophy.fill",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 24,
            sections: [
                .objective: "إعطاء اللاعب أهدافًا طويلة المدى مثل أول كبوت، ملك الصن، شيخ الحكم، وحل تحديات الحساب.",
                .playerCount: "الإنجازات فردية ومحفوظة محليًا، ولا تحتاج حسابًا أو اتصالًا بالإنترنت في النسخة الحالية.",
                .setup: "تظهر الإنجازات في شاشة مستقلة، وتقرأ تلقائيًا تقدم التدريب والحساب والأكاديمية وسجل مسجل النقاط.",
                .dealing: "لا توجد طريقة توزيع خاصة؛ الإنجازات تقرأ أحداث اللعب أو التسجيل أو التدريب عند اكتمال الربط الآلي.",
                .cardRanking: "إنجازات الصن والحكم تُحسب من نمط الصكة المسجل وسجل التقدم المحلي، لا من حالة عرض مؤقتة في الواجهة.",
                .howToPlay: "راجع قائمة الإنجازات، اعرف شرط كل لقب، وتابع تقدمك عبر اللعب والتدريب والتحديات.",
                .scoring: "الإنجازات لا تمنح نقاط قوة داخل اللعب؛ هي تقدم وتجميع ألقاب فقط.",
                .projects: "يمكن إضافة إنجازات للمشاريع مثل إتقان المشاريع عند اكتمال منطق المشاريع الكامل داخل المحرك.",
                .roundEnd: "عند نهاية الجولة أو المباراة يمكن للمحرك لاحقًا إرسال حدث فتح إنجاز واحد قابل للإعادة والتحقق.",
                .commonMistakes: "ربط الإنجاز بالواجهة مباشرة بدل أحداث المحرك أو السجل، أو جعله يغير قوة اللاعب داخل المباراة."
            ]
        ),
        GameDefinition(
            slug: "baloot-career-mode",
            arabicTitle: "نمط المسيرة",
            englishTitle: "Career Mode",
            shortDescription: "مسيرة Offline تحول اللعب والتدريب والحساب والإنجازات إلى رتبة XP ومحتوى مفتوح وخطوة تدريب تالية.",
            category: .balootTool,
            playerCountText: "لاعب واحد (تقدم محلي)",
            difficulty: .intermediate,
            estimatedDuration: "يتقدم مع الاستخدام",
            iconName: "flag.checkered",
            accentToken: "warning",
            isPlayable: false,
            sortOrder: 22,
            sections: [
                .objective: "تحويل تقدم اللاعب إلى مسار واضح يبدأ من لاعب مبتدئ ويتدرج حتى شيخ البلوت عبر اللعب والتدريب.",
                .playerCount: "المسيرة فردية وتعمل دون إنترنت، وتقرأ بيانات اللاعب المحلية من السجل والتدريب والأكاديمية.",
                .setup: "لا تحتاج إنشاء حساب؛ تبدأ المسيرة من بياناتك الحالية وتعرض XP والرتبة والمحتوى المفتوح تلقائيًا.",
                .dealing: "لا تغيّر المسيرة توزيع الجولة؛ هي طبقة تقدم فوق اللعب الحقيقي ومدرب وش تلعب وتحدي النقاط.",
                .cardRanking: "أي تقدم مرتبط بقرارات اللعب يعتمد على BalootEngine ومدرب الخبير، لا على تقييم واجهة مستقل.",
                .howToPlay: "العب مباريات، حل مواقف وش تلعب، أكمل دروس الأكاديمية، وأجب على تحديات الحساب لرفع رتبتك.",
                .scoring: "تضيف المباريات والتدريب والحساب والدروس والإنجازات XP، ولا تمنح أي أفضلية داخل اللعب.",
                .projects: "يمكن لاحقًا ربط مشاريع البلوت والكبوت داخل المسيرة عندما تتوسع أحداث المحرك التفصيلية.",
                .roundEnd: "بعد نهاية مباراة أو تدريب أو درس، تُعاد قراءة التقدم المحلي وتظهر الرتبة والخطوة التالية.",
                .commonMistakes: "اعتبار المسيرة مصدر أفضلية داخل اللعب؛ الصحيح أنها تقدم تدريبي وتجميلي فقط."
            ]
        ),
        GameDefinition(
            slug: "offline-tournaments",
            arabicTitle: "بطولات Offline",
            englishTitle: "Offline Tournaments",
            shortDescription: "إنشاء بطولات بلوت محلية من 4 أو 8 فرق مع جدول مباريات وسجل محفوظ عبر SwiftData.",
            category: .balootTool,
            playerCountText: "4 أو 8 فرق",
            difficulty: .intermediate,
            estimatedDuration: "حسب نظام البطولة",
            iconName: "trophy.fill",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 23,
            sections: [
                .objective: "تنظيم بطولة بلوت تعمل دون إنترنت، مع حفظ الجدول والتاريخ والبطل محليًا.",
                .playerCount: "تدعم البطولة 4 أو 8 فرق، ويمكن استخدامها لجلسات المجلس أو التدريب ضد خصوم محليين.",
                .setup: "اختر اسم البطولة، النظام، وعدد الفرق، ثم ينشئ التطبيق جدول المباريات ويحفظه في SwiftData.",
                .dealing: "لا تغير البطولة توزيع أوراق البلوت؛ هي طبقة تنظيم وجدولة فوق اللعب أو التسجيل.",
                .cardRanking: "كل مباراة داخل البطولة يجب أن تستخدم قواعد البلوت المختارة نفسها من المحرك أو قواعد مجلسي.",
                .howToPlay: "أنشئ الجدول، العب المباريات على الطاولة أو داخل التطبيق، ثم اعتمد البطل عند نهاية البطولة.",
                .scoring: "تعرض البطولة عدد المباريات والانتصارات والبطل، ويمكن لاحقًا ربط كل مباراة بجلسة Scorekeeper أو GameState.",
                .projects: "لا تضيف البطولة قواعد مشاريع جديدة؛ تعتمد على إعدادات البلوت المعتمدة لكل مباراة.",
                .roundEnd: "عند اعتماد البطل تصبح البطولة منتهية وتبقى في السجل المحلي للرجوع إليها.",
                .commonMistakes: "خلط نظام الدوري والخروج المغلوب أثناء نفس البطولة، أو حذف البطولة قبل اعتماد البطل النهائي."
            ]
        ),
        GameDefinition(
            slug: "baloot-scorekeeper",
            arabicTitle: "تسجيل البلوت",
            englishTitle: "Baloot Scorekeeper",
            shortDescription: "أداة مستقلة لتسجيل نتائج جلسة بلوت فعلية على الطاولة: الفرق، الصكات، المشاريع، والدبل.",
            category: .balootTool,
            playerCountText: "يخدم فريقين (4 لاعبين) على الطاولة",
            difficulty: .beginner,
            estimatedDuration: "طوال مدة الجلسة",
            iconName: "list.clipboard.fill",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 20,
            sections: [
                .objective: "تتبّع نقاط جلسة بلوت حقيقية بدقة، وإعلان الفريق الفائز فور بلوغ الهدف المتفق عليه.",
                .playerCount: "يُسجَّل باسم فريقين، كل فريق من لاعبين على الطاولة.",
                .setup: "أدخل اسمي الفريقين واختر الحد المستهدف (152 افتراضيًا أو قيمة مخصصة) قبل بدء أول صكة.",
                .dealing: "غير منطبق مباشرة؛ الأداة تُسجّل نتيجة كل صكة بعد لعبها فعليًا على الطاولة.",
                .cardRanking: "غير منطبق؛ هذه أداة تسجيل وليست محرك لعب.",
                .howToPlay: "بعد كل صكة، أدخل نوعها (صن أو حكم)، نقاط كل فريق، المشاريع، والمضاعف (دبل/ثري/فور/قهوة إن كانت مفعّلة)، ثم احفظ الجولة.",
                .scoring: "يُحسب إجمالي كل فريق تلقائيًا كمجموع كل الصكات المحفوظة، مع تطبيق المضاعف على كل صكة بحسب صيغة التسجيل المختارة من الإعدادات.",
                .projects: "أدخل قيمة مشاريع كل فريق يدويًا لكل صكة كما اتُّفق عليه على الطاولة.",
                .roundEnd: "تُعلَن الجلسة منتهية والفريق فائزًا فور بلوغ أحد الفريقين الهدف المستهدف بفارق واضح.",
                .commonMistakes: "نسيان اختيار المضاعف الصحيح، أو حفظ صكة بأرقام فارغة أو سالبة — والأداة تمنع ذلك تلقائيًا."
            ]
        ),
        GameDefinition(
            slug: "baloot-bidding-guide",
            arabicTitle: "دليل مزايدة البلوت",
            englishTitle: "Baloot Bidding Guide",
            shortDescription: "كتالوج تعلّمي يشرح ترتيب المزايدة: بس، أول، ثاني، صن، حكم، أشكال، ودبل.",
            category: .balootTool,
            playerCountText: "لاعب واحد (مرجع تعلّمي)",
            difficulty: .intermediate,
            estimatedDuration: "7–12 دقيقة للاطلاع",
            iconName: "quote.bubble.fill",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 31,
            sections: [
                .objective: "توضيح قرارات المزايدة قبل اللعب حتى يعرف اللاعب متى يمر، ومتى يطلب صن أو حكم، ومتى تكون المضاعفة منطقية.",
                .playerCount: "المزايدة تُفهم حول طاولة من أربعة لاعبين، لكن الدليل مخصص للتعلم الفردي.",
                .setup: "ابدأ بفهم موضع الموزّع والورقة المكشوفة وترتيب الكلام حول الطاولة؛ هذه العناصر تحدد الخيارات المتاحة.",
                .dealing: "يعرض الدليل فكرة توزيع أولي ثم قرار المزايدة قبل اكتمال يد اللاعب حسب الصيغة المتداولة.",
                .cardRanking: "يربط قرار المزايدة بقوة الأوراق: كثرة الحكم العالي تدعم حكم، وتوازن الأوراق العالية يدعم صن.",
                .howToPlay: "يوضح معنى بس، أول، ثاني، حكم، صن، أشكال، دبل، ثري، فور، وقهوة كقرارات قبل أو عند بداية الجولة.",
                .scoring: "يشرح أثر كل قرار على النتيجة: صن مضاعف عادة، والحكم أقل في المجموع، والدبل يرفع المكسب والخسارة.",
                .projects: "ينبّه إلى أن وجود مشروع قوي قد يغيّر قرار المزايدة، لكنه لا يكفي وحده إذا كانت اليد ضعيفة في الأكلات.",
                .roundEnd: "قرار المزايدة ينتهي عند ثبات النمط والمضاعف، ثم يبدأ اللعب العادي للأكلات.",
                .commonMistakes: "أشهر خطأ للمبتدئ هو المزايدة على اسم النمط فقط دون حساب قوة اليد، موقعه، ودعم الشريك المحتمل."
            ]
        ),
        GameDefinition(
            slug: "baloot-projects-reference",
            arabicTitle: "كتالوج مشاريع البلوت",
            englishTitle: "Baloot Projects Catalog",
            shortDescription: "مرجع سريع للمشاريع المشهورة: سرا، خمسين، مية، أربع ميات، والبلوت.",
            category: .balootTool,
            playerCountText: "لاعب واحد (مرجع تعلّمي)",
            difficulty: .intermediate,
            estimatedDuration: "5–8 دقائق للاطلاع",
            iconName: "rectangle.stack.badge.plus",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 35,
            sections: [
                .objective: "جمع أسماء المشاريع المشهورة وشروطها في مكان واحد ليسهل الرجوع إليها أثناء التعلم أو قبل الجلسة.",
                .playerCount: "المشاريع تخص يد لاعب ضمن فريقين من أربعة لاعبين، لكن المرجع فردي.",
                .setup: "تُفحص المشاريع بعد اكتمال اليد وقبل أو أثناء بداية الجولة حسب عرف المجلس.",
                .dealing: "لا يوجد توزيع خاص للمشاريع؛ تظهر من نفس يد اللاعب ذات الثماني أوراق.",
                .cardRanking: "تتابعات المشاريع تستخدم ترتيب التسلسل A ثم K ثم Q ثم J ثم 10 ثم 9 ثم 8 ثم 7، لا ترتيب قوة الأكلة دائمًا.",
                .howToPlay: "السرا ثلاث أوراق متتابعة من نفس النوع، والخمسين أربع متتابعة، والمية خمس متتابعة أو أربع أوراق من رتب معتبرة، وأربع ميات غالبًا أربع آسات في الصن، والبلوت شايب وبنت الحكم.",
                .scoring: "القيم تختلف بين صن وحكم وبين المجالس؛ لذلك يعرض التطبيق القاعدة العامة ويترك الإدخال النهائي في مسجّل النقاط حسب اتفاق اللاعبين.",
                .projects: "إذا أعلن الفريقان مشاريع، تُقارن قوة المشاريع عادة ولا تُحتسب إلا مشاريع الفريق صاحب المشروع الأقوى، بينما البلوت له معاملة خاصة في كثير من الصيغ.",
                .roundEnd: "تُضاف نقاط المشاريع إلى نتيجة الجولة قبل تطبيق المضاعفات إن كانت الصيغة المعتمدة تنص على ذلك.",
                .commonMistakes: "استخدام الورقة نفسها في أكثر من مشروع، أو إعلان تتابع غير صحيح مثل A-10-K بدل A-K-Q."
            ]
        ),
        GameDefinition(
            slug: "baloot-multiplayer-voice-guide",
            arabicTitle: "اللعب الجماعي والسوالف",
            englishTitle: "Multiplayer and Table Talk",
            shortDescription: "دليل يوضح أوضاع اللعب المتاحة: ضد الذكاء، أربعة أشخاص على نفس الجهاز، وما يلزم قبل تفعيل اللعب الصوتي عن بعد.",
            category: .balootTool,
            playerCountText: "لاعب واحد إلى 4 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "3–6 دقائق للاطلاع",
            iconName: "mic.and.signal.meter.fill",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 41,
            sections: [
                .objective: "توضيح الفروق بين اللعب ضد الذكاء الاصطناعي، اللعب المحلي بين الأشخاص، واللعب الشبكي بالصوت حتى يعرف اللاعب ما المتاح الآن وما يحتاج اتصالًا آمنًا.",
                .playerCount: "اللعب ضد الذكاء يدعم لاعبًا واحدًا مع ثلاثة آليين. اللعب المحلي يدعم أربعة أشخاص على نفس الجهاز بتمريره حسب الدور. اللعب الصوتي عن بعد يحتاج غرفة Online لأربعة لاعبين.",
                .setup: "في الوضع المحلي يختار اللاعب نمط الطاولة من شاشة اللعب. في اللعب الشبكي المقترح لاحقًا يلزم تسجيل دخول، إنشاء غرفة، دعوة لاعبين، ثم طلب إذن الميكروفون عند تشغيل الصوت.",
                .dealing: "محرك التوزيع نفسه يُستخدم لكل الأوضاع؛ الفرق فقط في مصدر قرار اللاعب: لمس بشري، قرار ذكاء اصطناعي، أو أمر قادم من لاعب متصل.",
                .cardRanking: "كل أوضاع اللعب تلتزم بنفس ترتيب صن وحكم حتى لا تختلف القواعد بين الذكاء والأشخاص.",
                .howToPlay: "وضع الذكاء مناسب للتدريب السريع. وضع الأشخاص مناسب لجلسة على جهاز واحد. وضع الصوت المقترح يجب أن يمنع الغش بإخفاء يد كل لاعب وإرسال الأفعال القانونية فقط للخادم.",
                .scoring: "النتائج تُحسب من المحرك نفسه في اللعب المحلي والآلي. في اللعب الشبكي يجب مزامنة سجل الأفعال والنتيجة النهائية بين الأجهزة لمنع اختلاف النتائج.",
                .projects: "عند إضافة مشاريع ودبل متقدمة للشبكة يجب إرسال الإعلانات كأحداث مستقلة قبل لعب الورقة حتى تُعرض للجميع بنفس الترتيب.",
                .roundEnd: "تنتهي الجولة محليًا فور اكتمال الأكلات. في اللعب الشبكي المقترح تُرسل نتيجة موقعة من مستضيف الغرفة أو الخادم ثم تُحفظ في السجل.",
                .commonMistakes: "تشغيل مايك أو دردشة قبل تحديث سياسة الخصوصية وصلاحيات App Store، أو إطلاق لعب شبكي بلا إعادة اتصال وحماية من انقطاع اللاعب."
            ]
        ),

        // MARK: - ألعاب ورق أخرى

        GameDefinition(
            slug: "kout-bou-sitta",
            arabicTitle: "كوت بو ستة",
            englishTitle: "Kout Bou Sitta",
            shortDescription: "لعبة ورق شعبية مستقلة عن البلوت، تعتمد على تجنّب أو جمع أوراق محددة حسب اتفاق اللاعبين.",
            category: .otherCardGame,
            playerCountText: "غالبًا 4 لاعبين",
            difficulty: .intermediate,
            estimatedDuration: "20–30 دقيقة",
            iconName: "6.circle.fill",
            accentToken: "otherGames",
            isPlayable: true,
            sortOrder: 50,
            sections: [
                .objective: "تحقيق أفضل نتيجة عبر تجنّب أوراق أو أكلات معيّنة تخسر نقاطًا، بحسب الصيغة المعتمدة من اللاعبين.",
                .playerCount: "تُلعب غالبًا بأربعة لاعبين، وتختلف التفاصيل بين المجالس.",
                .setup: "تُستخدم حزمة ورق عادية أو مختصرة حسب عرف اللاعبين قبل البدء.",
                .dealing: "تُوزَّع الأوراق بالتساوي على اللاعبين في بداية كل جولة.",
                .cardRanking: "يعتمد ترتيب الأوراق على الصيغة المتفق عليها بين اللاعبين قبل البدء.",
                .howToPlay: "يتناوب اللاعبون على اللعب، مع الحرص على تجنّب أو جمع الأوراق ذات الأثر السلبي أو الإيجابي حسب قواعد المجلس.",
                .scoring: "تُحتسب النتيجة حسب عدد الأوراق أو الأكلات المرصودة نهاية الجولة وفق الاتفاق المسبق.",
                .projects: "لا توجد مشاريع ثابتة متفق عليها عالميًا؛ تُترك لتقدير اللاعبين.",
                .roundEnd: "تنتهي الجولة بانتهاء الأوراق، وتُعلن النتيجة بحسب الصيغة المعتمدة.",
                .commonMistakes: "الخلط بين صيغ اللعب المختلفة المتداولة باسم هذه اللعبة دون اتفاق مسبق واضح."
            ]
        ),
        GameDefinition(
            slug: "tarneeb",
            arabicTitle: "طرنيب",
            englishTitle: "Tarneeb",
            shortDescription: "لعبة ورق جماعية شهيرة تعتمد على المزايدة لتحديد عدد الأكلات المستهدفة ونوع الحكم (الطرنيب).",
            category: .otherCardGame,
            playerCountText: "4 لاعبين (فريقان أو أفراد حسب الصيغة)",
            difficulty: .intermediate,
            estimatedDuration: "20–30 دقيقة للجولة",
            iconName: "suit.club.fill",
            accentToken: "otherGames",
            isPlayable: true,
            sortOrder: 51,
            sections: [
                .objective: "تحقيق عدد الأكلات الذي التزم به اللاعب أو الفريق أثناء المزايدة، أو أكثر.",
                .playerCount: "أربعة لاعبين، إما كل لاعب لنفسه أو في فريقين متقابلين حسب الصيغة المعتمدة.",
                .setup: "تُستخدم حزمة ورق كاملة من 52 ورقة عادة.",
                .dealing: "تُوزَّع كل الأوراق على اللاعبين الأربعة بالتساوي (13 ورقة لكل لاعب).",
                .cardRanking: "الآس أعلى ورقة وحتى 2 الأضعف في كل نوع، مع تفوّق نوع \"الطرنيب\" المُختار على بقية الأنواع.",
                .howToPlay: "يلتزم كل لاعب بعدد أكلات أثناء المزايدة، ثم يُلعب مع وجوب اتّباع النوع المطلوب أو القطع بالطرنيب عند عدم توفره.",
                .scoring: "يُحتسب الفارق بين الأكلات المُلتزَم بها والأكلات المُحقَّقة فعليًا، وقد تُخصم نقاط عند عدم الوفاء بالالتزام حسب الصيغة المعتمدة.",
                .projects: "لا توجد مشاريع بالمعنى المستخدم في البلوت؛ التركيز على دقة الالتزام بعدد الأكلات.",
                .roundEnd: "تنتهي الجولة بانتهاء كل الأوراق (13 أكلة)، وتُحدَّث النتيجة التراكمية.",
                .commonMistakes: "المبالغة في الالتزام بعدد أكلات أعلى من قوة اليد الفعلية."
            ]
        ),
        GameDefinition(
            slug: "trex",
            arabicTitle: "تركس",
            englishTitle: "Trix",
            shortDescription: "لعبة ورق تجمع عدة جولات مختلفة الأهداف في دورة واحدة (تجنّب أوراق معيّنة، أو التخلص من كل الأوراق أولًا).",
            category: .otherCardGame,
            playerCountText: "4 لاعبين أفراد",
            difficulty: .intermediate,
            estimatedDuration: "25–40 دقيقة للدورة الكاملة",
            iconName: "suit.diamond.fill",
            accentToken: "otherGames",
            isPlayable: true,
            sortOrder: 52,
            sections: [
                .objective: "تحقيق أقل عدد نقاط سلبية (أو أعلى نقاط إيجابية حسب الجولة) عبر دورة من عدة أنماط لعب مختلفة.",
                .playerCount: "أربعة لاعبين، كل لاعب يلعب لحسابه الخاص دون فرق ثابتة.",
                .setup: "تُستخدم حزمة ورق كاملة من 52 ورقة، وتُلعب عادة دورة من عدة جولات متتالية بأهداف مختلفة لكل جولة.",
                .dealing: "تُوزَّع كل الأوراق على اللاعبين الأربعة بالتساوي (13 ورقة لكل لاعب) في بداية كل جولة من الدورة.",
                .cardRanking: "يختلف الترتيب المستخدم حسب نوع الجولة داخل الدورة (بعض الجولات لا تعتمد على قوة الأوراق بل على تجنّب رموز معيّنة).",
                .howToPlay: "يجب اتّباع نفس النوع المطلوب إن توفر، وتختلف طريقة تحديد الفائز بكل جولة حسب هدفها الخاص ضمن الدورة.",
                .scoring: "تختلف طريقة الاحتساب من جولة لأخرى داخل نفس الدورة، وتُجمع النقاط تراكميًا حتى نهاية الدورة الكاملة.",
                .projects: "لا توجد مشاريع بالمفهوم المستخدم في البلوت.",
                .roundEnd: "تنتهي كل جولة فرعية بانتهاء الأوراق، وتنتهي الدورة الكاملة بعد لعب كل أنماط الجولات المتفق عليها.",
                .commonMistakes: "الخلط بين أهداف الجولات المختلفة داخل نفس الدورة، خصوصًا عند التبديل بين جولة تجنّب وجولة تجميع."
            ]
        ),
        GameDefinition(
            slug: "baloot-encyclopedia",
            arabicTitle: "موسوعة البلوت",
            englishTitle: "Baloot Encyclopedia",
            shortDescription: "مرجع سريع لمصطلحات البلوت: المزايدة، المضاعفات، المشاريع، والاحتساب، بتعريف ومثال لكل مصطلح.",
            category: .balootTool,
            playerCountText: "مرجع فردي",
            difficulty: .beginner,
            estimatedDuration: "تصفّح حر",
            iconName: "book.closed.fill",
            accentToken: "accent",
            isPlayable: false,
            sortOrder: 30,
            sections: [
                .objective: "تجميع كل مصطلحات البلوت المتفرقة في القواعد والتدريب في مرجع واحد قابل للبحث.",
                .playerCount: "أداة مرجعية فردية، لا علاقة لها بعدد لاعبي الطاولة.",
                .setup: "لا يوجد إعداد؛ المحتوى ثابت ومصنَّف حسب المزايدة والمضاعفات والمشاريع والاحتساب.",
                .dealing: "لا صلة بالتوزيع؛ هذا مرجع قراءة لا جزء من دورة لعب.",
                .cardRanking: "تشرح الموسوعة مفاهيم مثل الصن والحكم والحاكم، لكنها لا تستبدل صفحة القواعد الكاملة لكل نمط.",
                .howToPlay: "ابحث عن مصطلح أو تصفّح حسب التصنيف، واقرأ تعريفه ومثاله العملي.",
                .scoring: "بعض المصطلحات (كبوت، طيّاح المشتري) مرتبطة بالاحتساب مباشرة وتُشرح هنا باختصار.",
                .projects: "تصنيف «المشاريع» يغطي سرا وخمسين ومية وأربعمية والبلوت وتعارض المشاريع بين الفريقين.",
                .roundEnd: "لا صلة بنهاية الجولة؛ المحتوى مرجعي دائم لا يتغير بين الجولات.",
                .commonMistakes: "الخلط بين هذا المرجع المختصر وصفحة القواعد الكاملة لكل نمط لعب."
            ]
        ),
        GameDefinition(
            slug: "baloot-rare-cases",
            arabicTitle: "حالات نادرة",
            englishTitle: "Baloot Rare Cases",
            shortDescription: "مواقف حدّية نادرة الحدوث في المجلس الحقيقي (دورة ميتة، تعادل مشاريع، ترتيب التصعيد...) بحكمها وتفسيره.",
            category: .balootTool,
            playerCountText: "مرجع فردي",
            difficulty: .advanced,
            estimatedDuration: "تصفّح حر",
            iconName: "questionmark.folder.fill",
            accentToken: "primary",
            isPlayable: false,
            sortOrder: 40,
            sections: [
                .objective: "حسم الخلافات الشائعة على طاولة البلوت الحقيقية بحكم واضح مبني على نفس منطق BalootEngine.",
                .playerCount: "أداة مرجعية فردية، تفيد أي عدد من لاعبي المجلس عند الاختلاف على قاعدة.",
                .setup: "لا يوجد إعداد؛ كل حالة سؤال «ماذا لو؟» مع حكمها وسبب الحكم.",
                .dealing: "من ضمن الحالات المغطاة: ماذا يحدث عند تمرير الجميع مرتين بلا شراء.",
                .cardRanking: "تغطي حالات مثل شراء الصن بعد الحكم، وتقييد شراء الحكم في الجولة الأولى بشكل الورقة المكشوفة.",
                .howToPlay: "ابحث عن الموقف المختلف عليه أو تصفّح حسب التصنيف (مزايدة، مشاريع، مضاعفات، لعب).",
                .scoring: "تغطي حالات احتساب مثل الكبوت مع فشل طيّاح المشتري في نفس الجولة.",
                .projects: "تغطي تعادل المشاريع، واستثناء البلوت من المفاضلة، وتعدد مشاريع نفس الفريق.",
                .roundEnd: "الحالات مبنية على مواقف فعلية قابلة للحدوث في نهاية الجولة أو أثناء التصعيد والمزايدة.",
                .commonMistakes: "اعتبار حكم هذه الحالات اجتهادًا شخصيًا؛ كل حكم هنا مطابق لما يطبّقه محرك اللعب فعليًا."
            ]
        ),
        GameDefinition(
            slug: "hand",
            arabicTitle: "هاند",
            englishTitle: "Hand",
            shortDescription: "لعبة ورق ثنائية أو جماعية بسيطة تعتمد على مطابقة أو التخلص من الأوراق حسب قواعد متفق عليها.",
            category: .otherCardGame,
            playerCountText: "لاعبان إلى 4 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "hand.raised.fill",
            accentToken: "otherGames",
            isPlayable: true,
            sortOrder: 53,
            sections: [
                .objective: "التخلص من كل الأوراق في يد اللاعب قبل بقية اللاعبين، أو تحقيق أقل عدد نقاط متبقية بحسب الصيغة.",
                .playerCount: "من لاعبين حتى أربعة لاعبين، أفرادًا أو في فرق صغيرة.",
                .setup: "تُوزَّع الأوراق حسب عدد اللاعبين، وتُترك بقية الحزمة كسحب احتياطي إن كانت الصيغة تسمح بذلك.",
                .dealing: "عدد الأوراق لكل لاعب يعتمد على عدد اللاعبين والصيغة المعتمدة.",
                .cardRanking: "يعتمد الترتيب على الصيغة المحلية المتفق عليها بين اللاعبين قبل البدء.",
                .howToPlay: "يتناوب اللاعبون على اللعب أو المطابقة أو السحب حسب قواعد الصيغة المعتمدة، حتى يخلو أحدهم من الأوراق أو تنتهي الحزمة.",
                .scoring: "تُحتسب النتيجة عادة بعدّ الأوراق المتبقية بيد كل لاعب خاسر في نهاية الجولة.",
                .projects: "لا توجد مشاريع ثابتة؛ تعتمد اللعبة على قواعد مبسّطة متفق عليها.",
                .roundEnd: "تنتهي الجولة بخلوّ يد أحد اللاعبين من الأوراق أو باستنفاد الحزمة الاحتياطية.",
                .commonMistakes: "عدم الاتفاق المسبق على تفاصيل الصيغة المحلية المستخدمة، ما يسبب خلافًا أثناء اللعب."
            ]
        )
    ] + Self.otherCardGameReferences.map(\.gameDefinition)

    static let otherCardGameReferences: [CardGameReferenceDefinition] = [
        CardGameReferenceDefinition(
            slug: "bridge",
            arabicTitle: "بريدج",
            englishTitle: "Bridge",
            shortDescription: "لعبة شراكات عميقة تعتمد على مزايدة دقيقة ثم لعب الأكلات لتحقيق العقد.",
            playerCountText: "4 لاعبين (فريقان)",
            difficulty: .advanced,
            estimatedDuration: "30–60 دقيقة",
            iconName: "building.columns.fill",
            sortOrder: 54,
            objective: "تحقيق العقد الذي وصل إليه الفريق في المزايدة، أو إسقاط عقد الخصم دفاعيًا.",
            setup: "تُستخدم حزمة 52 ورقة، ويجلس الشريكان متقابلين. تبدأ الجولة بمزايدة تحدد النوع والعقد.",
            dealing: "تُوزَّع 13 ورقة لكل لاعب حتى تنتهي الحزمة كاملة.",
            cardRanking: "الآس أعلى ثم K ثم Q ثم J حتى 2، وقد يوجد نوع رابح حسب العقد.",
            howToPlay: "بعد المزايدة يلعب القائد واللاعب المكشوف وفق العقد، ويلتزم اللاعبون باتباع النوع إن أمكن.",
            scoring: "النقاط تعتمد على العقد، عدد الأكلات المطلوبة، وفشل أو نجاح الفريق في تحقيق الالتزام.",
            roundEnd: "تنتهي اليد بعد 13 أكلة، ثم تُحسب نتيجة العقد وتبدأ يد جديدة.",
            commonMistakes: "المزايدة بلا معلومات كافية للشريك أو كسر خطة العقد بلعب ورقة عالية في توقيت خاطئ."
        ),
        CardGameReferenceDefinition(
            slug: "poker-texas-holdem",
            arabicTitle: "بوكر تكساس هولدم",
            englishTitle: "Texas Hold'em Poker",
            shortDescription: "لعبة مراهنة وبناء أفضل يد من ورقتين خاصتين وخمس أوراق مشتركة.",
            playerCountText: "2 إلى 10 لاعبين",
            difficulty: .advanced,
            estimatedDuration: "حسب الطاولة",
            iconName: "suit.spade.fill",
            sortOrder: 55,
            objective: "الفوز بالرهان عبر أفضل تركيب من خمس أوراق أو دفع الخصوم للانسحاب.",
            setup: "يُحدَّد الموزع والرهانات الإجبارية، ثم تبدأ جولات المراهنة حول الطاولة.",
            dealing: "يحصل كل لاعب على ورقتين خاصتين، ثم تُكشف خمس أوراق مشتركة على مراحل.",
            cardRanking: "أقوى يد عادة Royal Flush ثم Straight Flush ثم Four of a Kind وصولًا إلى High Card.",
            howToPlay: "تتكرر المراهنة قبل الفلوب وبعده وبعد التيرن والريفر، ثم تُقارن الأيدي عند العرض النهائي.",
            scoring: "لا توجد نقاط ثابتة؛ الفائز يأخذ الرهان المتراكم في اليد.",
            roundEnd: "تنتهي اليد بانسحاب الجميع أمام لاعب واحد أو بمقارنة الأيدي بعد الورقة المشتركة الخامسة.",
            commonMistakes: "مطاردة يد ضعيفة بتكلفة عالية أو تجاهل موقع اللاعب وحجم الرهان."
        ),
        CardGameReferenceDefinition(
            slug: "blackjack",
            arabicTitle: "بلاك جاك",
            englishTitle: "Blackjack",
            shortDescription: "لعبة ضد الموزع هدفها الاقتراب من 21 دون تجاوزها.",
            playerCountText: "لاعب أو أكثر ضد الموزع",
            difficulty: .beginner,
            estimatedDuration: "دقائق لكل يد",
            iconName: "21.circle.fill",
            sortOrder: 56,
            objective: "الحصول على مجموع أعلى من الموزع دون تجاوز 21.",
            setup: "يلعب كل مشارك ضد الموزع مباشرة، وتُحتسب الآسات 1 أو 11 حسب مصلحة اليد.",
            dealing: "يحصل اللاعبون والموزع على ورقتين، وتبقى إحدى ورقتي الموزع مكشوفة غالبًا.",
            cardRanking: "الأرقام بقيمتها، الصور تساوي 10، والآس يساوي 1 أو 11.",
            howToPlay: "يختار اللاعب السحب أو الوقوف أو خيارات إضافية حسب الصيغة، ثم يكمل الموزع وفق قاعدة ثابتة.",
            scoring: "الفوز يكون عند هزيمة مجموع الموزع أو تجاوزه 21، والبلاك جاك الطبيعي له عائد أعلى في بعض الصيغ.",
            roundEnd: "تنتهي اليد بعد اكتمال قرارات اللاعبين ولعب الموزع، ثم تُسوّى النتائج.",
            commonMistakes: "السحب على مجموع قوي أمام ورقة موزع ضعيفة أو الوقوف مبكرًا أمام ورقة موزع قوية."
        ),
        CardGameReferenceDefinition(
            slug: "rummy",
            arabicTitle: "رمي",
            englishTitle: "Rummy",
            shortDescription: "لعبة تكوين مجموعات وتسلسلات من الأوراق ثم التخلص من الباقي.",
            playerCountText: "2 إلى 6 لاعبين",
            difficulty: .intermediate,
            estimatedDuration: "15–30 دقيقة",
            iconName: "rectangle.stack.fill",
            sortOrder: 57,
            objective: "تكوين مجموعات أو تسلسلات صحيحة وخفض قيمة الأوراق المتبقية في اليد.",
            setup: "تُستخدم حزمة أو أكثر حسب عدد اللاعبين، مع كومة سحب وكومة رمي.",
            dealing: "يُوزَّع عدد محدد من الأوراق لكل لاعب وتُترك بقية الحزمة للسحب.",
            cardRanking: "الترتيب الطبيعي A-2-3 حتى K، وقيمة الصور غالبًا 10.",
            howToPlay: "يسحب اللاعب ورقة، يحاول تكوين مجموعة أو تسلسل، ثم يرمي ورقة لينهي دوره.",
            scoring: "تُحسب قيمة الأوراق غير المركبة ضد اللاعب عند نهاية الجولة.",
            roundEnd: "تنتهي الجولة عندما يعلن لاعب إنهاء يده وفق الشروط المتفق عليها.",
            commonMistakes: "الاحتفاظ بأوراق عالية بلا خطة أو رمي ورقة تكمل تسلسل الخصم بوضوح."
        ),
        CardGameReferenceDefinition(
            slug: "gin-rummy",
            arabicTitle: "جِن رمي",
            englishTitle: "Gin Rummy",
            shortDescription: "نسخة ثنائية من الرمي تعتمد على تقليل الأوراق الميتة والإعلان في التوقيت المناسب.",
            playerCountText: "لاعبان",
            difficulty: .intermediate,
            estimatedDuration: "10–20 دقيقة",
            iconName: "person.2.fill",
            sortOrder: 58,
            objective: "تكوين مجموعات وتسلسلات وتقليل قيمة الأوراق غير المستخدمة قبل الإعلان.",
            setup: "يلعب لاعبان بحزمة 52 ورقة مع كومة سحب ورمي.",
            dealing: "تُوزَّع 10 أوراق لكل لاعب، وتبدأ كومة الرمي بورقة مكشوفة.",
            cardRanking: "الآس منخفض غالبًا، والتسلسلات تتبع الترتيب الطبيعي داخل نفس النوع.",
            howToPlay: "يسحب اللاعب من الكومة أو الرمي، ثم يرمي ورقة، ويحاول الوصول إلى Gin أو إعلان Knock.",
            scoring: "تُحسب الأوراق الميتة، وقد يحصل اللاعب على مكافأة إذا أنهى بلا أوراق زائدة.",
            roundEnd: "تنتهي الجولة عند إعلان Gin أو Knock أو نفاد السحب حسب القاعدة.",
            commonMistakes: "إظهار خطتك مبكرًا من خلال كومة الرمي أو الإعلان مع أوراق ميتة كثيرة."
        ),
        CardGameReferenceDefinition(
            slug: "hearts",
            arabicTitle: "هارتس",
            englishTitle: "Hearts",
            shortDescription: "لعبة تجنب نقاط سلبية؛ القلوب وملكة السبيت هي مصدر الخطر.",
            playerCountText: "4 لاعبين",
            difficulty: .intermediate,
            estimatedDuration: "20–40 دقيقة",
            iconName: "heart.fill",
            sortOrder: 59,
            objective: "تجنب أخذ القلوب وملكة السبيت لأنها تضيف نقاطًا سلبية.",
            setup: "تُستخدم حزمة 52 ورقة، وتُمرَّر أوراق بين اللاعبين في بعض الجولات.",
            dealing: "تُوزَّع 13 ورقة لكل لاعب.",
            cardRanking: "الترتيب الطبيعي داخل النوع من 2 إلى الآس.",
            howToPlay: "يلتزم اللاعبون باتباع النوع، ويحاولون تجنب الأكلات التي تحمل نقاطًا سلبية.",
            scoring: "كل قلب غالبًا نقطة سلبية، وملكة السبيت 13 نقطة سلبية.",
            roundEnd: "تنتهي الجولة بعد 13 أكلة وتُضاف النقاط السلبية لكل لاعب.",
            commonMistakes: "حمل أوراق عالية خطرة حتى النهاية أو كسر القلوب في توقيت يخدم الخصوم."
        ),
        CardGameReferenceDefinition(
            slug: "spades",
            arabicTitle: "سبيدز",
            englishTitle: "Spades",
            shortDescription: "لعبة شراكات فيها السبيت حكم دائم، والهدف تحقيق عدد الأكلات المعلن.",
            playerCountText: "4 لاعبين (فريقان)",
            difficulty: .intermediate,
            estimatedDuration: "20–35 دقيقة",
            iconName: "suit.spade.fill",
            sortOrder: 60,
            objective: "تحقيق عدد الأكلات الذي يعلنه الفريق مع كون السبيت هو النوع الرابح دائمًا.",
            setup: "يلعب شريكان ضد شريكين بحزمة 52 ورقة، ويعلن كل لاعب عدد الأكلات المتوقع.",
            dealing: "تُوزَّع 13 ورقة لكل لاعب.",
            cardRanking: "الآس أعلى داخل كل نوع، والسبيت يتغلب على كل الأنواع عند عدم اتباع النوع المطلوب.",
            howToPlay: "يجب اتباع النوع إن أمكن، ولا يبدأ السبيت عادة حتى ينكسر أو لا يبقى لدى اللاعب غيره.",
            scoring: "الفريق يكسب إذا حقق التزامه، وتوجد عقوبات للزيادة أو النقص حسب الصيغة.",
            roundEnd: "تنتهي الجولة بعد 13 أكلة وتُقارن الأكلات المحققة بالالتزام.",
            commonMistakes: "المبالغة في الالتزام أو صرف السبيت العالي قبل معرفة توزيع الأوراق."
        ),
        CardGameReferenceDefinition(
            slug: "whist",
            arabicTitle: "ويست",
            englishTitle: "Whist",
            shortDescription: "لعبة أكلات كلاسيكية تقوم على الشراكة واتباع النوع وجمع أكبر عدد من الأكلات.",
            playerCountText: "4 لاعبين (فريقان)",
            difficulty: .intermediate,
            estimatedDuration: "20–30 دقيقة",
            iconName: "person.3.sequence.fill",
            sortOrder: 61,
            objective: "جمع أكلات أكثر من الفريق الآخر عبر لعب منظم وقراءة يد الشريك.",
            setup: "تُستخدم حزمة 52 ورقة وشراكان متقابلان، وقد يحدد نوع رابح حسب الصيغة.",
            dealing: "تُوزَّع 13 ورقة لكل لاعب.",
            cardRanking: "الآس أعلى ثم K ثم Q ثم J حتى 2، والنوع الرابح يتفوق إذا كان معتمدًا.",
            howToPlay: "يقود لاعب ورقة، ويتبع الباقون النوع إن أمكن، وتفوز أعلى ورقة من النوع أو الرابح.",
            scoring: "تُحسب الأكلات الزائدة عن حد معين للفريق الفائز.",
            roundEnd: "تنتهي اليد بعد 13 أكلة وتُضاف النتيجة ثم ينتقل التوزيع.",
            commonMistakes: "عدم دعم الشريك أو كشف الأوراق العالية بلا حاجة."
        ),
        CardGameReferenceDefinition(
            slug: "euchre",
            arabicTitle: "يوكر",
            englishTitle: "Euchre",
            shortDescription: "لعبة أكلات سريعة بحزمة مختصرة ونوع رابح قوي.",
            playerCountText: "4 لاعبين (فريقان)",
            difficulty: .intermediate,
            estimatedDuration: "10–20 دقيقة",
            iconName: "bolt.fill",
            sortOrder: 62,
            objective: "تحقيق أغلب الأكلات في يد قصيرة باستخدام نوع رابح عالي التأثير.",
            setup: "تُستخدم عادة أوراق 9 إلى A، ويحدد اللاعبون النوع الرابح عبر عرض أو اختيار.",
            dealing: "يحصل كل لاعب غالبًا على 5 أوراق.",
            cardRanking: "أقوى ورقة هي ولد النوع الرابح، ثم ولد النوع من نفس اللون، ثم بقية الرابح.",
            howToPlay: "يلتزم اللاعبون باتباع النوع، ويقرر الفريق الملتزم هل يستطيع أخذ أغلب الأكلات.",
            scoring: "تحقيق الالتزام يمنح نقاطًا، والفشل يمنح الخصم نقاطًا أعلى.",
            roundEnd: "تنتهي اليد بعد 5 أكلات وتُحسب النتيجة بسرعة.",
            commonMistakes: "نسيان قوة الولد الثاني أو الالتزام بنوع رابح بلا دعم كاف."
        ),
        CardGameReferenceDefinition(
            slug: "canasta",
            arabicTitle: "كنستا",
            englishTitle: "Canasta",
            shortDescription: "لعبة تكوين مجموعات كبيرة من نفس الرتبة باستخدام حزمتين.",
            playerCountText: "2 إلى 6 لاعبين",
            difficulty: .advanced,
            estimatedDuration: "30–60 دقيقة",
            iconName: "square.stack.3d.up.fill",
            sortOrder: 63,
            objective: "تكوين كنستات من سبع أوراق أو أكثر من نفس الرتبة وجمع أعلى نقاط.",
            setup: "تُستخدم حزمتان مع جوكرات غالبًا، وتحدد الشراكات حسب عدد اللاعبين.",
            dealing: "يُوزَّع عدد أوراق متفق عليه وتبقى كومة سحب وكومة رمي.",
            cardRanking: "القيم تختلف؛ بعض الأوراق عالية النقاط وبعضها خاص مثل الجوكر والاثنين.",
            howToPlay: "يسحب اللاعب، يضع مجموعات صحيحة، وقد يأخذ كومة الرمي إذا استوفى الشروط.",
            scoring: "تُحسب نقاط المجموعات والكنستات وتُخصم قيمة الأوراق المتبقية.",
            roundEnd: "تنتهي الجولة عندما يخرج لاعب بعد تحقيق شروط النزول والكنستا.",
            commonMistakes: "فتح كومة الرمي للخصم أو الخروج قبل تحقيق قيمة كافية."
        ),
        CardGameReferenceDefinition(
            slug: "solitaire-klondike",
            arabicTitle: "سوليتير",
            englishTitle: "Klondike Solitaire",
            shortDescription: "لعبة فردية لترتيب الأوراق في أعمدة ثم بناء الأنواع من الآس إلى الملك.",
            playerCountText: "لاعب واحد",
            difficulty: .beginner,
            estimatedDuration: "5–15 دقيقة",
            iconName: "rectangle.portrait.on.rectangle.portrait.fill",
            sortOrder: 64,
            objective: "نقل كل الأوراق إلى قواعد الأنواع الأربعة مرتبة من الآس إلى الملك.",
            setup: "تُرتب سبعة أعمدة مع أوراق مخفية ومكشوفة، وتبقى كومة السحب جانبًا.",
            dealing: "يزداد عدد أوراق كل عمود تدريجيًا من عمود إلى سبعة أعمدة.",
            cardRanking: "الأعمدة تُبنى نزولًا وبألوان متبادلة، والقواعد تُبنى صعودًا حسب النوع.",
            howToPlay: "انقل الأوراق بين الأعمدة وافتح المخفي واسحب من الحزمة حتى تكتمل القواعد.",
            scoring: "الصيغ تختلف بين عد الحركات والوقت والنقاط، والهدف الأساسي هو إكمال البناء.",
            roundEnd: "تنتهي اللعبة عند نقل كل الأوراق إلى القواعد أو انعدام الحركات المفيدة.",
            commonMistakes: "نقل ورقة إلى القواعد مبكرًا إذا كانت تحتاجها لفتح عمود مخفي."
        ),
        CardGameReferenceDefinition(
            slug: "freecell",
            arabicTitle: "فري سيل",
            englishTitle: "FreeCell",
            shortDescription: "سوليتير مفتوح المعلومات يعتمد على خلايا مؤقتة لتفكيك الأعمدة.",
            playerCountText: "لاعب واحد",
            difficulty: .intermediate,
            estimatedDuration: "5–20 دقيقة",
            iconName: "square.grid.3x3.fill",
            sortOrder: 65,
            objective: "نقل كل الأوراق إلى القواعد باستخدام الخلايا الحرة كمساحات مؤقتة.",
            setup: "كل الأوراق مكشوفة منذ البداية في أعمدة، مع أربع خلايا حرة وأربع قواعد.",
            dealing: "تُوزَّع 52 ورقة على ثمانية أعمدة مكشوفة.",
            cardRanking: "الأعمدة تُبنى نزولًا بألوان متبادلة، والقواعد صعودًا من الآس.",
            howToPlay: "انقل أوراقًا بين الأعمدة والخلايا الحرة مع الحفاظ على مساحات كافية للحركة.",
            scoring: "النجاح يقاس بإكمال اللعبة، ويمكن إضافة عد للحركات أو الوقت.",
            roundEnd: "تنتهي عند اكتمال القواعد الأربع أو انسداد الحركة.",
            commonMistakes: "ملء الخلايا الحرة مبكرًا حتى تتوقف القدرة على نقل السلاسل."
        ),
        CardGameReferenceDefinition(
            slug: "spider-solitaire",
            arabicTitle: "سبايدر سوليتير",
            englishTitle: "Spider Solitaire",
            shortDescription: "لعبة فردية لبناء سلاسل كاملة من الملك إلى الآس ثم إزالتها.",
            playerCountText: "لاعب واحد",
            difficulty: .intermediate,
            estimatedDuration: "10–30 دقيقة",
            iconName: "rectangle.grid.3x2.fill",
            sortOrder: 66,
            objective: "تكوين سلاسل كاملة مرتبة من K إلى A من نفس النوع لإزالتها من الطاولة.",
            setup: "تُستخدم حزمتان وتختلف الصعوبة حسب عدد الأنواع المستخدمة.",
            dealing: "تُوزَّع أعمدة متعددة مع بعض الأوراق المخفية، وتبقى رزم توزيع إضافية.",
            cardRanking: "البناء نزولي من الملك إلى الآس، وتكتمل السلسلة عندما تكون من نفس النوع.",
            howToPlay: "انقل السلاسل الممكنة وافتح الأوراق المخفية، ثم وزع صفًا جديدًا عند الحاجة.",
            scoring: "يعتمد غالبًا على عدد الحركات والوقت وعدد السلاسل المكتملة.",
            roundEnd: "تنتهي عند إزالة كل السلاسل أو تعذر التقدم عمليًا.",
            commonMistakes: "توزيع صف جديد قبل تنظيف الأعمدة أو فتح أوراق مخفية كافية."
        ),
        CardGameReferenceDefinition(
            slug: "crazy-eights",
            arabicTitle: "كريزي إيتس",
            englishTitle: "Crazy Eights",
            shortDescription: "لعبة تخلص سريعة تعتمد على مطابقة النوع أو الرقم، والثمانية ورقة تغيير.",
            playerCountText: "2 إلى 7 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "5–15 دقيقة",
            iconName: "8.circle.fill",
            sortOrder: 67,
            objective: "التخلص من كل أوراقك قبل الآخرين عبر المطابقة أو تغيير النوع.",
            setup: "تُوزَّع يد لكل لاعب وتبدأ كومة رمي بورقة مكشوفة.",
            dealing: "عدد الأوراق يختلف حسب عدد اللاعبين، وتبقى بقية الحزمة للسحب.",
            cardRanking: "لا يعتمد الفوز على ترتيب قوة؛ الأهم مطابقة الرقم أو النوع.",
            howToPlay: "يلعب اللاعب ورقة تطابق الرقم أو النوع، أو يلعب 8 لتغيير النوع، وإلا يسحب.",
            scoring: "تُحسب قيمة أوراق الخصوم المتبقية للفائز أو ضدهم حسب الصيغة.",
            roundEnd: "تنتهي الجولة عندما يفرغ أحد اللاعبين يده.",
            commonMistakes: "استخدام ورقة الثمانية مبكرًا دون حاجة أو نسيان تغيير النوع لمصلحة اليد."
        ),
        CardGameReferenceDefinition(
            slug: "old-maid",
            arabicTitle: "العانس",
            englishTitle: "Old Maid",
            shortDescription: "لعبة خفيفة تعتمد على تكوين أزواج وتجنب بقاء الورقة الوحيدة في يدك.",
            playerCountText: "2 إلى 8 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "5–15 دقيقة",
            iconName: "person.crop.circle.badge.questionmark",
            sortOrder: 68,
            objective: "التخلص من الأزواج وتجنب أن تبقى الورقة الوحيدة غير المطابقة في يدك.",
            setup: "تُزال ورقة واحدة أو يستخدم جوكر/ملكة كالعانس حسب الصيغة.",
            dealing: "تُوزَّع كل الأوراق على اللاعبين وقد لا تتساوى الأعداد تمامًا.",
            cardRanking: "لا توجد قوة للأوراق؛ المطابقة تكون حسب الرتبة فقط.",
            howToPlay: "يسحب كل لاعب ورقة من يد اللاعب المجاور، ويطرح أي زوج يتكوّن لديه.",
            scoring: "غالبًا لا توجد نقاط؛ الخاسر هو من تبقى معه الورقة الوحيدة.",
            roundEnd: "تنتهي عندما تُطرح كل الأزواج وتبقى ورقة واحدة مع لاعب.",
            commonMistakes: "كشف ترتيب اليد أو عدم طرح الزوج فور تكوّنه حسب الصيغة."
        ),
        CardGameReferenceDefinition(
            slug: "go-fish",
            arabicTitle: "جو فيش",
            englishTitle: "Go Fish",
            shortDescription: "لعبة عائلية لجمع مجموعات من نفس الرتبة عبر سؤال اللاعبين والسحب.",
            playerCountText: "2 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "5–20 دقيقة",
            iconName: "questionmark.bubble.fill",
            sortOrder: 69,
            objective: "جمع أكبر عدد من مجموعات الرتب الكاملة.",
            setup: "تُوزَّع يد أولية لكل لاعب وتبقى كومة سحب في الوسط.",
            dealing: "عدد الأوراق الموزعة يختلف حسب عدد اللاعبين، غالبًا 5 أو 7.",
            cardRanking: "لا توجد قوة ترتيب؛ المطلوب جمع الرتب المتطابقة.",
            howToPlay: "تسأل لاعبًا عن رتبة تملك منها ورقة، فإن لم يملكها تسحب من الكومة.",
            scoring: "كل مجموعة مكتملة تمنح نقطة أو تُعد كتابًا للفائز.",
            roundEnd: "تنتهي عندما تكتمل كل المجموعات أو تنفد الأيدي والكومة.",
            commonMistakes: "سؤال عن رتبة لا تملكها أو نسيان من طلب أي رتبة سابقًا."
        ),
        CardGameReferenceDefinition(
            slug: "war",
            arabicTitle: "حرب",
            englishTitle: "War",
            shortDescription: "لعبة مقارنة مباشرة؛ أعلى ورقة تكسب الكومة، والتعادل يفتح حربًا.",
            playerCountText: "لاعبان غالبًا",
            difficulty: .beginner,
            estimatedDuration: "10–30 دقيقة",
            iconName: "shield.lefthalf.filled",
            sortOrder: 70,
            objective: "كسب كل أوراق الخصم عبر مقارنات متتالية.",
            setup: "تُقسم الحزمة بالتساوي بين اللاعبين دون رؤية ترتيب الأوراق.",
            dealing: "يحصل كل لاعب على نصف الحزمة مقلوبة.",
            cardRanking: "الآس أعلى ثم K حتى 2.",
            howToPlay: "يكشف كل لاعب أعلى ورقة، والأعلى يأخذ الورقتين؛ عند التعادل توضع أوراق إضافية ثم تقارن ورقة جديدة.",
            scoring: "لا توجد نقاط؛ الفوز بجمع كل الأوراق.",
            roundEnd: "تنتهي عندما يمتلك لاعب كل الأوراق أو يتفق اللاعبان على التوقف.",
            commonMistakes: "عدم الاتفاق على عدد الأوراق الموضوعة عند التعادل قبل بدء اللعب."
        ),
        CardGameReferenceDefinition(
            slug: "president",
            arabicTitle: "بريزيدنت",
            englishTitle: "President",
            shortDescription: "لعبة تخلص وترتيب اجتماعي؛ اللاعب يتخلص من أوراقه أولًا ليحصل على رتبة أعلى.",
            playerCountText: "3 إلى 8 لاعبين",
            difficulty: .intermediate,
            estimatedDuration: "15–30 دقيقة",
            iconName: "crown.fill",
            sortOrder: 71,
            objective: "التخلص من كل الأوراق مبكرًا والحفاظ على رتبة اجتماعية أعلى في الجولات التالية.",
            setup: "تُستخدم حزمة 52 ورقة، وقد تُضاف قواعد للاثنين أو الجوكر حسب الصيغة.",
            dealing: "تُوزَّع كل الأوراق على اللاعبين.",
            cardRanking: "تختلف الصيغ، وغالبًا يكون 2 عاليًا جدًا والآس أعلى من الملك.",
            howToPlay: "يلعب اللاعب مجموعة من نفس الرتبة، وعلى التالي لعب مجموعة أقوى بنفس العدد أو التمرير.",
            scoring: "الترتيب النهائي للاعبين يحدد الرتب أو النقاط في الجولة التالية.",
            roundEnd: "تنتهي الجولة عندما يتخلص الجميع من أوراقهم ما عدا الأخير.",
            commonMistakes: "صرف ورقة كسر قوية مبكرًا أو تمرير فرصة تمنع خصمًا من إنهاء يده."
        ),
        CardGameReferenceDefinition(
            slug: "durak",
            arabicTitle: "دوراك",
            englishTitle: "Durak",
            shortDescription: "لعبة هجوم ودفاع روسية؛ الهدف ألا تكون آخر لاعب يحمل أوراقًا.",
            playerCountText: "2 إلى 6 لاعبين",
            difficulty: .intermediate,
            estimatedDuration: "15–30 دقيقة",
            iconName: "arrow.up.shield.fill",
            sortOrder: 72,
            objective: "التخلص من الأوراق وعدم البقاء آخر لاعب يحمل يدًا.",
            setup: "تُستخدم غالبًا حزمة 36 ورقة، وتُكشف ورقة لتحديد نوع الحكم.",
            dealing: "يحصل كل لاعب على ست أوراق، ويُستكمل السحب بعد كل هجوم حتى تنفد الحزمة.",
            cardRanking: "داخل النوع يكون الآس أعلى، والحكم يتغلب على غير الحكم.",
            howToPlay: "يهاجم لاعب بورقة، ويدافع الآخر بورقة أعلى من نفس النوع أو حكم، ثم تُضاف هجمات مطابقة للرتب المفتوحة.",
            scoring: "غالبًا لا توجد نقاط؛ الخاسر هو آخر من يبقى معه أوراق.",
            roundEnd: "تنتهي عندما يتخلص الجميع من أوراقهم ويبقى لاعب واحد.",
            commonMistakes: "استخدام الحكم العالي للدفاع عن ورقة رخيصة أو الهجوم بما يساعد الخصم على التخلص."
        ),
        CardGameReferenceDefinition(
            slug: "pinochle",
            arabicTitle: "بينوكل",
            englishTitle: "Pinochle",
            shortDescription: "لعبة مزايدة وأكلات ومجموعات خاصة بحزمة مكررة.",
            playerCountText: "2 إلى 4 لاعبين",
            difficulty: .advanced,
            estimatedDuration: "30–60 دقيقة",
            iconName: "diamond.circle.fill",
            sortOrder: 73,
            objective: "الفوز بالمزايدة ثم جمع نقاط من المجموعات والأكلات لتحقيق العقد.",
            setup: "تُستخدم حزمة بينوكل خاصة غالبًا من أوراق 9 إلى A مكررة.",
            dealing: "تُوزَّع الأوراق حسب عدد اللاعبين والصيغة المعتمدة.",
            cardRanking: "الترتيب الشائع A ثم 10 ثم K ثم Q ثم J ثم 9، مع نوع رابح.",
            howToPlay: "تبدأ بمزايدة، ثم إعلان مجموعات، ثم لعب أكلات مع اتباع النوع والرابح.",
            scoring: "النقاط تأتي من الإعلانات والأوراق الرابحة في الأكلات، مع شرط تحقيق العقد.",
            roundEnd: "تنتهي اليد بعد لعب كل الأكلات وحساب العقد والإعلانات.",
            commonMistakes: "رفع المزايدة دون إعلانات كافية أو نسيان قيمة العشرات والآسات في الأكلات."
        ),
        CardGameReferenceDefinition(
            slug: "cribbage",
            arabicTitle: "كريبج",
            englishTitle: "Cribbage",
            shortDescription: "لعبة ثنائية غالبًا تجمع بين تكوين مجموعات وعدّ نقاط أثناء اللعب وبعده.",
            playerCountText: "لاعبان غالبًا",
            difficulty: .intermediate,
            estimatedDuration: "15–30 دقيقة",
            iconName: "number.circle.fill",
            sortOrder: 74,
            objective: "الوصول إلى مجموع نقاط الهدف عبر عدّ التركيبات أثناء اللعب وبعد كشف الأيدي.",
            setup: "يستخدم اللاعبان حزمة 52 ورقة ولوحة نقاط عادة، ويكوّن الموزع صندوقًا يسمى crib.",
            dealing: "تُوزَّع ست أوراق لكل لاعب غالبًا، ثم يتخلص كل لاعب من ورقتين إلى crib.",
            cardRanking: "الأوراق بقيمها للعد، والصور تساوي 10، والآس يساوي 1.",
            howToPlay: "يلعب اللاعبان أوراقًا بالتناوب مع عدّ المجموع حتى 31، ثم تُحتسب تركيبات اليد.",
            scoring: "النقاط تأتي من 15، الأزواج، السلاسل، الفلش، وnobs حسب الصيغة.",
            roundEnd: "تنتهي اليد بعد اللعب وعدّ يد غير الموزع ثم الموزع ثم crib.",
            commonMistakes: "اختيار أوراق سيئة للـcrib أو تفويت نقاط السلاسل أثناء العد."
        ),
        CardGameReferenceDefinition(
            slug: "skat",
            arabicTitle: "سكيت",
            englishTitle: "Skat",
            shortDescription: "لعبة ألمانية لثلاثة لاعبين تعتمد على مزايدة معقدة وعقود متعددة.",
            playerCountText: "3 لاعبين",
            difficulty: .advanced,
            estimatedDuration: "20–40 دقيقة",
            iconName: "triangle.fill",
            sortOrder: 75,
            objective: "يفوز اللاعب المنفرد بعقده ضد اللاعبين الآخرين إذا حقق شروط النقاط أو العقد.",
            setup: "تُستخدم حزمة 32 ورقة، وتوجد ورقتان جانبًا باسم Skat يدخلان في قرار العقد.",
            dealing: "يحصل كل لاعب على 10 أوراق وتُترك ورقتان في الوسط.",
            cardRanking: "ترتيب الأوراق يعتمد على نوع العقد؛ الأولاد لهم دور خاص في عقود النوع.",
            howToPlay: "بعد المزايدة يعلن الفائز العقد، ثم يلعب منفردًا ضد الاثنين مع الالتزام بالنوع.",
            scoring: "النتيجة تعتمد على قيمة العقد والمضاعفات وحالات الفوز أو الخسارة.",
            roundEnd: "تنتهي بعد 10 أكلات ثم تُقارن نقاط اللاعب المنفرد بشروط العقد.",
            commonMistakes: "اختيار عقد أعلى من قدرة اليد أو سوء تقدير قيمة الأولاد."
        ),
        CardGameReferenceDefinition(
            slug: "belote",
            arabicTitle: "بيلوت",
            englishTitle: "Belote",
            shortDescription: "قريبة من عائلة ألعاب الأكلات وفيها نوع حكم وإعلانات، لكنها تختلف عن البلوت الخليجي.",
            playerCountText: "4 لاعبين (فريقان)",
            difficulty: .intermediate,
            estimatedDuration: "20–40 دقيقة",
            iconName: "suit.heart.fill",
            sortOrder: 76,
            objective: "جمع نقاط أكثر من الفريق الآخر بعد اختيار نوع الحكم والإعلانات.",
            setup: "تُستخدم حزمة 32 ورقة، ويجلس الشريكان متقابلين.",
            dealing: "تُوزَّع 8 أوراق لكل لاعب بصيغ تختلف حسب البلد.",
            cardRanking: "في الحكم يكون J ثم 9 قويين، وفي غير الحكم يتغير ترتيب القوة والقيمة.",
            howToPlay: "يلتزم اللاعبون باتباع النوع، وتؤثر الإعلانات مثل Belote على النتيجة.",
            scoring: "تُجمع قيم الأوراق والأكلات والإعلانات، ويُشترط تحقيق الفريق الملتزم لنقاط كافية.",
            roundEnd: "تنتهي بعد 8 أكلات وتُحتسب النقاط ثم تبدأ يد جديدة.",
            commonMistakes: "خلط قواعد بيلوت الأوروبية مع البلوت المحلي رغم تشابه الأسماء وبعض الأوراق."
        ),
        CardGameReferenceDefinition(
            slug: "hokm",
            arabicTitle: "حكم",
            englishTitle: "Hokm",
            shortDescription: "لعبة أكلات فارسية/شرق أوسطية يحدد فيها الحاكم نوع الحكم ويحاول الفريق جمع أكثر الأكلات.",
            playerCountText: "4 لاعبين غالبًا",
            difficulty: .intermediate,
            estimatedDuration: "20–40 دقيقة",
            iconName: "crown.circle.fill",
            sortOrder: 77,
            objective: "الفوز بأغلب الأكلات باستخدام نوع الحكم الذي يختاره الحاكم.",
            setup: "يُحدد الحاكم، ثم يختار نوع الحكم بعد رؤية جزء من يده حسب الصيغة.",
            dealing: "تُوزَّع 13 ورقة لكل لاعب من حزمة 52 ورقة.",
            cardRanking: "الآس أعلى ثم K ثم Q ثم J حتى 2، والحكم يتغلب على بقية الأنواع.",
            howToPlay: "يقود اللاعب ورقة، ويلتزم الآخرون بالنوع إن أمكن، وإلا يمكنهم القطع بالحكم.",
            scoring: "الفريق الذي يحقق عدد الأكلات المطلوب يكسب الجولة، وتختلف سلسلة الفوز حسب الصيغة.",
            roundEnd: "تنتهي اليد بعد 13 أكلة أو عند حسم الفريق للفوز بعدد كاف من الأكلات.",
            commonMistakes: "اختيار حكم قصير بلا أوراق عالية أو قطع أكلة كان الشريك سيفوز بها."
        ),
        CardGameReferenceDefinition(
            slug: "estimation",
            arabicTitle: "إستيميشن",
            englishTitle: "Estimation",
            shortDescription: "لعبة مزايدة فردية أو جماعية يلتزم فيها اللاعب بعدد أكلات محدد.",
            playerCountText: "4 لاعبين غالبًا",
            difficulty: .advanced,
            estimatedDuration: "30–60 دقيقة",
            iconName: "chart.bar.fill",
            sortOrder: 78,
            objective: "تقدير عدد الأكلات المتوقع بدقة ثم تحقيق الالتزام أثناء اللعب.",
            setup: "تُستخدم حزمة 52 ورقة وتبدأ مزايدة يعلن فيها اللاعبون تقديراتهم.",
            dealing: "تُوزَّع 13 ورقة لكل لاعب.",
            cardRanking: "الآس أعلى عادة، وقد يحدد نوع حكم أو عقد خاص حسب الصيغة.",
            howToPlay: "بعد الالتزامات، تُلعب الأكلات مع اتباع النوع، ويحاول كل لاعب تحقيق رقمه لا أكثر ولا أقل في بعض الصيغ.",
            scoring: "الدقة في الالتزام تمنح نقاطًا، والخطأ يزيد الخصم أو يخصم من اللاعب حسب النظام.",
            roundEnd: "تنتهي بعد 13 أكلة وتُقارن النتائج بالتقديرات المعلنة.",
            commonMistakes: "تقدير اليد بعدد أكلات عاطفي بدل حساب الأوراق العالية وموقع اللعب."
        ),
        CardGameReferenceDefinition(
            slug: "basra",
            arabicTitle: "بسرة",
            englishTitle: "Basra",
            shortDescription: "لعبة تجميع أوراق من الأرض بقيم مطابقة أو مجموعات، مشهورة في عدة بلدان عربية.",
            playerCountText: "2 إلى 4 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–25 دقيقة",
            iconName: "tray.full.fill",
            sortOrder: 79,
            objective: "جمع أكبر قيمة من الأوراق من الأرض وتحقيق بَسرات عند تنظيف الطاولة.",
            setup: "تُستخدم حزمة 52 ورقة، وتوضع أوراق مكشوفة في الوسط كبداية.",
            dealing: "تُوزَّع أوراق على اللاعبين على دفعات، وتُعاد الدفعات حتى تنتهي الحزمة.",
            cardRanking: "لا تعتمد على ترتيب قوة تقليدي؛ المهم قيمة الورقة وقدرتها على جمع أوراق من الوسط.",
            howToPlay: "يلعب اللاعب ورقة لجمع أوراق مساوية أو مجموعات تحقق نفس القيمة، أو يضعها في الوسط إذا لم يجمع.",
            scoring: "النقاط تأتي من عدد الأوراق، أوراق معينة، والبسرة عند تنظيف الوسط حسب الصيغة.",
            roundEnd: "تنتهي الجولة بعد نفاد أوراق اللاعبين والحزمة ثم تُحسب الأوراق المجموعة.",
            commonMistakes: "ترك فرصة بسرة سهلة للخصم أو جمع أوراق قليلة القيمة بدل انتظار تنظيف أقوى."
        ),
        CardGameReferenceDefinition(
            slug: "seven-diamonds",
            arabicTitle: "سبعة الديمن",
            englishTitle: "Seven of Diamonds",
            shortDescription: "لعبة مجالس تعتمد على تجنب ورقة سبعة الديمن لأنها ورقة العقوبة الأساسية.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "suit.diamond.fill",
            sortOrder: 80,
            objective: "تجنب أخذ ورقة 7 ديمن في أكلاتك، أو دفع الخصوم لأخذها في توقيت محسوب.",
            setup: "تُستخدم حزمة 52 ورقة غالبًا. يتفق اللاعبون قبل البدء هل العقوبة على سبعة الديمن وحدها أو معها أوراق إضافية.",
            dealing: "تُوزَّع الأوراق بالتساوي قدر الإمكان، وقد تبقى أوراق خارج اللعب حسب عدد اللاعبين.",
            cardRanking: "الآس أعلى ثم K ثم Q ثم J حتى 2، ما لم يتفق المجلس على ترتيب مختلف.",
            howToPlay: "يلعب اللاعبون أكلات مع اتباع النوع المطلوب. من يأخذ الأكلة التي تحتوي 7 ديمن يتحمل عقوبتها.",
            scoring: "تُسجل عقوبة على صاحب أكلة 7 ديمن، والفائز عادة صاحب أقل عقوبات بعد عدد محدد من الجولات.",
            roundEnd: "تنتهي الجولة بعد نفاد الأوراق، ثم تُراجع الأكلات لمعرفة من أخذ 7 ديمن.",
            commonMistakes: "رمي 7 ديمن مبكرًا في أكلة قد تعود لك، أو تجاهل تتبع أوراق الديمن العالية."
        ),
        CardGameReferenceDefinition(
            slug: "queen-spades",
            arabicTitle: "بنت السبيت",
            englishTitle: "Queen of Spades",
            shortDescription: "لعبة عقوبة مشهورة: بنت السبيت هي الورقة الأخطر ويجب تجنب أخذها.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "suit.spade.fill",
            sortOrder: 81,
            objective: "تجنب الفوز بالأكلة التي تحتوي Q سبيت، أو إجبار خصم عليها.",
            setup: "تُستخدم حزمة 52 ورقة، وتُحدد قيمة عقوبة بنت السبيت قبل البداية.",
            dealing: "تُوزَّع الأوراق بالتساوي قدر الإمكان بين اللاعبين.",
            cardRanking: "الآس أعلى ثم K ثم Q ثم J حتى 2. بنت السبيت ليست الأقوى دائمًا لكنها تحمل العقوبة.",
            howToPlay: "اتبع النوع المطلوب إن توفر. حاول تفريغ السبيت أو حفظ ورقة أعلى/أقل حسب خطة التخلص من البنت.",
            scoring: "من يأخذ Q سبيت تسجل عليه عقوبة كبيرة، والفائز هو الأقل عقوبات.",
            roundEnd: "بعد نهاية الأوراق تُفحص الأكلات وتُضاف عقوبة بنت السبيت لمن أخذها.",
            commonMistakes: "الاحتفاظ بسبيت عالي طويلًا حتى تُجبر على أخذ بنت السبيت."
        ),
        CardGameReferenceDefinition(
            slug: "sahbiya",
            arabicTitle: "السحبية",
            englishTitle: "Draw Game",
            shortDescription: "لعبة سحب ومطابقة سريعة؛ اللاعب يسحب عند عدم قدرته على مطابقة الورقة المفتوحة.",
            playerCountText: "2 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "5–15 دقيقة",
            iconName: "square.stack.3d.down.forward.fill",
            sortOrder: 82,
            objective: "التخلص من أوراقك قبل الآخرين عبر المطابقة أو السحب عند عدم وجود حركة.",
            setup: "توضع ورقة مفتوحة في الوسط وبقية الحزمة للسحب. يتفق اللاعبون على الورق الحر أو العقوبات الإضافية.",
            dealing: "يوزَّع عدد ثابت من الأوراق لكل لاعب، غالبًا 5 إلى 7 حسب سرعة المجلس.",
            cardRanking: "لا تعتمد على القوة؛ المطابقة تكون حسب الرقم أو النوع.",
            howToPlay: "إذا امتلكت ورقة من نفس الرقم أو النوع العبها. إذا لم تملك، اسحب من الحزمة حتى تتوفر حركة أو ينتهي دورك حسب الاتفاق.",
            scoring: "الفائز من ينهي يده أولًا، ويمكن حساب أوراق الخاسرين كنقاط ضدهم.",
            roundEnd: "تنتهي عند خلو يد لاعب أو نفاد الحزمة وتعذر اللعب.",
            commonMistakes: "سحب أوراق كثيرة رغم وجود حركة قانونية، أو تغيير قواعد السحب أثناء الجولة."
        ),
        CardGameReferenceDefinition(
            slug: "jack-clubs",
            arabicTitle: "ولد الشريا",
            englishTitle: "Jack of Clubs",
            shortDescription: "نمط عقوبة محلي تكون فيه ورقة J شريا ورقة مرصودة عالية الأثر.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "suit.club.fill",
            sortOrder: 83,
            objective: "تجنب أخذ ولد الشريا أو استخدامه لإجبار خصم على العقوبة.",
            setup: "تُحدد قيمة عقوبة J شريا قبل بدء الجولة، وهل توجد أوراق عقوبة أخرى معه.",
            dealing: "تُوزَّع الأوراق بالتساوي حسب عدد اللاعبين.",
            cardRanking: "ترتيب القوة العادي من A إلى 2، والولد يحمل العقوبة بغض النظر عن قوته النسبية.",
            howToPlay: "اتبع النوع المطلوب وحاول مراقبة أوراق الشريا العالية قبل رمي ولد الشريا.",
            scoring: "تسجل العقوبة على اللاعب الذي يفوز بالأكلة المحتوية على J شريا.",
            roundEnd: "تنتهي الجولة بنفاد الأوراق ثم تُراجع الأكلات المرصودة.",
            commonMistakes: "رمي الولد في أكلة غير مضمونة أو نسيان أن الخصم قد يملك شريا أعلى."
        ),
        CardGameReferenceDefinition(
            slug: "king-hearts",
            arabicTitle: "شايب الهاص",
            englishTitle: "King of Hearts",
            shortDescription: "نمط عقوبة محلي يركز على تجنب شايب الهاص ضمن ألعاب الأكلات.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "heart.circle.fill",
            sortOrder: 84,
            objective: "تجنب أخذ K هاص عندما يكون ورقة العقوبة المتفق عليها.",
            setup: "يتفق اللاعبون على قيمة عقوبة شايب الهاص وهل الهاص كله عقوبة أو الشايب فقط.",
            dealing: "تُوزَّع الحزمة بين اللاعبين بالتساوي قدر الإمكان.",
            cardRanking: "الآس أعلى من الشايب غالبًا، ثم Q وJ حتى 2.",
            howToPlay: "تتبع الهاص الخارج وحاول ألا تقود الهاص إذا كان قد يجبرك على أخذ الشايب.",
            scoring: "من يأخذ K هاص تُضاف عليه عقوبة الجولة.",
            roundEnd: "بعد نهاية الأوراق تُحسب عقوبة شايب الهاص على صاحب الأكلة.",
            commonMistakes: "عدم حفظ خروج A هاص قبل تقييم أمان رمي K هاص."
        ),
        CardGameReferenceDefinition(
            slug: "diamonds-collector",
            arabicTitle: "تجميع الديمن",
            englishTitle: "Diamonds Collector",
            shortDescription: "لعبة تجميع يكون الديمن فيها مصدر النقاط بدل كونه عقوبة.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "diamond.circle.fill",
            sortOrder: 85,
            objective: "اكسب أكبر عدد من أوراق الديمن داخل أكلاتك.",
            setup: "تُستخدم حزمة 52 ورقة، وتُحدد قيمة كل ديمن أو بعض أوراق الديمن قبل اللعب.",
            dealing: "تُوزَّع الأوراق بالتساوي قدر الإمكان.",
            cardRanking: "الترتيب العادي A ثم K حتى 2، ولا يوجد حكم إلا إذا اتفق المجلس.",
            howToPlay: "اتبع النوع المطلوب، وحاول أخذ الأكلات التي تحمل ديمنًا كثيرًا أو ديمنًا عالي القيمة.",
            scoring: "تضاف نقطة أو قيمة متفق عليها لكل ورقة ديمن يحصل عليها اللاعب.",
            roundEnd: "تنتهي الجولة بنفاد الأوراق ثم تُجمع أوراق الديمن لدى كل لاعب.",
            commonMistakes: "أخذ أكلة فارغة من الديمن بورقة عالية، أو ترك أكلة ديمن سهلة للخصم."
        ),
        CardGameReferenceDefinition(
            slug: "hearts-penalty",
            arabicTitle: "عقوبة الهاص",
            englishTitle: "Hearts Penalty",
            shortDescription: "نمط مجالس بسيط: كل ورقة هاص تؤثر على نتيجة اللاعب الذي يأخذها.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "suit.heart.fill",
            sortOrder: 86,
            objective: "تجنب أخذ أوراق الهاص، خصوصًا عندما تتجمع في أكلة واحدة.",
            setup: "يحدد اللاعبون هل كل هاص بنقطة عقوبة أو أن بعض أوراق الهاص أعلى قيمة.",
            dealing: "تُوزَّع الحزمة بالتساوي حسب عدد اللاعبين.",
            cardRanking: "ترتيب القوة عادي، والهاص يحمل العقوبة عند دخوله في الأكلة.",
            howToPlay: "اتبع النوع المطلوب، وحاول تفريغ الهاص بذكاء عندما لا تستطيع أخذ الأكلة.",
            scoring: "كل ورقة هاص تُحسب عقوبة على صاحب الأكلة.",
            roundEnd: "تنتهي الجولة بنهاية الأوراق ثم تُجمع عقوبات الهاص.",
            commonMistakes: "قيادة الهاص مبكرًا قبل معرفة توزيع الأوراق العالية."
        ),
        CardGameReferenceDefinition(
            slug: "queens-penalty",
            arabicTitle: "عقوبة البنات",
            englishTitle: "Queens Penalty",
            shortDescription: "لعبة تجنب: كل بنت تحمل عقوبة، وبنت السبيت قد تكون الأعلى قيمة.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "person.crop.square.fill",
            sortOrder: 87,
            objective: "تجنب أخذ البنات في الأكلات، أو تمريرها للخصوم عند توفر فرصة.",
            setup: "تُحدد قيمة كل بنت وهل بنت السبيت مضاعفة قبل بدء الجولة.",
            dealing: "تُوزَّع الأوراق بالتساوي قدر الإمكان.",
            cardRanking: "الآس أعلى من الملك ثم البنت ثم الولد حتى 2.",
            howToPlay: "اتبع النوع المطلوب، وتخلص من البنات عندما تكون الأكلة للخصم غالبًا.",
            scoring: "كل بنت تضيف عقوبة، وقد تختلف قيمة بنت السبيت حسب اتفاق المجلس.",
            roundEnd: "بعد نفاد الأوراق تُراجع الأكلات وتُحسب البنات.",
            commonMistakes: "حمل البنات حتى نهاية الجولة مع نفاد الخيارات الآمنة."
        ),
        CardGameReferenceDefinition(
            slug: "last-two",
            arabicTitle: "آخر ورقتين",
            englishTitle: "Last Two",
            shortDescription: "نمط سريع يجعل آخر ورقتين في الجولة ذات قيمة خاصة في التسجيل.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "5–15 دقيقة",
            iconName: "2.circle.fill",
            sortOrder: 88,
            objective: "السيطرة على آخر الأكلات أو تجنبها حسب هل آخر ورقتين مكافأة أو عقوبة.",
            setup: "يتفق اللاعبون هل آخر ورقتين تمنح نقاطًا للفائز بها أو تُحسب عليه عقوبة.",
            dealing: "تُوزَّع الأوراق بالتساوي، ويُحفظ تسلسل اللعب حتى آخر دورين.",
            cardRanking: "الترتيب العادي A إلى 2 مع اتباع النوع المطلوب.",
            howToPlay: "لا تصرف أوراق السيطرة كلها في البداية؛ احتفظ بورقة تقود آخر الأكلات عند الحاجة.",
            scoring: "آخر ورقتين أو آخر أكلتين تُحسب بقيمة خاصة حسب الاتفاق.",
            roundEnd: "تنتهي الجولة بعد آخر ورقة وتُطبق قيمة آخر ورقتين.",
            commonMistakes: "إهمال التخطيط للنهاية وكسب نقاط قليلة مع خسارة آخر ورقتين."
        ),
        CardGameReferenceDefinition(
            slug: "no-tricks",
            arabicTitle: "بدون أكلات",
            englishTitle: "No Tricks",
            shortDescription: "نمط تجنب كامل: الهدف ألا تكسب أكلات إطلاقًا أو تكسب أقل عدد ممكن.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .intermediate,
            estimatedDuration: "10–20 دقيقة",
            iconName: "nosign",
            sortOrder: 89,
            objective: "تجنب أخذ الأكلات قدر الإمكان.",
            setup: "تُستخدم حزمة عادية، ويتفق اللاعبون على عقوبة كل أكلة.",
            dealing: "تُوزَّع الأوراق بالتساوي قدر الإمكان.",
            cardRanking: "القوة العادية من A إلى 2. الورقة الأعلى من النوع المطلوب تكسب الأكلة.",
            howToPlay: "اتبع النوع المطلوب وحاول رمي أوراق متوسطة أو منخفضة لا تكسب الأكلة.",
            scoring: "كل أكلة تأخذها تُحسب عقوبة عليك.",
            roundEnd: "تنتهي بنفاد الأوراق ويفوز الأقل أكلات.",
            commonMistakes: "رمي ورقة عالية مبكرًا في نوع لم تخرج أوراقه الأعلى."
        ),
        CardGameReferenceDefinition(
            slug: "no-hearts-no-queens",
            arabicTitle: "هاص وبنات",
            englishTitle: "Hearts and Queens",
            shortDescription: "نمط يجمع عقوبات الهاص والبنات في جولة واحدة.",
            playerCountText: "3 إلى 6 لاعبين",
            difficulty: .intermediate,
            estimatedDuration: "10–25 دقيقة",
            iconName: "heart.text.square.fill",
            sortOrder: 90,
            objective: "تجنب أخذ أي هاص أو بنت، خصوصًا عندما تجتمع العقوبات في أكلة واحدة.",
            setup: "تُحدد قيمة الهاص وقيمة البنات، وهل بنت السبيت أعلى من بقية البنات.",
            dealing: "تُوزَّع الأوراق بالتساوي حسب عدد اللاعبين.",
            cardRanking: "الترتيب العادي، ولا يوجد حكم في الصيغة الأساسية.",
            howToPlay: "تتبع خروج الهاص والبنات، وتخلص من العقوبات عندما تكون الأكلة مضمونة للخصم.",
            scoring: "تضاف عقوبات الهاص والبنات إلى صاحب الأكلة التي تحتويها.",
            roundEnd: "بعد نهاية الجولة تُحسب كل أوراق العقوبة المأخوذة.",
            commonMistakes: "التخلص من بنت في أكلة قد تعود لك بسبب نفاد أوراق الخصوم من النوع."
        ),
        CardGameReferenceDefinition(
            slug: "sequence",
            arabicTitle: "السلسلة",
            englishTitle: "Sequence",
            shortDescription: "لعبة ترتيب تعتمد على بناء سلسلة تصاعدية أو تنازلية من نفس النوع أو الرتبة.",
            playerCountText: "2 إلى 6 لاعبين",
            difficulty: .beginner,
            estimatedDuration: "10–20 دقيقة",
            iconName: "list.number",
            sortOrder: 91,
            objective: "التخلص من أوراقك ببناء سلاسل متتابعة.",
            setup: "تُفتح ورقة بداية أو يحدد اللاعبون رتبة بداية مثل 7، ثم تُبنى السلاسل حولها.",
            dealing: "تُوزَّع الأوراق بالتساوي أو بعدد ثابت حسب سرعة اللعبة.",
            cardRanking: "الأوراق تُرتب رقميًا من 2 إلى A أو حول رتبة بداية متفق عليها.",
            howToPlay: "العب ورقة تكمل سلسلة مفتوحة؛ إن لم تستطع فاسحب أو مرر حسب قاعدة المجلس.",
            scoring: "الفائز من يفرغ يده، وتُحسب أوراق الآخرين كنقاط عليهم.",
            roundEnd: "تنتهي عندما يفرغ لاعب يده أو تُقفل كل السلاسل.",
            commonMistakes: "فتح سلسلة لا تخدم يدك أو حبس ورقة يحتاجها أكثر من مسار."
        ),
        CardGameReferenceDefinition(
            slug: "memory-pairs",
            arabicTitle: "أزواج الذاكرة",
            englishTitle: "Memory Pairs",
            shortDescription: "لعبة خفيفة لاختبار الذاكرة عبر كشف أوراق ومحاولة إيجاد الأزواج.",
            playerCountText: "لاعب واحد إلى 4",
            difficulty: .beginner,
            estimatedDuration: "5–10 دقائق",
            iconName: "brain.head.profile",
            sortOrder: 92,
            objective: "اجمع أكبر عدد من الأزواج بتذكر أماكن الأوراق المكشوفة.",
            setup: "تُختار مجموعة أزواج وتُقلب على الطاولة عشوائيًا.",
            dealing: "لا يوجد توزيع يد؛ الأوراق كلها تكون مقلوبة على الطاولة.",
            cardRanking: "لا توجد قوة للأوراق، المطابقة حسب الرتبة أو الرمز المتفق عليه.",
            howToPlay: "اكشف ورقتين. إذا تطابقتا تحتفظ بهما، وإذا لم تتطابقا تُقلبان مرة أخرى.",
            scoring: "كل زوج صحيح يمنح نقطة.",
            roundEnd: "تنتهي عندما تُجمع كل الأزواج.",
            commonMistakes: "النقر بسرعة دون حفظ مواقع الأوراق أو تغيير معيار المطابقة وسط اللعبة."
        )
    ]
}
