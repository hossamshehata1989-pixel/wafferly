# ADR-077 — Credit Card Installment Down Payment Policy and Validation

**Status:** Accepted  
**Date:** 2026-10-24  
**Decision Type:** Financing Eligibility, Down Payment Source, and UI Validation  
**Related:** ADR-035 (Credit Card Domain), ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation), ADR-062 (Financing Overpayment and Excess Payment), ADR-067 (Financing Operation Idempotency), ADR-076 (Scheduled Execution Atomicity and Recovery)

## 1. Context

The Credit Card installment-entry flow supports a purchase amount and an optional down payment. A stale guard in the entry controller rejected every positive down payment in the credit-card installment-only flow, even when the selected down-payment source was Cash. This contradicted the product decision to allow a down payment in this flow.

The owner also explicitly confirmed that the down-payment source may be the same credit-card account selected as the financing source. The source must not be rejected merely because its ID matches the financing source ID.

The UI must prevent invalid amounts before execution and explain the validation failure to the user. A failed validation must not create a contract, transaction, ledger effect, or other financial mutation.

## 2. Decision

### 2.1 Down payment is supported

A Credit Card installment entry may include a down payment. The entry path must not reject all positive down payments solely because the entry originated from the Credit Card installment flow.

### 2.2 Permitted down-payment sources

The down-payment source may be a supported eligible payment account, including Cash. It may also be the same credit-card account selected as the financing source. The implementation must not apply a blanket rule that rejects the same-card source solely because the two account IDs match.

Source eligibility, currency consistency, credit-limit rules, and financial effects must continue to pass through the existing domain and Financial Operation Engine boundaries. This ADR does not authorize UI code to write financial truth directly or to bypass other existing financial guards.

### 2.3 Amount validation

For a purchase amount `P` and an enabled down payment `D`, the input is valid only when:

```text
P > 0
0 < D < P
Financed Principal = P - D
```

A down payment equal to or greater than the purchase amount is invalid for this installment-plan flow. The app must reject it before financial execution. A zero down payment is represented by leaving the down-payment option disabled, not by enabling the option with a zero amount.

This rule prevents a negative or zero financed principal from being used to create an ordinary installment plan.

### 2.4 Validation feedback

When the down payment is invalid, the screen must:

- show a clear validation message inside the installment-details surface, adjacent to the primary Continue action;
- use the active app locale (Arabic or English);
- prevent execution and financial mutation;
- clear or recompute the message when relevant inputs change, such as purchase amount, down-payment amount, or down-payment enabled state.

The error must remain visible within the open modal/sheet; relying only on a `SnackBar` behind the modal is insufficient.

### 2.5 Preserve the existing financial execution boundary

Once validation passes, the existing installment execution/save pipeline remains responsible for the financial operation. UI validation is an early user-feedback layer, not a replacement for domain validation or Financial Operation Engine guards.

This decision does not change ADR-062's strict rejection of financing-payment overpayments with a non-zero unallocated amount. ADR-062 governs allocation of financing payments against eligible obligations; it does not define the purchase down-payment limit described here.

## 3. Examples

| Purchase | Down payment | Source | Expected result |
|---:|---:|---|---|
| EGP 3,000 | EGP 700 | Cash | Valid input; proceed through existing execution pipeline |
| EGP 3,000 | EGP 700 | Same card used as financing source | Valid input; proceed through existing execution pipeline |
| EGP 3,000 | EGP 3,000 | Any eligible source | Reject before execution |
| EGP 3,000 | EGP 4,000 | Any eligible source | Reject before execution |

For the valid EGP 3,000 / EGP 700 case, the principal to be financed before any applicable interest/fees is EGP 2,300. Schedule calculation and rounding remain governed by ADR-053 and the applicable financing policy.

## 4. Verification Record

The owner manually confirmed successful execution for an EGP 3,000 purchase with an EGP 700 down payment using both:

- Cash as the down-payment source;
- the same credit card as the financing source.

The owner also confirmed that the invalid down-payment validation message was working after the UI patch. These are manual checks reported during development; they are not a claim that the complete automated test suite passed.

## 5. Required Tests

- valid down payment from Cash executes successfully;
- valid down payment from the same credit card as the financing source executes successfully;
- down payment equal to purchase amount is rejected before financial mutation;
- down payment greater than purchase amount is rejected before financial mutation;
- rejection creates no financing contract, transaction, ledger mutation, or balance mutation;
- the localized error is shown inside the open installment-details surface;
- the message clears/revalidates after a relevant input changes;
- existing source eligibility, currency, credit-limit, atomicity, and idempotency tests remain in force.

## 6. Consequences

- Credit Card installment entries may use a supported down payment instead of being blanket-rejected.
- Same-card down-payment source selection is allowed by product policy, subject to the ordinary domain and engine rules.
- Invalid down-payment amounts are stopped early with visible, localized feedback.
- Valid requests still use the existing financial operation boundary; no alternate UI-only save path is introduced.
