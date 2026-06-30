# ADR: Financial Operation Engine

**Status:** Accepted – Implementation Pending  
**Date:** 2025-06  
**Project:** Wafferly

---

## Context

أثناء اختبار الـ Development Demo، اكتشفنا Bug معماري في `GoalDetailsScreen`:

زر "Transfer To Saving" ينشئ `Transaction` مباشرة بدون أي Balance Validation، مما أدى إلى أن حساب Bank أصبح `-45,000 EGP` بعد تحويل من حساب رصيده صفر.

**التحليل كشف ثلاثة أخطاء:**

1. **غياب Balance Validation** في مسار Goal Transfer.
2. **مصدر المبلغ غلط**: الـ Dialog يستخدم `goal.targetAmount` بدلاً من رصيد الحساب الفعلي — والـ Goal Target هو Intent وليس Available Balance.
3. **غياب Pipeline موحدة**: كل Feature تنشئ `Transaction` بطريقتها الخاصة:
   - `TransactionEntryController` — فيه Validation
   - `GoalDetailsScreen` — بدون Validation
   - وأي Feature مستقبلية ستواجه نفس الخطر

هذا ينتهك القرار المعماري الأساسي:
> *Only authorized domain operations may create or modify Financial Truth.*

---

## Decision

### 1. FinancialOperation — Command

```dart
abstract class FinancialOperation {
  final String? resolution; // null في الجولة الأولى

  FinancialOperation resolve(Resolution resolution);
}

// أمثلة
class GoalTransferOperation      extends FinancialOperation {}
class ExpenseOperation           extends FinancialOperation {}
class CommitmentPaymentOperation extends FinancialOperation {}
```

**القواعد:**
- يحمل البيانات والـ Intent فقط — لا logic
- **Immutable** — لا يُعدَّل، يُستبدل بنسخة جديدة عبر `operation.resolve(...)`
- يحمل الـ Resolution في الجولة الثانية

---

### 2. FinancialOperationEngine — Orchestrator

```dart
class FinancialOperationEngine {
  Future<OperationResult> execute(FinancialOperation operation);
}
```

**القواعد:**
- **Stateless** بالكامل — لا `_pendingOperation`، لا `_lastValidation`، لا `_resume()`
- **Single Entry Point** لأي عملية تؤثر على Financial Truth
- لا يعرف شيئاً عن الـ UI — لا `BuildContext`، لا `Dialog`، لا `Navigator`
- كل `execute()` يبدأ من الصفر بغض النظر عن الجولة

---

### 3. Pipeline داخل الـ Engine

```
FinancialOperation
        │
        ▼
   Validators             ← مجموعة Validators مستقلة (راجع القسم التالي)
        │
        ▼
   Policy                 ← Execute / TempDebt / AddBalance / Cancel / RequireUserConfirmation
        │
        ▼
   PlanBuilder            ← يبني FinancialExecutionPlan
        │
        ▼
FinancialExecutionPlan
   └── List<FinancialMutation>
        │
        ▼
   Executor               ← ينفذ الـ Plan عبر TransactionService + LedgerService
        │
        ▼
OperationResult
```

**ملاحظة على الـ Policy:**
`RequireUserConfirmation` هي نتيجة السياسة — وليست طلباً مباشراً من الـ Engine للمستخدم. الـ Engine يعيد `UserConfirmationRequired` كـ `OperationResult`، والـ UI هي التي تقرر كيف تتعامل معه.

---

### 4. Validators — مستقلة وليست God Object

الـ Validation ليست Validator واحداً ضخماً، بل مجموعة Validators مستقلة يُشغّلها الـ Engine بالتسلسل:

```
Validators
    ├── BalanceValidator       ← هل الرصيد كافٍ؟
    ├── AllocationValidator    ← هل الـ Allocation صحيحة؟
    ├── GoalValidator          ← هل العملية تتوافق مع قواعد الـ Goal؟
    ├── CommitmentValidator    ← هل تتوافق مع قواعد الـ Commitment؟
    └── CurrencyValidator      ← هل العملات متوافقة؟
```

كل Validator مسؤول عن نطاق واحد فقط. إضافة قاعدة جديدة = إضافة Validator جديد — دون تعديل الموجود.

---

