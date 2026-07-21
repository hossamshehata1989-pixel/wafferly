ADR-006 — Balance Engine

Status: Accepted

Context

حدد ADR-005 أن Journal Entries تمثل المصدر الوحيد للحقيقة المالية داخل النظام، وأن جميع الحالات المالية الأخرى تُشتق منها.

وبالرغم من أن الحقيقة المالية أصبحت معرفة بصورة رسمية، إلا أن التطبيقات والمستخدمين لا يتعاملون مباشرة مع Journal Entries في معظم السيناريوهات اليومية.

بدلًا من ذلك، يعتمد النظام على مجموعة من القيم المشتقة مثل:

Account Balance
Cash Balance
Net Worth
Available Balance
Historical Balance

تمثل هذه القيم الحالة الحالية للنظام، لكنها ليست جزءًا من الحقيقة المالية نفسها.

ولذلك يحتاج النظام إلى طبقة مستقلة مسؤولة عن اشتقاق هذه الحالة بصورة متسقة وقابلة لإعادة البناء، دون التأثير على المصدر الأصلي للحقيقة المالية.

Problem Statement

يحتاج النظام إلى آلية موحدة للإجابة عن أسئلة مثل:

كم يملك هذا الحساب الآن؟
ما صافي ثروة المستخدم؟
كم كان الرصيد في تاريخ معين؟
ما الرصيد بعد آخر عملية منفذة؟

دون تحويل هذه القيم إلى مصدر للحقيقة المالية.

كما يجب أن يكون بالإمكان إعادة حسابها بالكامل في أي وقت اعتمادًا على Journal Entries فقط.

Architectural Principles
Principle 1 — Balance Is Derived, Never Stored as Truth

الرصيد ليس حقيقة مالية مستقلة.

بل هو نتيجة لتطبيق جميع Journal Entries ذات الصلة على مجموعة من الحسابات.

ولذلك لا يكتسب الرصيد أي سلطة مستقلة عن الحقيقة المالية.

Principle 2 — Same Truth, Many Views

يمكن اشتقاق عدة أرصدة مختلفة من نفس الحقيقة المالية.

على سبيل المثال:

رصيد حساب واحد.
إجمالي النقدية.
صافي الثروة.
إجمالي الالتزامات.

جميعها تعتمد على المصدر نفسه، لكنها تمثل وجهات نظر مختلفة للحقيقة المالية، وليست حقائق جديدة.

Principle 3 — Deterministic Calculation

إذا كانت Journal Entries متطابقة، فإن جميع عمليات حساب الرصيد يجب أن تعطي النتيجة نفسها دائمًا، بغض النظر عن الجهاز أو واجهة المستخدم أو وقت الحساب.

أتوقف هنا كما اتفقنا.

هذا هو الجزء الأول فقط.

قبل أن أكتب الجزء الثاني، سأراجع مرة أخرى كل ما صممناه سابقًا حول الـ Balance Engine (مثل BalancePort، وBalanceDomainGuard، واشتقاق الرصيد من الـ Engine) حتى أتأكد أن الـ ADR يوثق ما بنيناه بالفعل، ولا يفرض نموذجًا جديدًا. وهذا بالضبط هو الأسلوب الذي اتفقنا على اتباعه في بقية المشروع.


Decision

يعتمد النظام طبقة مستقلة تسمى Balance Engine.

تمثل هذه الطبقة المسؤول الوحيد عن اشتقاق الحالة المالية الحالية اعتمادًا على الحقيقة المالية.

ولا تنشئ Balance Engine أي حقيقة مالية جديدة.

كما لا تعدل Journal Entries.

بل تفسرها فقط.

Position Within the Architecture

تقع Balance Engine بعد طبقة الحقيقة المالية مباشرة.

Financial Operation

↓

Execution Engine

↓

Journal Entries
(Financial Truth)

↓

Balance Engine

↓

Current Financial State

ويضمن هذا التسلسل أن جميع القيم المشتقة تعتمد على نفس المصدر الرسمي للحقيقة.

Responsibilities

تتولى Balance Engine المسؤوليات التالية.

Balance Calculation

اشتقاق رصيد أي Account.

ولا يعتمد الحساب على قيمة مخزنة.

بل على Journal Entries المرتبطة بالحساب.

Financial Aggregation

