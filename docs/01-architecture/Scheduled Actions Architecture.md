# Wafferly Scheduled Actions Architecture

Status: APPROVED

Version: V1

---

# Purpose

This document defines the architecture responsible for discovering, organizing, and executing scheduled financial actions.

It establishes the separation between scheduling, execution, financial truth, and user interaction.

---

# Philosophy

Scheduled Actions provide a unified execution layer for every future financial operation.

Instead of creating separate execution systems for each feature, Wafferly exposes a single action pipeline.

Examples:

* Salary
* Subscription
* Rent
* Loan Payment
* Credit Card Payment
* Installment Payment
* Goal Contribution
* Budget Reset
* Transfer
* Future Investment Orders

All scheduled operations become Scheduled Actions.

---

# Scheduled Action

A Scheduled Action represents a financial action that is ready for user interaction or execution.

Scheduled Actions are derived objects.

They are never Financial Truth.

---

# Golden Rules

## Rule 1

Scheduled Actions are NOT Financial Truth.

They never own money.

They never become source of truth.

---

## Rule 2

Scheduled Actions are reproducible.

Deleting every Scheduled Action must never lose financial information.

The engine must always be able to recreate them from source domains.

---

## Rule 3

Scheduled Actions are immutable.

A Scheduled Action must never be modified directly.

Execution creates Financial Truth.

It never edits Scheduled Actions.

---

## Rule 4

The Financial Action Engine never executes actions.

Its responsibility ends after discovering available actions.

---

## Rule 5

Execution always requires an Executor.

Scheduled Actions never create Transactions directly.

---

# Architecture

Source Domains

↓

Financial Action Providers

↓

Schedule Evaluator

↓

Financial Action Engine

↓

Scheduled Actions

↓

Financial Action Center

↓

Scheduled Action Executor

↓

Financial Truth

---

# Source Domains

Scheduled Actions may originate from multiple domains.

Examples:

* Commitments
* Goals
* Budgets
* Investments
* Future Financial Features

Every domain remains the owner of its own business rules.

---

# Financial Action Providers

Each domain exposes a provider responsible for converting domain objects into Scheduled Actions.

Examples:

* Commitment Action Provider
* Goal Action Provider
* Budget Action Provider
* Investment Action Provider

The Financial Action Engine never understands domain-specific rules.

---

# Schedule Evaluator

Responsible for determining scheduling state.

Possible states include:

* Due
* Upcoming
* Overdue

Schedule Evaluator owns scheduling logic.

No provider should duplicate scheduling rules.

---

# Financial Action Engine

Responsibilities:

* Collect Scheduled Actions
* Evaluate schedules
* Merge actions
* Sort actions
* Filter actions

The engine never:

* Creates Transactions
* Updates Accounts
* Updates Ledger
* Executes actions

The engine only discovers actions.

---

# Scheduled Action Executor

Responsible for executing Scheduled Actions.

Execution is delegated to the appropriate domain service.

Examples:

Expense

↓

TransactionService

Goal Contribution

↓

GoalService

Transfer

↓

TransferService

Debt Payment

↓

TransactionService

The Executor never owns business logic.

It delegates execution.

---

# Financial Action Center

Financial Action Center is the unified interface for all scheduled financial operations.

Examples:

* Execute
* Delay
* Skip
* View Details

The Action Center never modifies Financial Truth directly.

It communicates only through the Scheduled Action Executor.

---

# Derived Data Rule

Scheduled Actions are derived data.

They must always be generated from source domains.

They must never become persistent financial truth.

---

# Future Expansion

The architecture supports future integrations without changing the engine.

Examples:

* OCR
* SMS Parsing
* AI Recommendations
* Widgets
* Wear OS
* Voice Assistants
* Banking Integrations

New features only need to provide Financial Action Providers.

The engine remains unchanged.

---
# Execution Policies

Execution Policies determine whether a Scheduled Action
may proceed to execution.

Policies evaluate business conditions.

Policies never execute actions.

Policies never modify Financial Truth.

Execution is always delegated to the Scheduled Action Executor.

---
# Automatic Completion

Scheduled Actions may be completed automatically.

Automatic completion requires verified financial evidence.

Examples:

- Open Banking
- Verified Bank SMS
- Verified Push Notification

Time alone must never create Financial Truth.

Scheduled Actions are completed through authorized execution,
not by assumptions.


---

# Final Principle

Financial Truth owns reality.

Source Domains own business rules.

The Financial Action Engine discovers actions.

The Scheduled Action Executor performs execution.

The Financial Action Center enables user interaction.

Every responsibility belongs to exactly one layer.

---

Status:

APPROVED
