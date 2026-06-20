# Goal Progress Projection

Status: APPROVED

Layer: Projection

Version: V4

---

# Purpose

Goal Progress measures funding achievement.

Goal Progress does not represent money ownership.

Goal Progress does not represent current state.

Goal Progress answers:

How much funding has been accumulated toward the Goal?

---

# Core Rule

Goal Progress

=

Achievement

Funding Sources

=

Current State

Activities

=

History

These concepts must remain independent.

---

# Formula

Goal Progress

=

Total Reserved
+
Total Saved

---

# Example

Target = 10000

Reserved = 3000

Saved = 2000

Result:

Progress = 5000

Completion = 50%

---

# Projection Rule

Goal Progress is a Projection.

Goal Progress must never be stored.

Goal Progress must always be calculated.

---

# Progress Stability Rule

Moving money between valid funding states must not reduce Goal Progress.

---

# Example

Before:

Reserved = 5000

Saved = 0

Progress = 5000

---

Transfer To Saving:

1000

---

After:

Reserved = 4000

Saved = 1000

Progress = 5000

---

# Incorrect Behavior

Reserved = 4000

Saved = 1000

Progress = 4000

Reason:

Money still belongs to the Goal Funding State.

Only the location changed.

---

# Goal Completion Rule

Goal Completion is not based on Activities.

Goal Completion is not based on Allocations alone.

Goal Completion is based on:

Goal Progress

> =

Target Amount

---

# Source Inputs

Goal Progress is derived from:

* Reserved Funding
* Saving Funding

Goal Progress must not be derived from:

* Activities directly
* Goal balances
* Stored values

---

# Relationship With Funding Sources

Architecture:

Funding Sources
↓
Goal Progress

Funding Sources are current state.

Goal Progress is achievement measurement.

---

# Relationship With Activities

Activities represent history.

Activities are not progress.

Example:

Reserve
Release
Transfer To Saving

These events contribute to funding state.

They do not directly define progress.

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

AI may display Goal Progress.

AI must read underlying financial truth directly.

Goal Progress is presentation state.

---

# Goal Progress Type

Goal Progress represents:

Accumulation Progress

Goals grow toward a target.

This differs from Budget Progress.

---

# Comparison

Goal Progress

=

Accumulation

Example:

Saved / Target

---

Budget Progress

=

Consumption

Example:

Spent / Budget

---

Goals grow.

Budgets shrink.

---

# Summary

Goal Progress represents achievement.

Goal Progress is a projection.

Goal Progress

=

Total Reserved
+
Total Saved

Goal Progress must never be stored.

Funding Sources represent current state.

Activities represent history.

Status:

APPROVED
