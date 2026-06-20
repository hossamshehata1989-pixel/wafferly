# Funding Sources Projection

Status: APPROVED

Layer: Projection

Version: V4

---

# Purpose

Funding Sources represent the current funding state.

Funding Sources do not represent history.

Funding Sources do not represent ownership.

Funding Sources answer:

Where does this funding currently exist?

---

# Core Rule

Funding Sources

=

Current State

Activities

=

History

These concepts must remain independent.

---

# Source Of Truth

Funding Sources are derived from:

* Allocations
* Goal Activities
* Saving Transfer Activities
* Saving Withdrawal Activities

Funding Sources are not stored.

Funding Sources are calculated.

---

# Funding Types

## Reserved Funding

Money remains inside source accounts.

Examples:

Cash → Reserve 100

Wallet → Reserve 50

Result:

Reserved Funding

Cash ...... 100

Wallet .... 50

---

## Saving Funding

Money exists inside real Saving Accounts.

Examples:

Cash
↓
Emergency Fund
↓
100

Wallet
↓
Travel Savings
↓
50

Result:

Saving Funding

Emergency Fund .... 100

Travel Savings ..... 50

---

# Current State Rule

Funding Sources must represent current state only.

Example:

Reserve +100

Release -40

Result:

Current Reserved Funding = 60

---

Example:

Transfer To Saving +100

Withdraw From Saving -40

Result:

Current Saving Funding = 60

---

# Projection Rule

Funding Sources are projections.

Funding Sources are never source of truth.

Funding Sources are recalculated whenever source data changes.

---

# Relationship With Goals

Goals use Funding Sources to determine:

* Current Reserved Funding
* Current Saving Funding
* Total Funding

Goals do not own money.

Funding Sources describe where goal funding currently exists.

---

# Relationship With Goal Progress

Funding Sources are inputs.

Goal Progress is derived.

Architecture:

Funding Sources
↓
Goal Progress

---

# Relationship With Activities

Activities describe:

History

Funding Sources describe:

Current State

Activities must never be used directly as funding state.

---

# Relationship With Forecasting

Forecasting reads:

* Allocations
* Goals
* Commitments

directly.

Forecasting must never use Funding Sources as source of truth.

---

# Relationship With AI

AI may display Funding Sources.

AI must read underlying truth directly.

Funding Sources are presentation state.

---

# Summary

Funding Sources represent current funding state.

Funding Sources are projections.

Activities represent history.

Accounts own money.

Funding Sources never own money.

Status:

APPROVED
