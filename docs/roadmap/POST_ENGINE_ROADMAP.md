# POST_ENGINE_ROADMAP.md

# Wafferly Financial Architecture
# Post Engine Integration Roadmap

---

# Overview

بعد اكتمال دمج دورة حياة المعاملة داخل الـ Financial Engine، ينتقل المشروع من مرحلة بناء المحرك إلى مرحلة استكمال المعمارية.

لم تعد الأولوية إضافة عمليات جديدة، وإنما التأكد من أن المحرك أصبح المركز الوحيد لجميع العمليات المالية، وأن النظام جاهز للانتقال الكامل إلى المعمارية الجديدة.

---

# Phase 1 — Engine Stabilization

الهدف:

تثبيت المحرك ومراجعة جميع مكوناته قبل أي Migration.

يشمل:

- Pipeline Review
- Handler Review
- Cleanup
- Regression Tests
- API Freeze

---

# Phase 2 — Writer Audit

الهدف:

إنشاء خريطة كاملة لجميع عمليات الكتابة داخل النظام.

تشمل جميع أنواع العمليات المالية:

- Expense
- Income
- Transfer
- Correction
- Delete
- Goal Operations
- Allocation Operations
- Future Financial Operations

لكل عملية يتم تحديد:

- نقطة البداية
- Application Layer
- Engine
- Handler
- Storage
- Writers المستخدمة

الهدف النهائي:

التأكد من عدم وجود أي Writer يعمل خارج الـ Financial Engine.

---

# Phase 3 — Ledger Audit

الهدف:

تحديد الدور الحقيقي للـ Ledger داخل النظام.

يتم مراجعة:

- كيفية إنشائه
- كيفية تحديثه
- علاقته بالـ Transactions
- علاقته بالـ Accounts
- علاقته بالـ Balance

السؤال الرئيسي:

> هل الـ Ledger هو المصدر الرسمي للحقيقة المالية، أم أنه مجرد Projection مشتق؟

---

# Phase 4 — Read Model Audit

الهدف:

رسم خريطة كاملة لجميع عمليات القراءة.

تشمل:

- Dashboard
- Accounts
- Balances
- Net Worth
- Reports
- Transactions
- Financial Action Center

لكل شاشة يتم تحديد مصدر البيانات:

- Transaction Storage
- Cache
- Projection
- Ledger

---

# Phase 5 — Dual Writer Removal

بعد التأكد من:

- اكتمال Writer Audit
- اكتمال Ledger Audit
- اكتمال Read Audit

يبدأ التخلص التدريجي من أي Writers قديمة.

لا يتم حذف أي Writer إلا بعد التأكد من وجود بديل يعمل بالكامل داخل الـ Engine.

---

# Phase 6 — Projection Cutover

الهدف:

تحويل جميع عمليات القراءة تدريجياً للاعتماد على الـ Ledger Projections.

عند نهاية هذه المرحلة تصبح:

- Ledger Projections هي Read Model الرسمي.
- Transactions تمثل Write Model.
- Financial Engine هو المسار الوحيد للكتابة.

---

# Phase 7 — Architecture Cleanup

المرحلة الأخيرة.

تشمل:

- إزالة Legacy Services
- إزالة Dual Writers
- إزالة Migration Code
- إزالة Dead Code
- تحديث جميع ADRs
- تحديث Architecture Diagrams

---

# Final Architecture Vision

```
                  UI
                   │
                   ▼
         TransactionApplicationService
                   │
                   ▼
        Financial Operation Engine
                   │
      ┌────────────┴────────────┐
      ▼                         ▼
Transaction Storage      Ledger Projection
 (Write Model)             (Read Model)
      │                         │
      └────────────┬────────────┘
                   ▼
          Presentation Layer
```

---

# Guiding Principles

- يوجد مسار كتابة واحد فقط.
- جميع العمليات تمر عبر الـ Financial Engine.
- لا توجد Special Cases داخل الـ Pipeline.
- الـ Ledger يمثل نموذج القراءة الرسمي.
- الـ Transactions تمثل السجل المالي الرسمي للكتابة.
- أي تغيير معماري مستقبلي يتطلب ADR جديد.

---

# Expected Outcome

عند اكتمال جميع المراحل يصبح النظام:

- Fully Engine Driven
- Single Write Path
- Projection-Based Read Model
- Architecture Consistent
- Ready for Future Financial Modules

مثل:

- Goals
- Budgets
- Investments
- Loans
- Installments
- ROSCA
- Shared Books
- Multi-Currency