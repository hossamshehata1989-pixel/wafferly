# Wafferly — Pay Card ADR Amendment Draft

**Status:** Draft for review — not yet merged into the repository; not Accepted for financial release  
**Scope:** Credit-card payment amount selection, payment allocation, reconciliation, and unpaid statement obligations.

## 1. Decisions captured from product discussion

1. The user enters the amount actually paid to the bank.
2. The payment screen shows Wafferly's current outstanding liability as a reference, not as an assumed official bank amount.
3. Use the actual minimum payment from the bank statement when the user supplies it or it is otherwise reliably available. Do not present an inferred percentage as an official amount.
4. The user may enter a custom payment amount.
5. A payment above the current liability is intended to be rejected under the current product policy.
6. When payment exceeds the current statement due but remains within current outstanding liability, the proposed allocation policy is to apply the excess against current unbilled liability, rather than creating a separate reserved balance for a future statement.
7. A closed statement is historical and must not be rewritten by a later payment.
8. If the bank's actual minimum payment is known from a reliable bank statement/source and the entered amount is lower, warn the user but do not block recording solely for that reason. If the minimum is unknown, do not show a below-minimum warning based on an estimated percentage.
9. A remaining statement obligation stays outstanding until paid. It becomes overdue only according to its due-date/status rules.
10. If the user reports a discrepancy between the actual bank balance and Wafferly's derived balance, ask for the reason. An unknown reason must remain a reconciliation, not be converted automatically into an expense.
11. If a discrepancy is identified as a genuine bank fee or interest charge, record it as the appropriate expense/financial event. Offer recurrence only after user confirmation.
12. After payment, show the payment amount and allocation details, including statement obligations, installments, and unbilled liability where the underlying data supports those distinctions.

## 2. Proposed amendment to ADR-073 — Credit Card Payment Amount Selection

### Decision

The payment amount field is user-entered and represents the amount the user actually paid or intends to record as paid. The UI may show current Wafferly outstanding liability and current statement due as reference values, but neither is silently treated as the amount paid.

The minimum payment value is taken from the bank statement when available. If unavailable, the application must state that the official minimum is unknown; it must not silently substitute a generic percentage as an official bank value. A below-minimum warning is shown only when the actual minimum is known from a reliable bank source.

### Validation and warning behavior

- Payment amount must be greater than zero.
- Payment amount is subject to the credit-card payment policy in ADR-051.
- If a known bank minimum exists and the entered payment is lower, show a warning explaining that the payment may be below the bank's required minimum. Do not block recording solely for that reason.
- If the bank minimum is unknown, do not show a minimum-payment warning or infer an official minimum.
- The screen must distinguish `Statement Due`, `Current Outstanding`, `Bank Minimum Due` (only when known), and `Payment Amount`.

### Explicit separation

ADR-073 selects the amount to record. It does not, by itself, define how that amount is allocated among a closed statement, unbilled charges, or installments. Allocation behavior belongs to ADR-051 and any related statement/installment allocation rules.

## 3. Proposed amendment to ADR-051 — Credit Card Payment / Settlement Operation

### Payment amount and current outstanding

The payment is an actual financial movement through the Financial Operation Engine. It decreases the source asset and the credit-card liability. It must not be modelled as a negative charge or by directly mutating a balance.

#### Intended payment vs. externally evidenced payment

The strict overpayment rule applies to a new payment that the user intends to execute or manually record as a new payment operation. It does **not** mean that Wafferly may reject or discard reliable external evidence (such as a verified bank SMS) that a payment has already occurred.

These cases must follow separate paths:

- **Intended/new payment:** validate against current authoritative liability. If the entered amount exceeds it, do not execute/record the payment as a normal `CreditCardPaymentOperation`; show the discrepancy and guide the user to establish the missing liability first.
- **Externally evidenced completed payment:** do not treat the evidence as a new payment request and do not discard it merely because its amount exceeds Wafferly's current liability. Route it to the external-event matching/reconciliation workflow. Determine whether missing purchases, fees, interest, or another discrepancy explains the difference. Record the appropriate underlying financial event(s) through authorized domain operations before settling the payment where feasible. An unknown difference follows the approved Balance Reconciliation path; it must not automatically become an expense.

Neither path may silently create a credit balance or directly edit an account balance. Evidence must be validated and deduplicated according to the existing SMS/OCR ingestion policy; evidence is not, by itself, permission to bypass financial-domain validation.

### Allocation boundary

A payment must preserve the historical statement amount. It may update the amount remaining to be paid against that statement, but must not rewrite the original closed statement snapshot.

For an amount greater than the remaining current statement due but not greater than total current outstanding liability, the proposed product policy is:

1. Allocate to eligible unpaid obligations according to the approved payment priority.
2. If the current statement due is fully covered, allocate the remaining amount against eligible current unbilled liability.
3. Do not create a separately reserved future-statement balance merely to represent this amount.
4. A later statement reflects the remaining eligible liability according to statement-generation rules; no statement that has already closed is rewritten.

