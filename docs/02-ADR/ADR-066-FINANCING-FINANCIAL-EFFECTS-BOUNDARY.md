# ADR-066 — Financing Financial Effects Boundary

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-041, ADR-042, ADR-047, ADR-051, ADR-052, ADR-059, ADR-060, ADR-063

## Context
Financing Domain operations may describe contractual changes, but actual financial effects belong to the Financial Operation Engine. Financing services must not become hidden financial writers.

## Decision
Establish:
```text
Financing Domain
  ↓
Policy / Calculator
  ↓
Domain Transition / Financial Intent
  ↓
FinancialOperationEngine
  ↓
Account / Transaction / Ledger
```

## Financing Domain Owns
- contract terms;
- schedule terms;
- installment state;
- interest calculation;
- fee policy;
- payment allocation;
- replacement/restructuring policy;
- contractual lifecycle.

## Financial Engine Owns
- actual money movement;
- Account mutation;
- Transaction creation;
- Ledger mutation;
- financial balance mutation;
- financial idempotency;
- financial atomicity.

## Forbidden Direct Writes
Financing services must not directly call financial mutation APIs or write financial Hive boxes outside approved persistence boundaries for non-financial domain state.

## No Shadow Balance
Financing must not maintain an independent monetary balance competing with Account/Transaction financial truth.

## Integration
Financing operations that cause actual money movement produce Financial Intents/Operations, including:
```text
Credit Card Charge
Credit Card Payment
Settlement
Refund
Reversal
Fee Financial Effect
```

## Tests
Architecture tests detect direct financial writers outside approved boundaries. Integration tests prove:
```text
Financing Intent
  ↓
Financial Engine
  ↓
Effective Financial Truth
```