اشتقاق القيم المجمعة مثل:

Cash Position
Total Assets
Total Liabilities
Total Income
Total Expenses
Net Worth

دون إنشاء حقيقة مالية جديدة.

Historical Reconstruction

إعادة بناء الحالة المالية عند أي نقطة زمنية.

بمعنى أن النظام يستطيع الإجابة على:

"ما كان رصيد هذا الحساب في 1 يناير؟"

من خلال تطبيق Journal Entries حتى تلك اللحظة فقط.

ولا يحتاج إلى Snapshots حتى تكون النتيجة صحيحة.

Domain Queries

توفير استعلامات المجال المالي مثل:

هل الرصيد الحالي كافٍ؟
كم الرصيد الحالي؟
كم صافي الثروة؟

دون أن تصبح هذه الاستعلامات جزءًا من الحقيقة المالية نفسها.

What Balance Engine Does NOT Do

لا تقوم Balance Engine بـ:

تنفيذ العمليات المالية.
تعديل Journal Entries.
إنشاء Journal Entries.
حفظ الحقيقة المالية.
اتخاذ قرارات مالية.

فهذه المسؤوليات تعود إلى Financial Operation Execution Engine.

Types of Balance

لا يقتصر مفهوم Balance على قيمة واحدة.

بل يمثل عائلة من القيم المشتقة.

Account Balance

الرصيد الحالي لحساب واحد.

Group Balance

الرصيد المجمع لمجموعة حسابات.

مثل:

جميع المحافظ.
جميع الحسابات البنكية.
جميع بطاقات الائتمان.
Net Worth

يمثل صافي المركز المالي.

ويشتق بالكامل من الحسابات.

ولا يخزن كحقيقة مستقلة.

Historical Balance

الرصيد عند لحظة زمنية معينة.

ويحسب باستخدام الحقيقة المالية المتاحة حتى تلك اللحظة.

Relationship with Accounts

لا يحتفظ Account برصيده باعتباره حقيقة مالية.

بل يصبح الرصيد نتيجة لتطبيق جميع Entry Lines المرتبطة بذلك الحساب.

وبالتالي:

Account

+

Journal Entries

↓

Balance

وليس:

Account

↓

Stored Balance
Relationship with Domain Guards

لا تستخدم Domain Guards أرصدة مخزنة.

بل تعتمد على Balance Engine للحصول على الحالة الحالية.

وبذلك يصبح جميع التحقق المالي مبنيًا على الحقيقة نفسها.

وهذا يضمن أن جميع قرارات المجال تعتمد على تفسير موحد للحقيقة المالية.

Architectural Consequences

ينتج عن هذا القرار عدة نتائج.

Single Source Interpretation

جميع أجزاء النظام تعتمد على نفس آلية حساب الرصيد.

ولا يسمح لكل Feature بحساب الرصيد بطريقتها الخاصة.

Replayability

يمكن حذف جميع الأرصدة المشتقة وإعادة بنائها بالكامل.

دون فقدان أي معلومة مالية.

Consistency

إذا تغيرت Journal Entries.

فإن جميع الأرصدة تتغير بصورة متسقة.

ولا يحتاج النظام إلى تحديثات يدوية للأرصدة.

Isolation

يمكن تطوير Balance Engine أو تحسين أدائه دون تغيير Financial Engine أو النموذج المحاسبي.


Architectural Invariants

تمثل المبادئ التالية القواعد الأساسية التي يجب أن يحافظ عليها Balance Engine في جميع الظروف.

Invariant 1 — Balance Is Never Financial Truth

الرصيد ليس حقيقة مالية.

ولا يجوز استخدامه باعتباره المصدر الرسمي لأي قرار مالي مستقل.

الحقيقة الوحيدة هي Journal Entries.

Invariant 2 — Every Balance Is Derived

كل قيمة Balance داخل النظام يجب أن تكون قابلة للاشتقاق بالكامل من Journal Entries.

ولا يجوز أن تعتمد صحة الرصيد على بيانات إضافية.

Invariant 3 — Same Truth Produces Same Balance

إذا كانت الحقيقة المالية متطابقة، فيجب أن تكون جميع الأرصدة الناتجة متطابقة.

ولا يجوز أن تختلف النتائج بسبب:

