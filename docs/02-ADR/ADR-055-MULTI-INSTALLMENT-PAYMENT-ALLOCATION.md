# ADR-055 — Multi-Installment Financing Payment Allocation

## Status
Accepted

## Decision
A payment allocated across multiple eligible installments uses this deterministic order:

1. Overdue installments first.
2. Installments due on the allocation date second.
3. Future installments last.
4. Within each group, due date ascending.
5. If due dates are equal, stable `installmentId` ascending.

Within each installment, ADR-054 applies: Fees → Interest → Principal.

Only non-terminal installments with an outstanding obligation are eligible. Settled, cancelled, and superseded installments are excluded.

The calculator is pure and does not mutate financing or financial-truth persistence.
