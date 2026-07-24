ADR-0016 — Financial Write Model & Ledger Projection

Status: Accepted

Date: 2026-07-24

Context

بعد الانتهاء من مراجعة الـ Financial Engine، ومراجعة المشروع بالكامل، ظهر أن المشروع يمر بمرحلة انتقالية (Migration) من الـ Legacy TransactionService إلى Financial Engine.

حالياً يوجد مساران مختلفان لإنشاء البيانات المالية:

Financial Engine
    ↓
CreateTransactionMutation
    ↓
HiveTransactionPort

و

TransactionService
    ↓
TransactionLedgerBuilder
    ↓
LedgerService

كما أن الـ Planner ينشئ أيضاً:

JournalEntryMutation

والتي تمثل الحقيقة المحاسبية (Accounting Intent) ولكنها لا تُستخدم حالياً لإنشاء الـ Ledger.

هذا أدى إلى:

تكرار منطق الـ Debit/Credit.
وجود أكثر من Writer للبيانات المالية.
اختلاف محتمل بين الـ Journal والـ Ledger.
استمرار اعتماد أجزاء من التطبيق على الـ Legacy Service.
Problem

كان أمامنا تصميمان محتملان:

Option A
JournalEntryMutation
        ↓
Journal Handler
        ↓
Ledger

أو

Option B
CreateTransactionMutation
        ↓
CreateTransactionHandler
        ↓
Ledger Projection Builder
        ↓
LedgerPort
Decision

يعتمد Wafferly التصميم التالي:

Operation
        │
        ▼
Planner
        │
        ├───────────────┐
        ▼               ▼
JournalMutation   CreateTransactionMutation
                        │
                        ▼
            CreateTransactionHandler
                        │
                        ├──────────────┐
                        ▼              ▼
           TransactionPort.save()   LedgerProjectionService.project(record)
                                             │
                                             ▼
                               TransactionLedgerBuilder.build(record)
                                             │
                                             ▼
                                     LedgerPort.persist(entries)
Rationale
1. FinancialTransactionRecord هو الـ Write Model الحقيقي

يمتلك:

transactionId
amount
occurredAt
account ids
category
payment method
note

وهي جميع البيانات المطلوبة لبناء LedgerEntry.

بينما JournalEntryMutation لا تمتلك هذه البيانات، ولا ينبغي تحميلها بها.

2. JournalEntryMutation تظل Accounting Model

مسؤوليتها الوحيدة:

تمثيل القيد المحاسبي.
دعم Integrity Rules.
التحقق من توازن القيود.
تمثيل الأثر المحاسبي للعملية.

ولا تتحمل بيانات Application أو UI.

3. Ledger هو Projection

داخل Wafferly:

Transaction تمثل الـ Business Transaction.
Journal تمثل الـ Accounting Intent.
Ledger يمثل Persistent Projection يُستخدم للأغراض المحاسبية والتحليلية.

Ledger is derived from the Financial Write Model and must never become an independent source of business truth.

ولهذا يتم إنشاء الـ Ledger Projection بواسطة LedgerProjectionService، والتي تستخدم TransactionLedgerBuilder لبناء الـ Ledger Entries.

4. عدم تلويث الـ Journal

لن تتم إضافة:

transactionId
category
purpose
note
actor
paymentMethod

إلى JournalEntryMutation.

أي Metadata مطلوبة للـ Ledger تأتي من FinancialTransactionRecord.

5. Single Responsibility

CreateTransactionHandler

↓

TransactionPort.save()

↓

LedgerProjectionService.project(record)

ثم داخل الخدمة:

LedgerProjectionService

↓

TransactionLedgerBuilder.build()

↓

LedgerPort.persist()


// ==================================================

Migration Plan (Updated)
Phase 1 — Introduce LedgerProjectionService
Goal

Introduce a coordinator responsible for creating Ledger projections without changing any existing behavior.

Responsibilities

LedgerProjectionService coordinates:

Idempotency validation.
Category → LedgerAccount resolution.
TransactionLedgerBuilder invocation.
Ledger persistence.
It MUST NOT
Save Transactions.
Contain CRUD logic.
Contain UI logic.
Replace TransactionLedgerBuilder.

TransactionLedgerBuilder remains responsible only for converting a Financial Transaction into immutable LedgerEntry objects.

Phase 2 — Introduce LedgerPort

Create:

LedgerPort

and

HiveLedgerPort

LedgerProjectionService must depend only on LedgerPort.

No direct dependency on LedgerService should remain.

Phase 3 — Move Ledger Projection into Financial Engine

Modify CreateTransactionMutationHandler.

Instead of:

Save Transaction

it becomes:

Save Transaction
↓

LedgerProjectionService.project(record)

The handler coordinates only.

Business rules remain inside:

LedgerProjectionService
TransactionLedgerBuilder
Phase 4 — Deprecate Legacy Ledger Writes

Remove:

TransactionService._createLedgerEntriesForTransaction()

TransactionService must no longer generate Ledger entries.

Phase 5 — Remove Legacy Write Path

Remove write operations from TransactionService.

Financial Engine becomes the only financial writer.

Phase 6 — Financial Corrections

Implement immutable financial corrections.

Current UpdateTransactionMutation is transitional.

Future design:

Reverse

↓

Create

↓

Ledger Projection



--------------------------------


Architectural Rules

وده أهم جزء في الـ ADR كله.

Architectural Rules
Rule 1

FinancialTransactionRecord is the Financial Write Model.

Rule 2

JournalEntryMutation is an Accounting Model.

It must remain free of:

transactionId
category
note
paymentMethod
actor
UI metadata
Rule 3

Ledger is generated as a Projection.

It is not manually created anywhere else.

Rule 4

TransactionLedgerBuilder is a Pure Builder.

It only converts a FinancialTransactionRecord into immutable LedgerEntries.

No persistence.

No database access.

No idempotency.

Rule 5

LedgerProjectionService is an Orchestrator.

Responsibilities:

resolve mappings
invoke builder
check idempotency
persist through LedgerPort

It contains no Transaction CRUD.

Rule 6

Mutation Handlers coordinate.

They do not contain accounting rules.

Rule 7

Only the Financial Engine may write Financial Truth.

Legacy services are temporary until migration completes.

ثالثًا: الخطة التنفيذية النهائية

أنا شايف إن دي هتبقى الـ Roadmap الرسمية للمشروع.


Rule 8

LedgerProjectionService is the only component allowed to create Ledger entries.

No other service, mutation handler, or application service may build Ledger entries directly.

TransactionLedgerBuilder must never be invoked outside LedgerProjectionService.



Rule 9 — Builder Purity

TransactionLedgerBuilder must be deterministic and side-effect free.

It must:

always produce identical LedgerEntries for identical input.
never access repositories.
never generate business decisions.
never depend on infrastructure.


============================================================
Financial Engine Migration Roadmap
STEP 0
ADR Approved

STEP 1
Introduce LedgerProjectionService

STEP 2
Move Mapping + Idempotency + Persistence into it

STEP 3
Introduce LedgerPort

STEP 4
Move LedgerProjectionService into CreateTransactionHandler

STEP 5

Regression Verification

Verify that:

- Expense
- Income
- Transfer

produce identical:

- Transactions
- Ledger Entries
- Account Balances

before and after the migration.

STEP 6
Remove Legacy Ledger Writes

STEP 7
Remove TransactionService Writes

STEP 8
Correction Refactor

STEP 9
Replace Memory Ports

STEP 10
Read Model Refactor


-------------------------------------------------
Migration Completion Criteria

The migration is considered complete when all of the following are true:

Financial Engine is the only component performing financial writes.
TransactionService performs no financial write operations.
Ledger entries are created exclusively through LedgerProjectionService.
TransactionLedgerBuilder has no infrastructure dependencies.
LedgerPort is used by all Ledger persistence operations.
Expense, Income, Transfer, and Correction flows are executed entirely through the Financial Engine.
All regression tests pass with identical financial results.

-------------------------------------------------



Consequences
الإيجابيات
إزالة ازدواجية منطق إنشاء Ledger.
جعل Financial Engine هو الكاتب الوحيد.
الحفاظ على نقاء JournalEntryMutation.
تحسين قابلية الاختبار.
تقليل احتمالات اختلاف Ledger عن Transaction.
تسهيل تنفيذ Correction مستقبلاً.
السلبيات

خلال فترة الـ Migration سيظل المشروع يحتوي على مسارين حتى يتم نقل جميع نقاط الكتابة إلى الـ Engine.

Non-goals

هذا القرار لا يغير حالياً:

Source of Truth للقراءة.
BalanceService.
Reports.
Analytics.
Financial Queries.

هذه ستناقش في ADR مستقل عند إعادة تصميم طبقة القراءة (Read Model).

Future Work

بعد اكتمال الـ Migration:

إزالة Legacy TransactionService Writes.
إنشاء HiveLedgerPort.
إنشاء HiveJournalEntryPort.
إعادة تصميم Correction وفق Immutable Financial History.
مراجعة Query Layer لتحديد ما إذا كانت ستقرأ من Transaction أو Ledger حسب احتياجات المنتج.