الجهاز.
طريقة التخزين.
واجهة المستخدم.
وقت الحساب.
Invariant 4 — Balance Never Modifies Financial Truth

لا يجوز لـ Balance Engine:

إنشاء Journal Entries.
تعديل Journal Entries.
حذف Journal Entries.

فهو يفسر الحقيقة فقط.

Invariant 5 — Every Derived State Is Disposable

يمكن حذف:

Balance
Net Worth
Reports
Dashboard Values

ثم إعادة إنتاجها بالكامل.

دون فقدان أي معلومة مالية.

Invariant 6 — Domain Decisions Depend on Derived State, Not Stored State

عندما يحتاج Domain إلى معرفة الرصيد الحالي (مثل التحقق من كفاية الرصيد)، فإنه يعتمد على Balance Engine لاستخراج الحالة الحالية من الحقيقة المالية، وليس على قيمة مخزنة مسبقًا.

Invariant 7 — Balance Represents a Point in Time

كل Balance يمثل الحالة المالية عند لحظة زمنية محددة.

ولذلك فإن تغيير نطاق الزمن يؤدي إلى Balance مختلفة، مع بقاء الحقيقة المالية نفسها دون تغيير.

Consequences

اعتماد Balance Engine كطبقة مستقلة يؤدي إلى النتائج التالية.

Unified Balance Calculation

جميع أجزاء النظام تستخدم آلية واحدة لحساب الرصيد.

ولا توجد طرق متعددة أو متعارضة لحساب نفس المفهوم.

Historical Accuracy

يمكن إعادة بناء الحالة المالية لأي تاريخ.

وهو ما يدعم:

التقارير التاريخية.
مراجعة العمليات.
تحليل الأداء المالي.
Future Extensibility

يمكن إضافة أنواع جديدة من الأرصدة (مثل أرصدة المحافظ الاستثمارية أو المحافظ المشتركة) دون تعديل الحقيقة المالية.

Clear Separation of Responsibilities
Financial Engine ينشئ الحقيقة.
Accounting Model يمثل الحقيقة.
Balance Engine يفسر الحقيقة.

ولا تتداخل مسؤوليات هذه الطبقات.

Rejected Alternatives
Alternative 1 — Store Balance Inside Accounts

تم رفض هذا البديل.

لأنه يجعل الرصيد مصدرًا للحقيقة.

ويؤدي إلى مشكلات في الاتساق وإعادة البناء.

Alternative 2 — Let Every Feature Calculate Its Own Balance

تم رفض هذا البديل.

لأنه يؤدي إلى اختلاف طرق الحساب بين الميزات المختلفة.

ويفقد النظام الاتساق.

Alternative 3 — Treat Balance as Financial Truth

تم رفض هذا البديل.

لأن الرصيد يمثل نتيجة للحقيقة المالية، وليس الحقيقة نفسها.

Alternative 4 — Couple Balance Calculation to Storage

تم رفض هذا البديل.

لأن طريقة التخزين أو تحسين الأداء لا ينبغي أن تؤثر على تعريف الرصيد داخل المجال.

Deferred Decisions

لا يغطي هذا القرار:

Snapshot Strategies.
Cache Policies.
Materialized Views.
Performance Optimizations.
Incremental Balance Calculation.
Distributed Balance Computation.

جميع هذه الموضوعات تعتبر تفاصيل تنفيذية يمكن تغييرها دون التأثير على النموذج المعماري.

Summary

يعرف هذا القرار Balance Engine باعتباره الطبقة المسؤولة عن اشتقاق الحالة المالية الحالية من الحقيقة المالية.

ويؤكد القرار أن:

Journal Entries هي المصدر الوحيد للحقيقة.
الرصيد قيمة مشتقة وليست حقيقة.
جميع الأرصدة قابلة لإعادة البناء.
لا يحق لـ Balance Engine تعديل الحقيقة المالية.
جميع استعلامات المجال المتعلقة بالحالة الحالية تعتمد على Balance Engine.

وبذلك يصبح لدينا فصل واضح بين:

Financial Truth
        │
        ▼
Accounting Model
        │
        ▼
Balance Engine
        │
        ▼
Current Financial State

وهذا الفصل يضمن أن أي تحسين مستقبلي في الأداء أو التخزين أو آلية الحساب لن يغير تعريف الحقيقة المالية أو مسؤوليات الطبقات الأساسية.