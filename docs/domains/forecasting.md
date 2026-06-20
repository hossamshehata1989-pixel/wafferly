# Forecasting Domain

Status: APPROVED

Domain: Forecasting

Version: V4

---

# Purpose

Forecasting predicts future financial outcomes.

Forecasting does not represent financial truth.

Forecasting computes possible future states based on current truth and future expectations.

---

# Core Rule

Forecasting

=

Prediction

Forecasting is not:

* Financial Truth
* Projection Layer
* Ledger
* Analytics

Forecasting produces predictions.

---

# Forecasting Inputs

Forecasting must read directly from:

* Accounts
* Transactions
* Ledger
* Allocations
* Goals
* Budgets
* Commitments
* Liabilities
* Investments

Forecasting must never use Projection Layer as source of truth.

---

# Computation Independence Rule

Allowed:

Financial Truth
↓
Forecasting

Forbidden:

Projection
↓
Forecasting

Forecasting must calculate independently.

---

# Forecast Types

## Future Balance Forecast

Predicts future account balances.

Example:

Current Cash = 10000

Salary +12000

Rent -4000

Result:

Future Cash = 18000

---

## Future Available Balance Forecast

Predicts future available money.

Inputs:

* Account Balances
* Allocations
* Commitments

Example:

Cash = 10000

Allocations = 3000

Rent = 2000

Future Available = 5000

---

## Future Cash Flow Forecast

Predicts inflows and outflows.

Examples:

* Salary

* Refund

- Rent

- Subscription

- Loan Payment

---

## Future Obligations Forecast

Predicts upcoming obligations.

Examples:

* Bills
* Installments
* Loan Payments
* Subscriptions

---

## Goal Completion Forecast

Predicts when a Goal may reach target.

Inputs:

* Current Funding
* Scheduled Contributions
* Commitments
* User Behavior

---

## Budget Exhaustion Forecast

Predicts when a Budget may be exhausted.

Inputs:

* Budget Funding
* Spending Velocity
* Historical Transactions

---

# Forecast Dates

Forecasting supports:

* Tomorrow
* Next Week
* Next Month
* Custom Date

Any future date may be evaluated.

---

# Scheduled Goals

Scheduled Goals participate in forecasting.

Example:

Monthly Goal Contribution = 1000

Forecast includes expected contributions.

---

# Unscheduled Goals

Unscheduled Goals are excluded from forecasts.

Reason:

No future funding plan exists.

---

# Forecast Warning Rule

If a Goal has no funding schedule:

Forecast must display warning.

Example:

Goal has no contribution plan.

Forecast accuracy reduced.

---

# Behavioral Forecasting

Supported.

Behavioral Forecasting may use:

* Historical Spending
* Historical Saving
* Budget Usage
* Goal Contributions

Behavioral Forecasting is predictive only.

Never source of truth.

---

# Forecasting Outputs

Forecasting may produce:

* Future Balance
* Future Available Balance
* Future Cash Flow
* Goal Forecasts
* Budget Forecasts
* Obligation Forecasts

Outputs are projections.

Outputs are never stored as truth.

---

# Relationship With Projection Layer

Projection Layer

=

Current State

Forecasting Layer

=

Future State

These layers are independent.

---

# Relationship With Analytics

Analytics explains what happened.

Forecasting predicts what may happen.

They are separate domains.

---

# Relationship With AI

AI may consume Forecasting outputs.

Forecasting remains independent.

AI must never become Forecasting source of truth.

---

# Source Of Truth

Forecasting owns:

Predictions

Forecasting does not own:

* Money
* Balances
* Ledger
* Financial Truth

Financial Truth remains:

Accounts
Transactions
Ledger
Allocations
Commitments
Liabilities

Only

---

# Summary

Forecasting predicts future outcomes.

Forecasting reads directly from Financial Truth.

Forecasting must never depend on Projection Layer.

Forecasting is prediction, not truth.

Status:

APPROVED
