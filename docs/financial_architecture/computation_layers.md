# Computation Layers

Status: APPROVED

Version: V4

---

# Purpose

Define how derived systems operate in Wafferly.

---

# Core Principle

Financial Truth
↓
Independent Computation Layers

---

# Financial Truth

Contains:

- Accounts
- Transactions
- Ledger
- Allocations
- Liabilities
- Commitments
- Investments
- Members

---

# Computation Layers

Projection Layer

Forecasting Layer

Analytics Layer

AI Layer

---

# Projection Layer

Represents current state.

Examples:

- Funding Sources
- Reserved Money
- Available Balance
- Goal Progress
- Budget Remaining

---

# Forecasting Layer

Represents future predictions.

Examples:

- Future Balance
- Future Available Balance
- Future Cash Flow
- Goal Forecast

---

# Analytics Layer

Represents historical understanding.

Examples:

- Reports
- Trends
- Net Worth Analysis

---

# AI Layer

Represents decision support.

Examples:

- Insights
- Recommendations
- Impact Analysis

---

# Derived Data Independence Rule

Allowed:

Financial Truth
↓
Projection

Financial Truth
↓
Forecasting

Financial Truth
↓
Analytics

Financial Truth
↓
AI

---

Forbidden:

Projection
↓
Forecasting

Projection
↓
Analytics

Projection
↓
AI

Forecasting
↓
Analytics

Analytics
↓
AI

---

# Reason

Avoid:

- Hidden Bugs
- Data Drift
- Debugging Complexity
- Multiple Truth Chains

---

# Summary

All computation layers are independent.

All computation layers read directly from Financial Truth.

Status:

APPROVED