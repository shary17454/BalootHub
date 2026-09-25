# مراجعة هندسية — 25 سبتمبر 2026

## أهم الأخطاء ونتيجة إصلاحها

1. **انهيار احتساب النقاط عند تجاوز سعة Int — مؤكد، أولوية عالية.**
   موضعه `ScoreRules.finalScore` و`ScoreSession.teamOneTotal/teamTwoTotal` و`PlayerStatsAnalyzer`.
   أعاد الاختبار الانهيار فعليًا قبل الإصلاح باستخدام `Int.max` مع مشروع أو مضاعف.
   أصبحت المدخلات الجديدة تُرفض قبل الحفظ إذا تجاوزت سعة نتيجة الجولة أو مجموع الجلسة، مع استثناء الجولة الجاري تعديلها من الجمع.
   القيم القديمة المتطرفة تبقى قابلة للقراءة؛ العرض يتشبع عند `Int.max` دون تعديل البيانات المخزنة. المتوسط لم يعد يتحول من Double إلى Int بصورة قد تنهار.
   الدليل: اختبارات الحدود الدقيقة، تجاوز الجمع والضرب، تعديل الجولة، الإحصاءات، وحزمة الانهيار السابقة `BalootHubReviewSep25OverflowBefore.xcresult`.
2. **نقاط المشاريع غير الصالحة تتحول إلى صفر — مؤكد، أولوية عالية.**
   كان `Int(text) ?? 0` يُسقط الإدخال غير الصالح بصمت. أصبح المحلل المشترك `ScoreRoundInput` يقبل الأرقام العشرية العربية والفارسية واللاتينية ويمنع النص السالب/العشري/المتجاوز؛ الفراغ مسموح للمشاريع فقط ويعني صفرًا.
   استُخدم المحلل أيضًا في الإكمال التلقائي، مع رسائل تحقق مترجمة. اختبارات المدخلات والحالات الحدية ناجحة.
3. **فشل قراءة الكتالوج يُعامل كقاعدة فارغة — مسار خطأ مؤكد، أولوية عالية.**
   `CatalogSeeder.refresh` كان يبتلع خطأ fetch ثم يحاول زرع كل العناصر. أصبح يمرر الخطأ قبل أي إدراج، ويسجله من نقطة الإقلاع بخصوصية `.private`.
   حقن خطأ قراءة يثبت عدم تغيير عدد السجلات وعدم وجود تغييرات معلقة. لم تُحذف قاعدة فعلية ولم يُحاكَ فسادها بإتلاف بيانات المستخدم.
4. **التخزين الاحتياطي المؤقت غير معلن — مؤكد، أولوية عالية.**
   كان فشل فتح SwiftData يؤدي في Release إلى مخزن ذاكرة دون إبلاغ المستخدم، وفي Debug إلى assertion.
   أصبح التطبيق يستمر ويعرض تنبيهًا بأن تغييرات الجلسة لن تبقى بعد الإغلاق، مع بقاء ملف البيانات الأصلي دون مساس.
   أُصلح تداخل التنبيه مع شريط التنقل بعد كشفه في اللقطة الأولى. اختبار المصنع الفاشل واختبار إعادة فتح مخزن قرص مؤقت ناجحان.
5. **الاشتراك والتزامن — أخطاء مؤكدة في المسارات، أولوية عالية.**
   `isBusy` لم يشمل الشراء الجاري. أضيف قفل شراء يمنع تداخل الشراء/الاستعادة ويُفرج عنه في النجاح والإلغاء والخطأ.
   تحديثات StoreKit لم تعد تضيف أي معاملة متحققة مباشرة إلى الاستحقاقات؛ تعيد قراءة `currentEntitlements` وتستبعد الملغى/المستبدل، مع منع كتابة نتيجة تحديث قديمة فوق الأحدث.
   أزيل فلتر تاريخ الانتهاء اليدوي الذي يسحب الاشتراك أثناء مهلة السداد رغم كونه مستحقًا بحسب Apple.
   يحدث الاستحقاق عند عودة التطبيق للنشاط، وتظهر حالة التحميل وزر إعادة المحاولة إذا لم تتوفر المنتجات.
   الدليل: StoreKitTest محلي للشراء، الاستعادة، الانتهاء، رد المبلغ، مهلة السداد، موافقة ولي الأمر، تعذر الشبكة وإعادة المحاولة، وتزامن الشراء والإلغاء.

