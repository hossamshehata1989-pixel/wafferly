# ADR-046 — Monthly / Periodic Due-Date Rollover Policy

**Status:** Accepted
**Date:** 2026-09-26
**Scope:** ScheduleRule monthly recurrence and all features that consume recurring due dates
**Related:** `05-SCHEDULED-MONEY-CONTRACT_V2.md`, `ADR-035-CREDIT-CARD-DOMAIN.md`

## Context

The existing monthly recurrence implementation constructed the next date with the current day-of-month:

```dart
DateTime(
  rule.nextDueDate.year,
  rule.nextDueDate.month + 1,
  rule.nextDueDate.day,
)
```

Dart normalizes an invalid day by overflowing into the following month. Therefore a January 31 recurrence could become March 3 instead of February 28. This is implicit runtime behavior and is not an acceptable financial scheduling contract.

The Scheduled Money Contract V2 explicitly requires an encoded and tested monthly end-of-month policy. The same policy is required before Credit Card statement closing dates and due dates can safely depend on monthly recurrence.

## Decision

Wafferly uses **anchor-preserving monthly recurrence with explicit clamping**.

### 1. Original day-of-month is the anchor

For a monthly `ScheduleRule`, the intended day-of-month anchor is `startDate.day`.

Examples:

```text
startDate = Jan 30  → anchor = 30
startDate = Jan 31  → anchor = 31
```

The anchor is not silently replaced by a clamped occurrence day.

### 2. End-of-month anchors remain end-of-month

If `startDate` is the last day of its month, the rule is an end-of-month rule.

```text
Jan 31 → Feb 28 → Mar 31 → Apr 30 → May 31
Jan 31 (leap year) → Feb 29 → Mar 31
```

### 3. Non-EOM anchors clamp only when necessary

If the anchor day exists in the target month, it is used directly. If it does not exist, the occurrence is clamped to the target month's last day.

```text
Jan 30 → Feb 28 → Mar 30 → Apr 30 → May 30
```

The February 28 occurrence does **not** permanently change the anchor from 30 to 28.

### 4. No implicit DateTime overflow

Monthly recurrence must never depend on Dart's `DateTime` overflow normalization for its business semantics.

The target year, target month, and valid target day are calculated explicitly before constructing the `DateTime`.

## Consequences

### Positive

- Monthly due dates are deterministic.
- End-of-month commitments remain end-of-month.
- Credit Card statement/due-date schedules can safely build on the recurrence primitive.
- Short months and leap years have explicit behavior.
- The original day-of-month intent is preserved across clamped months.

### Trade-off

`ScheduleRule.startDate` is now part of the monthly recurrence calculation semantics. Existing rules therefore retain their persisted `startDate`; it must not be discarded or rewritten as part of occurrence advancement.

## Non-Goals

This ADR does not define:

- Credit Card statement generation.
- Statement due-date offsets.
- Minimum payment calculation.
- Installment schedules.
- Occurrence failure/retry state.
- Automatic advancement/persistence of `ScheduleRule.nextDueDate`.

Those concerns remain separate contracts.

## Regression Matrix

| Input | Next occurrence |
|---|---|
| Jan 31, non-leap year | Feb 28 |
| Feb 28 from Jan-31 EOM rule | Mar 31 |
| Jan 31, leap year | Feb 29 |
| Feb 29 from Jan-31 EOM rule | Mar 31 |
| Apr 30 EOM rule | May 31 |
| Jan 30 non-EOM rule | Feb 28 |
| Feb 28 from Jan-30 rule | Mar 30 |
| Dec 31 EOM rule | Jan 31 next year |

## Implementation

`ScheduleRuleService.calculateNextDueDate()` delegates monthly calculation to an explicit `_calculateNextMonthlyDueDate()` implementation that derives the anchor from `ScheduleRule.startDate`, detects an EOM anchor, computes the target month's last day, and clamps only when required.

Regression coverage is provided in:

`test/services/schedule_rule_service_eom_test.dart`
