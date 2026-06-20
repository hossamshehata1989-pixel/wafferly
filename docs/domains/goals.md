# Goals Domain

Status: APPROVED

Domain: Planning

Version: V4

---

# Purpose

Goals represent financial purpose.

Goals answer a single question:

Why am I reserving or saving this money?

Examples:

* Emergency Fund
* Vacation
* Car Purchase
* House Down Payment
* Laptop Purchase

Goals explain purpose.

Goals never own money.

---

# Core Rule

Goal

=

Purpose Only

Goals do not own:

* Money
* Accounts
* Balances
* Net Worth

Goals store only:

* Metadata
* Lifecycle State
* Activities
* Configuration

---

# Goal Ownership Rule

Accounts own money.

Allocations reserve money.

Goals explain purpose.

Goals never own money.

---

# Goal Structure

A Goal may contain:

* Title
* Description
* Target Amount
* Target Date
* Funding Method
* Activities
* Lifecycle State

Goals must not contain:

* Balance
* Current Amount
* Saved Amount
* AccountId

---

# Goal Funding Architecture

Goal funding consists of three independent concepts:

## Goal Activities

History

## Funding Sources

Current State

## Goal Progress

Achievement Tracking

These concepts must remain independent.

---

# Goal Activities

Activities represent historical events.

Examples:

* Reserve
* Release
* Transfer To Saving
* Complete Goal
* Cancel Goal
* Archive Goal

Activities are immutable.

Activities are audit trail only.

Activities are not current state.

---

# Funding Sources

Funding Sources represent the current funding state of a Goal.

Funding Sources are projections.

Funding Sources are never stored.

Funding Sources are calculated.

---

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

# Funding Sources Rule

Funding Sources describe:

Current State

Activities describe:

History

Funding Sources are not Activities.

Activities are not Funding Sources.

---

# Goal Progress

Goal Progress is a Projection.

Formula:

Goal Progress

=

Total Reserved
+
Total Saved

Goal Progress must never be stored.

---

# Important Progress Rule

Money moving between valid funding states must not reduce progress.

Example:

Reserved = 5000

Transfer To Saving = 1000

Result:

Reserved = 4000

Saved = 1000

Progress = 5000

---

# Goal Funding Projection Service

GoalFundingProjectionService

is the single source for Goal Funding State.

Responsibilities:

* Reserved Sources
* Saving Sources
* Total Reserved
* Total Saved
* Total Progress

Returns:

GoalFundingProjection

{
reservedSources,
savingSources,
totalReserved,
totalSaved,
totalProgress
}

---

# Goal Lifecycle

Possible States:

* Active
* Completed
* Cancelled
* Archived

---

# Complete Goal

Complete Goal is not a financial operation.

Complete Goal is a lifecycle change.

After completion the user may choose:

* Keep Reserved
* Release Money
* Transfer To Saving

---

# Cancel Goal

Cancel Goal is not a financial operation.

The user chooses how to resolve existing funding.

---

# Transfer To Saving

Transfer To Saving is a real financial operation.

Transfer To Saving creates:

* Transfer Transactions
* Goal Activities
* Goal Allocation Releases

Transfer To Saving does not create:

* Saving Allocations

---

# Transfer To Saving Traceability Rule

Every funding source must preserve source traceability.

Example:

Wallet Reserved = 500

Cash Reserved = 300

Bank Reserved = 200

Destination:

Emergency Fund

Result:

Wallet → Emergency Fund = 500

Cash → Emergency Fund = 300

Bank → Emergency Fund = 200

One Transfer per Funding Source.

---

# Partial Transfer To Saving

Supported.

Example:

Cash Reserved = 600

Transfer = 200

Result:

Reserved = 400

Saved = 200

Progress = 600

Progress remains unchanged.

---

# Goal Actions

Supported Actions:

* Reserve Money
* Release Reservation
* Transfer To Saving
* Complete Goal
* Cancel Goal
* Archive Goal

---

# Funding Method Types

Supported Funding Methods:

## Reserve Funding

Money remains inside liquidity accounts.

---

## Saving Funding

Money is transferred into real Saving Accounts.

---

# Goal Details Layout

Goal Progress

↓

Funding Sources

↓

Goal Activities

↓

Actions

Funding Sources must appear before Actions.

---

# Relationship With Forecasting

Forecasting reads:

* Goals
* Allocations
* Commitments

directly.

Forecasting must never use Goal Progress as source of truth.

---

# Relationship With AI

AI reads:

* Goals
* Allocations
* Activities

directly.

AI must never use Goal Progress as source of truth.

---

# Summary

Goals explain purpose.

Funding Sources represent current state.

Activities represent history.

Goal Progress represents achievement.

Accounts own money.

Allocations provide funding intent.

Goals never own money.

Status:

APPROVED
