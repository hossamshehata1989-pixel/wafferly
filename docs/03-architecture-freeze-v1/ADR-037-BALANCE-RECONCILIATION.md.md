ADR-036 — منع تعديل الرصيد المباشر واعتماد Balance Reconciliation

الحالة: Accepted
التاريخ: 2026-09-23
النطاق: Account Balance / Financial Truth / Single Writer
مرتبط بـ: ADR-004 — Financial Operation Engine Authority; ADR-0011 — Transaction Metadata; ADR-032 — Debt Domain Architecture; Single Writer Boundary & Remaining Financial Writers

1. السياق

في النظام الحالي، الرصيد الظاهر للحساب ليس قيمة يتم تخزينها داخل Account، وإنما هو قيمة مشتقة من الحركات المالية المسجلة في الـ Ledger.

بالتالي، الرصيد يمثل نتيجة للحقيقة المالية، وليس حقلًا مستقلًا يمكن للمستخدم تغييره مباشرة.

مع ذلك، كان هناك في واجهة تعديل الحساب إمكانية إدخال رصيد جديد للحساب، وكان المسار البرمجي يستقبل oldBalance وnewBalance ثم يحاول إنشاء Balance Adjustment.

المشكلة أن هذا المسار لا يمثل عملية مالية مكتملة حاليًا؛ إذ إن createBalanceAdjustment() يرفض أي فرق غير صفري ويطلب تنفيذ التغيير من خلال Financial Operation Engine.

وبالتالي فإن السماح للمستخدم بتعديل الرقم مباشرة يخلق مفهومًا خاطئًا: كأن الرصيد نفسه هو مصدر الحقيقة ويمكن تغييره يدويًا.

القاعدة المعمارية هي:

Financial Truth is created by Financial Operations and derived through Ledger.

2. المشكلة

نحتاج إلى طريقة صحيحة للتعامل مع حالة يكون فيها:

الرصيد الفعلي الموجود في الواقع ≠ الرصيد المحسوب في Wafferly

مثال:

الرصيد في Wafferly = 8,500
الرصيد الفعلي = 10,000

الفرق = +1,500

لا يصح ببساطة تغيير 8,500 إلى 10,000.

لأن هذا التغيير يجب أن يكون له أثر مالي مسجل يمكن تتبعه ومراجعته وتصحيحه لاحقًا.

3. القرار

3.1 منع تعديل الرصيد مباشرة

يتم منع تعديل الرصيد مباشرة من شاشة Account Edit.

الرصيد في شاشة تعديل الحساب يصبح:

Read-only / للعرض فقط

ولا يُسمح للمستخدم بإدخال قيمة جديدة ليتم اعتبارها الرصيد النهائي للحساب.

3.2 اعتماد Balance Reconciliation

عند وجود اختلاف بين الرصيد الفعلي والرصيد المحسوب في Wafferly، يتم التعامل معه من خلال:

Balance Reconciliation

أي تسوية / مطابقة الرصيد الفعلي مع الرصيد المسجل في النظام.

الـ Reconciliation ليست تعديلًا مباشرًا للرصيد، وإنما Financial Operation تسجل الحركة الناتجة عن الفرق.

المسار المعماري المستهدف:

Actual Balance
      ↓
Compare with Wafferly Balance
      ↓
Reconciliation Difference
      ↓
Balance Reconciliation Intent
      ↓
BalanceReconciliationOperation
      ↓
FinancialOperationEngine
      ↓
Planner
      ↓
Transaction + Journal
      ↓
Ledger
      ↓
Derived Account Balance

وبالتالي يصبح الرصيد الجديد نتيجة للعملية المالية، وليس قيمة قام المستخدم بتغييرها يدويًا.

4. لماذا Balance Reconciliation؟

هناك فرق جوهري بين:

تعديل الرصيد

"الرصيد المفروض يبقى 10,000"

وهذا يتعامل مع الرصيد كأنه رقم مستقل.

وبين:

Reconciliation

"النظام يقول 8,500
والرصيد الفعلي 10,000
إذن يوجد فرق +1,500
وسنسجل هذا الفرق كعملية مالية موثقة."

الطريقة الثانية تحافظ على مبدأ أن:

الرصيد مشتق من Financial Truth ولا يتم تخزينه أو تغييره مباشرة.

5. الدوافع المعمارية

5.1 الحفاظ على Single Source of Truth

الحقيقة المالية يجب أن تظل في:

Financial Operation
        ↓
Transaction
        ↓
Ledger

وليس في قيمة يتم تعديلها داخل Account.

5.2 الحفاظ على Single Writer Boundary

أي تغيير حقيقي في الوضع المالي للحساب يجب أن يمر من خلال الـ Financial Operation Engine.

Direct Balance Edit
        ✗

بينما:

Balance Reconciliation
        ↓
FinancialOperationEngine
        ✓

5.3 قابلية التتبع والمراجعة

إذا تغير الرصيد نتيجة Reconciliation، يجب أن نستطيع معرفة:

الرصيد قبل التسوية

الرصيد الفعلي

قيمة الفرق

سبب التسوية

وقت العملية

الحساب المتأثر

العملية المالية التي أنشأت الفرق

5.4 دعم التصحيح المستقبلي

إذا تم تسجيل Reconciliation بشكل خاطئ، فلا ينبغي العودة إلى Edit Balance لإصلاحه، بل يكون التصحيح من خلال آلية Correction / Invalidation المعتمدة في المعمارية.

6. Reconciliation ليست Temp Debt Settlement

يجب الفصل بوضوح بين المفهومين.

Temporary Debt Settlement

هدفه تسوية التزام مالي موجود بالفعل:

Cash      ↓
Temp Debt ↑

ولا ينشئ Expense جديدًا.

أما:

Balance Reconciliation

فهدفه معالجة فرق بين:

System Derived Balance
        مقابل
Actual Observed Balance

لذلك فهما عمليتان ماليتان مختلفتان ولا يجوز استخدام Balance Reconciliation كبديل لـ Temporary Debt Settlement.

7. الحساب المقابل للـ Reconciliation

يُعتمد مبدئيًا إنشاء System Account مستقل خاص بالتسويات:

balance_reconciliation_equity

وذلك على غرار:

opening_balance_equity

الهدف هو الفصل بين:

Opening Balance

رصيد تم إدخاله عند إنشاء/تهيئة الحساب.

Balance Reconciliation

فرق تم اكتشافه لاحقًا بين الرصيد المسجل والرصيد الفعلي.

ملاحظة: تفاصيل الـ debit/credit والـ journal lines لكل نوع Account سيتم تحديدها في عقد Balance Reconciliation وتنفيذ الـ Planner، ولا يتم افتراضها في هذا القرار قبل اعتماد القواعد الخاصة بها.

8. سبب وضع ReconciliationReason داخل Intent

عملية Reconciliation قد تحتاج إلى سبب، مثل:

cashCountDifference
bankStatementReconciliation
previouslyUnrecorded
dataMigrationCorrection
other

لكن هذه المعلومات لا يجب إضافتها إلى TransactionMetadata العامة.

السبب أن TransactionMetadata مشتركة بين العمليات المالية، ويجب ألا تتحول إلى مكان يحتوي على حقول خاصة بعملية واحدة.

لذلك تكون:

BalanceReconciliationIntent
        └── ReconciliationReason

بدلًا من:

TransactionMetadata
        └── reconciliationReason

9. البدائل المرفوضة

9.1 السماح بتعديل الرصيد مباشرة

مرفوض.

هذا يتعامل مع الرصيد باعتباره مصدر الحقيقة، بينما الرصيد في Wafferly قيمة مشتقة من الـ Ledger، ولا ينتج Financial Transaction/Journal واضحًا يفسر سبب التغيير.

9.2 استخدام createBalanceAdjustment() كحل مباشر

