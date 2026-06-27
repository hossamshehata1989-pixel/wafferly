# Wafferly Architecture Decision Log

Status: ACTIVE

Version: V1

---

# Purpose

This document records every approved architecture decision.

It is the official reference for architectural decisions made throughout the Wafferly project.

Architecture documents explain the system.

This document explains the decisions.

---

## Decision 001

Financial Truth owns money.

Status:

APPROVED

Reference:

Financial Architecture V4

---

## Decision 002

Accounts are the only owners of money.

Status:

APPROVED

Reference:

Financial Architecture V4

---

## Decision 003

Transactions move money.

Status:

APPROVED

Reference:

Financial Architecture V4

---

## Decision 004

Projection is derived.

Projection never becomes Financial Truth.

Status:

APPROVED

Reference:

Projection Architecture

---

## Decision 005

Forecasting reads source domains directly.

Forecasting never depends on Projection.

Status:

APPROVED

Reference:

Forecasting Architecture

---

## Decision 006

Analytics reads source domains directly.

Analytics never depends on Projection.

Status:

APPROVED

Reference:

Analytics Architecture

---

## Decision 007

Debt payments are not expenses.

Debt payments must use:

CommitmentType.liabilityPayment

Status:

APPROVED

Reference:

Financial Architecture V4

---

## Decision 008

Scheduled Actions are derived domain objects.

They never become Financial Truth.

Status:

APPROVED

Reference:

Scheduled Actions Architecture

---

## Decision 009

Scheduled Actions are reproducible.

Deleting all Scheduled Actions must never lose financial information.

Status:

APPROVED

Reference:

Scheduled Actions Architecture

---

## Decision 010

Scheduled Actions are immutable.

Execution never modifies Scheduled Actions.

Status:

APPROVED

Reference:

Scheduled Actions Architecture

---

## Decision 011

Financial Action Engine discovers actions only.

Execution belongs to the Scheduled Action Executor.

Status:

APPROVED

Reference:

Scheduled Actions Architecture

---

## Decision 012

Every derived computation layer reads directly from source domains.

Derived layers never become source of truth.

Status:

APPROVED

Reference:

Financial Architecture V4

---

## Decision 013

Scheduling is evaluated by a dedicated Schedule Evaluator.

Scheduling logic must never be duplicated across providers.

Status:

APPROVED

Reference:

Scheduled Actions Architecture

---

## Decision 014

Every domain exposes Financial Actions through a Provider.

The Financial Action Engine never contains domain-specific business rules.

Status:

APPROVED

Reference:

Scheduled Actions Architecture

---

Status:

ACTIVE


---

## Decision 015

Evidence is not Financial Truth.

Evidence is an ingress into Financial Truth.

Status:

APPROVED

Reference:

Financial Architecture V4

---

## Decision 016

Financial Truth must never be created from time alone.

Status:

APPROVED

Reference:

Financial Architecture V4

---

## Decision 017

Financial Truth may only be created or modified through authorized application domain operations.

Status:

APPROVED

Reference:

Financial Rules
