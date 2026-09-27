# ADR-062 — Financing Overpayment & Excess Payment

## Status
Accepted

## Decision
The allocation calculator may return a non-zero `unallocatedAmount` when a payment exceeds all eligible financing obligations.

For the strict MVP payment boundary, a financial payment operation must reject any non-zero unallocated amount. It must not silently create a credit balance, future principal reduction, refund, or other shadow financial state.

`unallocatedAmount` is a calculation result only; it is not persisted as a second source of truth.
