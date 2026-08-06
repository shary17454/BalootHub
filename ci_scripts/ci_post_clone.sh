#!/bin/sh
#
# سكربت Xcode Cloud — يعمل بعد استنساخ المستودع مباشرة، قبل حل اعتماديات
# Swift Package Manager وقبل أي خطوة بناء. يوثّق بيئة البناء ويتحقق من وجود
# حزمة BalootEngine المحلية قبل المتابعة، حتى تظهر أي مشكلة بنية مبكرًا
# وبوضوح في سجلّ Xcode Cloud بدل فشل غامض لاحقًا أثناء البناء.
set -e

echo "==> لمّة بلوت (Baloot Hub) — ci_post_clone"
echo "Xcode: $(xcodebuild -version | head -1)"
echo "Swift: $(swift --version 2>/dev/null | head -1)"
echo "الفرع: ${CI_BRANCH:-غير معروف} | الفعل: ${CI_XCODEBUILD_ACTION:-غير معروف}"

PACKAGE_MANIFEST="$CI_PRIMARY_REPOSITORY_PATH/Packages/BalootEngine/Package.swift"
if [ ! -f "$PACKAGE_MANIFEST" ]; then
    echo "خطأ: لم يتم العثور على حزمة BalootEngine المحلية في $PACKAGE_MANIFEST" >&2
    exit 1
fi

echo "==> تم التحقق من بنية المشروع بنجاح"
