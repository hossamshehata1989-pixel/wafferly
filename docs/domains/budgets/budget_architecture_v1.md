# Wafferly Budget Architecture v1.0

## Status

Approved

## Phase

Phase 3 – Budget System

---

# 1. Budget Types

تم اعتماد نوعين من الميزانيات:

### Monitoring Budget

الغرض:

* مراقبة الإنفاق فقط.
* لا تحجز أموال.
* لا تؤثر على Available Balance.

مثال:

Food Budget = 5000

Spent = 3000

Remaining = 2000

---

### Protected Budget

الغرض:

* حجز أموال مسبقاً للميزانية.
* تقليل Available Balance.
* تعمل بطريقة Envelope Budgeting.

مثال:

Food Budget = 5000

Reserved = 5000

Available Balance -= 5000

---

# 2. Budget Funding

Budget مرتبطة بحساب أو أكثر.

مثال:

Food Budget = 5000

Sources:

Cash = 2000

Bank = 2000

Wallet = 1000

لا يسمح بإنشاء Budget Protected بدون وجود Funding Source حقيقي.

---

# 3. Multi-Source Funding

معتمد رسمياً.

يمكن تمويل Budget من عدة حسابات.

مثال:

Cash → 1000

Bank → 3000

Wallet → 1000

Food Budget = 5000

---

# 4. Budget Consumption Model

تم اعتماد:

Envelope Style

عند تسجيل مصروف من نفس الفئة:

Food Budget = 5000

Expense = 1000

يصبح:

Reserved = 4000

Spent = 1000

Remaining = 4000

أي أن المصروف يستهلك الحجز مباشرة.

---

# 5. Budget Overspending

عند تجاوز الميزانية:

لا يتم حفظ Transaction مباشرة.

يظهر Budget Resolution Dialog أولاً.

---

## Resolution Options

### Increase Budget

زيادة الميزانية.

---

### Move From Another Budget

نقل جزء من ميزانية أخرى.

مثال:

Transport -500

Food +500

---

### Ignore Budget

تجاهل الميزانية لهذا المصروف.

---

### Cancel

إلغاء العملية.

---

بعد اتخاذ القرار يتم حفظ Transaction.

---

# 6. Budget Increase Rules

عند زيادة Budget:

لا يسمح بزيادة الرقم مباشرة.

يجب تحديد مصدر الزيادة.

مثال:

Food Budget:

5000 → 7000

يجب تحديد:

Transport -2000

Food +2000

أو

Cash Available -2000

Food +2000

---

# 7. Budget Activities

لكل Budget سجل Activities مستقل.

أمثلة:

Created

Funded

Increased

Reduced

Overspent

Released

Transferred

Rolled Over

Closed

---

# 8. Budget Period Policy

كل Budget تمتلك سياسة انتهاء مستقلة.

المستخدم يحددها عند الإنشاء.

---

## Available Policies

### Reset

تبدأ الفترة الجديدة من الصفر.

---

### Carry Forward

ترحيل المتبقي للفترة التالية.

---

### Transfer To Saving

تحويل المتبقي إلى Saving Account.

---

### Release

فك الحجز وإعادة الأموال للرصيد المتاح.

---

### Keep Reserved

الإبقاء على المبلغ محجوزاً.

---

# 9. Keep Reserved Safeguard

إذا كانت هناك أموال محجوزة من فترة سابقة:

يجب تحذير المستخدم قبل إنشاء حجز جديد.

مثال:

Existing Reserved = 2000

New Budget Reservation = 5000

Total Reserved = 7000

ويختار المستخدم أحد الخيارات:

* Continue Existing Reservation
* Add New Reservation
* Release Existing Reservation

---

# 10. Budget To Budget Transfer

معتمد رسمياً.

مثال:

Transport Remaining = 1500

Move 1000

↓

Food Budget

فتصبح:

Transport Remaining = 500

Food Remaining += 1000

ويتم إنشاء Activity.

---

# 11. Relationship With Goals

Goal ≠ Budget

Goal:

* Saving Money
* Long-Term
* Progress Driven

Budget:

* Spending Control
* Short-Term
* Consumption Driven

---

# 12. Relationship With Allocation

Budget لا تستخدم Goal Allocation الحالية مباشرة.

سيتم إنشاء:

BudgetAllocationService

مستقلة عن:

GoalAllocationService

مع الحفاظ على نفس الفلسفة:

Reserve

Release

Available Balance Impact

Activities

Projection

---

# 13. Relationship With Virtual Saving Account

المبالغ المحجوزة يمكن عرضها داخل:

Virtual Saving Account

كمركز موحد لإدارة الأموال المحجوزة.

يمكن للمستخدم:

* Release
* Transfer
* Review Reservations

من مكان واحد.

---

# Final Architecture

Accounts
↓
Transactions
↓
Ledger
↓
Balance Service
↓
Available Balance

Goals
↓
Goal Allocation Engine

Budgets
↓
Budget Allocation Engine

Virtual Saving
↓
Reserved Money Management

Source Of Truth:

Accounts + Transactions + Ledger

Only

Everything Else Is Derived