مرفوض كحل معماري نهائي.

الـ method الحالية تمنع الفرق غير الصفري وتطلب التنفيذ من خلال Financial Operation Engine. لا يتم تجاوز الحماية أو تحويلها إلى direct balance mutation، بل يتم استبدال المفهوم بعملية مالية رسمية عند تنفيذ Reconciliation.

9.3 استخدام Opening Balance للعملية

مرفوض.

Opening Balance يمثل رصيدًا افتتاحيًا للحساب، بينما Reconciliation يحدث بعد وجود تاريخ مالي فعلي للحساب. خلط الاثنين يؤدي إلى خلط المعنى التاريخي والتقريري.

9.4 اعتبار Reconciliation نوعًا من Expense أو Income

مرفوض.

Reconciliation ليست مصروفًا ولا دخلًا، وإنما عملية مطابقة للفرق المكتشف بين الوضع المسجل والوضع الفعلي، ولذلك تحتاج إلى Financial Operation وJournal semantics خاصة بها.

9.5 استخدام Temporary Debt لتسجيل فرق الرصيد

مرفوض.

Temporary Debt يمثل Liability حقيقية تنشأ من حالة محددة لعدم كفاية السيولة أثناء Expense. أما Reconciliation فلها معنى مختلف تمامًا.

9.6 تعديل Account.balance

مرفوض.

لا يوجد balance مستقل يمثل Financial Truth داخل Account. الرصيد يجب أن يظل Derived Value من الـ Financial History / Ledger.

10. تأثير القرار على الـ UI

شاشة:

Edit Account

لن تسمح بتعديل الرصيد مباشرة.

بدلًا من ذلك:

Balance
10,000

يُعرض كقيمة Read-only.

وفي مرحلة لاحقة يمكن توفير Action مستقل:

Reconcile Balance

بحيث تكون العملية واضحة للمستخدم كعملية مالية مستقلة وليست تعديلًا لبيانات الحساب.

11. ما لم يتم حسمه في هذا ADR

هذا القرار يعتمد Balance Reconciliation كـ Domain Concept، لكنه لا يحسم بعد جميع تفاصيل التنفيذ المحاسبي.

يجب تحديدها قبل تنفيذ العملية، ومنها:

الحسابات المسموح لها بالـ Reconciliation.

كيفية تحديد الـ debit/credit حسب Account Nature.

الـ Journal Entry النهائي.

تأثير العملية على Net Worth.

هل جميع أنواع الحسابات تقبل Reconciliation أم أنواع محددة فقط.

قائمة ReconciliationReason النهائية.

سياسة Correction / Invalidation.

Idempotency semantics للعملية.

Transaction Type الخاص بالـ Reconciliation إن كان مطلوبًا.

قواعد الـ Planner والـ Domain Guards.

12. النتيجة المعمارية

Account
  │
  └── Metadata / Configuration

Ledger
  │
  └── Financial Truth

Balance
  │
  └── Derived from Financial Truth

Direct Balance Editing
  ✗ Forbidden

Balance Reconciliation
  ✓ Financial Operation

Temporary Debt Settlement
  ✓ Separate Financial Operation

والقاعدة الأساسية:

لا يتم تعديل الرصيد نفسه. يتم تسجيل العملية المالية التي تفسر لماذا يجب أن يصبح الرصيد مختلفًا.

13. حالة القرار

Accepted — Architectural Decision

تم اعتماد:

منع Direct Balance Editing.

جعل الرصيد Read-only في Account Edit.

اعتماد Balance Reconciliation كالمسار الرسمي لمعالجة فروق الرصيد.

عدم استخدام Opening Balance أو Temporary Debt كبديل للـ Reconciliation.

عدم تنفيذ العملية قبل اعتماد الـ Accounting Contract الخاص بها.

التالي: تصميم BalanceReconciliationIntent وBalanceReconciliationOperation والـ Planner/Journal contract قبل كتابة الكود.