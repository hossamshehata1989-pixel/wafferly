ADR-029 — Planning Execution Plan
Status

✅ Accepted

Context

Planning Engine بدأت بـ Pipeline:

Operation
    ↓
Interpreter
    ↓
Guards
    ↓
Policies
    ↓
Planner
    ↓
ExecutionPlan
    ↓
Integrity
    ↓
Executor

فى البداية كانت PlanningExecutionPlan مجرد Placeholder.

لكن مع قرب تنفيذ:

Split
Merge
Reallocate

أصبح لابد أن تصبح الخطة (Execution Plan) تمثل خطوات التنفيذ الفعلية.

Decision
PlanningExecutionPlan تصبح:
PlanningExecutionPlan

وتحتوى فقط على:

List<PlanningMutation>

bool requiresUserApproval

ولا أى حقول أخرى.

PlanningMutation

ليست CRUD.

وليست Database Operations.

بل تمثل Domain Mutations.

الأنواع الحالية فقط:

ReserveMutation

ReleaseMutation

ولا يوجد غيرهما.

العمليات المركبة تُترجم إلى مجموعة من هذه الـ Mutations.

مثال:

Split

↓

ReleaseMutation

ReserveMutation

ReserveMutation
Merge

↓

ReleaseMutation

ReleaseMutation

ReserveMutation
Reallocate

↓

ReleaseMutation

ReserveMutation
Responsibilities
Interpreter

يفهم نوع العملية فقط.

Guards

يتحقق من صحة الطلب.

Policies

يطبق قواعد العمل.

Planner

هو Decision Maker.

يبنى ExecutionPlan كاملة.

ويقرر:

Reserve
Release
ترتيب التنفيذ

ولا يترك أى قرار للـ Executor.

Integrity

تراجع الخطة كاملة.

مثال:

Split

1000

↓

600

+

200

+

200

✔
Executor

تنفذ الخطة فقط.

ولا تعرف:

Goal
Budget
Split
Merge
Reallocate

بل تعرف فقط:

PlanningMutation
Rejected Alternatives
CRUD Mutations
CreateAllocation

UpdateAllocation

DeleteAllocation

تم رفضها.

السبب:

تفقد الـ Domain Semantics.

وتجعل Audit و Integrity أصعب.

Rich Execution Plan

تم رفض:

Preconditions

Expected Effects

Compensation

Metadata

السبب:

كل منها يكرر مسئولية موجودة بالفعل داخل:

Guards
Policies
Integrity
Saga/Application Layer

ويحول ExecutionPlan إلى God Object.

Consequences

Split و Merge و Reallocate لن تحتاج أى منطق داخل Executor.

بل تتحول كلها إلى PlanningMutations.

وبذلك يصبح Executor ثابتًا مهما زاد عدد أنواع العمليات.

Future

لاحقًا فقط يمكن إضافة:

UnitOfWork

Optimistic Locking

PlanningOperation Store

دون الحاجة لتعديل PlanningExecutionPlan.

القرار المعمارى النهائى

أنا شايف إننا وصلنا للشكل اللى كنت أتمنى نوصل له من أول يوم.

والأجمل إننا ما وصلناش له بالـ "فلسفة"، وصلنا له بعد ما بنينا Reserve وRelease فعلًا، وشفنا أين تبدأ المسئوليات تختلط.