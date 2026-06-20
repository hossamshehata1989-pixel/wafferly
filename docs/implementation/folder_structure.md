# Folder Structure

Status: APPROVED

Category: Implementation

Version: V4

---

# Purpose

Define the long-term project structure for Wafferly.

The structure must follow architecture.

Folders must reflect domain boundaries.

---

# Root Structure

/docs
/lib
/assets
/test

---

# Documentation

docs/

├── financial-rules
├── domains
├── projections
├── implementation
├── roadmap
└── financial_architecture

---

# Flutter Structure

lib/

├── core
├── features
├── shared
├── services
├── projections
├── repositories
├── sync
├── ai
└── app

---

# Core Layer

core/

Contains:

- constants
- enums
- utilities
- errors
- base classes

Core contains no business domains.

---

# Features Layer

features/

Contains business domains.

Example:

features/

├── accounts
├── transactions
├── goals
├── budgets
├── liabilities
├── commitments
├── recurring
├── forecasting
├── investments
└── shared_finance

---

# Domain Structure

Example:

goals/

├── models
├── services
├── projections
├── validators
├── repositories
├── screens
├── widgets
└── activities

---

# Shared Layer

shared/

Reusable components.

Examples:

- dialogs
- widgets
- forms
- selectors

No business ownership.

---

# Services Layer

services/

Cross-domain services.

Examples:

- notification service
- export service
- import service

---

# Projection Layer

projections/

Global projection services.

Examples:

- AvailableBalanceProjectionService
- ReservedMoneyProjectionService

---

# Repository Layer

repositories/

Persistence layer.

Examples:

- GoalRepository
- BudgetRepository
- AccountRepository

Repositories contain no business logic.

---

# Sync Layer

sync/

Examples:

- SupabaseSyncService
- AccountSyncService
- GoalSyncService

Responsible for synchronization only.

---

# AI Layer

ai/

Examples:

- Context Builder
- Insights Engine
- Recommendation Engine
- Action Engine

AI remains isolated from financial truth ownership.

---

# Test Structure

test/

Mirror production structure.

Example:

test/

├── goals
├── budgets
├── forecasting
├── liabilities

---

# Folder Ownership Rule

Each domain owns:

- Models
- Services
- Validators
- Activities
- Screens

Avoid cross-domain ownership.

---

# Dependency Rule

Allowed:

UI
↓
Services
↓
Repositories

Forbidden:

UI
↓
Repositories directly

---

# Architecture Alignment

Folder structure must reflect:

Financial Truth
↓
Planning
↓
Projection
↓
Forecasting
↓
Analytics

Never the reverse.

---

# Summary

Folders follow architecture.

Domains remain isolated.

Business logic lives in services.

Persistence lives in repositories.

Projection logic lives in projection services.

Status:

APPROVED