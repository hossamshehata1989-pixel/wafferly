# Recurring Domain

Status: APPROVED

Domain: Scheduling

Version: V4

---

# Purpose

Recurring Engine is scheduling infrastructure.

Recurring Engine does not represent a financial domain.

Recurring Engine exists to schedule future events.

---

# Core Rule

Recurring Engine

=

Scheduling Layer

Recurring Engine is not:

* Bills Engine
* Subscription Engine
* Loan Engine
* Installment Engine
* Rent Engine

Recurring Engine is used by those domains.

---

# Responsibilities

Recurring Engine is responsible for:

* Frequency
* Next Occurrence
* Reminder
* Auto Create
* Pause
* Resume
* Skip
* End Date

Recurring Engine owns scheduling.

Recurring Engine does not own money.

---

# Architecture Position

Recurring Engine
↓
Commitment Layer

Examples:

Recurring Rule
↓
Rent Commitment

Recurring Rule
↓
Salary Commitment

Recurring Rule
↓
Subscription Commitment

Recurring Rule
↓
Loan Payment Commitment

---

# Supported Domains

Recurring Engine may be used by:

* Bills
* Subscriptions
* Rent
* Salary
* Loans
* Installments
* Future Financial Commitments

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

At due date:

* Notify user
* Await confirmation
* Create transaction after confirmation

---

# Frequency Support

Supported frequencies:

* Daily
* Weekly
* Monthly
* Quarterly
* Yearly

Custom frequencies may be added later.

---

# Next Occurrence

Recurring Engine owns:

Next Occurrence Calculation

The calculation must be deterministic.

The next date must always be derived from rule configuration.

---

# Skip Occurrence

Supported.

Example:

Netflix

May → Skip

June → Continue Normally

Skipping one occurrence must not affect future occurrences.

---

# Pause / Resume

Supported.

States:

* Active
* Paused

When resumed:

Next Occurrence is recalculated.

---

# End Date Support

Supported options:

## No End Date

Rule continues indefinitely.

---

## Fixed End Date

Example:

End After

31 Dec 2028

---

## Fixed Occurrence Count

Example:

24 Monthly Payments

Then stop automatically.

---

# Variable Amount Support

Each recurring rule may contain:

Default Amount

Example:

Electricity Bill

Default Amount = 300

---

# Occurrence Options

At execution time:

User may choose:

## Confirm

Use default amount.

---

## Edit This Occurrence

Modify current occurrence only.

Future occurrences unchanged.

---

## Update Default Amount

Modify recurring template.

Future occurrences updated.

---

# Reservation Support

Recurring Rules may generate reservations.

Examples:

* Rent
* School Fees
* Installments
* Loan Payments

---

# Reservation Timing

Supported:

* No Reservation
* On Due Date
* 3 Days Before
* 7 Days Before
* 14 Days Before
* Custom

---

# Insufficient Funds Policy

When available liquidity is insufficient:

Example:

Rent = 3000

Available = 1000

Result:

* Transaction not created
* Reminder displayed

---

# Temporary Debt Rule

Recurring Engine must never create Temporary Debt automatically.

Temporary Debt has its own lifecycle and user-controlled workflow.

---

# Delete Rule

Deleting a Recurring Rule:

Deletes only the rule.

Must never delete:

* Historical Transactions
* Activities
* Reports
* Analytics

---

# Activities

Examples:

* Created
* Triggered
* Paused
* Resumed
* Skipped
* Modified
* Deleted
* Completed

Activities represent history.

Activities are not current state.

---

# Relationship With Commitments

Recurring Engine provides scheduling.

Commitments provide financial meaning.

Architecture:

Recurring Engine
↓
Commitment Layer

---

# Relationship With Forecasting

Forecasting reads:

* Recurring Rules
* Commitments

directly.

Forecasting must never use:

Next Occurrence projections

as source of truth.

---

# Relationship With AI

AI may:

* Explain schedules
* Recommend changes
* Predict future impact

AI must never modify recurring rules automatically.

---

# Source Of Truth

Recurring Engine owns:

Scheduling Rules

Recurring Engine does not own:

* Money
* Balances
* Net Worth

Financial truth remains:

Accounts
↓
Transactions
↓
Ledger

Only

---

# Summary

Recurring Engine is scheduling infrastructure.

Recurring Engine owns timing.

Recurring Engine does not own money.

Recurring Engine powers Commitments.

Status:

APPROVED
