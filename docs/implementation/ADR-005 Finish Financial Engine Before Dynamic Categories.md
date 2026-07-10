ADR-005 — Accepted ✅
Finish Financial Engine Before Dynamic Categories
القرار

لن نبدأ تطوير Dynamic Categories قبل اكتمال الـ Financial Engine.

السبب أن:

Financial Truth always comes before Financial Flexibility.

صحة النظام المالي أولًا، ثم مرونة النظام.

Sprint Roadmap
Sprint 1 — Complete Expense Pipeline

الهدف:

إنهاء جميع سيناريوهات Expense بالكامل عبر الـ Financial Engine، وإزالة أي اعتماد مباشر على الـ Legacy Flow.

Checklist

☐ Temporary Ledger Mapping (واضح ومؤقت)

☐ Normal Expense

☐ Exceptional Expense

☐ Confirmation Flow

☐ Temp Debt

☐ Goal Allocation

☐ Goal Transfer

☐ Expense Tests

☐ Expense Bug Fixes

Temporary Ledger Mapping

أتفق على أن يكون الحل واضحًا وصريحًا وليس حلًا يخفي المشكلة.

إذا لم يجد الـ Planner Mapping للفئة:

يستخدم Default Expense Ledger Account مؤقتًا.
يطبع Warning واضحًا فى الـ Debug.
لا يرمي Exception.
يكون عليه TODO واضح يشير إلى ADR-0010.

مثال:

// TODO(ADR-0010)
//
// Temporary implementation.
//
// Remove after LedgerAccountResolver integration.
// Planned for Sprint 6 (Architecture Cleanup).

debugPrint(
  '[TEMP] Category "$categoryId" mapped to Default Expense Ledger.',
);

لكن أضيف شرطًا مهمًا:

هذا السلوك المؤقت يكون لـ Expense Categories فقط.

أما إذا كانت العملية من نوع آخر (مثل Income أو Goal أو Transfer) فلا يتم استخدام Default Mapping، لأن ذلك قد يخفي أخطاء حقيقية في منطق النظام.

Sprint 2

Income Pipeline

Sprint 3

Transfer Pipeline

Sprint 4

Infrastructure Completion

يشمل:

HiveJournalRepository
HiveAllocationAdapter
HiveGoalActivityAdapter
HiveFinancialUnitOfWork
إزالة جميع Memory Adapters
Sprint 5

Engine Stabilization

يشمل:

Integration Tests
Bug Fixes
Atomicity
Rollback
Idempotency
Performance Review

ثم:

feat(financial-engine): financial engine fully integrated

وسيكون هذا أول Production Milestone.

Sprint 6

Architecture Cleanup

يشمل:

حذف ChartOfAccounts
حذف AccountMapping
إدخال LedgerAccountResolver
إزالة آخر Legacy Flow
إزالة آخر Stub
إزالة جميع Debug Logs المؤقتة
ADR Rule — Scope Management

قبل تنفيذ أي Feature جديدة نسأل:

هل هذه الـ Feature تمنع وصول Financial Engine إلى Production؟

إذا كانت الإجابة:

لا

⬇️

تدخل Backlog.

إذا كانت:

نعم

⬇️

تدخل الـ Sprint الحالية.

Rule for Temporary Code
Temporary code must never become a new Source of Truth
أي كود مؤقت يجب أن يحقق الشروط التالية:

يحتوي على TODO يشير إلى الـ ADR أو الـ Sprint التي ستزيله.
يطبع Warning واضحًا أثناء التطوير.
لا يغير التصميم النهائي المستهدف.
يمكن حذفه بالكامل دون التأثير على سلوك النظام بعد اكتمال الـ Refactor.

أعتبر هذه الخطة هي Roadmap الرسمية لـ Financial Engine، ولن نقوم بأي Refactor معماري كبير أو Feature جديدة خارج نطاق هذه الـ Roadmap حتى نصل إلى Production Milestone للـ Financial Engine.