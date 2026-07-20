ADR-0011 — Financial Command Model

Status: Accepted

Date: 2026-07-10

Owner: Wafferly Financial Architecture

Scope: Financial Engine — Write Model

Context

أثناء دمج (Integration) الـ Financial Engine مع التطبيق الحقيقي، ظهر خلل معماري في نقطة دخول (Entry Point) الـ Engine.

الـ Financial Engine تستقبل حالياً عمليات مثل:

ExpenseOperation
IncomeOperation
TransferOperation

لكن هذه العمليات لا تحتوي إلا على جزء محدود من بيانات الحدث المالي.

في المقابل، إنشاء الـ Transaction الفعلية داخل النظام يتطلب بيانات إضافية لا تصل إلى الـ Engine، مما يؤدي إلى:

فقدان معلومات قبل دخول الـ Engine.
إعادة بناء نفس البيانات في أكثر من طبقة.
تكرار منطق إنشاء الـ Transaction.
صعوبة إضافة Mutations جديدة.
زيادة احتمالية وجود أكثر من مصدر للحقيقة (Multiple Sources of Truth).

أثناء المراجعة تمت دراسة عدة بدائل، منها:

DTO موحد (FinancialTransactionData).
Payload مستقل لكل عملية.
تقسيم البيانات حسب المفاهيم (Concepts).


Decision Drivers
This decision is driven by the following architectural goals:

- Preserve Accounts as the only Source of Truth.
- Eliminate data loss before entering the Financial Engine.
- Prevent God Objects and duplicated payloads.
- Keep the Financial Engine independent from Infrastructure.
- Maintain strict separation of responsibilities.
- Support future financial channels (SMS, OCR, Voice, AI, API).
- Keep the Write Model compatible with future CQRS adoption.

Decision

يعتمد المشروع نموذج Financial Command Model كنقطة الدخول الوحيدة إلى الـ Financial Engine.

لن يتم استخدام DTO موحد يحمل جميع البيانات، ولن يتم إنشاء Payload مستقل لكل عملية.

بدلاً من ذلك سيتم تقسيم البيانات إلى ثلاثة مفاهيم مستقلة، لكل منها مسؤولية واضحة.

ExpenseCommand
│
├── ExpenseIntent
├── TransactionMetadata
└── ExecutionContext

وينطبق نفس المبدأ على:

IncomeCommand
TransferCommand
GoalTransferCommand
DebtCommand
Future Commands
Architectural Model
Presentation
        │
        ▼
Application Service
        │
        ▼
ExpenseCommand
        │
        ├── ExpenseIntent
        ├── TransactionMetadata
        └── ExecutionContext
        │
        ▼
Financial Interpreter
        │
        ▼
NormalizedIntent
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
FinancialExecutionPlan
        │
        ▼
Executor
Responsibilities
1. Financial Intent

يمثل الحقيقة المالية (Financial Truth) للعملية.

ويحتوي فقط على البيانات التي تؤثر على القرارات المالية.

أمثلة:

amount
sourceAccountId
destinationAccountId
categoryId
goalId
debtId

أي تغيير داخل الـ Intent قد يؤدي إلى تغيير في الرصيد أو القيود المحاسبية أو قواعد المجال (Domain Rules).

2. Transaction Metadata

تمثل وصف العملية (Transaction Description).

ولا تؤثر على الحقيقة المالية.

أمثلة:

note
occurredAt
paymentMethod
currencyCode

وتستخدم عند:

إنشاء Transaction
عرض البيانات للمستخدم
التقارير
البحث
Constraint

TransactionMetadata يجب أن تحتوي فقط على البيانات المشتركة بين جميع أنواع العمليات.

أي حقل خاص بعملية معينة لا يجوز إضافته إليها.

3. Execution Context

يمثل بيئة التنفيذ فقط.

ولا يمثل أي جزء من الـ Domain Model.

أمثلة:

actorMemberId
source (UI / SMS / OCR / API)
requestId
correlationId
idempotencyKey

ويستخدم في:

Idempotency
Audit
Observability
Logging

ولا يجوز أن يؤثر على Business Logic.

Pipeline Responsibilities

كل مرحلة داخل الـ Financial Engine تقرأ فقط البيانات التي تحتاجها.

إذن تصبح:

Stage	Intent	Metadata	Context
Interpreter	✅	✅	✅
Domain Guard	✅	❌	❌
Policy	✅	❌	❌
Planner	✅	✅	❌
Executor	❌	❌	❌
Audit	✅	✅	✅


Architectural Constraints

