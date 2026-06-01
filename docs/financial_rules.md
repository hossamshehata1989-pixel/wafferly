# Wafferly Financial Architecture

## Financial Rules

### Source of Truth

Accounts + Transactions are the only source of truth.

Any balance shown in the application must ultimately be derived from accounts and transactions.

---

### Accounts

Accounts represent real financial containers.

Examples:

* Cash
* Bank Accounts
* Wallets

Real balances live here.

---

### Transactions

Transactions are financial events that modify balances.

Examples:

* Expense
* Income
* Transfer
* Borrow
* Lend
* Repayment
* Collection

---

### Members

Members are actors/participants.

Members are NOT financial containers.

A member can participate in transactions but does not own a balance.

---

### Goals

Goals are allocation layers.

Goals do not contain money.

Money always remains inside real accounts.

Goals only reserve or allocate portions of existing balances.

---

### Reserved Money

Reserved money does not reduce actual balance.

Reserved money reduces available balance only.

Example:

Cash = 10,000

Goal Allocation = 3,000

Actual Balance = 10,000

Available Balance = 7,000

---

### Budgets

Budgets are policy and allocation layers.

Budgets do not own balances.

Budgets analyze and control spending behavior.

---

### Analysis

Analysis is derived data only.

Analysis never becomes a source of truth.

All reports must be calculated from accounts and transactions.

---

### Archive

Financial entities should be archived, not deleted.

Historical financial data must remain available for reporting and auditing purposes.

---

# Net Worth

## Core Principle

Wafferly is built around Net Worth, not just account balances.

Net Worth = Assets - Liabilities

Assets:

* Cash
* Bank Accounts
* Wallets
* Lent (Money you will get)

Liabilities:

* Borrowed (Money you owe)
* Temporary Debt

Every financial operation must preserve this principle.

---

# Borrowed (Money I Owe)

Borrowed is a Liability.

Example:

Cash
+1000

Borrowed
+1000

Net Worth remains unchanged.

---

## Repayment

Cash
-300

Borrowed
-300

Net Worth remains unchanged.

---

# Lent (Money Others Owe Me)

Lent is an Asset.

Example:

Cash
-1000

Lent
+1000

Net Worth remains unchanged.

---

## Collection

Cash
+300

Lent
-300

Net Worth remains unchanged.

---

# Effect on Real Accounts

Borrowed and Lent MUST affect the selected real account.

Examples:

Borrowed:

Cash
+1000

Borrowed
+1000

Lent:

Cash
-1000

Lent
+1000

This follows Double Entry Accounting principles.

---

# Rejected Design

Borrowed
+1000

Cash unchanged

Rejected because it creates unrealistic balances and inaccurate reports.

---

# Temporary Debt

Temporary Debt is NOT Borrowed.

Borrowed:

* Real borrowing transaction
* Money entered a real account

Temporary Debt:

* Insufficient balance workaround
* No real borrowing transaction

---

# Insufficient Balance Flow

Available Balance = 200

Expense = 500

Shortage = 300

Options:

* Choose Another Account
* Add Income
* Temporary Debt
* Cancel

---

# Temporary Debt Accumulation

Temporary Debt accumulates into a single balance.

Example:

Shortage #1 = 300

Shortage #2 = 100

Temporary Debt Balance = 400

Wafferly does not create a separate debt record for every shortage.

---

# Income Settlement Reminder

When:

Income > 0

AND

Temporary Debt Balance > 0

Wafferly displays:

"You have a temporary debt.

Would you like to settle it now?"

Options:

* Settle Debt
* Keep Debt

---

# Final Design Summary

# Borrowed

Real Liability
+
Affects Real Account

# Lent

Real Asset
+
Affects Real Account

# Temporary Debt

Insufficient Balance Workaround
+
Liability
+
No Real Borrowing Transaction

All three affect Net Worth correctly and preserve accounting consistency.


# BORROWED / LENT RULES

## Rule 12: Borrowed Account Behavior

Borrowed is a Liability Account.

When user borrows money:

Real Account
(Cash / Bank / Wallet)
+
Borrowed Account

Example:

Borrow 1000 EGP

Cash
+1000

Borrowed
+1000

Result:

* Available cash increases
* Liability increases
* Net Worth remains unchanged

When user repays debt:

Cash
-300

Borrowed
-300

Result:

* Cash decreases
* Remaining liability decreases

Status:
[APPROVED]

---

## Rule 13: Lent Account Behavior

Lent is an Asset Account.

When user lends money:

Real Account
(Cash / Bank / Wallet)
↓
Lent Account

Example:

Lend 1000 EGP

Cash
-1000

Lent
+1000

Result:

* Cash decreases
* Receivable asset increases
* Net Worth remains unchanged

When money is collected:

Cash
+300

Lent
-300

Result:

* Cash increases
* Remaining receivable decreases

Status:
[APPROVED]

---

## Rule 14: Double Entry Principle

Borrowed and Lent transactions must affect:

1. A real account
   (Cash / Bank / Wallet)

AND

2. A counterpart account
   (Borrowed / Lent)

Forbidden:

❌ Update Borrowed only
❌ Update Lent only
❌ Ignore real account balance

Reason:

Balances
Ledger
Reports
Analysis

must remain synchronized.

Status:
[APPROVED]

---

# GOALS / BUDGETS (PRELIMINARY DECISIONS)

## Rule 15: Goals

Goal is NOT an Account.

Goal represents:

✓ Saving target
✓ Financial objective

Goal does not create money.

Status:
[PRELIMINARY]

---

## Rule 16: Budgets

Budget is NOT an Account.

Budget represents:

✓ Spending limit
✓ Spending tracking

Budget does not represent real money.

Status:
[PRELIMINARY]

---

## Rule 17: Budget Feature Toggle

Expected behavior:

User may choose:

Budgets ON
or
Budgets OFF

Reason:

Some users want budgeting.
Some users only want expense tracking.

Status:
[PRELIMINARY]

---

## Rule 18: Reserved Money

Current direction:

Account Balance
remains unchanged

# Available Balance

Balance - Reserved Money

Example:

Cash = 10,000

Reserved = 3,000

Available = 7,000

Status:
[PRELIMINARY]

Note:

Goals / Budgets / Reserved Money
have NOT been fully finalized yet.
Only Borrowed / Lent decisions are considered approved.



# البنية المالية لتطبيق Wafferly

آخر تحديث: مرحلة استقرار المحرك المالي (Financial Engine Stabilization)

---

# 1. المبادئ الأساسية

## مصدر الحقيقة (Source of Truth)

المصدر الحقيقي الوحيد للبيانات المالية داخل Wafferly هو:

الحسابات (Accounts)
+
المعاملات (Transactions)

أي شيء آخر يجب أن يتم اشتقاقه منهما.

أمثلة:

* التحليلات (Analysis)
* التقارير (Reports)
* الميزانيات (Budgets)
* الأهداف (Goals)
* الأموال المحجوزة (Reserved Money)

ليست مصادر حقيقة للبيانات.

---

## التدفق المالي

المعاملات
↓
Ledger
↓
الأرصدة
↓
التقارير
↓
التحليلات

الـ Ledger جزء من المحرك المالي.

الـ Ledger ليس طبقة تقارير فقط.

الحالة:
[معتمد]

---

# 2. الحسابات

الحسابات تمثل أوعية مالية حقيقية.

أمثلة:

* نقدي (Cash)
* حسابات بنكية
* محافظ
* بطاقات ائتمان
* قروض
* استثمارات

الأرصدة الحقيقية تعيش هنا.

الحالة:
[معتمد]

---

# 3. المعاملات

المعاملات هي أحداث مالية.

أمثلة:

* مصروف
* دخل
* تحويل
* استلاف (Borrow)
* إقراض (Lend)
* سداد
* تحصيل

المعاملات هي التي تعدل الأرصدة من خلال الـ Ledger.

الحالة:
[معتمد]

---

# 4. الأعضاء (Members)

الأعضاء هم أطراف مشاركة فقط.

العضو ليس حسابًا ماليًا.

العضو لا يمتلك رصيدًا.

يمكن ربط العضو بمعاملة لكنه ليس مصدر أموال.

الحالة:
[معتمد]

---

# 5. سياسة الأرشفة

الكيانات المالية يجب أرشفتها بدلًا من حذفها متى أمكن.

السبب:

الحفاظ على السجل التاريخي للتقارير والتحليلات.

أمثلة:

* الحسابات
* الأهداف
* الأعضاء

الحالة:
[معتمد]

---

# 6. صافي الثروة (Net Worth)

## المعادلة الأساسية

صافي الثروة

=

## الأصول

الالتزامات

---

## الأصول (Assets)

أمثلة:

* النقدية
* الحسابات البنكية
* المحافظ
* الاستثمارات
* الأموال التي لي عند الآخرين (Lent)

---

## الالتزامات (Liabilities)

أمثلة:

* الأموال التي عليّ للآخرين (Borrowed)
* القروض
* بطاقات الائتمان
* الديون المؤقتة (Temporary Debt)

الحالة:
[معتمد]

---

# 7. Borrowed (أموال مستحقة عليّ)

Borrowed يعتبر التزامًا (Liability).

عندما أستلف 1000 جنيه:

النقدية
+1000

Borrowed
+1000

النتيجة:

* النقدية زادت
* الالتزامات زادت
* صافي الثروة لم يتغير

---

## عند السداد

النقدية
-300

Borrowed
-300

النتيجة:

