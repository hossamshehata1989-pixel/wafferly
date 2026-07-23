ADR-0014 — Financial Operation Resolution Pipeline

Status: Proposed

1. Context

بدأ Financial Engine في Wafferly كنظام Generic.

كان الـ Pipeline كالتالي:

Command
    ↓
Intent
    ↓
Operation
    ↓
Interpreter
    ↓
NormalizedIntent
    ↓
Planner
    ↓
ExecutionPlan
    ↓
Executor

وكانت مسؤولية الـ Interpreter هي تحويل العمليات المختلفة إلى نموذج موحد (NormalizedIntent) يستطيع الـ Planner التعامل معه.

مع تطور النظام وإضافة Financial Engine الحقيقي، ثم الانتقال إلى Typed Operations، تغيرت طبيعة هذه الطبقة بالكامل.

أصبحت العمليات المالية المستقبلية تشمل:

Expense
Income
Transfer
Investment Buy
Investment Sell
Dividend
Interest
FX
Debt Settlement
وغيرها.

وأصبحت كل عملية تحمل خصائص مختلفة جذريًا.

في الوقت نفسه ظهرت حاجة إلى عمليات مثل:

Resolve FX Rate
Resolve FIFO/LIFO Lots
Resolve Default Accounts
Resolve Fees
Resolve Taxes
Resolve Settlement Accounts

وكلها تعتمد على I/O وعلى حالة النظام الحالية.

2. Problem Statement

أصبح اسم:

Interpreter

غير معبر عن المسؤولية الفعلية.

كما أصبح:

NormalizedIntent

لا يقوم بأي Normalization بعد الانتقال إلى Typed Operations.

وفي المقابل يجب الحفاظ على أن تكون:

Planner

Pure Function بالكامل.

أي لا تعتمد على:

Repository
APIs
Storage
Services
أي I/O
3. Architectural Decision

سيتم إعادة تعريف المرحلة الواقعة بين Operation وPlanner.

بدلاً من:

Interpreter
        ↓
NormalizedIntent

سيصبح لدينا:

OperationResolver
        ↓
ResolvedOperation
4. Responsibilities
Operation

يمثل نية المستخدم أو النظام.

لا يحتوي إلا على المعلومات المعروفة لحظة إنشاء العملية.

مثال:

InvestmentSellOperation

قد يحتوي على:

InstrumentId
Quantity

ولا يحتوي على:

Matched Lots
Realized Gain
Taxes
Fees
OperationResolver

هذه المرحلة هي المرحلة الوحيدة المسموح لها بعمل I/O قبل التخطيط.

مسؤولياتها:

Repository Lookups
FX Resolution
FIFO/LIFO Resolution
Default Account Resolution
Fee Resolution
Tax Resolution
Configuration Resolution
Policy Resolution

كما تقوم ببناء Snapshot كامل للحالة المطلوبة للتخطيط.

ResolvedOperation

يمثل العملية بعد اكتمال جميع الحقائق المطلوبة.

يحتوي فقط على بيانات نهائية ثابتة (Immutable Snapshot).

مثال:

ResolvedInvestmentSellOperation

قد يحتوي على:

matchedLots
realizedGain
exchangeRate
settlementAccount
fees
taxes

ولا يحتاج أي Lookup إضافي.

Planner

Planner يجب أن تكون Pure.

ممنوع عليها:

Repository
HTTP
Hive
Ports
Services
أي I/O

مدخلاتها:

ResolvedOperation

مخرجاتها:

ExecutionPlan

وتقتصر مسؤوليتها على:

تحويل الحقائق المالية الجاهزة إلى Mutations مالية.

5. Domain Validation Pipeline

تم تقسيم قواعد الـ Domain إلى نوعين.

Structural Validation

تعتمد فقط على العملية نفسها.

لا تحتاج إلى أي بيانات خارجية.

أمثلة:

Amount > 0
الحسابات مختلفة
Category موجودة
Quantity > 0

تنفذ قبل Resolution.

Contextual Validation

تعتمد على حالة النظام.

تحتاج Resolution أولاً.

أمثلة:

الرصيد كافٍ
السهم موجود
عدد الأسهم كافٍ
سعر الصرف متاح
السوق مفتوح
حدود الائتمان

تنفذ بعد Resolution.

6. Final Pipeline
Command
        │
        ▼
Intent
        │
        ▼
Typed Operation
        │
        ▼
Structural Validation
        │
        ▼
OperationResolver
        │
        ▼
ResolvedOperation
        │
        ▼
Contextual Validation
        │
        ▼
Planner (Pure)
        │
        ▼
ExecutionPlan
        │
        ▼
Executor
7. Expected Benefits
إزالة مفهوم Interpreter الذي لم يعد يعبر عن المسؤولية الفعلية.
إزالة NormalizedIntent التي لم تعد تقوم بعملية Normalization.
الحفاظ على Planner كدالة نقية (Pure Function).
فصل واضح بين I/O والمنطق المالي.
دعم طبيعي للاستثمارات، والـ FX، والديون، والمنتجات المالية المستقبلية.
تحسين قابلية الاختبار (Testability) عبر اختبار كل مرحلة بمعزل عن الأخرى.
توفير Snapshot قابل لإعادة التنفيذ (Replay) والتدقيق (Audit) لأنه يجمد الحقائق المستخدمة وقت اتخاذ القرار.
8. Open Questions

قبل اعتماد هذا الـ ADR نهائيًا، ما زالت هناك عدة قرارات معمارية تحتاج للحسم:

ما نقطة بداية الـ Typed Hierarchy؟
هل تبدأ من Operation فقط؟
أم من Intent أيضًا؟
هل يكون ResolvedOperation عبارة عن Sealed Hierarchy موازية لـ Operation؟
ResolvedExpenseOperation
ResolvedTransferOperation
ResolvedInvestmentSellOperation
...
هل الـ OperationResolver نفسه يكون Service واحدة تقوم بالتوجيه (Routing)، أم تكون هناك Resolvers متخصصة لكل نوع (ExpenseResolver، InvestmentResolver، ...)، مع واجهة مشتركة؟