ADR-0XX — Delete Operation Requires Transaction Snapshot
Status

Accepted ✅

Context

أثناء تنفيذ Delete Transaction داخل Financial Engine V4، كان التصميم الأول يعتمد على:

DeleteTransactionIntent
    ↓
transactionId

ثم يقوم الـ FinancialPlanner بتحميل المعاملة باستخدام TransactionLookupPort.

الفكرة كانت تقليل البيانات المنقولة داخل الـ Operation وجعل الـ Planner هو المسؤول عن استرجاع المعاملة.

Problem

ترتيب الـ Engine هو:

Interpreter
    ↓
Domain Guard
    ↓
Policy
    ↓
Planner
    ↓
Integrity
    ↓
Executor

وبالتالي فإن:

Interpreter يعمل قبل Planner.
Domain Guards تعمل قبل Planner.
Policies تعمل قبل Planner.

بينما DeleteTransactionIntent كان يحتوي فقط على:

transactionId

ولذلك لم يكن الـ Interpreter قادرًا على إنشاء NormalizedIntent لأن الحقول التالية مطلوبة:

amount
sourceAccountId
categoryId
actorMemberId
isExceptional

وهذه البيانات لا يمكن الحصول عليها إلا بعد تشغيل الـ Planner، وهو متأخر في الـ Pipeline.

Decision

تم تغيير التصميم ليصبح:

UI
    ↓
Application Service
    ↓
Load Transaction
    ↓
DeleteTransactionIntent(transaction)
    ↓
DeleteOperation

أي أن الـ Application Layer تقوم بتحميل المعاملة أولًا ثم تمرر Snapshot كامل إلى الـ Engine.

Rationale

هذا القرار يسمح للـ Interpreter بإنشاء NormalizedIntent بصورة صحيحة دون:

إدخال قيم وهمية.
جعل حقول NormalizedIntent اختيارية.
إضافة استثناءات خاصة بعملية الحذف.

كما يحافظ على ثبات تصميم الـ Engine وعدم إدخال حالات خاصة داخل الـ Domain Guard أو الـ Policy Layer.

Consequences
Advantages
جميع مراحل الـ Engine تمتلك البيانات التي تحتاجها.
لا يوجد Special Case للحذف.
NormalizedIntent يبقى ثابتًا لجميع العمليات.
Domain Guards تعمل بنفس الطريقة مع جميع أنواع العمليات.
Policy Pipeline لا تحتاج أي استثناءات.
الـ Planner يصبح مسؤولًا عن التخطيط فقط، وليس استكمال البيانات الناقصة.
Trade-offs
Application Layer تقوم بعملية Lookup واحدة قبل إنشاء الـ Operation.
الـ Operation أصبح يحمل Snapshot بدلًا من Identifier فقط.

هذا مقبول لأن الـ Snapshot يمثل الحالة الفعلية التي سيتم تنفيذ العملية عليها، وهو أكثر استقرارًا من إعادة القراءة لاحقًا.

Alternatives Considered
Alternative A

تحميل المعاملة داخل Planner.

Rejected

يكسر ترتيب الـ Engine لأن Interpreter وDomain Guard وPolicy تعمل قبل Planner.

Alternative B

جعل NormalizedIntent.amount وsourceAccountId اختيارية.

Rejected

يؤدي إلى انتشار التعامل مع null داخل جميع الـ Guards والـ Policies ويضعف العقد (Contract) الخاص بـ NormalizedIntent.

Alternative C

استخدام قيم وهمية مثل:

amount = 0
sourceAccountId = ""

Rejected

يمثل بيانات غير صحيحة (Domain Lie) وقد يؤدي إلى قرارات خاطئة داخل الـ Engine.

Result

تم تنفيذ Delete Transaction بالكامل من خلال الـ Financial Engine، وأصبح مسار التنفيذ:

Application Service
        │
        ▼
Load Transaction Snapshot
        │
        ▼
DeleteTransactionIntent
        │
        ▼
DeleteOperation
        │
        ▼
Interpreter
        │
        ▼
Domain Guard
        │
        ▼
Policy
        │
        ▼
Planner
        │
        ▼
Integrity Checker
        │
        ▼
Executor

وقد تم التحقق من نجاح التنفيذ بوصول العملية إلى:

ENGINE RESULT = OperationSucceeded

مع حذف المعاملة فعليًا من قاعدة البيانات أثناء التنفيذ.