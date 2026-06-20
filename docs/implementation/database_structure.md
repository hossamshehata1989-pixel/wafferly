# Database Structure

Status: APPROVED

Category: Implementation

Version: V4

---

# Purpose

Define how data is organized inside Wafferly.

This document describes storage architecture.

It does not define business rules.

Business rules belong to Domain Documents.

---

# Core Principle

Storage must follow architecture.

Storage must never redefine architecture.

Financial truth remains:

- Accounts
- Transactions
- Ledger
- Allocations
- Commitments
- Liabilities

---

# Storage Layers

Financial Truth Layer

- Accounts
- Transactions
- Ledger
- Allocations
- Commitments
- Liabilities
- Investments
- Members

---

Planning Layer

- Goals
- Budgets

---

History Layer

- Goal Activities
- Budget Activities
- Commitment Activities

---

Configuration Layer

- User Settings
- Forecast Settings
- AI Settings

---

# Source Of Truth Rule

Store only truth.

Do not store projections.

---

# Never Store

Examples:

- Available Balance
- Reserved Money
- Goal Progress
- Budget Remaining
- Funding Sources

These values are projections.

---

# Store

Examples:

- Account Balance
- Transactions
- Allocations
- Commitments
- Liabilities
- Activities

These are truth.

---

# Accounts

Store:

- id
- name
- type
- balance
- currency
- status

Accounts own money.

---

# Transactions

Store:

- id
- type
- amount
- sourceAccountId
- destinationAccountId
- categoryId
- date

Transactions move money.

---

# Ledger

Store:

- transaction references
- balance history
- audit information

Ledger represents financial history.

---

# Goals

Store:

- metadata
- lifecycle
- target amount
- target date

Do not store:

- balance
- saved amount
- progress

---

# Allocations

Store:

- source account
- allocation type
- amount
- status

Allocations represent planning intent.

---

# Budgets

Store:

- budget definition
- funding configuration
- policy configuration

Do not store:

- remaining amount

---

# Commitments

Store:

- recurring configuration
- expected amount
- schedule

---

# Liabilities

Store:

- obligation amount
- remaining amount
- status

Liabilities are financial truth.

---

# Activities

Store:

- event history

Examples:

- Goal Activities
- Budget Activities
- Commitment Activities

Activities represent history.

Activities do not represent current state.

---

# Projection Rule

Projection data must never be persisted as truth.

Projection Services must recalculate from stored truth.

---

# Offline First

Primary Storage:

Hive

Future:

Hive
↓
Sync Services
↓
Supabase

Hive remains the local operational source.

---

# Summary

Store truth.

Compute projections.

Never store derived state.

Architecture drives storage.

Storage never drives architecture.

Status:

APPROVED