* النقدية قلت
* الدين المتبقي قل
* صافي الثروة لم يتغير

الحالة:
[معتمد]

---

# 8. Lent (أموال مستحقة لي)

Lent يعتبر أصلًا (Asset).

عندما أسلف شخصًا 1000 جنيه:

النقدية
-1000

Lent
+1000

النتيجة:

* النقدية قلت
* المبلغ المستحق لي زاد
* صافي الثروة لم يتغير

---

## عند التحصيل

النقدية
+300

Lent
-300

النتيجة:

* النقدية زادت
* المبلغ المتبقي لي قل
* صافي الثروة لم يتغير

الحالة:
[معتمد]

---

# 9. قاعدة القيد المزدوج (Double Entry)

أي عملية Borrowed أو Lent يجب أن تؤثر على:

1. حساب حقيقي

مثل:

* Cash
* Bank
* Wallet

و

2. حساب مقابل

مثل:

* Borrowed
* Lent

ممنوع:

❌ تعديل Borrowed فقط

❌ تعديل Lent فقط

❌ تجاهل الحساب الحقيقي

السبب:

لضمان تطابق:

* الأرصدة
* Ledger
* التقارير
* التحليلات

الحالة:
[معتمد]

---

# 10. Temporary Debt (الدين المؤقت)

الدين المؤقت ليس Borrowed.

Borrowed:

* حدث استلاف حقيقي
* دخلت أموال فعلية إلى حساب حقيقي

Temporary Debt:

* حل مؤقت لنقص الرصيد
* لم يحدث استلاف فعلي

الحالة:
[معتمد]

---

# 11. مسار الرصيد غير الكافي

مثال:

الرصيد المتاح = 200

المصروف = 500

العجز = 300

الخيارات:

* اختيار حساب آخر
* إضافة دخل
* دين مؤقت
* إلغاء

الحالة:
[معتمد]

---

# 12. تراكم الدين المؤقت

الدين المؤقت يتراكم داخل رصيد واحد.

مثال:

العجز الأول = 300

العجز الثاني = 100

إجمالي الدين المؤقت = 400

لا يتم إنشاء سجل دين مستقل لكل عجز.

الحالة:
[معتمد]

---

# 13. تذكير تسوية الدين المؤقت

عندما:

الدخل > 0

و

رصيد الدين المؤقت > 0

يعرض النظام:

"لديك دين مؤقت، هل تريد تسويته الآن؟"

الخيارات:

* تسوية الدين
* الاحتفاظ بالدين

الحالة:
[معتمد]

---

# 14. الأهداف (Goals)

الهدف ليس حسابًا ماليًا.

الهدف يمثل:

* هدف ادخار
* هدف مالي

الأموال تظل داخل الحسابات الحقيقية.

الهدف لا ينشئ أموالًا جديدة.

الحالة:
[قيد النقاش]

---

# 15. الأموال المحجوزة (Reserved Money)

الاتجاه الحالي:

الأموال المحجوزة لا تقلل الرصيد الفعلي.

الأموال المحجوزة تقلل الرصيد المتاح فقط.

مثال:

الرصيد = 10,000

المبلغ المحجوز = 3,000

الرصيد الفعلي = 10,000

الرصيد المتاح = 7,000

الحالة:
[قيد النقاش]

---

# 16. الميزانيات (Budgets)

الميزانية ليست حسابًا ماليًا.

الميزانية تمثل:

* حدود صرف
* مراقبة الإنفاق
* التحكم في الإنفاق

الميزانية لا تمتلك أموالًا.

الحالة:
[قيد النقاش]

---

# 17. تفعيل الميزانيات

الاتجاه الحالي:

الميزة اختيارية.

يمكن للمستخدم اختيار:

تشغيل الميزانيات

أو

إيقاف الميزانيات

السبب:

بعض المستخدمين يريدون إدارة ميزانيات تفصيلية.

وبعضهم يريد فقط تسجيل المصروفات.

الحالة:
[قيد النقاش]

---

# القرارات المفتوحة

المواضيع التالية لم تُحسم نهائيًا بعد:

* آلية تمويل الأهداف (Goals Funding)
* كيفية عمل Reserved Money
* طريقة تنفيذ Budgets
* العلاقة بين Goals و Reserved Money
* العلاقة بين Budgets و Reserved Money

---

# الملخص النهائي

مصدر الحقيقة:

الحسابات + المعاملات

المحرك المالي:

المعاملات
↓
Ledger
↓
الأرصدة
↓
التقارير
↓
التحليلات

قرارات معتمدة:

✓ Borrowed

✓ Lent

✓ Temporary Debt

✓ الأرشفة

✓ نموذج Net Worth

قرارات ما زالت قيد النقاش:

◌ Goals

◌ Reserved Money

◌ Budgets
