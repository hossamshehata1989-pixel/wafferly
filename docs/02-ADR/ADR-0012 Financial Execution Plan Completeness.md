ADR-0012 — Financial Execution Plan Completeness

Status: Accepted

Date: 2026-07-10

Owner: Wafferly Financial Architecture

Scope: Financial Engine — Planning & Execution

Context

أثناء استكمال دمج (Integration) الـ Financial Engine مع التطبيق الحقيقي، تم اكتشاف أن الـ FinancialExecutionPlan قد تنجح وتُنفذ بالكامل، بينما لا يتم إنشاء جميع الآثار (Side Effects) اللازمة للعملية المالية.

في الوضع الحالي، يقوم الـ Planner بإنشاء بعض الـ Mutations فقط (مثل JournalEntryMutation)، بينما يتم إنشاء أجزاء أخرى من الحقيقة المالية خارج الـ Engine أو لا يتم إنشاؤها إطلاقًا.

أدى ذلك إلى ظهور حالات مثل:

نجاح العملية (OperationSucceeded).
عدم إنشاء Transaction.
عدم تحديث الرصيد الظاهر للمستخدم.
عدم ظهور العملية في صفحة المعاملات.
عدم ظهورها في التحليلات.

رغم أن الـ Engine تعتبر العملية ناجحة.

وهذا يمثل خرقًا لمبدأ:

Financial Engine is the only Writer of Financial Truth.

Problem

وجود أجزاء من الحقيقة المالية يتم إنشاؤها خارج الـ FinancialExecutionPlan يؤدي إلى:

تعدد أماكن كتابة الحقيقة المالية.
فقدان الاتساق بين البيانات.
صعوبة ضمان Atomicity.
صعوبة تنفيذ Rollback.
زيادة Coupling بين الـ Engine والخدمات الخارجية.
Decision

يعتمد المشروع المبدأ التالي:

FinancialExecutionPlan must contain every mutation required to materialize the financial operation.

أي أن الـ Planner مسؤولة عن إنتاج جميع الـ Mutations اللازمة لتنفيذ العملية بالكامل.

ولا يجوز لأي طبقة خارج الـ Financial Engine إنشاء آثار مالية إضافية بعد تنفيذ الـ Plan.

Responsibilities
Planner

مسؤولة عن:

تحليل الـ Intent.
إنشاء FinancialExecutionPlan.
إنشاء جميع الـ Mutations المطلوبة.

ولا تقوم بأي كتابة مباشرة للبيانات.

Execution Plan

يمثل الوصف الكامل (Complete Description) لما يجب أن يحدث.

ويحتوي على جميع الـ Mutations اللازمة.

Executor

مسؤولة فقط عن تنفيذ الـ Plan.

ولا يجوز لها:

إنشاء Mutations جديدة.
اتخاذ قرارات مالية.
استنتاج بيانات مفقودة.
Mutation Handlers

كل Handler مسؤولة عن تنفيذ Mutation واحدة فقط.

ولا يجوز لها إنشاء Mutations إضافية.

Required Completeness

كل عملية مالية يجب أن تنتج جميع الـ Mutations اللازمة لتمثيل الحقيقة المالية بالكامل.

على سبيل المثال:

Expense
Expense Plan
│
├── CreateTransactionMutation
├── CreateJournalEntryMutation
├── BalanceMutation (إذا كانت مطلوبة)
└── Any domain-specific mutations
Income
Income Plan
│
├── CreateTransactionMutation
├── CreateJournalEntryMutation
└── ...
Goal Transfer
Goal Transfer Plan
│
├── CreateTransactionMutation
├── CreateJournalEntryMutation
├── ReleaseAllocationMutation
├── GoalActivityMutation
└── ...
Architectural Constraints
Rule 1 — Complete Planning

لا يجوز أن يعتمد نجاح العملية على Mutation يتم إنشاؤها خارج الـ Planner.

Rule 2 — No Hidden Side Effects

لا يجوز لأي Service أو Repository إنشاء Transaction أو Journal أو Allocation بشكل ضمني بعد انتهاء الـ Executor.

جميع الآثار يجب أن تكون ممثلة داخل FinancialExecutionPlan.

Rule 3 — Executor Is Passive

الـ Executor تنفذ فقط.

ولا يجوز لها:

إنشاء Transaction.
إنشاء Journal.
إنشاء Allocation.
اتخاذ أي قرار مالي.
Rule 4 — Mutation Independence

كل Mutation تمثل تغييرًا ذريًا (Atomic Change).

ويجب أن تكون قابلة للتنفيذ بصورة مستقلة داخل Unit of Work.

Consequences
Positive
جميع التغييرات المالية تصبح مرئية داخل الـ ExecutionPlan.
سهولة مراجعة أي عملية مالية قبل تنفيذها.
دعم كامل للـ Atomicity والـ Rollback.
تقليل الـ Coupling.
دعم أفضل للاختبارات (Planner يمكن اختبارها دون الحاجة إلى Hive).
Negative
زيادة عدد الـ Mutations داخل بعض العمليات.
الحاجة إلى إنشاء Mutation جديدة لكل نوع من أنواع التغييرات المالية.

وهذه تكلفة مقبولة مقابل وضوح النظام وقابليته للتوسع.

Invariants

يجب أن تتحقق القواعد التالية دائمًا:

كل FinancialExecutionPlan تمثل الوصف الكامل للعملية.
لا توجد كتابة للحقيقة المالية خارج الـ ExecutionPlan.
كل Mutation مسؤولة عن تغيير واحد فقط.
الـ Executor لا تضيف ولا تحذف Mutations.
نجاح الـ Engine يعني أن جميع Mutations الموجودة في الـ Plan قد تم تنفيذها داخل Unit of Work واحدة.
Relationship to Previous ADRs

ADR-0010

يحافظ على أن Accounts هي المصدر الوحيد للحقيقة المالية.

ADR-0011

يعتمد على Financial Command Model لإنتاج الـ Intent.

ADR-0012 (هذا القرار)

يحدد أن الـ Planner هي المسؤولة عن تحويل الـ Intent إلى خطة تنفيذ كاملة (Complete Execution Plan)، وأن الـ Executor تنفذ هذه الخطة دون تعديل.

Rationale

تم رفض تصميم يعتمد على إنشاء بعض التغييرات المالية داخل الـ Executor أو الخدمات الخارجية، لأنه يؤدي إلى تعدد أماكن كتابة الحقيقة المالية، ويكسر مبدأ أن الـ Financial Engine هي الكاتب الوحيد للحقيقة المالية.

تم اعتماد مبدأ Complete Execution Plan بحيث تصبح جميع الآثار المالية ممثلة بصورة صريحة داخل الـ FinancialExecutionPlan قبل بدء التنفيذ، مما يجعل النظام أكثر وضوحًا، وأسهل في الاختبار، وأكثر توافقًا مع مبادئ DDD وClean Architecture وUnit of Work.