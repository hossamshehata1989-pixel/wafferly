# Phase 3 — Obligations & Scheduling

Status: COMPLETED

Version: V4

---

# Goal

Introduce future obligations and scheduling without mixing them with financial truth.

Separate:

What I Owe

from

What May Happen

---

# Domains

Completed:

- Liabilities
- Commitments
- Recurring Engine

---

# Liabilities Architecture

Liabilities

=

Current Obligations

Examples:

- Loan
- Installment
- Borrowed Money
- Temporary Debt
- Saving Circle Liability

---

# Liability Rule

Liabilities affect:

- Net Worth
- Financial Position
- Outstanding Obligations

Liabilities are Financial Truth.

---

# Temporary Debt

Implemented as a dedicated liability type.

Purpose:

Allow recording expenses when liquidity is insufficient.

---

# Temporary Debt Rules

- System Account
- Single Instance
- Dedicated Settlement Flow
- Supports Partial Settlement
- Supports Full Settlement

---

# Saving Circle

Implemented as a Liability Lifecycle.

States:

- Waiting
- Received
- Completed

Liability created only after payout is received.

---

# Commitments Architecture

Commitments

=

Expected Future Financial Events

Examples:

- Bills
- Subscriptions
- Rent
- Salary
- Loan Payments
- Installment Payments

---

# Commitments Rule

Commitments:

- Do not own money
- Do not affect Net Worth directly
- Represent future expectations

---

# Liabilities vs Commitments

Liabilities

=

Current Obligations

Commitments

=

Future Expectations

---

# Recurring Engine

Recurring Engine

=

Scheduling Infrastructure

Not:

- Bills Engine
- Subscription Engine
- Loan Engine

---

# Recurring Responsibilities

- Frequency
- Next Occurrence
- Reminder
- Auto Create
- Pause
- Resume
- Skip
- End Date

---

# Execution Modes

Supported:

- Reminder Only
- Auto Create
- Hybrid

---

# Reservation Support

Recurring Rules may create reservations.

Examples:

- Rent
- School Fees
- Loan Payments
- Installments

---

# Variable Amount Support

Supported:

- Confirm
- Edit This Occurrence
- Update Default Amount

---

# Skip / Pause / Resume

Implemented.

---

# End Date Policies

Supported:

- No End Date
- Fixed End Date
- Fixed Occurrence Count

---

# Core Rules Established

Liabilities are Financial Truth.

Commitments are Future Expectations.

Recurring owns scheduling.

Commitments own meaning.

Temporary Debt is never created automatically.

---

# Outcome

Obligations Layer completed.

Scheduling Layer completed.

Architecture:

Liabilities
↓
Current Obligations

Recurring
↓
Commitments

Status:

COMPLETED