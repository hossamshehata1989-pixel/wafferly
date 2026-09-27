# ADR-065 — Financing Waiver & Forgiveness Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-054, ADR-057, ADR-058, ADR-059, ADR-060, ADR-064

## Context
A financing obligation may be waived or forgiven. Waiver must not be implemented as deletion or silent mutation of the historical obligation.

## Decision
Introduce explicit waiver/forgiveness events.

```text
Original Obligation
  ↓
Waiver Event
  ↓
Remaining Effective Obligation
```

## Eligible Components
The policy explicitly identifies what is waived:
```text
Fee
Late Fee
Interest
Principal
Other contractual component
```

## Historical Preservation
The original amount remains historically visible. The waiver creates a new effective event that changes the outstanding obligation.

## No Silent Deletion
Never:
```text
delete fee
set historical fee = 0
rewrite payment
rewrite statement
```

## Financial Effect
Waiver is not automatically a cash transaction. If a financial adjustment is required, it passes through the Financial Operation Engine.

## Authorization
The domain may carry explicit actor/reason/reason-code where product policy requires it. Exact authorization mechanism is outside this ADR.

## Idempotency
Repeated waiver requests for the same stable obligation/event must not produce duplicate waivers.

## Required Tests
- fee waiver;
- late-fee waiver;
- interest waiver;
- principal waiver;
- historical preservation;
- settlement after waiver;
- duplicate waiver prevention;
- cancellation/replacement interaction.