### 5. FinancialExecutionPlan

```dart
class FinancialExecutionPlan {
  final List<FinancialMutation> mutations;
}

sealed class FinancialMutation {}

// Core — يعرفها الـ Engine مباشرة
class CreateTransaction     extends FinancialMutation {}
class CreateLedgerEntry     extends FinancialMutation {}
class CreateScheduledAction extends FinancialMutation {}

// Domain-specific — كل domain يعرّف mutations خاصة به
class UpdateGoalAllocation  extends FinancialMutation {}
class SettleCommitment      extends FinancialMutation {}
```

**قاعدة الـ FinancialMutation:**
> `FinancialMutation` is a **declarative description of a domain state change**. It contains no execution logic.

```dart
// ✅ صح — Data فقط
class UpdateGoalAllocation extends FinancialMutation {
  final String goalId;
  final double amount;
}

// ❌ غلط — Execution Logic داخل الـ Mutation
class CreateTransaction extends FinancialMutation {
  Future execute() async { ... } // يكسر التصميم
}

// ❌ غلط — Storage Detail
class HivePutGoal     extends FinancialMutation {}
class SqlInsert       extends FinancialMutation {}
class FirestoreUpdate extends FinancialMutation {}
```

الـ Mutation تصف **ماذا يتغير في الـ Domain** — الـ Executor هو الوحيد الذي يعرف كيف يُنفَّذ.

**لماذا `FinancialExecutionPlan` وليس `Transaction.create()` مباشرة؟**
- يفصل بين **Planning** (ماذا سننفذ؟) و**Execution** (نفّذ)
- يدعم العمليات المركّبة: عملية واحدة قد تنتج أكثر من Mutation
- يمكن فحص الـ Plan قبل التنفيذ — لو فيها خطأ يُكتشف قبل أن أي شيء يُحفظ
- يجعل الـ Engine قابلاً للاختبار بسهولة

---

### 6. OperationResult — sealed class

```dart
sealed class OperationResult {}

class OperationSucceeded extends OperationResult {
  final FinancialExecutionSummary summary;
}

class InsufficientBalance extends OperationResult {
  final double required;
  final double available;
  final List<Resolution> options;
}

class ValidationFailed extends OperationResult {
  final String reason;
}

class UserConfirmationRequired extends OperationResult {
  final List<Resolution> options;
}
```

**قاعدة الـ Summary:**
> `ExecutionSummary` تحمل فقط **artifacts produced during execution**، وليس input data.

```dart
class FinancialExecutionSummary {
  final List<String> createdTransactionIds;
  final Map<String, double> balanceChanges;
  final List<String> createdMutationIds;
}
```

- إذا أنشأ الـ Engine Goal جديدة → يرجع الـ ID لأنه **ناتج عن التنفيذ**
- أما `goalId` كان موجوداً في الـ Operation أصلاً → لا يُرجع

---

### 7. Re-entry بدون State

```dart
// الجولة الأولى
final operation = GoalTransferOperation(
  sourceAccountId: 'bank',
  destinationAccountId: 'savings',
  amount: 45000,
);

final result = await engine.execute(operation);
// result = InsufficientBalance(available: 0, required: 45000, options: [...])

// المستخدم اختار TempDebt — ينشأ Object جديد Immutable
final resolved = operation.resolve(Resolution.tempDebt);

final result2 = await engine.execute(resolved);
// result2 = OperationSucceeded(summary: ...)
```

الـ Engine لا يعرف أن هذه "الجولة الثانية" — هو دائماً يستقبل `FinancialOperation` ويعيد `OperationResult`.

---

## Engine Guarantees

هذه هي الـ Contract التي يلتزم بها `FinancialOperationEngine` في جميع الأحوال:

| الضمان | التفاصيل |
|--------|----------|
| **Validation First** | كل عملية تُفحص قبل التنفيذ — بدون استثناء |
| **No Partial Mutation** | إذا فشل الـ Validation، لا يُعدَّل أي Financial Truth |
| **Deterministic** | نفس الـ `FinancialOperation` تنتج دائماً نفس الـ `OperationResult` في نفس الحالة |
| **Stateless** | لا يحتفظ بأي حالة بين الـ Executions |
| **UI Agnostic** | لا يعرف شيئاً عن الـ Presentation Layer |
| **Complete Result** | كل تنفيذ ناجح يرجع `OperationSucceeded` مع `ExecutionSummary` |

