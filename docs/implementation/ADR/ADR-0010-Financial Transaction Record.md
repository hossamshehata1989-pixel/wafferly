ADR-0013 — Financial Transaction Record
Status

Accepted

Date

2026-07-10

Owner

Wafferly Financial Architecture

Scope

Financial Engine — Domain Write Model

Context

بعد اعتماد:

ADR-008 — Financial Command Model
ADR-009 — Financial Execution Plan Completeness

أصبح الـ Financial Engine مسؤولة بالكامل عن إنتاج جميع نتائج العملية المالية (Financial Outcomes).

لكن أثناء دمج الـ Engine مع طبقة التطبيق، ظهر سؤال معماري مهم:

كيف تمثل الـ Planner العملية المالية التي قررت إنشاءها دون أن تعتمد على نموذج التخزين (Persistence Model)؟

في التصميم السابق، كانت هناك محاولة لاستخدام:

Transaction

داخل الـ Financial Engine.

لكن Transaction هي كيان خاص بطبقة التخزين (Persistence Entity)، وتحتوي على تفاصيل لا تخص الـ Domain مثل:

Hive annotations
Storage identifiers
Serialization concerns
Persistence implementation details

هذا أدى إلى كسر أحد أهم مبادئ Clean Architecture:

The Domain must never depend on Infrastructure Models.

لذلك احتاج المشروع إلى نموذج Domain مستقل يمثل العملية المالية كما قررها الـ Planner، دون أي اعتماد على تقنية التخزين.

Decision

يعتمد المشروع كائنًا جديدًا داخل الـ Financial Engine يسمى:

FinancialTransactionRecord

ويمثل هذا الكائن Domain Value Object يصف العملية المالية الناتجة عن التخطيط (Planning).

ولا يمثل:

Persistence Entity
Database Model
DTO
API Contract

بل يمثل فقط الحقيقة التي قرر الـ Financial Planner كتابتها.

Architectural Model
Presentation
        │
        ▼
Financial Command
        │
        ▼
Interpreter
        │
        ▼
Planner
        │
        ▼
FinancialTransactionRecord
        │
        ▼
CreateTransactionMutation
        │
        ▼
Executor

ويتم تحويله لاحقًا بواسطة طبقة الـ Infrastructure إلى نموذج التخزين المناسب.

Responsibilities
FinancialTransactionRecord

يمثل الوصف المالي النهائي للعملية بعد انتهاء جميع قرارات الـ Domain.

ويحتوي فقط على البيانات اللازمة لإنشاء Transaction داخل النظام.

أمثلة:

transactionId
type
accountId
amount
categoryId
occurredAt
paymentMethod
currencyCode
note
isExceptional
Planner

الـ Planner هي المكون الوحيد المسؤول عن إنشاء FinancialTransactionRecord.

ولا يجوز لأي طبقة أخرى إنشاء هذا الكائن بشكل مباشر.

Executor

الـ Executor لا تتخذ أي قرار.

بل تقوم فقط بتنفيذ الـ Mutations التي تحمل FinancialTransactionRecord.

Architectural Constraints
Rule 1 — Domain Ownership

FinancialTransactionRecord مملوكة بالكامل للـ Financial Engine.

ولا يجوز استخدامها كنموذج تخزين.

Rule 2 — Value Object

FinancialTransactionRecord تعتبر Domain Value Object.

ولذلك:

Immutable
بلا سلوك خاص بالتخزين
بلا Serialization
بلا Hive annotations
بلا Database concerns
Rule 3 — No Infrastructure Dependency

لا يجوز أن تستورد FinancialTransactionRecord أي نموذج من طبقة Infrastructure.

مثل:

import '../../models/transaction.dart';

يعتبر مخالفة معمارية.

Rule 4 — Planner Authority

الـ Planner هي المصدر الوحيد لإنشاء FinancialTransactionRecord.

ولا يجوز لـ:

UI
Application Layer
Infrastructure

إنشاؤها مباشرة.

Rule 5 — Domain Completeness

يجب أن تحتوي FinancialTransactionRecord على جميع البيانات التي يحتاجها Executor لإنشاء Transaction.

ولا يجوز للـ Executor أن تستنتج بيانات جديدة.

Rule 6 — No Persistence Concerns

لا يجوز أن تحتوي FinancialTransactionRecord على:

Hive Keys
Database IDs الخاصة بالتخزين
ORM metadata
Serialization metadata

أي تفاصيل تخص التخزين تعتبر خارج مسؤوليتها.

Lifecycle
ExpenseIntent
        │
        ▼
Planner
        │
        ▼
FinancialTransactionRecord
        │
        ▼
CreateTransactionMutation
        │
        ▼
Infrastructure Adapter
        │
        ▼
Transaction Entity
        │
        ▼
Database
Consequences
Positive
فصل كامل بين الـ Domain والـ Persistence.
الحفاظ على استقلال الـ Financial Engine.
تحسين قابلية الاختبار.
دعم أكثر من طبقة تخزين دون تعديل الـ Domain.
التوافق مع DDD و Clean Architecture.
Negative
إضافة Value Object جديدة داخل الـ Engine.
الحاجة إلى تحويل لاحق داخل طبقة Infrastructure.

وهذه تكلفة معمارية مقبولة.

Future Evolution

قد يتم توسيع FinancialTransactionRecord مستقبلًا لدعم:

Transfers
Income
Investments
Shared Finance
Multi-currency
Scheduled Actions

لكن دون تحويلها إلى Persistence Entity.

Invariants

يجب أن تتحقق دائمًا القواعد التالية:

FinancialTransactionRecord ليست Transaction Entity.
لا تعتمد على Hive أو Supabase أو أي قاعدة بيانات.
لا تنشأ إلا بواسطة الـ Planner.
تمثل القرار المالي النهائي.
لا تحتوي على Business Logic.
لا تحتوي على Persistence Logic.
Relationship to Previous ADRs

ADR-007

يحافظ على أن:

Accounts are the only Source of Truth.

ADR-008

يستقبل Financial Commands وينتج نتائج Domain.

ADR-009

الـ Planner تنتج جميع الـ Mutations اللازمة لتنفيذ العملية.

ADR-0010 (هذا القرار)

يعرف النموذج الذي يحمل وصف العملية المالية الناتجة عن الـ Planner قبل تحويلها إلى نموذج التخزين.

Rationale

تم رفض استخدام Transaction Entity داخل الـ Financial Engine لأنه يربط طبقة المجال مباشرة بتقنية التخزين، مما يكسر مبادئ Clean Architecture وDependency Inversion.

كما تم رفض استخدام DTO عامة لأنها تتحول مع الوقت إلى God Objects يصعب صيانتها.

تم اعتماد FinancialTransactionRecord باعتبارها Domain Value Object مستقلة، تمثل الحقيقة التي قررها الـ Financial Planner، وتسمح للـ Infrastructure بتحويلها إلى أي نموذج تخزين مناسب دون التأثير على قلب النظام المالي.