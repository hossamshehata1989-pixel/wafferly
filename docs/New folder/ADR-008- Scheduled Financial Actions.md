ADR-008
Scheduled Financial Actions

Status: Accepted

Context

حتى هذه المرحلة، يصف النظام العمليات المالية التي تحدث الآن.

بمجرد أن يقرر المستخدم تنفيذ عملية مالية، تمر عبر:

Financial Understanding
Canonical Financial Draft
Financial Operation Execution Engine
Accounting Model
Balance Engine

وتتحول إلى Financial Truth.

لكن النظام لا يمتلك بعد تمثيلًا رسميًا للأحداث التي من المفترض أن تحدث في المستقبل.

مثل:

راتب يوم 25 من كل شهر.
اشتراك Netflix.
إيجار أول الشهر.
تحويل أسبوعي للادخار.
قسط سيارة.
تحويل مستقبلي لمرة واحدة.

هذه العمليات ليست حقيقة مالية.

لكنها أيضًا ليست مجرد أفكار.

إنها التزامات أو تعليمات مستقبلية يجب أن يستطيع النظام الاحتفاظ بها وإدارتها دون التأثير على الحالة المالية الحالية.

Problem Statement

كيف يمثل النظام عملية مالية مستقبلية دون تحويلها إلى Financial Truth قبل موعد تنفيذها؟

ويجب أن يسمح هذا التمثيل بـ:

التخزين.
التعديل.
الإلغاء.
التكرار.
التنفيذ المستقبلي.

مع الحفاظ على أن:

Balance لا يتغير.
Journal Entries لا تُنشأ.
Financial Truth لا تتأثر.

حتى يحدث التنفيذ الفعلي.

Architectural Principles
Principle 1 — Future Intent Is Not Financial Truth

Scheduled Financial Action تمثل نية مستقبلية فقط.

ولا تعتبر حدثًا ماليًا.

Principle 2 — Scheduling Never Creates Financial Truth

مرور الوقت لا ينشئ الحقيقة المالية.

بل يجعل العملية مؤهلة لمحاولة التنفيذ.

Principle 3 — Execution Remains the Only Source of Financial Truth

حتى بعد حلول موعد التنفيذ.

تمر العملية بنفس دورة التنفيذ العادية.

ولا توجد أي طريقة بديلة لإنشاء Journal Entries.

Principle 4 — Scheduled Actions Store Intent Only

يخزن الـ Scheduled Financial Action:

العملية المطلوبة.
بياناتها.
قاعدة التكرار.
المراجع المطلوبة.

ولا يخزن حقائق تعتمد على الزمن أو حالة النظام مثل:

Exchange Rate
Current Balance
Market Price
Resolved Accounts
Any runtime resolution

كل هذه الحقائق تُحل وقت التنفيذ فقط.

Principle 5 — Scheduled Actions Are Independent of Planning

قد تستخدم Planning طبقة الجدولة.

وقد تستخدمها Commitments.

وقد يستخدمها المستخدم مباشرة.

ولذلك Scheduled Financial Action ليست جزءًا من Financial Planning Layer.

بل Capability مستقلة داخل Financial Domain.

Principle 6 — One Occurrence Produces At Most One Operation

كل Occurrence ينتج Financial Operation واحدة فقط.

بغض النظر عن:

إعادة المحاولة.
تشغيل Scheduler أكثر من مرة.
Race Conditions.
إعادة تشغيل التطبيق.
Decision

يعتمد النظام كيانًا جديدًا يسمى:

Scheduled Financial Action

ويمثل تعليمات لتنفيذ عملية مالية مستقبلية.

ولا يمثل:

Financial Truth
Financial Operation
Journal Entry

بل يمثل Intent فقط.

Architectural Position

بدلًا من الرسم القديم:

Planning

↓

Scheduled Action

يصبح:

                Financial Domain

     ┌──────────────┬──────────────┐
     │              │              │
Execution      Planning      Scheduled Actions
     │              │              │
     └──────────────┴──────────────┘
                    │
                    ▼
          Schedule Evaluation
                    │
                    ▼
     Financial Operation Draft
                    │
                    ▼
 Financial Operation Execution Engine
                    │
                    ▼
             Journal Entries
                    │
                    ▼
             Balance Engine

لاحظ أن:

Planning قد تنشئ Scheduled Actions.
Commitments قد تنشئ Scheduled Actions.
المستخدم قد ينشئ Scheduled Actions مباشرة.

لكن Scheduled Actions نفسها ليست جزءًا من أيٍ منها.

Deferred Concepts

يعالج هذا ADR الجدولة الزمنية (Time-Based Scheduling) فقط.

ولا يفترض أن الوقت هو النوع الوحيد من المحفزات (Triggers).

يُحتمل مستقبلًا دعم:

Event-Based Automation
Condition-Based Automation
Rule-Based Financial Automation

لكن هذه المفاهيم مؤجلة عمدًا إلى ADR مستقل، بعد توفر متطلبات حقيقية تحدد حدودها ومسؤولياتها.

ولا يجوز تفسير هذا ADR على أن Scheduling هي النموذج الوحيد الممكن للأتمتة داخل النظام.

Architectural Consequences

ينتج عن هذا القرار:

تمثيل رسمي للعمليات المستقبلية.
فصل واضح بين النية المستقبلية والحقيقة المالية.
إمكانية دعم العمليات المتكررة دون المساس بالمحاسبة.
إمكانية استخدام الجدولة من أكثر من Sub-domain دون خلق اعتمادية على Planning.
الحفاظ على أن Financial Operation Execution Engine هو البوابة الوحيدة لإنشاء Financial Truth.
إبقاء الباب مفتوحًا لتطور مستقبلي نحو Financial Automation دون فرض تجريدات غير مبررة في هذه المرحلة.