## المشروع والمعمارية وحدود التغيير

- المستودع الأصلي: `/Users/shrybnhshymbnmrzwqbnhwyd/Developer/Projects/BalootHub`، وليس نسخة التدقيق المعزولة.
- GitHub: `shary17454/BalootHub`؛ الفرع الأساس `main` عند `0797443` مطابق لـorigin بعد fetch. لا تعديلات مستخدم عند البدء.
- فرع هذه المراجعة: `fix/engineering-review-2026-09-25`. لا دمج في main ضمن المراجعة.
- Swift 6، SwiftUI، Observation، SwiftData محلي، StoreKit 2، وحزمة Swift محلية `Packages/BalootEngine`؛ iOS 17+ وiPhone/iPad.
- الطبقات الموجودة مناسبة: App للتوجيه، Features للواجهات، Domain للنماذج والخدمات، Core للتصميم والتخزين، ومحرك مستقل بلا SwiftUI. لا حاجة لإعادة كتابة المعمارية.
- الوظائف الأساسية: البلوت المحلي مع AI أو أربعة لاعبين على جهاز واحد، ألعاب الورق الأخرى، مسجل النقاط والسجل، التدريب/الاختبارات/الإعادة/الإحصاءات، الكتالوج والإعدادات، وBaloot Plus الاختياري.
- لا خادم أو تسجيل دخول/خروج أو API مخصص أو قاعدة بيانات خادمية أو مزامنة حسابات؛ هذه البنود **غير منطبقة**. لا إضافة لأي مكون منها.
- لم يتغير مخطط SwiftData أو معرّف الحزمة أو الإصدار أو قواعد اللعب أو الرسوم المعتمدة. لا ترحيل إنتاج مطلوب لهذه الدفعة.
- حُصر تقليل التكرار في محلل النقاط والجمع الآمن. تقسيم ملفات التدريب الضخمة قرار متابعة، لا إعادة هيكلة واسعة مختلطة بإصلاحات الأعطال.

## قائمة الفحص والأدلة وحدود التغطية

