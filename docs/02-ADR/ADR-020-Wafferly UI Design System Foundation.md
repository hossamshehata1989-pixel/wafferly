ADR-UI-001 — Wafferly UI Design System Foundation
Status
Accepted
Context

بعد اكتمال تطوير أول شاشتي إدخال في Wafferly (Add Member و Add Account)، ظهرت مجموعة من المشاكل:

اختلاف في ارتفاع الـ TextFields.
اختلاف في شكل الـ Dropdown.
اختلاف في الـ Date Picker.
اختلاف في أزرار الحفظ.
وجود Magic Numbers موزعة في الشاشات.
إعادة كتابة نفس InputDecoration في أكثر من مكان.
ضعف الـ Responsive على الأجهزة الصغيرة مثل iPhone SE.

كما أن المشروع سيتوسع ليشمل عددًا كبيرًا من شاشات الإدخال (Goals، Books، Categories، Accounts، Members...)، لذلك كان لابد من وجود نظام UI موحد.

Decision

اعتماد Component-based Design System بدلاً من Screen-based Abstraction.

يعتمد النظام على المبادئ التالية:

1. Reusable Components

إنشاء Widgets عامة لإعادة الاستخدام مثل:

WafferlyButton
WafferlyTextField
WafferlyDropdown
WafferlyDatePicker
WafferlySectionTitle
2. Shared Input Decoration

جميع الحقول تستخدم:

WafferlyInputDecoration

كمصدر وحيد لشكل InputDecoration.

3. Responsive Tokens

جميع المقاسات تعتمد على:

ResponsiveMetrics

بدلاً من استخدام قيم ثابتة داخل الشاشات.

يشمل ذلك:

Typography
Icons
Radius
Buttons
Inputs
Spacing
4. No Screen Scaffold Abstraction

تم رفض إنشاء Widget عامة من نوع:

WafferlyFormScreen

لأن شاشات الإدخال تختلف في ترتيب ومحتوى عناصرها.

بدلاً من ذلك، يتم توحيد الـ Components فقط، بينما تظل كل شاشة مسؤولة عن Layout الخاص بها.

5. Single Source of Truth

أي تعديل مستقبلي على:

Text Fields
Buttons
Responsive
Input Decorations

يتم من خلال الـ Shared Components فقط.

Consequences
Advantages
اتساق كامل بين شاشات الإدخال.
سهولة إضافة شاشات جديدة.
تحسين الـ Responsive.
تقليل التكرار.
سهولة صيانة الـ UI.
Trade-offs
زيادة بسيطة في عدد ملفات الـ Shared Widgets.
أي Component جديد يجب أن يكون له أكثر من مستهلك قبل استخراجه.
Rules

يمنع داخل الشاشات استخدام:

fontSize: 14
EdgeInsets.all(16)
BorderRadius.circular(16)
ElevatedButton(...)
TextFormField(...)

إلا إذا كان هناك سبب معماري واضح.

Future Extensions

يمكن إضافة Components عامة مستقبلًا عند ظهور أكثر من مستهلك لها، مثل:

WafferlyAvatarPicker
WafferlyCurrencyField
WafferlySearchField

ولا يتم إنشاء أي Component استباقيًا.