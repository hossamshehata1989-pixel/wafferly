ADR-021
Financial Truth Boundary & Opening Balance Modeling

Status: Accepted

Date: 2026-08-03

Context

Wafferly is built around the concept of Financial Truth.

The Financial Engine is the only component responsible for producing and preserving Financial Truth.

Reference Data (Accounts, Members, Categories, Books, etc.) exists outside Financial Truth.

Until this ADR, the architectural boundary of the Financial Engine was not explicitly defined.

Additionally, Account Creation introduced an important question:

Should Opening Balance be stored as Account state, or represented as Financial Truth?

Decision
1. Financial Engine Scope

The Financial Engine is responsible only for operations that create or modify Financial Truth.

Reference Data lifecycle is explicitly outside the Engine.

2. Reference Data

The following entities SHALL NOT pass through the Financial Engine:

Members
Accounts (creation)
Categories
Books
Tags
Currencies
Account Rename
Member Avatar
Category Color

These operations are handled by their own Application Services and Repositories.

3. Financial Operations

The following operations SHALL always pass through the Financial Engine:

Expense
Income
Transfer
Correction
Delete
Opening Balance

Future operations:

Interest Accrual
Loan Payment
Credit Card Interest
Investment Events
Imported Bank Transactions
Reconciliation Adjustments
Opening Balance

Opening Balance is NOT an Account property.

Opening Balance is the first accepted Financial Truth of an Account.

Therefore:

Opening Balance SHALL always be represented as a Financial Operation.

Account Creation Workflow

Creating an Account is a Business Workflow, not a Financial Operation.

The Application Service orchestrates both responsibilities.

Create Account Workflow

        │
        ▼

AccountRepository.create()

        │
        ▼

Opening Balance ?

        │
        ▼

FinancialOperationEngine.execute()

        │
        ▼

Journal Entries

        │
        ▼

Financial Truth
Engine Responsibility

The Financial Engine:

owns Financial Behavior
validates Financial Invariants
creates Journal Entries
creates Financial Transactions

The Engine does NOT:

create Accounts
rename Accounts
manage Members
manage Categories
manage Books
Opening Balance = 0

The platform adopts a deterministic Genesis model.

Every Account SHALL generate exactly one Opening Balance Financial Operation, including zero-value opening balances.

Therefore:

Opening Balance = 0

↓

OpeningBalanceOperation

↓

Journal

↓

Transaction

↓

Genesis Financial Event

There are no special cases based on amount.

Architectural Principles

The platform follows these invariants:

Financial Truth

Financial Truth is immutable.

Source of Truth

Transactions are the only source of financial truth.

Balances are always derived.

Reference Data

Reference Data never modifies Financial Truth directly.

Engine Boundary

The Financial Engine is the only component allowed to create Financial Truth.

Application Services may orchestrate workflows but never bypass the Engine for financial events.

Deterministic History

Every Account has exactly one Genesis Financial Event.

No Account enters Financial Truth without an Opening Balance operation.

Consequences

Positive:

Single architectural rule.
No special cases.
Compatible with Audit.
Compatible with Reconciliation.
Compatible with Bank Import.
Compatible with Event Sourcing.
Compatible with Shared Books.
Compatible with Investments.
Compatible with Professional Accounting.

Trade-offs:

Zero opening balances create a Financial Operation.
Additional journal records exist for zero-value accounts.
Simpler long-term architecture outweighs the additional records.
Implementation Notes

The implementation introduces:

OpeningBalanceOperation
OpeningBalanceIntent
FinancialActionType.openingBalance
Planner support
Interpreter support
Domain Guard support
ChartOfAccounts Opening Balance Equity account
Genesis Journal creation
Genesis Transaction creation

Account creation no longer writes Transactions directly.

Financial Truth is produced exclusively through the Financial Engine.

Verification

This ADR has been verified through:

Independent Architecture Review (Claude)
Independent Architecture Review (DeepSeek)
Internal Architecture Review
Successful implementation
Successful application execution
Successful end-to-end workflow verification

Verified scenarios:

✅ Opening Balance = 1000
✅ Opening Balance = 0
✅ Genesis Transaction created
✅ Account balance derived correctly
✅ Financial Engine pipeline executed successfully