ADR-0014 — Infrastructure Adapter Responsibility
Status

Accepted

Date

2026-07-10

Owner

Wafferly Financial Architecture

Scope

Financial Engine — Infrastructure Boundary

Context

بعد اعتماد:

ADR-008 — Financial Command Model
ADR-009 — Financial Execution Plan Completeness
ADR-0010 — Financial Transaction Record

أصبحت الـ Financial Engine مسؤولة بالكامل عن إنتاج النتيجة المالية (Financial Outcome) في صورة Domain Models مستقلة عن أي تقنية تخزين.

في المقابل، تستخدم طبقة الـ Infrastructure نماذج مختلفة للتخزين مثل:

Hive Entities
Supabase Rows
REST DTOs
Future Persistence Models

ظهر سؤال معماري مهم:

Where should the translation between Domain Models and Persistence Models occur?

تمت دراسة بديلين رئيسيين.

Option A — Dedicated Mapper

إنشاء Mapper مستقلة مسؤولة عن التحويل.

FinancialTransactionRecord
        │
        ▼
TransactionMapper
        │
        ▼
Transaction Entity
        │
        ▼
HiveTransactionPort
Advantages
فصل واضح لمسؤولية التحويل.
سهولة اختبار الـ Mapping بشكل مستقل.
إمكانية إعادة الاستخدام.
Disadvantages
إضافة Abstraction جديدة دون وجود إعادة استخدام فعلية.
زيادة عدد المكونات بدون حاجة حالية.
تعقيد غير مبرر في المرحلة الحالية.
Option B — Adapter-Owned Translation

اعتبار الترجمة جزءًا من مسؤولية الـ Adapter نفسها.

FinancialTransactionRecord
        │
        ▼
HiveTransactionPort
        │
        ├── Structural Translation
        ├── Persistence Operations
        ▼
Hive
Decision

يعتمد المشروع الخيار الثاني.

Infrastructure Adapters are responsible for translating Domain Models into Persistence Models.

ولا يتم إنشاء Mapper مستقلة إلا عند ظهور احتياج حقيقي لإعادة استخدام نفس منطق التحويل بين أكثر من Adapter.

Architectural Model
                Financial Engine
                        │
                        ▼
                FinancialTransactionRecord
                        │
                        ▼
                 TransactionPort
                        │
                        ▼
             HiveTransactionPort
                        │
          ┌─────────────┴─────────────┐
          │                           │
          ▼                           ▼
 Structural Translation        Persistence Operations
          │                           │
          └─────────────┬─────────────┘
                        ▼
                 Hive Database

وينطبق نفس المبدأ مستقبلاً على:

JournalPort
GoalActivityPort
AllocationPort
AccountPort
Supabase Adapters
Cloud Synchronization Adapters
Responsibilities
Financial Engine

مسؤولة عن إنتاج Domain Models فقط.

ولا تعرف أي شيء عن:

Hive
Supabase
SQL
JSON
ORM
Serialization
Persistence Entities
Ports

تمثل العقود (Contracts) بين الـ Domain والـ Infrastructure.

ولا تحتوي أي منطق خاص بالتخزين.

Infrastructure Adapter

تمثل طبقة التنفيذ (Implementation Layer).

وتكون مسؤولة عن:

تنفيذ الـ Port.
الترجمة الهيكلية (Structural Translation).
تنفيذ عمليات التخزين.
التعامل مع تقنية التخزين المستخدمة.
Persistence Model

تمثل الشكل الفعلي للبيانات داخل قاعدة البيانات.

ولا يجوز استخدامها داخل الـ Financial Engine.

Architectural Constraints
Rule 1 — Domain Isolation

لا يجوز لأي مكون داخل الـ Financial Engine أن يعتمد على Persistence Models.

مثل:

import '../../models/transaction.dart';

يعتبر مخالفة معمارية.

Rule 2 — Structural Translation Only

يجوز للـ Adapter تحويل:

FinancialTransactionRecord

إلى:

Transaction Entity

لكن هذا التحويل يجب أن يكون Structural Translation فقط.

أي نقل البيانات من نموذج إلى آخر دون اتخاذ أي قرار.

Rule 3 — No Business Logic

يمنع وجود أي Business Logic داخل الـ Adapter.

أمثلة ممنوعة:

if (record.isExceptional)

if (record.type == TransactionType.expense)

switch (record.categoryId)

أي قرار مالي يجب أن يكون قد تم اتخاذه مسبقًا داخل:

Interpreter
Domain Guard
Policy
Planner

ولا يجوز اتخاذه داخل طبقة Infrastructure.

Rule 4 — Adapter Owns Translation

