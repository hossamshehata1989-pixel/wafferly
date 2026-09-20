# Pre-Credit-Card Implementation Checklist

**Status:** Gate Checklist
**Rule:** Do not connect the real Credit Card financial backend/UI actions until this gate is closed or an explicit exception is recorded.

## A. Financial Engine Foundation

- [ ] Correction operation has a real planner and execution path.
- [ ] Invalidation/deletion semantics have a real planner and execution path.
- [ ] Account balance adjustment has a real Financial Engine operation.
- [ ] Financial Engine remains the only active financial writer.
- [ ] Legacy transaction writers are removed from active feature flows.
- [ ] Financial Unit of Work provides real all-or-nothing behavior.
- [ ] Idempotency storage is durable where retries can cross process boundaries.
- [ ] `Money` is used internally by financial-domain amounts and arithmetic.
- [ ] Persistence/legacy `double` conversions stay at explicit boundaries.

## B. Scheduled Money

- [ ] Active-only commitment filter enforced in the production action provider. *(Implemented; production-provider test target updated, verification pending.)*
- [ ] Completed one-time occurrences never reappear. *(Implemented; regression existed, verification pending after current changeset.)*
- [ ] Missed recurring occurrence policy is implemented and tested. *(Stack policy implemented; verification pending after current changeset.)*
- [ ] Occurrence lifecycle includes explicit failure/retry semantics.
- [ ] Occurrence completion and rule advancement are idempotent. *(Base behavior implemented; catch-up advancement added, verification pending.)*
- [ ] Scheduled transaction ↔ occurrence/commitment linkage exists.
- [ ] Scheduled execution is observationally atomic with scheduling-state transition.
- [ ] Financial Action Center projection groups occurrences by actionable commitment without changing domain occurrence identity. *(Implemented; verification pending.)*
- [ ] Grouped actions support explicit occurrence selection before execution. *(Implemented; verification pending.)*
- [ ] Monthly end-of-month policy is explicit and tested.
- [ ] Production provider has direct unit/integration coverage. *(Test now targets the production provider; verification pending next `flutter test`.)*
- [ ] Duplicate `CommitmentActionProvider` behavior is consolidated. *(Production implementation remains authoritative; test target updated, verification pending.)*

## C. Planning Integration

- [ ] Financial Engine and Planning Engine use the same production allocation repository dependency.
- [ ] Goal-transfer/allocation release flows are verified end-to-end after wiring change.

## D. Credit Card Domain Contract

- [ ] Liability Account remains the balance source of truth.
- [ ] Credit Card Profile model is defined.
- [ ] Credit limit is represented as `Money`.
- [ ] Available credit is derived, not duplicated as balance truth.
- [ ] Credit exposure rules are explicit.
- [ ] Dedicated `CreditCardChargeOperation` (or equivalent) is defined.
- [ ] Card purchase does not use cash liquidity guard semantics.
- [ ] Card payment is a liability settlement operation.
- [ ] Payment source metadata comes from the real source account/instrument.
- [ ] Statement-cycle ownership is defined.
- [ ] Minimum-payment semantics are defined.
- [ ] Refund/reversal semantics are defined.
- [ ] Installment conversion has its own contract and is not hidden inside generic Commitment logic.
- [ ] Card-related scheduled operations use stable occurrence identity.

## E. Tests

- [ ] Card purchase success.
- [ ] Card purchase exceeds available credit.
- [ ] Card purchase with exact credit limit.
- [ ] Card payment reduces liability and source asset correctly.
- [ ] Card payment idempotency.
- [ ] Refund/reversal behavior.
- [ ] Statement-period inclusion boundaries.
- [ ] Due-date calculation.
- [ ] Partial payment behavior.
- [ ] Installment-contract creation and payment schedule behavior.
- [ ] Restart/retry safety for scheduled card operations.

## F. UI Wiring Rule

Until sections A–E are closed:

```text
CreditCardsScreen
   = presentation / prototype only

No direct financial write
No direct Hive transaction mutation
No fake balance synchronization
```

Once the foundation is closed, the Credit Card UI may call the application/domain entry point and receive `OperationResult` rather than manipulating financial state directly.