أي كسر لأي ضمان من هذه الضمانات يُعتبر خرقاً للـ ADR ويستوجب المراجعة.

---

## Architectural Rule — إلزامية

> **Financial Truth MAY ONLY be modified through `FinancialOperationEngine.execute()`.**

### ممنوع تماماً في أي مكان خارج الـ Engine:

```dart
// ❌ ممنوع
Transaction.create(...)
TransactionService.add(...)
LedgerService.create(...)
// أي تعديل مباشر على Balance أو Ledger أو Financial Truth
```

### المسار الوحيد المسموح:

```dart
// ✅ المسار الصحيح الوحيد
await FinancialOperationEngine.instance.execute(operation);
```

**تنطبق هذه القاعدة على:**
- جميع شاشات الـ UI والـ Controllers
- جميع الـ Services الأخرى
- SMS Automation / OCR / Financial Action Center
- أي Feature مستقبلية

أي مطور يكتب `TransactionService.add(...)` من شاشة أو Controller مباشرة يخالف هذا الـ ADR بشكل صريح.

---

## Non-Goals

`FinancialOperationEngine` **ليس** مسؤولاً عن:

- UI أو Dialogs أو Bottom Sheets أو Navigation
- Toasts أو SnackBars
- Analytics أو Logging للـ UI
- اختيار المستخدم للـ Resolution — مسؤولية الـ Presentation Layer
- حفظ الـ Workflow بين الجولتين — مسؤولية الـ UI

مسؤوليته فقط:
```
Validate → Policy → PlanBuilder → Execute → OperationResult
```

---

## Consequences

### إيجابيات
- ✅ باب كامل من الأخطاء يُغلق: لا Transaction بدون Validation
- ✅ قاعدة واحدة للـ TempDebt تنطبق على Goal / Commitment / Expense / SMS
- ✅ كل Feature جديدة تمر بنفس الـ Pipeline تلقائياً
- ✅ الـ Engine قابل للاختبار بالكامل بدون UI
- ✅ الـ OperationResult يجعل الـ UI واضحة ومتوقعة

### تكاليف
- ⚠️ `TransactionEntryController` يحتاج Refactor تدريجي ليمر بالـ Engine
- ⚠️ Goal Transfer يحتاج إعادة كتابة كاملة لاستخدام الـ Pipeline
- ⚠️ TempDebt ينتقل من `TransactionEntryController` إلى الـ Policy Layer

---

## Migration Path

**المرحلة الأولى — Fix the Bug (الآن):**
- إعادة كتابة `GoalDetailsScreen` لتستخدم `FinancialOperationEngine`
- إصلاح `availableAmount` ليأتي من رصيد الحساب وليس `goal.targetAmount`

**المرحلة الثانية — بناء الـ Engine:**
- تعريف `FinancialOperation` و`FinancialExecutionPlan` و`OperationResult`
- نقل منطق الـ Validation من `TransactionEntryController` إلى الـ Validators
- نقل TempDebt إلى الـ Policy Layer

**المرحلة الثالثة — Migration تدريجي:**
- ربط كل Feature بالـ Engine واحدة تلو الأخرى

**المرحلة الرابعة — Cleanup إلزامي:**
- بعد ربط كل Feature، تُعلَّن جميع المسارات القديمة `@deprecated`
- يُحدَّد موعد صريح لحذفها
- لا يُقبل بقاء `TransactionEntryController` و`FinancialOperationEngine` شغّالَين معاً بشكل دائم

---

## Summary

هذا الـ ADR لا يعالج Bug واحداً في Goal Transfer. هو يضع البوابة الوحيدة التي تحكم كل العمليات المالية في Wafferly — الحالية والمستقبلية.

> The Financial Operation Engine never interacts with the user directly.  
> It only evaluates, executes, and returns an OperationResult.  
> User interaction is exclusively the responsibility of the Presentation Layer.

---

## Architectural Principle

> **`FinancialOperationEngine` is the only authority allowed to mutate Financial Truth.**  
> Every financial feature, current or future, must enter the system through this engine.