**Important dependency:** “Apply to unbilled liability first” requires an authoritative way to identify and allocate eligible unbilled charges and avoid double-counting. It must not be implemented as a label-only change or as a direct balance adjustment. Confirm compatibility with ADR-069 and the actual payment/statement services before coding.

**V1 safety gate:** If the current implementation cannot reliably distinguish closed-statement items from unbilled liability and allocate without double-counting, do not implement the excess-allocation behavior yet. For the first release, constrain the supported manual Pay Card workflow to amounts that can be allocated safely against the known statement due, and clearly guide the user when they enter a larger amount. Do not silently clamp the amount or pretend the app recorded a larger real-world payment than it can safely represent. A confirmed external payment above the statement due must still go through the external-event/reconciliation path, not be discarded.

### Partial payments and overdue

A partial payment reduces the unpaid amount by the amount allocated to the obligation. It does not close the obligation while a positive amount remains.

An obligation becomes overdue according to its due date and lifecycle rules; a partial payment does not make the unpaid amount overdue before its due date. After due date, only the remaining unpaid amount is overdue.

### Allocation transparency

The operation/result should expose enough allocation information for the UI to explain the payment, including the allocated amount by obligation/statement/installment and any remaining amount. Do not invent allocation rows if the current domain cannot authoritatively support them.

## 4. Proposed relationship to ADR-036 — Balance Reconciliation

When the actual observed bank balance differs from Wafferly's derived credit-card liability, prompt the user to classify the discrepancy. Candidate reasons for the UI (to be approved against ADR-036's final reason enum) include:

- Previously unrecorded purchase/charge
- Bank fee
- Interest charge
- Other known reason
- Unknown reason

An unknown discrepancy follows the Balance Reconciliation path. It must not be automatically classified as an expense. A known fee or interest amount should instead be recorded as the corresponding real financial event where feasible; after recording, the derived liability and the observed balance should be compared again.

Do not use reconciliation to conceal a known missing transaction, and do not edit the derived account balance directly. The exact accounting treatment still depends on the reconciliation accounting contract; ADR-036 itself leaves some planner/journal semantics unresolved.

If a fee or interest charge is genuinely recurring, offer to create a recurring item only after the user explicitly confirms it. Do not auto-create recurrence from a single observed charge.

## 5. Relationship to ADR-050 — Statement Lifecycle and Due-Date Generation

- The closed statement remains a historical record of what was due for its period.
- Payments change the unpaid amount associated with a statement; they do not rewrite the original statement total.
- A remaining amount stays outstanding before the due date.
- After the due date, the remaining unpaid amount follows the approved overdue lifecycle.
- Future statements are generated by the statement lifecycle rules and include the remaining eligible liability according to approved allocation/statement rules. Do not create a new “reserved future statement balance” unless a separate explicit decision introduces that concept.

The canonical ADR-050 file must be identified before patching because project snapshots contain multiple candidate files.

## 6. Agreed working policy: intended payment exceeds Wafferly outstanding

**Agreed direction: Option A — strict rejection for a new/intended payment, with a guided recovery path.** This records the product direction agreed in discussion. The canonical ADR has not yet been patched in the repository, so this draft is not evidence of a merged or release-approved decision.

If the user enters an amount above current Wafferly liability, do not simply dismiss the entry or reset the screen. Keep the entered amount and show the excess difference `X`, with a clear explanation that the amount exceeds recorded liability. Offer guided next steps, such as:

- Record a missing purchase/charge.
- Record a verified bank fee or interest charge.
- Start Balance Reconciliation when the cause is unknown or cannot yet be classified.

After the user resolves the difference through the appropriate authorized financial operation, return to the same Pay Card screen with the previously entered payment amount preserved, and revalidate against the refreshed liability before execution. Do not automatically classify the difference as an expense.

Option B (an atomic combined adjustment + payment workflow) is deferred. It would require an explicit transactional workflow and accounting design; ADR-036 still leaves key reconciliation planner/journal semantics open, so it should not be assumed for the current implementation.

This decision applies to **new/intended payments**, not to reliable external evidence that a payment has already happened. Externally evidenced payments follow the path specified in ADR-051's “Intended payment vs. externally evidenced payment” subsection.

## 7. Tests to add or verify