| المجال | ما تم | ما لم يثبت أو بقي |
|---|---|---|
| تعريف المشروع والتعليمات | المسار/remote/الفرع/الحالة والوثائق؛ لا AGENTS إضافي في النطاق المفحوص | لا تغييرات على مشاريع أخرى |
| الإقلاع والتنقل واللعب | اختبارات AppRoute وGamePlaythrough وBalootGameViewModel وLocalHandoff ومحركات الألعاب؛ تشغيل فعلي بمحاكيات | لم تُنفذ جلسة يدوية كاملة لكل لعبة |
| التخزين | حقن فشل فتح/قراءة؛ كتابة جلسة وجولة لملف مؤقت ثم إعادة فتحه والتحقق من الهوية والدرجات | امتلاء القرص وفشل كل شاشة حفظ لم يُختبرا عمليًا |
| النقاط والإحصاءات | رفض overflow والمدخلات غير الصالحة؛ الحفاظ على القيم الطبيعية؛ عرض عربي | لا ادعاء بصحة كل ملف بيانات قديم محتمل |
| StoreKit | ستة اختبارات تكامل محلية؛ 18 تنفيذًا ناجحًا في ثلاث إعادات | لا حساب Apple Sandbox حي أو إثبات إعدادات/موافقة المنتجات في App Store Connect |
| الفراغ/الخطأ/إعادة المحاولة | رسائل الإدخال، فشل تحميل المنتجات وإعادة المحاولة، Ask to Buy والإلغاء، التخزين المؤقت | انقطاع شبكة حقيقي على جهاز فعلي لم يُختبر |
| العربية والواجهة | اختبارات StringCatalog/LocalizationIntegrity؛ ترجمة النصوص الجديدة لعشر لغات؛ لقطات RTL من الواجهات الفعلية | ليست مراجعة لغوية بشرية لكل اللغات أو اختبار VoiceOver كامل |
| الأجهزة والوصول | Dynamic Type والألوان الدلالية وواجهات iPhone وiPad المفحوصة؛ لقطات بأحجام محددة | جميع المقاسات وSplit View والأفقي وحجم الخط الأقصى ليست كلها مختبرة بهذه الدفعة |
| الأمن والخصوصية | فحص الأسرار المتتبعة، Privacy Manifest، عدم وجود عميل HTTP مخصص؛ StoreKit verified فقط؛ سجلات التخزين خاصة | هذا ليس اختبار اختراق؛ تجاوز المالك المحلي يحتاج قرار منتج |
| الاعتماديات | حزمة محلية بلا حزم خارجية؛ لا تحديثات عشوائية أو lockfile متغير | SDK/متطلبات المتجر يجب مراجعتها عند الرفع الفعلي |
| الأداء | مراجعة مهام AI وإلغاء المهام وتقليل الحساب الحراري/البطارية الموجودة أصلًا، وعدم إضافة مؤقت أو استطلاع دائم | لا قياس طاقة/ذاكرة/Instruments على جهاز فعلي، ولا نسبة تحسن مدعاة |
| CI والتوثيق | اختيار المحاكي بالـUDID، تسلسل اختبارات StoreKit، حفظ xcresult دائمًا؛ إزالة ادعاء إلزام Xcode Cloud/عدم وجود شراء | نتيجة GitHub على الفرع تُراجع مستقلًا عن الاختبارات المحلية |
| مخطط البيانات/API/الترحيلات | لا تغيير على مخطط البيانات؛ لا API خادمي | لا ترحيل إنتاج نُفذ أو مطلوب |

## نتائج التحقق الفعلية

البيئة: Xcode 27.0 (27A266a)، macOS 27.0؛ المحاكي iPhone 16 Pro / iOS 18.6
`A49F7EA3-6575-4986-9AAA-69B7DE158034`. لا يجوز اعتبار زمن الاختبارات مقياس أداء واجهة أو بطارية.

| الفحص | قبل التعديل | بعد الإصلاح |
|---|---|---|
| اختبارات التطبيق XCTest | 756 ناجحة، 0 فشل/تخطٍّ | 774 ناجحة، 0 فشل/تخطٍّ؛ بعد إصلاح موضع التنبيه وإضافة لقطة خطأ الشبكة |
| حزمة BalootEngine | 261 Swift Testing في 21 مجموعة ناجحة، وXCTest ناجح | أُعيد `swift test` ونجح: 261 Swift Testing و26 XCTest؛ المصدر لم يتغير |
| اختبارات StoreKit المحلية | غير موجودة | 6 اختبارات، ثلاث إعادات = 18 تنفيذًا ناجحًا |
| SwiftLint strict | 40 مخالفة | 40 مخالفة قائمة؛ لم تُرفع الحدود أو تُعطل قواعد |
| JSON/plist/YAML وgit diff --check | — | ناجحة |
| Release وArchive | لا استدلال من بناء المحاكي | نجح Archive Release؛ codesign صالح بتوقيع Apple Development؛ تعطل تصدير Distribution كما هو موضح أدناه |

حزم الأدلة المحلية (ليست ملفات تُدفع إلى Git):

