Library
/
ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION.md
ADR-050-CREDIT-CAR…ATE-GENERATION.md



ADR-050 — Credit Card Statement Lifecycle & Due-Date Generation
Status: Proposed → Implementation
Date: 2026-09-27
Related: ADR-035 (Credit Card Domain), ADR-046 (Monthly / Periodic Due-Date Rollover Policy), ADR-048 (Credit Card Charge Operation), ADR-049 (Credit Limit Domain Guard)

1. Context
Credit Card Charge and Credit Limit validation are now separate domain concerns.

A Credit Card charge increases the Liability Account's authoritative financial position. The CreditCardProfile contains card-specific configuration and must not become a second balance source.

The remaining contract is to define how card transactions are grouped into statement cycles, when a statement closes, what balance belongs to that statement, and how its payment due date is derived.

The monthly rollover behavior required by scheduled-money contracts is already defined by ADR-046 and must be reused rather than reimplemented.

2. Decision
A Credit Card statement is a derived domain object representing a closed billing period and its financial amount at statement close.

The statement lifecycle is:

OPEN CYCLE
    ↓
STATEMENT CLOSE
    ↓
CLOSED STATEMENT
    ↓
DUE DATE
    ↓
PAYMENT / SETTLEMENT
Statement lifecycle state must not replace the Liability Account as the source of current financial position.

3. Statement Cycle
A Credit Card profile may define the recurring statement-cycle configuration required to determine:

cycle start;

cycle closing day;

due-date rule/offset.

A concrete statement cycle represents one deterministic period.

The cycle identity must be stable and unique so that the same period cannot produce duplicate statements.

4. Statement Closing
At statement close, the system determines the transactions belonging to the closed cycle using the effective financial transaction boundary.

The close operation must be deterministic and idempotent.

Closing a statement must not create a duplicate financial transaction merely because the close operation is retried.

Statement closing is a domain/scheduling transition, not a replacement for the underlying financial history.

5. Statement Balance
The statement balance is the amount attributable to the closed billing period at the statement closing boundary.

It is distinct from:

Outstanding Liability
Available Credit
Payment Amount
The current outstanding liability remains derived from authoritative financial state.

A statement must therefore not introduce a second authoritative account balance.

Conceptually:

Liability Account
    = current financial position

Statement
    = historical/periodic snapshot of the closed billing cycle
6. Due-Date Generation
The due date is derived from the statement closing event and the Credit Card's configured due-date rule.

Conceptually:

Statement Closing Date
        ↓
Due-Date Rule / Offset
        ↓
Payment Due Date
Monthly date calculation must reuse the explicit rollover semantics established by ADR-046.

In particular:

end-of-month anchors remain end-of-month;

invalid target days are explicitly clamped;

Dart DateTime overflow must not define financial scheduling semantics.

7. Statement Identity and Idempotency
Each statement cycle must have a stable identity.

A repeated close request for an already-created statement must not create a second statement for the same cycle.

The statement lifecycle must therefore support:

same cycle + retry
        ↓
same statement identity
        ↓
no duplicate statement
Where scheduled execution is involved, the existing scheduled execution atomicity/recovery contract applies.

8. Relationship to Financial Truth
The following ownership remains mandatory:

Concern	Owner
Current liability	Liability Account / effective financial transactions
Credit limit	CreditCardProfile
Current credit exposure	Derived from liability state
Available credit	Derived
Statement cycle configuration	CreditCardProfile / card-domain configuration
Statement lifecycle	Statement domain
Statement balance	Closed-period statement state
Actual purchase mutation	FinancialOperationEngine
Idempotency	Financial Engine / applicable lifecycle identity
A Statement must never become an independent replacement for the Liability Account.

9. Corrections and Invalidations
Statement calculations must use effective financial truth.

If a transaction is corrected or invalidated, the read-side semantics defined by ADR-042 determine whether the transaction remains effective.

Historical persisted transaction records are not deleted merely because their financial effect is superseded.

10. Due-Date Boundary Cases
The implementation must explicitly test:

ordinary monthly closing dates;

closing on the last day of a month;

February in a non-leap year;

February in a leap year;

year transition;

a due-date offset crossing a month/year boundary.

No financial due date may depend on implicit DateTime overflow.

11. Non-Goals
This ADR does not define:

minimum payment calculation;

interest calculation;

grace-period rules;

installment financing;

refund/reversal implementation;

Credit Card payment/settlement operation;

automatic payment execution;

interest accrual.

Those require separate domain decisions.

12. Required Tests
The implementation gate must cover:

statement cycle boundaries are deterministic;

transactions are assigned to the correct cycle;

statement close produces one statement;

repeated close is idempotent;

statement balance is derived from the correct effective transactions;

corrected/inactivated transactions follow effective-truth rules;

due date is generated from the configured closing-date rule;

EOM and leap-year behavior follows ADR-046;

year-boundary behavior is correct;

statement creation does not mutate the Liability Account independently;

retry/recovery does not create duplicate statements.

13. Architectural Invariants
The following invariants are mandatory:

Statement ≠ Liability Balance
Statement Balance ≠ Available Credit
Statement Close ≠ Payment
Payment ≠ Charge
And:

Credit Card Charge
        ↓
FinancialOperationEngine
        ↓
Financial Truth
        ↓
Statement Read/Close Boundary
The Credit Card feature must not directly mutate financial persistence.

14. Consequence
This establishes a deterministic statement lifecycle while preserving the existing architecture:

Liability Account remains financial truth.

CreditCardProfile remains card configuration.

FinancialOperationEngine remains the financial writer.

Effective Financial Truth remains the read boundary.

ADR-046 remains the monthly date-rollover contract.

Statement state becomes a separate periodic lifecycle rather than a duplicate balance system.

15. Implementation Boundary
Implementation should begin only after the existing Credit Card models and scheduling primitives are inspected.

No new balance source should be introduced solely to support statements.

The first implementation step is the statement-cycle domain model and its deterministic cycle resolver, followed by close/idempotency tests.