ADR-017 — Complete Ledger Integration into Financial Engine

Status: Proposed

Date: 2026-07-26

Supersedes: ADR-016 Phase 3

Context

تم تنفيذ جزء كبير من بنية الـ Ledger خلال ADR-016:

LedgerEntry Model
LedgerAccount
LedgerPort
HiveLedgerPort
TransactionLedgerBuilder
CategoryLedgerMapper
LedgerProjectionService

كما تم إدخال مفهوم JournalEntryMutation داخل Financial Engine.

ولكن بعد مراجعة الكود الحالي، تبين أن هناك نظامين منفصلين للـ Ledger.

Financial Engine Pipeline
FinancialOperationEngine
        ↓
Planner
        ↓
JournalEntryMutation
        ↓
JournalEntryMutationHandler
        ↓
MemoryJournalEntryRepository

الـ Engine ينتج JournalEntryMutation ولكنه لا يقوم بإنتاج LedgerEntries ولا يكتبها في Hive.

Legacy Ledger Pipeline
Transaction
      ↓
LedgerProjectionService
      ↓
TransactionLedgerBuilder
      ↓
HiveLedgerPort
      ↓
LedgerService
      ↓
Hive

وهو المسار الفعلي المستخدم لإنتاج LedgerEntries وتخزينها.

Problem

يوجد انفصال كامل بين:

JournalEntryMutation

و

LedgerEntry

كما أن:

JournalEntryMutationHandler لا يستطيع استخدام HiveLedgerPort مباشرة لأن نوع البيانات مختلف.

JournalEntryMutation

≠

LedgerEntry

لذلك فإن استبدال MemoryJournalEntryRepository بـ HiveLedgerPort مباشرة يعتبر قراراً غير صحيح معمارياً.

Decision

يصبح Financial Engine هو المسؤول الوحيد عن إنشاء الـ Ledger الحقيقي.

ولكن يتم ذلك بإضافة مرحلة Projection داخل الـ Engine بدلاً من نقل LedgerProjectionService كما هو.

تصبح سلسلة التنفيذ:

FinancialOperationEngine
        ↓
Planner
        ↓
JournalEntryMutation
        ↓
JournalEntryProjection
        ↓
List<LedgerEntry>
        ↓
HiveLedgerPort
        ↓
Hive
Architectural Rules
Rule 1

JournalEntryMutation يمثل الحقيقة المحاسبية (Accounting Intent).

ولا يمثل كيان التخزين.

Rule 2

LedgerEntry يمثل Projection قابلاً للتخزين فقط.

ولا يحتوي على Business Rules.

Rule 3

عملية التحويل بينهما تتم داخل طبقة مستقلة.

JournalEntryProjection

ولا تتم داخل Handler.

Rule 4

JournalEntryMutationHandler يظل Coordinator فقط.

ويصبح مسؤولا عن:

JournalEntryMutation

↓

JournalEntryProjection

↓

LedgerPort

ولا يحتوي على أي منطق محاسبي.

Rule 5

TransactionLedgerBuilder يبقى Pure Builder.

ولا يتم دمجه داخل HivePort.

ولا داخل LedgerService.

Rule 6

HiveLedgerPort يبقى Infrastructure Adapter فقط.

ولا يحتوي على Business Logic.

Migration Plan
Phase 1

إنشاء

JournalEntryProjection

مسؤول عن تحويل

JournalEntryMutation

↓

LedgerEntry
Phase 2

تعديل

JournalEntryMutationHandler

ليصبح:

Mutation

↓

Projection

↓

HiveLedgerPort

بدلاً من:

Mutation

↓

MemoryRepository
Phase 3

إزالة

MemoryJournalEntryRepository
Phase 4

إزالة

MemoryJournalEntryAdapter
Phase 5

تعديل

FinancialEngineBootstrap

لحقن:

HiveLedgerPort

بدلاً من MemoryRepository.

Phase 6

بعد التأكد من نجاح:

Create
Update
Delete

داخل الـ Engine،

يتم حذف:

LedgerProjectionService

من الـ Legacy Write Path.

Phase 7

إزالة أي استدعاء لـ:

LedgerProjectionService.project()

من TransactionService.

Phase 8

إلغاء الـ Dual Writers نهائياً.

Consequences
Positive
Financial Engine يصبح المسؤول الوحيد عن جميع عمليات الكتابة.
إزالة ازدواجية الكتابة.
مصدر واحد للحقيقة (Single Write Pipeline).
توحيد Create / Update / Delete تحت نفس الـ Execution Pipeline.
سهولة إضافة Audit وReplay وUndo مستقبلاً.
Negative
إضافة طبقة Projection جديدة.
نقل منطق Projection من Legacy إلى Engine.
الحاجة إلى اختبار كامل لمسارات Create وUpdate وDelete قبل إزالة الـ Legacy.
Out of Scope

هذا القرار لا يشمل:

Ledger Analytics
Ledger Reports
Balance Calculations
Financial Read Models
إصلاح مشكلة Edit/Update الحالية