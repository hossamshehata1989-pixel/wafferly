# Liabilities Domain

Status: APPROVED

Domain: Obligations

Version: V4

---

# Purpose

Liabilities represent obligations that already exist.

Liabilities answer:

What do I currently owe?

Liabilities are not future expectations.

Liabilities are current financial obligations.

---

# Core Rule

Liabilities

=

Current Obligations

Examples:

* Loan
* Installment
* Borrowed Money
* Temporary Debt
* Saving Circle Liability

---

# Liability Ownership

Liabilities belong to the Accounts Layer.

Liabilities affect:

* Net Worth
* Financial Position
* Outstanding Obligations

Liabilities are part of Financial Truth.

---

# Liabilities vs Commitments

Liabilities

=

Current Obligations

Commitments

=

Expected Future Events

---

# Examples

Liability:

Borrowed Money = 5000

The debt already exists.

---

Commitment:

Rent Next Month = 3000

The obligation does not exist yet.

Only the expectation exists.

---

# Liability Types

## Borrowed Money

Money borrowed from another party.

Creates a current obligation.

---

## Loan

Formal debt obligation.

May contain:

* Principal
* Interest
* Payment Schedule

---

## Installment

Outstanding installment obligation.

Represents remaining amount owed.

---

## Temporary Debt

Emergency debt mechanism.

Created only when:

Expense Amount

>

Total Available Liquidity

---

## Saving Circle Liability

Created only after payout is received.

Example:

Received Amount = 10000

Remaining Installments = 9000

Result:

Saving Circle Liability = 9000

---

# Temporary Debt Architecture

Purpose:

Allow expense recording when available liquidity is insufficient.

Preserve financial history.

Force future settlement.

Prevent abuse.

---

# Temporary Debt Rules

Only one Temporary Debt account exists.

Fixed ID:

temp_debt_account

Temporary Debt is a system account.

---

# Temporary Debt Creation Rule

Temporary Debt may be created only when:

Expense Amount

>

Total Available Liquidity

---

# Temporary Debt Decision Flow

Step 1

Review Liquidity Accounts

---

Step 2

Review Saving Money

---

Step 3

Review Reserved Money

User may:

* Edit Reservation
* Reduce Reservation
* Delete Reservation

---

Step 4

Create Temporary Debt

---

# Temporary Debt Settlement

Settlement is not:

* Expense
* Income
* Transfer

Settlement is a dedicated financial operation.

Transaction Type:

Debt Settlement

---

# Partial Settlement

Supported.

Example:

Outstanding Debt = 5000

Settlement = 2000

Remaining Debt = 3000

---

# Full Settlement

Example:

Outstanding Debt = 5000

Settlement = 5000

Remaining Debt = 0

Debt Cycle becomes inactive.

---

# Debt Cycle Rule

When Outstanding Debt = 0

Deactivate Debt Cycle.

Archive Debt Configuration.

Keep System Account.

Reactivate when needed.

---

# Saving Circle

Official Name:

Saving Circle

ROSCA is internal terminology only.

---

# Saving Circle States

## Waiting

User contributes.

No payout received.

No liability exists.

---

## Received

Payout received.

Remaining installments still exist.

Saving Circle Liability is created.

---

## Completed

Remaining Liability = 0

Saving Circle completed.

May be archived.

---

# Relationship With Net Worth

Liabilities affect Net Worth.

Examples:

* Borrowed Money
* Loans
* Installments
* Temporary Debt
* Saving Circle Liability

All reduce financial position.

---

# Relationship With Forecasting

Forecasting reads Liabilities directly.

Forecasting must never read:

* Liability Projections
* Derived Debt Metrics

as source of truth.

---

# Relationship With AI

AI reads Liabilities directly.

AI may:

* Explain debt impact
* Analyze risk
* Suggest alternatives

AI may never settle debt automatically.

---

# Summary

Liabilities represent obligations that already exist.

Liabilities are Financial Truth.

Liabilities affect Net Worth.

Liabilities are not Commitments.

Status:

APPROVED
