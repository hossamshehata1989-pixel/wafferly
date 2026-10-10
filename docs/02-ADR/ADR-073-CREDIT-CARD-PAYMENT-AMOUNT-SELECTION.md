# ADR-073 — Credit Card Payment Amount Selection and Derived Statement Due

**Status:** Accepted for the initial payment-screen implementation  
**Date:** 2026-10-11  
**Related:** ADR-050 (Credit Card Statement Lifecycle), ADR-051 (Credit Card Payment Settlement), ADR-069 (Credit Card Statement ↔ Installment Relationship), ADR-072 (Credit Card Linked Bank Account)

## Context

The Credit Card payment screen previously offered only the current outstanding amount. That amount includes both billed and potentially unbilled activity, so it cannot stand in for the amount due on the current monthly statement.

The profile already stores a statement closing day and a payment due day. Effective card charges, card payment transactions, active financing contracts, and financing installments are also available to the read projection.

The project does not yet persist a closed statement entity or import an issuer-provided statement. Therefore an amount calculated in the current implementation must not be represented as a bank-imported or immutable official statement.

## Decision

The Pay Credit Card screen offers three choices:

1. **Statement Due** — the remaining recorded obligations billed into statement cycles whose payment due dates are on or before the payment-due date for the current calendar month. Prior unpaid obligations are carried into the amount due. The amount is estimated from effective Wafferly transactions and schedules, and is visibly described as calculated rather than imported.
2. **Full Outstanding** — the authoritative current outstanding liability derived from the existing financial balance projection.
3. **Custom Amount** — a user-entered amount, still subject to the existing engine constraints that it be positive and not exceed current outstanding.

Statement Due is the default selection when both closing day and payment due day are configured and the calculated due amount is positive. If either setting is missing, or the calculation finds no amount due for the current payment cycle, Statement Due is unavailable for selection and Full Outstanding is selected by default.

Payments already recorded as Credit Card payment operations are allocated read-side to the oldest eligible recorded obligations first. This prevents a payment from being deducted again from a more recent statement while an older recorded obligation remains outstanding.

For a converted Credit Card charge, the original charge is omitted from a statement cycle when the conversion became effective by that cycle's close boundary; scheduled installments are included in the cycles containing their scheduled due dates. A conversion effective after a cycle closes does not rewrite that cycle's historical charge representation.

All actual payment mutation continues to pass through the Financial Operation Engine under ADR-051. The derived statement amount is only a payment-selection projection and is never a second account balance.

## Explicit Limitations

- The calculated statement due is not an official issuer statement and may differ when bank-side fees, interest, adjustments, refunds, or unrecorded events have not been imported into Wafferly.
- This ADR does not create or close a persisted statement, implement bank statement import, or define minimum-payment calculation.
- A future implementation of the full ADR-050 statement lifecycle must add stable statement identity, immutable close snapshots, close idempotency, and reconciliation with issuer-provided statement data. It may replace this calculated read-side estimate without changing the three payment modes.

## Validation Requirements

- Statement amount excludes unbilled current-cycle activity whose payment due date is after the current month's due date.
- Already-recorded payments reduce oldest eligible obligations first.
- The selected statement amount cannot exceed current outstanding.
- Full Outstanding uses current financial truth rather than statement estimate.
- Custom Amount continues to use ADR-051 validation and engine execution.
- End-of-month dates clamp explicitly; no invalid statement or due day is allowed to determine behavior through `DateTime` overflow.
- Converted charges do not double-count with their scheduled installments.
