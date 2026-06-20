# Allocations Domain

Status: APPROVED

Domain: Planning

Version: V4

---

# Purpose

Allocations are the foundation of the Planning Layer.

Allocations represent intent.

Allocations do not represent ownership.

Allocations do not represent balances.

Allocations explain how existing money should be planned.

---

# Domain Position

Architecture:

Accounts
↓
Allocations
↓
Goals

Accounts
↓
Allocations
↓
Budgets

Allocations connect financial truth to planning.

---

# Core Rule

Allocations represent planning intent.

Allocations never own money.

Accounts always own money.

---

# Allocation Ownership Rule

Creating an Allocation:

* Does not create money
* Does not move money
* Does not change account balances

Deleting an Allocation:

* Does not delete money
* Does not restore money
* Does not modify Ledger

Allocations only affect planning state.

---

# Allocation Types

Current Allocation Types:

## Goal Allocation

Purpose:

Reserve money for a Goal.

---

## Saving Allocation

Purpose:

Reserve money for Virtual Saving.

Saving Allocation belongs to the Planning Layer.

Saving Allocation is not a Saving Account.

---

## Budget Surplus Allocation

Purpose:

Reserve unused budget money.

Created explicitly by the user.

Never automatic.

---

# Source Accounts

Allocations reference existing Accounts.

Examples:

* Cash
* Wallet
* Bank
* Real Saving Accounts

Allocations may never reference money that does not exist.

---

# Allocation Validation Rule

Allocation Amount

must not exceed

Available Money

Example:

Cash = 1000

Allocation = 5000

Invalid

---

# Allocation Effects

Allocations may affect:

* Reserved Money
* Available Balance
* Goal Funding State
* Budget Funding State
* Forecasting

Allocations never affect:

* Ledger Balance
* Net Worth
* Account Ownership

directly.

---

# Allocations And Goals

Architecture:

Account
↓
Allocation
↓
Goal

Goals explain purpose.

Allocations provide funding intent.

Accounts own money.

---

# Allocations And Budgets

Architecture:

Account
↓
Allocation
↓
Budget

Budgets monitor spending.

Allocations reserve money for spending plans.

---

# Allocations And Virtual Saving

Architecture:

Account
↓
Saving Allocation
↓
Virtual Saving

Virtual Saving is a projection.

Virtual Saving owns no money.

---

# Allocations And Reserved Money

Reserved Money

=

Sum(Active Allocations)

Reserved Money is derived.

Allocations are source data.

---

# Allocations And Available Balance

Available Balance

=

## Account Balance

Active Allocations

Available Balance is derived.

Allocations are source data.

---

# Allocation Activities

Examples:

* Created
* Updated
* Reduced
* Released
* Transferred

Activities represent history.

Activities are not current state.

---

# Relationship With Forecasting

Forecasting reads Allocations directly.

Forecasting must never use:

* Reserved Money
* Available Balance

as source of truth.

---

# Relationship With AI

AI reads Allocations directly.

AI uses Allocations as planning truth.

AI must never use derived projections as planning truth.

---

# Summary

Accounts own money.

Allocations represent planning intent.

Allocations never own money.

Allocations are the Planning Source Of Truth.

Status:

APPROVED