الـ Adapter هي المكون الوحيد داخل النظام المسموح له بمعرفة:

Domain Models
Persistence Models

في الوقت نفسه.

ولا يجوز لأي طبقة أخرى الجمع بينهما.

Rule 5 — Extract Mappers Only When Justified

لا يتم إنشاء Mapper مستقلة إلا عند تحقق أحد الشروط التالية:

وجود أكثر من Adapter تستخدم نفس قواعد التحويل.
ظهور تكرار فعلي (Real Duplication).
تحول عملية التحويل إلى مسؤولية مستقلة قابلة لإعادة الاستخدام.

قبل ذلك يعتبر استخراج Mapper:

Premature Abstraction

ويخالف مبدأ:

Architecture should grow with the system.

Rule 6 — Persistence Independence

يجب أن يظل الـ Financial Engine غير متأثر بإضافة أو تغيير أي تقنية تخزين.

مثل:

Hive
Supabase
SQLite
PostgreSQL
REST API
Cloud Sync

أي تغيير في تقنية التخزين يجب أن يقتصر على طبقة Infrastructure فقط.

Consequences
Positive
الحفاظ على استقلال الـ Financial Engine.
تقليل عدد الـ Abstractions غير الضرورية.
الالتزام بمبدأ YAGNI (You Aren't Gonna Need It).
دعم إضافة تقنيات تخزين جديدة دون تعديل الـ Domain.
تبسيط طبقة Infrastructure في المرحلة الحالية.
الالتزام بمبادئ Ports & Adapters وClean Architecture.
Negative
تحتوي كل Adapter على منطق ترجمة هيكلي بسيط.
قد يتم استخراج Mapper مستقلة مستقبلاً عند ظهور إعادة استخدام فعلية.

وهذا Refactoring مقصود ومقبول.

Future Evolution

عند إضافة طبقات تخزين جديدة مثل:

HiveTransactionPort

SupabaseTransactionPort

SQLiteTransactionPort

RestTransactionPort

وظهور تكرار واضح في منطق التحويل،

يتم استخراج:

TransactionMapper

أو أي Mapper متخصصة،

دون إجراء أي تعديل داخل الـ Financial Engine.

Invariants

يجب أن تتحقق القواعد التالية دائمًا:

الـ Financial Engine لا تعرف أي Persistence Model.
الـ Persistence Models لا تدخل الـ Domain.
الـ Adapter هي نقطة الالتقاء الوحيدة بين الـ Domain والـ Infrastructure.
التحويل داخل الـ Adapter يظل هيكليًا فقط.
يمنع تمامًا وجود Business Logic داخل الـ Adapter.
لا يتم إنشاء Mapper مستقلة إلا عند وجود احتياج حقيقي مثبت.
Relationship to Previous ADRs

ADR-007

يحافظ على مبدأ:

Accounts are the only Source of Truth.

ADR-008

يعتمد Financial Commands كنقطة الدخول الوحيدة للـ Write Model.

ADR-009

يجعل الـ Planner مسؤولة عن إنتاج خطة التنفيذ الكاملة (Execution Plan).

ADR-0010

يعرف FinancialTransactionRecord كـ Domain Value Object مستقلة عن التخزين.

ADR-0011 (هذا القرار)

يحدد المسؤولية الرسمية لترجمة Domain Models إلى Persistence Models، ويثبت أن هذه المسؤولية تقع على عاتق طبقة الـ Infrastructure Adapters، مع منع أي Business Logic داخلها، وتأجيل استخراج Mapper مستقلة حتى يظهر احتياج فعلي لها.

Rationale

تم رفض إنشاء Mapper مستقلة في هذه المرحلة لأن المشروع يمتلك Adapter واحدة فقط، ولا يوجد أي تكرار حقيقي يبرر إضافة طبقة تجريد جديدة.

في المقابل، تم اعتماد أن تكون الترجمة الهيكلية (Structural Translation) جزءًا من المسؤولية الطبيعية للـ Infrastructure Adapter، باعتبارها نقطة الاتصال الرسمية بين لغة الـ Domain ولغة الـ Persistence.

هذا القرار يحقق توازنًا بين البساطة الحالية وقابلية التوسع المستقبلية، ويحافظ على استقلال الـ Financial Engine، مع وضع قواعد واضحة تمنع تسرب أي Business Logic إلى طبقة الـ Infrastructure.

وعند ظهور أكثر من Adapter أو تكرار فعلي في منطق التحويل، يتم استخراج Mapper مستقلة من خلال Refactoring محسوب، دون التأثير على الـ Domain أو كسر مبادئ Clean Architecture أو Dependency Inversion أو Ports & Adapters.