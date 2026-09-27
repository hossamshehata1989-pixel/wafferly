# ADR-069 — No-Double-Counting Implementation Gate

The end-to-end boundary now proves the following sequence without introducing a second financial ledger:

```text
Posted Charge
    ↓
ADR-070 Financing Conversion
    ↓
Contract + Installments
    ↓
ADR-069 Statement Contribution
    ↓
Statement Projection
```

## Before Statement Close

A conversion effective on or before statement close suppresses the full originating charge from the statement projection. Only the statement-bound installment contribution is emitted.

Therefore:

```text
10,000 original charge
+
3,333.33 installment

≠
13,333.33 statement balance
```

The statement projection contains only the eligible installment contribution for that financing representation.

## After Statement Close

A conversion effective after the close boundary does not rewrite the historical statement period. The original charge remains represented in that period.

## Boundary

`CreditCardStatementProjection` is a read-only projection. It does not mutate Account, Transaction, Ledger, Balance, or Financial Engine state.
