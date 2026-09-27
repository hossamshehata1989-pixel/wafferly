# ADR-054 — Financing Payment Allocation Order

## Status
Accepted

## Decision
A financing payment is allocated within an eligible installment in this deterministic order:

1. Fees
2. Interest
3. Principal

The calculation is pure and receives outstanding component snapshots. It does not mutate contracts, installments, accounts, transactions, ledgers, or financial-engine state.

Partial payments are allowed. The calculator returns the exact allocation and any remaining unallocated amount.

Payment execution remains a Financial Engine concern; this ADR defines only allocation semantics.