- `/tmp/BalootHubReviewSep25Baseline.xcresult`: خط الأساس.
- `/tmp/BalootHubReviewSep25OverflowBefore.xcresult`: الانهيار المعاد إنتاجه قبل الإصلاح.
- `/tmp/BalootHubReviewSep25StoreKitRepeat.xcresult`: إعادات الاشتراك.
- `/tmp/BalootHubReviewSep25Verified.xcresult`: 771/771 قبل إضافة لقطتي العرض.
- `/tmp/BalootHubReviewSep25Final.xcresult`: 773/773 مع لقطتي نموذج النقاط والإحصاءات.
- `/tmp/BalootHubReviewSep25LayoutVerified.xcresult`: إعادة التحقق بعد تصحيح موضع التنبيه.
- `/tmp/BalootHubReviewSep25Delivery.xcresult`: **نتيجة التسليم النهائية 774/774**، تشمل حالة إعادة المحاولة بعد خطأ الشبكة.
- `/tmp/BalootHubReviewSep25Screenshots/`: لقطات مراجعة يدويًا؛ SnapshotTests تُلحق لقطاتها بحزمة xcresult أيضًا. هذه اختبارات رسم smoke وليست مقارنة صور آلية أو اختبار تفاعل لمس.
- `/tmp/BalootHubReviewSep25RetryScreenshot/`: لقطة فشل تحميل المنتجات من محاكاة StoreKit، تظهر رسالة الخطأ وزر إعادة المحاولة واستعادة المشتريات بالعربية دون قص في المقاس المفحوص.

**تشخيص الإخفاقات أثناء العمل:**

- تجربة واحدة تعطلت قبل تشغيل الاختبارات برسالة CoreSimulator `server died`؛ حُلّت بتشغيل المحاكي المحدد واستعمال توقيع محاكي ad-hoc، دون تغيير الكود لعطل البيئة.
- أول اختبار refund كان يفترض أن وصول التحديث فوري. فشل بعد 0.12 ثانية في المجموعة الكبيرة؛ أصبح ينتظر إزالة الاستحقاق بواسطة المستمع الفعلي حتى خمس ثوانٍ، مع إبقاء assertion النهائي، ونجح في الإعادات والمجموعة الكاملة. لم يُحذف اختبار أو يُضعف شرطه.
- SwiftLint بلا DEVELOPER_DIR تعطل بسبب اختيار CommandLineTools؛ أُعيد ببيئة Xcode و`--no-cache`، فبقيت المخالفات الأربعون الحقيقية فقط.
- التحكم بواجهة Device Hub تعذر؛ استُخدمت لقطات محاكيات Xcode واختبارات الرسم بدل ادعاء اختبار لمس لم يحصل.
- محاولة Archive اليدوية رفضت ملفًا **يديره Xcode** رغم تطابق الحزمة/الفريق/شهادة Distribution. هذا قيد مسار توقيع، لا خطأ شيفرة. لا إنشاء/إلغاء شهادات ولا استيراد P12.

### أوامر قابلة لإعادة التنفيذ

تنفذ من المستودع الأصلي، مع اختيار اسم جديد لحزمة النتائج إن كانت موجودة:

```sh
git status --short --branch
git remote -v
DEVELOPER_DIR=/Applications/Xcode-27.app/Contents/Developer swift test --package-path Packages/BalootEngine --scratch-path /tmp/BalootHubReviewSep25Engine
DEVELOPER_DIR=/Applications/Xcode-27.app/Contents/Developer xcodebuild test -project BalootHub.xcodeproj -scheme BalootHub -destination 'platform=iOS Simulator,id=A49F7EA3-6575-4986-9AAA-69B7DE158034' -derivedDataPath /tmp/BalootHubReviewSep25 -resultBundlePath /tmp/BalootHubReviewSep25Delivery.xcresult -parallel-testing-enabled NO -testLanguage ar -testRegion SA -quiet CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-
DEVELOPER_DIR=/Applications/Xcode-27.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/BalootHubReviewSep25Delivery.xcresult
DEVELOPER_DIR=/Applications/Xcode-27.app/Contents/Developer swiftlint lint --strict --quiet --no-cache
git diff --check
```

أمر Archive المحلي الناجح:

```sh
DEVELOPER_DIR=/Applications/Xcode-27.app/Contents/Developer xcodebuild archive -project BalootHub.xcodeproj -scheme BalootHub -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/BalootHubReviewSep25ArchiveData -archivePath /tmp/BalootHubReviewSep25Automatic.xcarchive -resultBundlePath /tmp/BalootHubReviewSep25AutomaticArchive.xcresult -quiet CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=4HM66AD594
codesign --verify --deep --strict --verbose=2 /tmp/BalootHubReviewSep25Automatic.xcarchive/Products/Applications/BalootHub.app
codesign -d --verbose=2 /tmp/BalootHubReviewSep25Automatic.xcarchive/Products/Applications/BalootHub.app
```

قيد التحميل والشبكة والموافقة في الاختبارات يُحقن بواسطة `SKTestSession` من
`BalootHubTests/Fixtures/BalootPlus.storekit`؛ لا ربط لهذه التهيئة بإصدار الإنتاج ولا دفع حقيقي.
وسيط `-BalootHubTemporaryStore` للعرض التجريبي يعمل في Debug فقط.

## الملفات المتأثرة

- `Domain/Services/ScoreRules.swift` و`Domain/Models/ScoreSession.swift`: المدخلات والحساب الآمن.
- `Features/Scorekeeper/AddEditRoundView.swift`: التحقق قبل الحفظ ورسائل محلية؛ `PlayerStatsAnalyzer.swift` و`PlayerStatsView.swift`: المتوسط والمجاميع.
- `Core/Persistence/CatalogSeeder.swift` و`PersistenceController.swift` و`App/BalootHubApp.swift`: فشل القراءة/الفتح وتنبيه التخزين المؤقت وتجديد الاستحقاقات.
- `Domain/Services/BalootPlusSubscription.swift` و`Features/Purchase/BalootPlusView.swift`: قفل العمليات والاستحقاقات وإعادة المحاولة.
- `Resources/Localizable.xcstrings`: نصا الخطأ والتنبيه مترجمان.
- اختبارات `ScoreRules` و`ScoreSession` و`PlayerStatsAnalyzer` و`CatalogSeeder` و`BalootPlusSubscription` و`AppReviewReadiness`، وملف StoreKit التجريبي الجديد.
- `.github/workflows/ci.yml` و`README.md` وهذا التقرير؛ لا مفاتيح/شهادات/حزم بناء ضمن Git.

## المتبقي وخريطة الطريق

| الأولوية | الدليل والنوع | الإجراء المقترح والتقدير التقريبي |
|---|---|---|
| عالية قبل إصدار المتجر | حالات StoreKit مثبتة محليًا فقط | Sandbox حي/TestFlight: شراء/استعادة/رد/انتهاء على جهاز، وفحص إعدادات المنتجات. نصف يوم عند توفر الحسابات والنسخة |
| عالية/قرار منتج | `BalootPlusOwnerEntitlementOverride` يعتمد على digest محلي في UserDefaults/البيئة؛ ليس إثبات هوية آمنًا ضد العبث بالجهاز | تحديد سياسة تجاوز المالك ثم تعديله باختبارات؛ 0.5–1 يوم. لم تُحذف وظيفة مثبتة عمدًا بلا قرار |
| متوسطة، مخاطرة | `try? modelContext.save()` في Settings، Catalog، MatchHistory، OfflineTournaments وواجهات أخرى يخفي فشل الحفظ | حقن فشل حفظ لكل تدفق وعرض/استعادة حالة مدروسة بدل rollback عام قد يمس تغييرات أخرى؛ 1–2 يوم |
| متوسطة، تحتاج قياسًا | ثلاث مهام detached في `OtherCardGamePlayView` عند 511/581/703 لا تنقل إلغاء الحساب الداخلي؛ نتيجة المهمة تُمنع بعد الإلغاء | قياس كوت/تركس/هاند ثم ربط الإلغاء إذا ثبت أثر محسوس؛ 0.5–1 يوم. لا دليل استنزاف بطارية مقاس بهذه المراجعة |
| متوسطة | 40 مخالفة strict؛ `WhatToPlayStatsAnalyzer` نحو 5440 سطرًا و`WhatToPlayTrainerView` نحو 5030 | تفكيك تدريجي حسب الوظيفة بعقود واختبارات سلوك؛ 2–4 أيام، دون إعادة تصميم اللعب |
| متوسطة | `.public` في سجل أخطاء Home وبعض تفاصيل اللعب؛ لا إثبات تسرب شخصي في الاختبارات | مراجعة تصنيف الحقول وتقليل بيانات السجل؛ 0.5 يوم |
| متوسطة | لم ينفذ Instruments/VoiceOver/مصفوفة أحجام كاملة | جهاز حقيقي: Time Profiler/Allocations/Energy، اللعب 15 دقيقة والخلفية/الحرارة، ثم AX وأفقي iPad؛ 1–2 يوم |