Invariants
The following invariants must always hold:

1. Every Financial Command contains exactly one Intent.

2. Every Intent represents exactly one financial event.

3. Every FinancialExecutionPlan is derived from exactly one Intent.

4. Accounts remain the only Source of Truth.

5. The Financial Engine remains the only writer of Financial Truth.

6. TransactionMetadata never affects account balances.

7. ExecutionContext never changes business decisions.

=======================================================


Rule 1 — Financial Truth
Financial decisions must be derived only from the Intent.

TransactionMetadata may enrich persisted records,
but must never change the resulting financial state.

----


Rule 2 — Execution Isolation

ExecutionContext لا يجوز استخدامها لاتخاذ أي قرار مالي.

لا يجوز كتابة منطق مثل:

if (context.source == Source.sms) {
  ...
}

داخل:

Planner
Policy
Domain Guard


---

Rule 3 — Shared Metadata Only

TransactionMetadata لا يجوز أن تحتوي على بيانات تخص عملية معينة فقط.

أمثلة غير مسموح بها:

goalId
installmentNumber
investmentId
recurringScheduleId

هذه البيانات تنتمي إلى الـ Intent الخاصة بالعملية.


---

Rule 4 — No God Objects

لا يجوز إنشاء DTO يحتوي جميع البيانات الخاصة بجميع أنواع العمليات.

أي تصميم يؤدي إلى DTO تتزايد مسؤولياته بمرور الوقت يعتبر مخالفاً لهذه المعمارية.


---


Rule 5 — Minimal Visibility

كل مرحلة داخل الـ Engine يجب أن ترى أقل قدر ممكن من البيانات.

لا يجوز لأي مرحلة الوصول إلى بيانات لا تستخدمها.

Consequences
Positive
فصل واضح بين Domain وInfrastructure.
منع تحول الـ DTO إلى God Object.
تقليل الـ Coupling بين طبقات النظام.
إعادة استخدام عالية.
سهولة إضافة مصادر إدخال جديدة (SMS، OCR، Voice، API).
توافق كامل مع Clean Architecture وDDD.
جاهزية مستقبلية لـ CQRS.
Negative
زيادة عدد الكائنات (Objects) الداخلة إلى الـ Engine.
الحاجة إلى بناء Commands داخل Application Layer.
الحاجة إلى تحديث الـ Interpreter لاستقبال النموذج الجديد.

هذه التكلفة مقبولة مقابل الاستقرار طويل المدى.

Deferred Work

هذا القرار لا يغير:

Planner Algorithm
Executor
Policy Engine
Domain Guard
Journal Architecture

وسيتم تطبيقه تدريجياً أثناء استكمال دمج الـ Financial Engine.

Architectural Principles Preserved

هذا القرار يحافظ بالكامل على المبادئ الأساسية لـ Wafferly V4:

Accounts are the only Source of Truth.
Financial Engine is the only Writer of Financial Truth.
Single Source of Truth.
Clean Architecture.
Dependency Inversion.
Ports & Adapters.
Domain-Driven Design (DDD).
CQRS-ready Architecture.
===========================================

Future Extensions

This architecture intentionally leaves room for future command sources:

- SMS Parsing
- OCR
- Voice Commands
- AI Assistant
- API Integrations
- Scheduled Automations
- Shared Finance
- Business Books

These integrations should introduce new Command producers only.

No modification to the Financial Engine pipeline should be required.

==============================================

Rationale

تم رفض DTO موحد لأنه يؤدي مع الوقت إلى God Object يصعب صيانته.

كما تم رفض إنشاء Payload مستقل لكل عملية لأنه يؤدي إلى تكرار البيانات المشتركة وزيادة تكلفة الصيانة.

تم اعتماد Financial Command Model لأنه يفصل البيانات حسب المسؤولية (Responsibility) وليس حسب نوع العملية، مما يوفر توازناً بين المرونة، وقابلية التوسع، والمحافظة على حدود الطبقات (Architectural Boundaries) دون المساس بمصدر الحقيقة المالي أو استقلالية الـ Financial Engine.

---



Rule 6 — Domain Purity

Financial decisions must never depend on the execution channel.

Examples:

❌

if (source == sms)

❌

if (source == api)

❌

if (source == ocr)

داخل:

Policy
Planner
Domain Guard

ممنوع.


---


Migration Completion
Migration is complete when:

• No legacy FinancialOperation enters the Financial Engine.

• All write operations use Financial Commands.

• Transaction creation is performed only through the Execution Plan.

• Legacy entry points are removed.