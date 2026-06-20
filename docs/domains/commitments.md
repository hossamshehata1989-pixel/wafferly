# Commitments Domain

Status: APPROVED

Domain: Commitments

Version: V4

---

# Purpose

Commitments represent expected future financial events.

Commitments answer:

What is expected to happen in the future?

Commitments are not debts.

Commitments are not liabilities.

Commitments represent future expectations.

---

# Core Rule

Commitments

=

Expected Future Financial Events

Examples:

* Bills
* Subscriptions
* Rent
* Salary
* Loan Payments
* Installment Payments

---

# Commitments vs Liabilities

Liabilities

=

Current Obligations

Examples:

* Loan Balance
* Borrowed Money
* Temporary Debt

---

Commitments

=

Expected Future Events

Examples:

* Next Rent Payment
* Next Salary
* Next Subscription Renewal

---

# Domain Position

Architecture:

Recurring Engine
↓
Commitments
↓
Forecasting

Commitments are generated and managed through Recurring Rules.

---

# Commitment Types

## Bills

Examples:

* Electricity
* Water
* Internet
* Mobile

---

## Subscriptions

Examples:

* Netflix
* Spotify
* ChatGPT
* YouTube Premium

---

## Rent

Examples:

* Apartment Rent
* Office Rent

---

## Salary

Examples:

* Monthly Salary
* Side Income
* Pension

---

## Loan Payments

Expected future loan installments.

The liability already exists.

The payment schedule belongs here.

---

## Installment Payments

Expected future installment payments.

The remaining debt belongs to Liabilities.

The payment schedule belongs to Commitments.

---

# Commitment Ownership Rule

Commitments never own money.

Commitments never own balances.

Commitments never affect Net Worth directly.

Commitments represent future expectations only.

---

# Relationship With Recurring Engine

Recurring Engine is scheduling infrastructure.

Recurring Engine controls:

* Frequency
* Reminder
* Auto Create
* Pause
* Resume
* Skip
* End Date

Commitments use Recurring Engine.

---

# Execution Modes

## Reminder Only

At due date:

* Notify user
* No transaction created

---

## Auto Create

At due date:

* Create transaction automatically

---

## Hybrid

Notify user first.

Create transaction after confirmation.

---

# Insufficient Funds Policy

When available liquidity is insufficient:

Example:

Rent = 3000

Available = 1000

Result:

* Transaction not created
* Reminder shown

Temporary Debt must never be created automatically.

---

# Reservation Support

Commitments may create reservations.

Examples:

* Rent
* Loan Payment
* School Fees
* Subscription

---

# Reservation Timing

Supported options:

* No Reservation
* On Due Date
* 3 Days Before
* 7 Days Before
* 14 Days Before
* Custom

---

# Variable Amount Support

Each Commitment may have:

Default Amount

Example:

Electricity Bill

Default = 300

---

Supported Actions:

* Confirm
* Edit This Occurrence
* Update Default Amount

---

# Skip Occurrence

Supported.

Example:

Netflix

May → Skip

June → Continue Normally

---

# Pause / Resume

Supported.

States:

* Active
* Paused

Resume recalculates Next Occurrence.

---

# End Date

Supported:

* No End Date
* Fixed End Date
* Number Of Occurrences

---

# Delete Rule

Deleting a Commitment:

Deletes only the rule.

Never deletes:

* Historical Transactions
* Reports
* Analytics

---

# Commitment Activities

Examples:

* Created
* Triggered
* Skipped
* Paused
* Resumed
* Modified
* Completed
* Deleted

Activities represent history only.

---

# Relationship With Forecasting

Commitments are one of the primary inputs to Forecasting.

Forecasting reads:

* Commitments
* Liabilities
* Allocations
* Accounts

directly.

---

# Relationship With AI

AI may:

* Analyze commitments
* Predict cash flow impact
* Recommend changes

AI must never modify commitments automatically.

---

# Source Of Truth

Commitments do not own money.

Commitments do not own balances.

Financial Truth remains:

Accounts
↓
Transactions
↓
Ledger

Only

---

# Summary

Commitments represent expected future financial events.

Commitments are not liabilities.

Commitments do not own money.

Commitments are primary inputs for Forecasting.

Status:

APPROVED