هذه تقديرات تنفيذ لا التزام زمني أو نتيجة قياس. لم تُضف أدوات تحليلات أو جمع بيانات أو خدمة مدفوعة.

## التوقيع والنشر والتراجع

- هوية `Apple Distribution: Shary ALADHYANI (4HM66AD594)` موجودة في Keychain؛ الفحص الأول `security find-identity -v -p codesigning`.
- ملف Store الموجود `add8b754-86a3-4af5-ad41-9c793fd1fece` يطابق `4HM66AD594.app.balooThub.ios` وشهادة Distribution، بلا `get-task-allow` أو قائمة أجهزة، وينتهي في 19 سبتمبر 2027.
- **بناء Release وArchive: نجح** في `/tmp/BalootHubReviewSep25Automatic.xcarchive`، باستخدام Xcode محليًا ودون `-allowProvisioningUpdates`.
- **توقيع Archive الأصلي: نجح التحقق** بـ`codesign --verify --deep --strict --verbose=2`؛ الهوية الفعلية **Apple Development** والفريق `4HM66AD594`، وليست Distribution.
- **تصدير Distribution: لم يكتمل.** التصدير اليدوي رفض الملف الموجود لأنه Xcode-managed. منعت مراجعة الصلاحيات محاولة التصدير التلقائي لاحتمال إنشاء/تحديث موارد توقيع Apple؛ لم يُتجاوز المنع. يتطلب استكمال هذه المرحلة ملف توزيع يدويًا متوافقًا أو تفويضًا صريحًا لمسار التوقيع المُدار. لا تبديل شهادة/استيراد P12/إلغاء شهادة تم.
- **لم تُرفع هذه التغييرات إلى App Store Connect، ولم تُرسل إلى App Review، ولم تتحقق موافقة Apple لهذه الدفعة.** رقم المصدر الحالي 3.0.9 (504) ليس إثباتًا لأحدث بناء متاح في المتجر؛ يلزم جرد حي قبل اختيار رقم إصدار/بناء جديد.
- التسليم عبر PR للمراجعة، لا merge ولا تعديل شهادة أو صلاحية إنتاج. لا استخدام لـXcode Cloud في هذه المراجعة.
- بعد اعتماد التغييرات: تحقق Sandbox والجهاز الفعلي، ثم أنشئ Archive برقم بناء متاح محليًا، صدّره بتوقيع Distribution وتحقق منه، ثم ارفع وتحقق من معالجة Apple واختيار البناء والإرسال كخطوات مستقلة.
- التراجع: قبل الدمج اترك main دون تغيير. بعد الدمج استخدم `git revert` للـcommit عبر PR؛ لا reset أو حذف بيانات. لا ترحيل مخطط جديد يلزم عكسه؛ إصدار المتجر لا يرجع بمجرد Git revert بل يحتاج بناءً ورفعًا جديدين.

مرجع سلوك الاستحقاق: [Apple Transaction.currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements)
يشمل الاشتراك في مهلة السداد؛ و[StoreKitTest](https://developer.apple.com/documentation/storekittest/sktestsession) هو بيئة الاختبار المحلية، لا موافقة متجر.
