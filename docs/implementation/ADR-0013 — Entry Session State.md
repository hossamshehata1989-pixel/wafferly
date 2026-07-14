ADR-0013 — Entry Session State

Status: Accepted

Date: 2026-07-15

Decision Type: UX + Application Architecture

Context

تعتمد جميع شاشات إدخال العمليات المالية في Wafferly على جلسة إدخال (Entry Session) يمر خلالها المستخدم بعدة مراحل:

اختيار الفئة
اختيار الحساب
اختيار العضو
كتابة المبلغ
إضافة الملاحظات
تحديد Exceptional
تعديل التاريخ

أثناء هذه الجلسة قد تكون البيانات:

فارغة تمامًا.
غير مكتملة.
مكتملة وجاهزة للحفظ.

كان المنطق السابق يعتمد على شروط متناثرة داخل الـ UI مثل:

if(amount > 0)
...

أو

if(category != null)
...

مما يؤدي إلى:

تكرار الشروط.
اختلاف السلوك بين Expense و Income.
صعوبة إضافة حقول جديدة مستقبلًا.
Decision

يصبح TransactionEntryController هو المصدر الوحيد لحالة جلسة الإدخال.

ويقدم حالة موحدة تسمى:

enum EntryState {
  empty,
  draft,
  readyToSave,
}

ولا يسمح لأي Widget باستنتاج الحالة بنفسه.

EntryState Definitions
Empty

لا توجد أي بيانات قام المستخدم بإدخالها.

أمثلة:

لا مبلغ.
لا فئة.
لا تعديل على التاريخ.
لا ملاحظات.
العضو الافتراضي.
الحساب الافتراضي.
Exceptional غير مفعل.

السلوك:

Done
↓

Close Screen
Draft

بدأ المستخدم إدخال البيانات لكن العملية غير صالحة للحفظ.

أمثلة:

اختيار فئة فقط.
كتابة مبلغ فقط.
كتابة Note فقط.
تغيير التاريخ.
تغيير العضو.
تفعيل Exceptional.
حذف الحساب.
أي تعديل لا يحقق شروط الحفظ.

السلوك:

Done
↓

Discard Changes Dialog
ReadyToSave

العملية تحقق الحد الأدنى للحفظ.

الحد الأدنى الحالي:

Account موجود.
Category موجودة.
Amount > 0.

السلوك:

Done
↓

Save Transaction
↓

Close Screen
Controller Responsibilities

يصبح الكنترولر مسئولًا عن:

EntryState get entryState;

ولا يعرف الـ UI أي تفاصيل عن كيفية حسابها.

UI Responsibilities

الـ UI لا يحتوي أي Business Rules.

زر Done يصبح فقط:

switch(controller.entryState)

ولا يقوم بأي تحليل للبيانات.

Extensibility

عند إضافة أي Metadata مستقبلًا مثل:

Merchant
Receipt
Location
Tags
Project
Cost Center

لن يتغير زر Done.

سيتم فقط تعديل منطق:

_hasDraft()
_canSave()

داخل الكنترولر.

Benefits

✅ مصدر واحد للحقيقة (Single Source of Truth).

✅ إزالة جميع شروط الحفظ من الـ UI.

✅ توحيد السلوك بين Expense و Income و Transfer.

✅ سهولة إضافة خصائص جديدة.

✅ قابلية أعلى للاختبار (Unit Testing).

✅ يمنع اختلاف سلوك الأزرار بين الشاشات.

Consequences

يعتمد كل من:

Done Button
Back Navigation
Unsaved Changes Dialog
Future Keyboard Shortcuts
Auto Save (إن وجد مستقبلًا)

على:

controller.entryState

بدلًا من تحليل البيانات داخل الـ Widgets.