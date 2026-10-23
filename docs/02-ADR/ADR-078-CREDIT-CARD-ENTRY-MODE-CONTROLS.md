# ADR-078 — Credit Card Entry Mode Controls by Entry Intent

**Status:** Accepted  
**Date:** 2026-10-24  
**Decision Type:** Expense Entry UX and Interaction Boundary  
**Related:** ADR-013 (Entry Session State), ADR-020 (Wafferly UI Design System), ADR-035 (Credit Card Domain), ADR-052 (Installment / Financing Contract Model), ADR-077 (Credit Card Installment Down Payment Policy and Validation)

## 1. Context

The shared expense-entry interface can be opened with different intents. A normal expense made from a credit-card screen and a new installment purchase made from that screen must not expose interchangeable financial actions. If both `Full Payment` and `Installment` appear active in the wrong flow, a user can initiate an action that does not belong to the current entry intent or encounter a misleading error.

The UI must preserve the explicit entry intent supplied by navigation/session state. Control availability must not be inferred from language, RTL/LTR direction, entered amount, or visual placement.

## 2. Decision

### 2.1 Normal expense entry from a Credit Card

When the user enters the normal expense flow from a Credit Card account:

- `Full Payment` is the active/available payment mode for the current entry;
- `Installment` is visibly disabled and non-interactive in this flow;
- pressing the disabled control must not open installment details, alter the entry mode, or trigger a financial operation.

### 2.2 Installment purchase entry from a Credit Card

When the user enters the dedicated Credit Card installment-purchase flow:

- `Installment` is the active/available mode and owns the action to open installment details;
- `Full Payment` is visibly disabled and non-interactive in this flow;
- the entry must not silently fall back to a normal full-payment card charge.

### 2.3 Entry intent is explicit

The active mode is determined by the route/session intent (for example, the dedicated credit-card-installment entry flag), not by locale, UI direction, button order, or the amount being entered. Arabic/RTL and English/LTR layouts must preserve the same mode semantics.

### 2.4 Control ownership and Done behavior

In the dedicated installment-entry flow, the `Installment` control is responsible for opening the installment-details surface. The `Done` control in the entry panel must not have a financial effect and must not act as an alternative way to open the installment-details surface. Financial execution remains attached only to the explicitly designated action in the installment-details flow after validation.

The two controls must remain separate. Their visual states and interaction callbacks must not be merged into a single ambiguous action.

### 2.5 Localization requirement

All user-visible input-panel labels and related validation text must use the app localization resources in Arabic and English. This includes, but is not limited to, `Today`, `Installment`, `Full Payment`, `Done`, and `Note`. Adding or changing UI labels must not introduce new hard-coded user-facing strings where a localized resource is expected.

### 2.6 Financial boundary

These are interaction rules, not permission to bypass financial validation. The existing Financial Operation Engine remains responsible for authoritative financial writes, with its validation, atomicity, and idempotency requirements unchanged.

## 3. Behavior Matrix

| Entry intent | Full Payment | Installment | Required behavior |
|---|---|---|---|
| Normal expense from Credit Card | Active/available | Disabled/non-interactive | Continue only through the normal expense path |
| Installment purchase from Credit Card | Disabled/non-interactive | Active/available | Installment control opens installment details; execution follows that flow |

## 4. Required Tests

- normal card-expense flow enables Full Payment and disables Installment;
- installment-only flow enables Installment and disables Full Payment;
- a disabled control has no callback side effect;
- Installment opens details in the installment-only flow;
- Done causes no financial mutation and does not replace Installment's navigation role;
- both modes retain the intended selected credit-card account;
- mode semantics are identical in Arabic/RTL and English/LTR;
- all input-panel strings in scope resolve from the Arabic and English localization resources;
- no change to financial execution rules or the Financial Operation Engine's writer boundary.

## 5. Consequences

- Entry intent determines which payment-mode action is available.
- The UI communicates disabled actions rather than allowing invalid paths and then reporting an avoidable runtime error.
- `Installment`, `Full Payment`, and `Done` have distinct, testable responsibilities.
- Localization and layout direction do not change financial behavior.