1. Manual payment amount is independent of displayed current outstanding and statement due.
2. Known bank minimum is shown; unknown minimum is not fabricated.
3. Payment below known minimum warns but can be recorded.
4. Exact statement-due payment closes the statement's unpaid portion without rewriting statement total.
5. Partial payment leaves the correct remaining amount outstanding.
6. Remaining amount becomes overdue only after the due date.
7. Payment greater than statement due but not greater than current outstanding allocates to current eligible unbilled liability according to the approved allocation policy.
8. Historical closed statement snapshot is unchanged after payment.
9. A new/intended payment above current outstanding is rejected with a clear explanation; the entered amount is preserved while the user resolves missing liability, and is revalidated afterward.
10. A verified external SMS/OCR event for a completed payment above current outstanding is routed to matching/reconciliation and is not discarded as a rejected new payment; it must not silently create a credit balance.
11. Unknown discrepancy enters Balance Reconciliation and does not create an expense automatically.
12. Known fee/interest discrepancy can be recorded as the proper financial event and offered recurrence only with confirmation.
13. If the actual bank minimum is unknown, no below-minimum warning is shown; if it is known and the entered amount is lower, a warning is shown but does not block solely on that basis.
14. If unbilled liability cannot be identified and allocated authoritatively, V1 does not allocate excess into it or claim a breakdown the domain cannot support.
15. Payment allocation details shown in UI match the allocation result from the Financial Operation Engine.
16. Repeated submission or duplicate SMS/OCR evidence does not duplicate the same financial operation, using the project's established idempotency/deduplication mechanism where applicable.
17. A due date or scheduled reminder alone does not create a CreditCardPaymentOperation or reduce the derived liability.
18. A preconfigured recurring reminder prompts the user to confirm whether the payment actually occurred; only an affirmative confirmation of the payment event proceeds to the ordinary authorized payment-recording path.
19. Choosing “not paid yet” leaves the liability unchanged and allows the reminder to remain pending or be deferred.
20. A user-confirmed amount different from the suggested amount is revalidated against current authoritative liability; any excess follows the intended-payment recovery policy.
21. A verified external payment event and a user confirmation for the same payment are deduplicated so they cannot create duplicate financial effects.

## 8. Implementation gate

Before editing production code:

1. Identify the canonical ADR-073 and ADR-050 files in the actual working tree.
2. Read the actual `CreditCardPaymentScreen`, payment operation/service, statement-due calculation, statement lifecycle, and unbilled allocation code.
3. Confirm whether current outstanding is authoritative and whether unbilled charges can be selected and allocated independently from closed statement items.
4. Carry the agreed Option A from Section 6 into the identified canonical ADR and verify that the recovery path matches the current domain/accounting contract.
5. Confirm the external-evidence distinction is consistent with the canonical SMS/OCR ingestion and financial-operation policies.
6. Update ADRs first, then implement the selected behavior and add/run focused tests.

**This file is a proposal only. It does not modify canonical ADRs or production code.**


## 9. Pre-approved recurring reminders and lightweight confirmation

### Decision

A user's prior approval to receive or prepare recurring Credit Card payment actions authorizes Wafferly to schedule a reminder and present a lightweight confirmation request. It does **not** authorize Wafferly to create a payment transaction merely because a due date has arrived.

On the expected payment date, the Financial Action Center or notification may ask, for example: **“Did you pay EGP X?”** The user must explicitly confirm that the payment actually occurred before Wafferly records it as a completed payment. The confirmation action must clearly mean “I have paid this amount,” not merely “I approve the reminder” or “I intend to pay.”

- **User confirms payment occurred:** submit the normal `CreditCardPaymentOperation` through the authorized application/financial-engine path, applying the same liability validation, discrepancy handling, and idempotency controls as other user-confirmed payments.
- **User says payment has not occurred:** do not create a payment operation and do not reduce liability. Keep the action pending or let the user defer/reschedule the reminder.
- **User reports a different amount:** use the amount explicitly confirmed by the user and revalidate it against refreshed authoritative liability. If it exceeds recorded liability, follow Section 6's guided recovery path.
- **Reliable external evidence arrives:** process it through the existing evidence matching/deduplication path. If the same payment was already recorded after user confirmation, do not record it again.

The default product behavior is **scheduled reminder + one-tap confirmation**, not silent payment registration. A future silent-registration mode, if ever added, must be a separate advanced opt-in with explicit disclosure that Wafferly may record a payment based on the user's standing instruction without independently verifying that the bank received it. It is out of scope for this amendment and must not be inferred from ordinary recurring-reminder approval.

### Financial truth boundary

Time determines when to ask; it does not prove that money moved. A reminder or due Scheduled Action is derived workflow data only. Financial Truth is created only after an authorized, explicit user confirmation that the payment occurred, or after reliable external evidence is accepted through the appropriate ingestion path. Wafferly must not claim to have sent money to the bank unless a separate supported bank/payment integration actually performed that transfer.

## 10. Definition of completion: functional vs. financial release

Pay Card progress must be tracked at two distinct levels:

### A. Functionally complete

This status may be used when the payment UI and user flow are implemented; domain decisions and ADR changes are reviewed; Pay Card is exposed through the Financial Action Center's Executor without duplicating financial logic; contract/unit/integration tests for the intended behavior pass against the current interfaces; and no direct Hive/Drift persistence access has been introduced into UI or domain orchestration code.

This status does not claim atomic financial persistence has been proven.

### B. Financially approved for release

Do not mark Pay Card `Accepted` for financial release until the final storage implementation (targeting Drift) passes tests showing that:

- payment, required journal/ledger effects, and operation idempotency outcome are committed atomically;
- injected failures cannot leave partial financial effects;
- retrying the same operation does not duplicate the payment;
- duplicate SMS/OCR evidence and user confirmation for the same real-world payment cannot create duplicate effects;
- the derived card liability and source-asset balance remain consistent after successful execution and after rollback.

Until those gates pass, the feature may be labelled **Functionally Complete — Financial Release Pending**. Do not mark the ADR `Accepted` merely because the screen and happy-path tests work.
