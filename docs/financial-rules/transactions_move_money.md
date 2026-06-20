# Transactions Move Money

Status: APPROVED

Category: Financial Rule

Version: V4

---

# Purpose

Define how real money movement is represented inside Wafferly.

---

# Rule

Every real financial movement must be represented by a Transaction.

Transactions are the only mechanism that moves money between Accounts.

---

# Examples

Transactions include:

* Income
* Expense
* Transfer
* Borrow
* Lend
* Debt Settlement
* Investment Buy
* Investment Sell

---

# Record Reality Rule

Transactions must represent what actually happened.

Examples:

Correct:

Salary
→ Bank Account

Single Income Transaction

---

Correct:

Cash
→ Emergency Fund

Transfer Transaction

---

Incorrect:

Salary
→ Cash
→ Bank

when the money was deposited directly into the Bank Account.

Reason:

Artificial transactions must never be created.

---

# Transaction Ownership

Transactions do not own money.

Transactions move money between Accounts.

Accounts remain the owners of money.

---

# Relationship With Ledger

Architecture:

Transactions
↓
Ledger
↓
Balances

Balances must be derived from Ledger activity.

---

# Relationship With Planning

Transactions move money.

Allocations reserve money.

These are separate concepts.

Example:

Cash = 10000

Goal Allocation = 3000

No Transaction occurred.

Money did not move.

---

# Relationship With Forecasting

Forecasting may predict future transactions.

Forecasting must never create transactions automatically.

Only actual financial events create transactions.

---

# Relationship With AI

AI may recommend transactions.

AI must never create transactions without user confirmation.

---

# Summary

Transactions represent real financial movement.

Record what actually happened.

Never create artificial transactions.

Accounts own money.

Transactions move money.

Status:

APPROVED
