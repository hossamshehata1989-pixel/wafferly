ADR-008 — Rich Financial Operations

Status: Accepted

Date: 2026-07-10

Owner: Financial Engine Team

Context

خلال دمج الـ Financial Engine مع التطبيق الحقيقي (Sprint 1)، اكتشفنا أن الـ Engine تنجح في تنفيذ الـ Planning والـ Journal، لكنها لا تستطيع إنشاء Transaction حقيقية داخل النظام.

سبب المشكلة لم يكن في الـ Executor أو الـ Planner أو الـ Mutation Handlers، وإنما في تصميم الـ Write Model نفسه.

حالياً يدخل إلى الـ Engine:

ExpenseOperation

والذي يحتوي على معلومات محدودة فقط:

sourceAccountId
amount
categoryId
occurredAt
note

بينما Transaction الحقيقية داخل النظام تحتوي على معلومات إضافية كثيرة مثل:

paymentMethod
currencyCode
subCategoryId
actorMemberId
source
isExceptional
createdAt
updatedAt
id

وبالتالي لا تستطيع الـ Planner إنشاء Transaction دون إعادة تكوين بيانات فقدت قبل دخول الـ Engine.

هذا يؤدي إلى:

تكرار منطق إنشاء Transaction.
تكرار قواعد العمل.
كسر مبدأ Single Source of Truth.
صعوبة إضافة Mutations جديدة مستقبلاً.
Decision

لن تقوم الـ Planner بإنشاء Transaction من بيانات ناقصة.

بدلاً من ذلك، سيتم إدخال الحدث المالي بالكامل إلى الـ Financial Engine منذ البداية.

سيتم إنشاء نموذج جديد يسمى:

FinancialTransactionData

ويصبح هو الحمولة (Payload) الأساسية التي تنتقل عبر جميع مراحل الـ Engine.

New Write Flow
Presentation
        │
        ▼
TransactionEntryController
        │
        ▼
FinancialTransactionData
        │
        ▼
ExpenseOperation
        │
        ▼
Financial Interpreter
        │
        ▼
NormalizedIntent
        │
        ▼
Planner
        │
        ▼
FinancialExecutionPlan
        │
        ├── TransactionMutation
        ├── JournalMutation
        ├── AllocationMutation
        ├── GoalActivityMutation
        └── ...
        │
        ▼
Executor
Responsibilities
FinancialTransactionData

يمثل الحدث المالي كما أدخله المستخدم.

لا يحتوي أي منطق.

هو DTO فقط.

ExpenseOperation

يمثل Intent مالي.

يحتوي على:

FinancialTransactionData

وليس مجموعة كبيرة من المتغيرات المنفصلة.

Interpreter

يقوم بتحويل:

FinancialTransactionData

إلى

NormalizedIntent

اللازمة لاتخاذ القرار المالي.

Planner

لا تعيد إنشاء Transaction.

بل تستخدم FinancialTransactionData الموجودة بالفعل لإنتاج:

TransactionMutation
JournalMutation
AllocationMutation
GoalActivityMutation
...
Executor

ينفذ الـ Mutations فقط.

ولا ينشئ أي بيانات جديدة.

Benefits
Single Source of Truth

يتم إنشاء بيانات العملية مرة واحدة فقط.

No Data Reconstruction

لا تحتاج أي طبقة إلى إعادة بناء Transaction.

Clean Architecture

الـ Engine تستقبل DTO مستقلاً عن Hive.

Testability

يمكن اختبار الـ Engine باستخدام FinancialTransactionData دون الحاجة إلى Controller أو UI.

Extensibility

إضافة خصائص مستقبلية مثل:

OCR
SMS
Voice
AI
Import CSV

لن يتطلب تعديل جميع الطبقات.

CQRS Ready

FinancialTransactionData تمثل Command Payload.

NormalizedIntent تمثل Domain Intent.

FinancialExecutionPlan تمثل Execution Plan.

وهذا يتوافق مع انتقال المشروع لاحقاً إلى CQRS الكامل.

Consequences

سيتم تعديل:

ExpenseOperation
IncomeOperation
TransferOperation

لتعتمد على:

FinancialTransactionData

بدلاً من تمرير عدد كبير من الخصائص.

لن يتم تعديل:

FinancialOperationEngine
Planner Pipeline
Executor Pipeline
Policy Pipeline

لأن التغيير يخص نموذج الإدخال فقط.

Deferred Work

لن يتم تنفيذ:

TransactionMutation
HiveTransactionPort
TransactionHandler

إلا بعد اكتمال FinancialTransactionData.

وبذلك يتم تنفيذها مرة واحدة فقط بالشكل الصحيح.

Architectural Principle

Financial Truth starts with a complete Financial Event.

وليس مع Transaction، ولا مع Journal، ولا مع Ledger.

فالحدث المالي الكامل هو نقطة الدخول الوحيدة إلى الـ Financial Engine.