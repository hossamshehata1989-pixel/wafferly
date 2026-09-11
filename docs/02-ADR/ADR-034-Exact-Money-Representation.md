# ADR-034 --- Exact Money Representation

-   **Status:** Accepted
-   **Date:** 2026-09-11
-   **Decision Type:** Financial Data Representation
-   **Related Domains:** Financial Engine, Planning, Accounts, Ledger

## 1. Context

Wafferly historically represented internal financial amounts primarily
as `double`.

Binary floating-point representation is not appropriate as the
authoritative representation for exact monetary calculations because
arithmetic can introduce precision and rounding artifacts.

The application also contains persistence and legacy boundaries that
currently use `double`.

A single representation policy is therefore required so the domain can
use exact monetary arithmetic without requiring an immediate rewrite of
every persistence boundary.

## 2. Decision

Wafferly adopts `Money` backed by `Decimal` as the authoritative
internal representation of monetary values.

The `Money` value object is the domain-level representation for
financial amounts.

The internal financial model must not use `double` as the authoritative
representation for monetary calculations.

## 3. Representation Policy

### Domain / Business Logic

Financial calculations use:

``` text
Money
  ↓
Decimal
```

This applies to financial operation amounts, transaction amounts,
planning operation amounts, allocations, reservations, available-balance
calculations, constraints, and balance-related domain calculations.

### Persistence / Legacy Boundaries

`double` may remain temporarily at persistence or legacy integration
boundaries where existing schemas/adapters require it.

Conversion happens only at the boundary:

``` text
Domain Money
    ↓
Persistence / Legacy Adapter
    ↓
double
```

and on read:

``` text
double
    ↓
Persistence / Legacy Adapter
    ↓
Money
```

The use of `double` at such a boundary does not make it the domain
representation.

## 4. Conversion Rules

Conversions must be explicit.

Examples:

``` dart
Money.fromDouble(value)
```

and:

``` dart
money.toDouble()
```

Boundary conversions must not leak into domain calculations.

A value must not be converted to `double` merely to perform arithmetic
that can be performed with `Money`.

## 5. Money Invariants

`Money` must:

-   represent exact decimal monetary values;
-   reject non-finite `double` input at conversion boundaries;
-   support exact addition and subtraction;
-   support exact comparison;
-   preserve sign;
-   provide a canonical zero value;
-   avoid hidden floating-point arithmetic inside the domain layer;
-   behave as an immutable value object.

Equality is based on the underlying exact decimal value.

## 6. Architectural Consequences

The migration establishes a clear boundary between exact financial
domain representation and legacy/infrastructure representation.

The Financial Engine and Planning Engine operate on `Money` internally
while infrastructure adapters may continue to serialize/deserialize
through `double` until their storage contracts are migrated.

No UI layer may bypass the domain representation by performing financial
calculations directly with `double`.

The established financial execution flow remains:

``` text
UI
 ↓
Controller / ViewModel
 ↓
Service / Use Case
 ↓
Financial Operation Execution Engine
 ↓
Transaction / Ledger
```

## 7. Persistence Compatibility

Existing Hive adapters and legacy persistence models may continue to
store `double` where their established schema requires it.

The adapter is responsible for converting between the stored
representation and `Money`.

This keeps the migration backward-compatible while allowing the
financial domain to become exact.

A future persistence migration to an exact decimal-compatible storage
representation is a separate decision and is not required by this ADR.

## 8. Migration Strategy

The migration is incremental:

1.  Introduce the `Money` value object.
2.  Migrate financial domain models and calculations to `Money`.
3.  Update guards, constraints, projections, allocations, and financial
    operations to use `Money`.
4.  Keep legacy `double` fields only where required by persistence or
    external contracts.
5.  Convert explicitly at those boundaries.
6.  Add regression tests for exact arithmetic and financial behavior.
7.  Remove remaining internal monetary `double` usage as individual
    boundaries become migratable.

The migration must not alter the financial meaning of existing amounts.

## 9. Rejected Alternatives

### Continue using `double` everywhere

Rejected because it leaves exact monetary calculations dependent on
binary floating-point behavior.

### Convert the entire persistence layer immediately

Rejected because it unnecessarily couples the domain migration to a
storage-schema migration and increases migration risk.

### Use integer minor units everywhere

Not adopted as the current Wafferly representation because the domain is
being migrated around `Decimal` through the `Money` value object.

A future change to the monetary representation requires a separate ADR.

### Allow mixed `Money` and `double` arithmetic in the domain

Rejected because it weakens the boundary and makes precision guarantees
dependent on caller discipline.

## 10. Testing Requirements

Tests cover:

-   exact addition and subtraction;
-   comparison;
-   zero and negative values;
-   conversion at legacy boundaries;
-   financial operation behavior;
-   planning calculations;
-   available-balance calculations;
-   regression of existing financial-engine scenarios;
-   serialization/deserialization compatibility;
-   the `Money` value object itself.

## 11. Integrity

Money conversion must not silently round or mutate a financial value.

Where a legacy boundary requires `double`, conversion behavior must
remain deterministic and covered by tests.

Financial integrity checks remain responsible for detecting invalid
financial state; `Money` does not replace existing balance, transaction,
ledger, or idempotency invariants.

## 12. Status

**Accepted.**
