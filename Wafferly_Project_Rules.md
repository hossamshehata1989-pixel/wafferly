Today 4:11 PM
Pasted markdown(20260904-172654).md
File
بص يا صديقي انا غيرت شوية حاجات في الملف سيبهم متغيرهمش وضيف عليهم اننا عايزين نشيل الكونتينر اللي بيحوي كلمة must او need , او want ونكبر الكلام 
ممكن تقولي اعملها ازاي 
وقولي رايك في النتيجه اللي عملتها بكل حياديه
هو احنا لو غيرنا اللون بدل ما الثيم غامق خليناه فاتح هيظهر بالمنظر دا ؟
Wafferly_Project_Rules.md(1).txt
Document
طيب دا كان موجود في root المروع 

أكيد. لو قصدك كود التعديلات اللي هنضيفها في Wafferly_Project_Rules.md، أقدر أطلع لك الجزء الجاهز للنسخ مباشرة.

راجع الصوره دي وكل دول في سكوبنا 

أيوه، راجعت الصورة بالكامل، وكده الصورة دي بتقفل موضوع الـ Scope بشكل واضح. هنعتبر كل ما هو موجود فيها داخل Scope المشروع وقبل الـ Launch، مش Future Scope.

✅ تم تثبيته كـ In Scope
Financial Core — ADR-001 → ADR-007
Financial Domain Foundation
Canonical Financial Draft
Understanding Workflow Model
Financial Operation Execution Engine
Financial Accounting Model
Balance Derivation Engine
Planning Layer
Goals
Allocations
Funding Strategies
علاقتها بالحسابات والأرصدة
Pre-Launch Domains — ADR-008 → ADR-013+
Scheduled Financial Actions
العمليات المجدولة
التنفيذ التلقائي
recurring financial actions
Financial Projection
توقع الأرصدة المستقبلية
Cash-flow projection
السيناريوهات والتحليل المستقبلي
Investment Domain
Gold
Precious Metals
Stocks
Holdings
Buy/Sell
Valuation
Profit/Loss
Market Prices
Debt Domain
Loans
Borrowing
Repayments
Schedules
Interest
Settlements
Multi-Currency
Base Currency
Transaction Currency
Exchange Rates
Currency Conversion
FX Gain/Loss
وإدارة أسعار الصرف
Additional Capabilities
Imports
Sync
Categorization
Budgets
Analytics
Reports
Notifications
Integrations
Security
🔐 والـ Cross-Cutting Architecture دي كمان Scope أساسي
Security & Permissions
Audit & Traceability
Data Integrity
Idempotency & Consistency
Observability & Monitoring
Performance & Scalability
وكمان من اتفاقاتنا السابقة

هنعتبر ضمن الـ Scope كذلك:

SMS
Prediction
Voice Typing
Engines المطلوبة لكل Domain
Live FX / Exchange Rates
Live Stock Prices
Live Gold / Precious Metals Prices
Supabase
Authentication
RLS
Encryption / Secure Storage
Offline-first + Sync
Premium / Paid Features
Multi-device readiness

والأهم: مش هنحط أي واحد من دول تحت "Future Scope" بالغلط.

الصورة فعليًا بتوضح إن المشروع المستهدف هو:

نظام مالي شخصي متكامل، قابل للتوسع، دقيق، ومبني على Financial Core قوي، وليس مجرد Expense Tracker.

وبالتالي من هنا ورايح لما نراجع Wafferly_Project_Rules.md، هنستخدم الـ ADR-001 → ADR-013+ الموجودين في الصورة كـ Scope مرجعي، وأي Rule تتعارض معاهم تتعدل بدل ما نعتبر الميزة Future.

ملاحظة مهمة: الـ ADR-013+ عبارة عن مظلة للـ Additional Capabilities، فمش هفسرها على إنها "أي Feature ممكنة في المستقبل"؛ هنلتزم بالمذكور في الصورة وما اتفقنا عليه تحديدًا.

ولو هنكمل تعديل ملف الـ Rules، فالأصح دلوقتي إني أدمج الـ ADRs دي رسميًا داخل الـ Master Rules File وأعمل consistency check كامل بدل ما نضيف Rules متفرقة كل مرة.

اكتب الكود كامل 

تمام. ده الـ Wafferly_Project_Rules.md كامل بعد التحديث، ودمجت فيه الـ ADR-001 → ADR-013+ وكل الـ Scope اللي اتفقنا عليه، بما فيه:

Scheduled Financial Actions
Financial Projection
Investments
Gold / Precious Metals / Stocks
Debt
Multi-Currency
Live FX / Exchange Rates
Live Market Prices
SMS
Prediction
Voice Typing
Engines المطلوبة
Supabase
Authentication / RLS / Security
Offline + Sync
Premium
Audit / Traceability
Data Integrity
Idempotency
Observability
Performance / Scalability

وكمان راجعت الملف بعد التعديل:

66 Rule
الترقيم من 1 → 66 بدون فجوات
لا يوجد Duplicate Rules
مفيش تعارض في الـ Scope بالنسبة للحاجات اللي ثبتنا إنها Pre-Launch.
الملف الكامل

تحميل Wafferly_Project_Rules.md

وده هو نفس ملف الـ Master Rules، مش ملف جديد منفصل.

Wafferly_Project_Rules.md
Document

Library
/
Wafferly_Project_Rules.md
Wafferly Project Rules

Last Updated:
Financial Engine + Transactions Stabilization Phase

FINANCIAL ENGINE RULES
Rule 1: Ledger Is Part of Financial Engine

Transactions

↓

Ledger

↓

Balances

↓

Reports

↓

Analysis

Notes:

Ledger is NOT a reporting layer only
Ledger participates in financial calculations
Ledger data must stay synchronized

Status:
[APPROVED]

Rule 2: Transaction Lifecycle Sync

Create Transaction

↓

Transaction

↓

Create Ledger Entries

Update Transaction

↓

Update

↓

Delete old Ledger Entries

↓

Update Transaction

↓

Recreate Ledger Entries

Delete Transaction

↓

Delete

↓

Delete Ledger Entries

↓

Delete Transaction

Notes:

Do not leave orphan LedgerEntries
Delete and update must keep Ledger synchronized

Status:
[APPROVED]

Rule 3: Runtime Verification First

Before adding architecture:

Required:

✓ Verify existing implementation
✓ Verify method existence
✓ Verify runtime behavior

Forbidden:

❌ Create new services
❌ Singleton conversions
❌ Event systems
❌ Observers
❌ Streams
❌ Sync managers
❌ Random architecture refactors

Status:
[APPROVED]

ACCOUNT RULES
Rule 4: Account Delete Policy

If account has linked transactions:

Delete

↓

Archive only

Result:

isArchived=true

If account has NO linked transactions:

Delete

↓

Hard delete

Status:
[APPROVED]

Rule 5: Archived Account Behavior

Archived account hidden from:

✓ Add transaction
✓ Account selectors
✓ Active accounts list

Archived account still available in:

✓ Historical transactions
✓ Ledger
✓ Reports
✓ Analysis
✓ Balance calculations

Status:
[APPROVED]

Rule 6: Account Restore Policy

Lifecycle:

Active
↓
Archive
↓
Restore

Restore:

isArchived=false

Restored account returns to:

✓ Add transaction
✓ Account selectors
✓ Accounts screen

Status:
[APPROVED]

TRANSACTIONS RULES
Rule 7: Screen Responsibility

TransactionsScreen:

✓ History
✓ Search
✓ Filters
✓ Grouping

ExpensesScreen:

✓ Create flow
✓ Edit flow

ExpensesList:

Legacy
↓
Remove gradually

Status:
[APPROVED]

Rule 8: Search Rules

Search supports:

✓ Arabic
✓ English

Priority:

StartsWith()
↓
Contains()

Normalization:

أ/إ/آ → ا

ة → ه

ى → ي

Status:
[APPROVED]

Rule 9: Date Filters

Available filters:

Today
Last 3 Days
Last 7 Days
This Month (Default)
Last 3 Months
This Year
All Time

Status:
[APPROVED]

Rule 10: Transaction Grouping

Today
Last 3 Days
Last 7 Days

↓

Daily grouping

This Month
Last 3 Months

↓

Monthly grouping

This Year
All Time

↓

Year grouping

Status:
[APPROVED]

Rule 11: Transaction Tabs

Available:

✓ All
✓ Expenses
✓ Income
✓ Transfer

Disabled:

Borrow/Lend
Payments

Reason:

Models not ready yet

Status:
[APPROVED]

FUTURE IMPROVEMENTS
Atomic transaction lifecycle
Dismissible cleanup
Hierarchical category filter
Edit flow integration
Analysis verification
ARCHITECTURE / DATA ACCESS RULES
Rule 12: UI Must Not Access Storage Directly

Screens and Widgets MUST NOT directly access:

Hive
Hive.box()
Hive adapters
Supabase
Supabase client/database tables
Storage APIs

Required flow:

UI / Screen
↓
Controller / ViewModel
↓
Service / Use Case
↓
Repository
↓
Data Source

Status:
[APPROVED]

Rule 13: Business Logic Must Not Live in UI

Do not put financial calculations, data aggregation, lifecycle decisions, or business rules inside:

build()
widget callbacks
State classes
UI-only loaders

Business logic belongs in plain Dart classes such as:

Services
Use Cases
ViewModels
Projection services
Domain/financial engines

The UI should consume prepared state.

Status:
[APPROVED]

Rule 14: Existing Financial Engines Are the Source of Truth

Do not duplicate calculations already owned by:

Financial Engine
Planning Engine
FinancialOperationEngine
Projection Services
Existing domain Services

Before implementing a new calculation:

Search the existing implementation.
Verify its behavior.
Reuse it when applicable.
Only introduce new logic when the existing architecture does not cover the requirement.

Status:
[APPROVED]

Rule 15: Runtime Verification Before Architecture Changes

Before creating a new service, repository, manager, observer, stream, synchronization layer, or singleton:

Verify the current implementation.
Verify available methods.
Verify actual runtime behavior.
Check whether an existing service already solves the problem.

Do not add architecture only because it may be useful in the future.

Status:
[APPROVED]

FINANCIAL DOMAIN OWNERSHIP
Rule 16: Goal Ownership

Goal owns:

Purpose
Target
Deadline
Goal lifecycle

Goal does NOT directly own:

Executed money movement
Account balance
Ledger balance
Schedule

Money associated with a Goal must be represented through the appropriate financial mechanism.

Status:
[APPROVED]

Rule 17: Budget Ownership

Budget owns:

Spending control policy
Budget limits
Budget configuration

Budget does NOT represent:

Executed transaction
Account balance
Actual money movement

Actual financial movement remains a Transaction concern.

Status:
[APPROVED]

Rule 18: Allocation Ownership

Allocation represents:

Planning reservation intent
Reserved money state

Allocation is operational planning state.

Allocation is NOT a replacement for:

Transaction
Ledger
Financial history

Status:
[APPROVED]

Rule 19: Reserved Money Is Projection-Based

Reserved Money must be derived from active Planning Engine allocations.

Do not create a second independent balance source for Reserved Money.

Each active allocation remains independently identifiable.

UI grouping must not merge separate allocations into one financial record.

Status:
[APPROVED]

Rule 20: Commitment vs Transaction

Commitment represents a future financial event.

Transaction represents an executed financial movement.

Do not treat a scheduled Commitment as an executed Transaction.

Do not create fake Transactions merely to represent future scheduled events.

Status:
[APPROVED]

GOAL LIFECYCLE RULES
Rule 21: Goal Funding Mechanisms

Two funding mechanisms are supported:

Transfer-to-Saving Goal

Money is physically transferred from the original/liquidity account to the Saving Account using a real Transfer Transaction.

Reserve / Locked Goal

Money remains in the original liquidity account and is reserved through Planning Engine Allocation.

Status:
[APPROVED]

Rule 22: Goal Financial History

Financial history is derived from GoalActivity.

Relevant activity types include:

reserve
release
transferToSaving
completedReserved
completedRelease

Do not add a second independent financial-history system to the Goal model.

Status:
[APPROVED]

Rule 23: Goal Cancel / Archive / Complete

Lifecycle actions must respect the funding mechanism.

For Transfer-to-Saving Goals:

Cancel / Archive follows the approved archive lifecycle.
Do not introduce an unrelated generic financial-history warning flow.

For Reserve / Locked Goals with currently reserved money:

The user must be offered:

Keep Reserved
Transfer to Saving
Release

Complete follows the same reserved-money decision where applicable.

Final Goal status must match the action:

Cancel → cancelled
Archive → completed/archive representation
Complete → completed

Release operations must use the Planning Engine.

Status:
[APPROVED]

MONEY RULES
Rule 24: Money Representation Decision

The current project-wide double representation is NOT the final representation for the pre-launch financial architecture.

Before implementing or freezing the Supabase schema for:

Multi-currency
Investment assets
Live market-price valuation

the project shall migrate its financial/domain money calculations to a precise decimal representation.

Approved Direction
Use Decimal for financial calculations and persisted monetary values where exact decimal arithmetic is required.
Supabase monetary values shall use an appropriate exact decimal/numeric database representation, not floating-point storage.
Asset quantities and market prices may require precision beyond two decimal places; do not assume every financial value is a two-decimal currency amount.
Currency amounts, exchange rates, investment prices, quantities, and valuation calculations must each define their required precision and rounding policy.
Migration Rule

This is a PROJECT-WIDE migration decision.

Do NOT convert only one feature or screen. Before starting production implementation of Multi-currency or Investments:

Inventory all money-bearing models, services, engines, projections, and persistence code.
Define precision and rounding rules.
Define the Decimal representation and serialization format.
Migrate the affected financial core consistently.
Add/update financial integrity and regression tests.
Verify existing balances, transactions, ledger entries, goals, budgets, allocations, and commitments.
Only then freeze the corresponding Supabase schema.

Until this migration is completed, existing double code must be treated as legacy/current implementation, not as the final financial storage contract.

Status:
[APPROVED]

Rule 25: Rounding and Currency Conversion

Currency conversion, investment valuation, and price-linked calculations MUST use the approved exact-decimal representation and an explicitly defined rounding policy.

Any multi-currency implementation must define:

Base currency
Transaction currency
Exchange rate ownership
Rate timestamp/source
Precision
Rounding mode
Storage representation

Exchange rates and investment prices must not be calculated or persisted as binary floating-point values when exact decimal representation is required.

SUPABASE / FUTURE BACKEND ARCHITECTURE
Rule 26: Supabase Is In Scope Now

Supabase is an active implementation phase of Wafferly, not merely a future capability.

The migration must be deliberate and layered. Existing financial/domain logic must not be rewritten simply because persistence is moving to Supabase.

Current direction:

UI
↓
Controllers / ViewModels
↓
Services / Use Cases
↓
Repositories
↓
Supabase

Hive remains part of the local/offline strategy where applicable.

Status:
[APPROVED]

Rule 27: Supabase Cloud Source of Truth

For cloud-backed data:

Supabase
↓
Cloud Source of Truth

Hive
↓
Local Offline Cache

Hive must not become a second independent financial source of truth.

Local/offline writes must be synchronized through the approved sync architecture rather than creating a competing financial truth.

Status:
[APPROVED]

Rule 28: Repository Abstraction

The intended storage architecture is:

Service
↓
Repository
↓
Data Source

The Repository must isolate business/domain code from the underlying persistence technology.

Future implementations may include:

Hive data source
Supabase data source

The UI must not change merely because the underlying persistence technology changes.

Status:
[APPROVED]

Rule 29: Supabase Schema Must Follow Domain Ownership

Supabase tables must be designed from the approved domain model.

Do not create tables merely by copying Flutter classes one-to-one without reviewing:

Ownership
Relationships
Lifecycle
Referential integrity
IDs
Audit fields
Soft deletion/archive behavior
Financial history
Projection vs source-of-truth data

Status:
[APPROVED]

Rule 30: Supabase Migration Is a Separate Phase

Before creating the production Supabase schema:

Review all domain models.
Review all repositories/services.
Review entity relationships.
Decide the final money representation.
Define user ownership.
Define authentication.
Define RLS policies.
Define sync strategy.
Define conflict resolution.
Define migration/backup strategy.

Do not freeze the database schema before these decisions.

Status:
[APPROVED]

AUTHENTICATION / IDENTITY RULES
Rule 31: User Ownership

Cloud data must be associated with an authenticated user.

Conceptually:

User
↓
user_id
↓
Accounts / Transactions / Goals / Budgets / Allocations / Commitments

Every cloud-owned entity must have a clearly defined ownership rule.

Status:
[APPROVED]

Rule 32: Authentication

Authentication is IN SCOPE before launch.

The approved initial authentication strategy is:

Supabase Auth
↓
Email
↓
Password

Additional authentication providers may be added later if explicitly approved.

Authentication implementation must not leak authentication concerns into financial-domain logic.

Status:
[APPROVED]

SECURITY RULES
Rule 33: Row Level Security

Supabase RLS MUST be enabled for user-owned financial data.

The security model must enforce:

User A
↓
User A data only

The application UI must never be the only security boundary.

Status:
[APPROVED]

Rule 34: Secrets

Never commit or embed server-side secrets in the Flutter application.

Never expose:

Supabase service-role key
Payment provider secret keys
Private API credentials
Server-side encryption secrets

in the client application or public repository.

Secrets must remain server-side or in an approved secure secret-management mechanism.

Status:
[APPROVED]

Rule 35: Local Sensitive Data

Sensitive local data must use an approved encrypted storage strategy when required.

Credentials, tokens, and other secrets should use secure platform storage rather than ordinary application storage.

Hive encryption and secure storage are separate concerns and must not be treated as interchangeable.

Status:
[APPROVED]

Rule 36: Transport Security

Cloud communication must use secure transport.

Do not introduce insecure HTTP communication for financial/user data.

Status:
[APPROVED]

OFFLINE / SYNC RULES
Rule 37: Offline-First Direction

The application should be designed to remain useful when connectivity is unavailable.

Conceptual flow:

UI
↓
Services
↓
Repository
↓
Local Cache

When online:

Local State
↓
Sync
↓
Supabase

Status:
[APPROVED]

Rule 38: Sync Must Not Duplicate Financial Logic

Synchronization is a data consistency mechanism.

It must NOT become a second Financial Engine.

The Financial Engine remains responsible for financial meaning/calculation.

Sync is responsible for moving and reconciling persisted state.

Status:
[APPROVED]

Rule 39: Conflict Resolution

Before production multi-device synchronization, a formal conflict-resolution policy must be defined.

The policy must specify:

Which fields are mutable
Last-write behavior where appropriate
Operation ordering
Delete/archive conflicts
Transaction conflicts
Allocation conflicts
Goal lifecycle conflicts
Retry behavior
Idempotency

Do not implement arbitrary conflict behavior.

Status:
[APPROVED]

Rule 40: Sync Queue

If a local operation is queued for later synchronization, it must have enough information to:

Identify the operation
Identify the affected entity
Preserve ordering where required
Retry safely
Avoid duplicate execution
Record failure state

Do not create a generic SyncManager without first verifying the required behavior and architecture.

Status:
[APPROVED]

BACKUP / RESTORE RULES
Rule 41: Cloud Backup

When cloud synchronization is implemented, cloud persistence should provide recovery from device loss.

Backup and synchronization are related but are not identical concepts.

Status:
[APPROVED]

Rule 42: Restore

Restore must preserve:

User ownership
Entity relationships
Transaction history
Goal history
Allocation state
Commitment state

Restoring data must not silently recreate duplicate financial movements.

Status:
[APPROVED]

MONETIZATION / PAID FEATURES
Rule 43: Free vs Premium

Wafferly may support:

Free
↓
Core personal-finance functionality

Premium
↓
Advanced functionality

Paid features must be designed as product entitlements rather than scattered UI-only checks.

Status:
[APPROVED]

Rule 44: Feature Gating

Do not scatter subscription checks throughout the application.

Preferred conceptual flow:

Subscription / Entitlement
↓
Feature Access Policy
↓
UI + Services

A premium feature must not rely only on hiding a button.

Any server-backed premium capability must also be protected server-side where applicable.

Status:
[APPROVED]

Rule 45: Payments

Payment-provider secrets must remain server-side.

Subscription status must be treated as an entitlement/state that can be verified independently from local UI state.

Do not trust a client-side boolean such as:

isPremium = true

as the sole authority for paid access.

Status:
[APPROVED]

MULTI-DEVICE RULES
Rule 46: Multi-Device Readiness

The architecture should allow one authenticated user to access the same cloud-backed financial data from multiple devices.

This does NOT require implementing multi-device support now.

Current architecture must simply avoid decisions that make it impossible later.

Status:
[APPROVED]

UI / THEME / RESPONSIVE RULES
Rule 47: Current Theme Priority

Current priority:

Dark Theme first.

Do not redesign existing screens for Light Theme unless explicitly requested.

The existing dark visual language should remain consistent across new screens.

Status:
[APPROVED]

Rule 48: Light Theme

Light Theme is a later dedicated phase.

Do NOT implement Light Theme by simply changing the background from dark to white.

A proper Light Theme must define:

Surface colors
Text colors
Borders
Shadows
Semantic colors
Gradients
Icon treatment
Contrast
Disabled states

Before a project-wide Light Theme implementation, propose the plan and confirm.

Status:
[APPROVED]

Rule 49: Existing Widget Language

New UI should follow the existing Wafferly visual structure, including established components such as:

_Panel
_IconBox
Existing dark surfaces
Existing spacing language
Existing semantic color language

Do not introduce an unrelated visual system for one screen.

Status:
[APPROVED]

Rule 50: ResponsiveMetrics

All meaningful spacing and dimensions should use ResponsiveMetrics where the project already provides it.

Use the appropriate helpers:

size()
text()
spacing()
h()

Avoid arbitrary fixed vertical dimensions when a responsive metric is appropriate.

Status:
[APPROVED]

LOCALIZATION / RTL RULES
Rule 51: Localization

Localization is a dedicated project-wide phase.

Initial supported languages:

English
Arabic

Do not scatter hard-coded user-facing strings through new architecture where avoidable.

Status:
[APPROVED]

Rule 52: Arabic / RTL

Arabic support requires more than translating strings.

A full RTL review must cover:

Layout direction
Alignment
Icons with directional meaning
Navigation
Padding
Dates
Numbers
Currency presentation
Text wrapping
Dialogs
Lists

Do not assume that translated text automatically makes the UI RTL-correct.

Status:
[APPROVED]

APPROVED ARCHITECTURE / ADR SCOPE BASELINE

The following ADR baseline is part of the approved Wafferly architecture and product scope. These ADRs are not future-only concepts; the listed domains and capabilities are part of the planned pre-launch system unless explicitly moved by an approved rule change.

ADR-001 — Financial Domain Foundation

The Financial Domain Foundation defines the financial domain boundaries, core concepts, ownership rules, and ubiquitous language.

ADR-002 — Canonical Financial Draft

The Canonical Financial Draft is the controlled artifact that crosses the boundary from user understanding toward financial execution. It must be validated before execution and must not directly mutate financial truth.

ADR-003 — Understanding Workflow Model

The Understanding Workflow models the lifecycle from Input → Session → Process → Result, including clarification where required. Ambiguous natural-language input must not become a financial operation without sufficient validation.

ADR-004 — Financial Operation Execution Engine

The Financial Operation Execution Engine is the single authoritative execution boundary for financial operations. It validates and executes approved financial operations and coordinates the creation/update/deletion of the authoritative financial records according to the existing Financial Engine and Ledger rules.

No UI, voice parser, SMS parser, prediction component, scheduled action, or external market-data service may bypass this execution boundary to mutate financial truth.

ADR-005 — Financial Accounting Model

The accounting model defines Journal Entries, Entry Lines, Accounts, and Books as the authoritative accounting representation of executed financial movements.

ADR-006 — Balance Derivation Engine

Balances and financial state are derived from the approved immutable/accounting records. UI components must not independently invent balance calculations.

ADR-007 — Planning Layer

The Planning Layer owns Goals, Allocations, funding strategies, and their relationship to accounts and balances. Planning intent is distinct from executed financial movement.

ADR-008 — Scheduled Financial Actions

Scheduled Financial Actions are IN SCOPE before launch. They model future-dated and recurring financial actions and define how approved scheduled actions are validated, queued, executed, retried, and kept idempotent.

Scheduling must not create duplicate financial movements and must execute through the Financial Operation Execution Engine.

ADR-009 — Financial Projection

Financial Projection is IN SCOPE before launch. It projects future balances and cash flows using actual financial state plus applicable scheduled actions, goals, allocations, commitments, and other approved planning inputs. Projection is calculated state and must never mutate actual financial truth.

ADR-010 — Investment Domain

The Investment Domain is IN SCOPE before launch and includes, at minimum:

Gold
Precious metals
Stocks
Holdings / positions
Buy / sell operations
Quantity and cost basis where applicable
Current valuation
Profit / loss
Historical and current market prices

Investment execution and accounting must remain distinct from external price retrieval.

ADR-011 — Debt Domain

The Debt Domain is IN SCOPE before launch and includes, as applicable:

Loans
Borrowing
Repayments
Debt schedules
Interest
Settlements
Credit Cards
Reusable Installment Facilities
Single Installment Plans
Borrowed Money
Temporary Debt
Rotating Savings / Saving Circle lifecycle where approved

The detailed ownership boundary between Accounts and Manage is defined by ADR-032.

Debt operations that create actual financial movements must execute through the Financial Operation Execution Engine.

ADR-012 — Multi-Currency Support

Multi-Currency is IN SCOPE before launch and includes:

Base currency
Transaction currency
Exchange rates
Currency conversion
FX gain/loss where applicable
Historical exchange-rate handling
Explicit precision and rounding policy

FX rates are external data inputs and must not replace the authoritative financial records.

ADR-013+ — Additional Approved Capabilities

The following capabilities are also IN SCOPE before launch as part of the approved product direction:

Imports
Synchronization
Categorization
Budgets
Analytics
Reports
Notifications
Integrations
Security and permissions
SMS-based input/integration where supported by the product design
Prediction / forecasting capabilities
Voice Typing / voice-assisted financial input
Premium / paid features foundation
Authentication
Supabase cloud persistence
Offline-first local persistence and synchronization
Multi-device readiness
ADR-032 — Debt Domain Architecture

The Debt Domain uses a single financial source of truth while allowing Accounts and Manage to have different responsibilities. Accounts owns the structural financial-position representation of liabilities; Manage owns debt workflows and operational UX. Neither screen may maintain an independent authoritative debt balance.

Debt workflows that create actual financial movements must use the Financial Operation Execution Engine and the authoritative Transaction / Ledger pipeline. Future payment expectations remain represented by Commitments and applicable Schedule Rules / Occurrences until actual execution occurs.

Debt concepts may include Credit Cards, Reusable Installment Facilities, Single Installment Plans, Loans, Borrowed Money, Temporary Debt, and Rotating Savings / Saving Circle liabilities after actual receipt. Installment classification is based on the business concept; the existence of a limit is a facility property and is not the sole classification rule.

Accounts may show debt categories as navigable rollups or representations of liability Accounts. Such items must reuse the underlying approved workflow rather than create duplicate CRUD or financial logic.

Rotating Savings / Saving Circle expected payout does not automatically create an active liability. After the user confirms actual receipt, the approved financial operation establishes the resulting liability and actual financial records.

Status:
[APPROVED]

Voice Input Safety Boundary

Voice input must follow a controlled flow:

Voice → Speech-to-Text → Text Understanding/Parser → Financial Intent → Validation → User Confirmation → Financial Operation Execution Engine

Voice input must not execute a financial transaction directly without the required validation and confirmation policy.

Prediction Safety Boundary

Prediction components may forecast, classify, score, or recommend based on approved financial data. They must not directly modify transactions, ledger entries, balances, allocations, or other financial truth.

SMS Safety Boundary

SMS ingestion/parsing is an input/integration capability. Parsed SMS content must be treated as untrusted input and must pass through the same understanding, validation, and execution boundaries before creating financial records.

Live Market Data / Pricing Architecture

External pricing must follow an explicit separation of responsibilities:

Market Data Provider → Market Data Service → Price/Rate Data → Pricing/Valuation Engine → Investment Projection / Presentation

For currencies:

FX Provider → Exchange Rate Service → Approved FX Rate → Currency Conversion / Valuation

For investments:

Market Provider → Price Service → Asset Price → Investment Valuation Engine

The architecture must define, before production integration:

Supported providers/sources
Asset coverage
Base and quote currencies
Timestamp of each price/rate
Source/provider identity
Update frequency
Meaning of “live” (for example: tick, minute, delayed, or last available)
Staleness handling
Missing-price behavior
Market-closed behavior
Precision and rounding
Caching strategy
Failure/retry behavior

External market prices and exchange rates are inputs to valuation/projection. They do not become a replacement for executed transaction or ledger truth.

Engine Ownership Principle

Every important domain engine must have one authoritative responsibility. Engines may calculate or orchestrate within their ownership boundary, but they must not duplicate another engine’s source of truth.

Status:
[APPROVED]

CURRENT / FUTURE SCOPE RULES
Rule 53: Current Scope vs Future Scope

The following are IN SCOPE before launch and must be implemented as real product capabilities, subject to phased implementation and the dependency order defined by the architecture:

Current / Pre-Launch Scope
Financial Core / ADR-001 → ADR-007
Financial Domain Foundation
Canonical Financial Draft
Understanding Workflow Model
Financial Operation Execution Engine
Financial Accounting Model
Balance Derivation Engine
Planning Layer (Goals, Allocations, Funding Strategies)
Financial Expansion / ADR-008 → ADR-013+
Scheduled Financial Actions
Financial Projection
Investment Domain:
Gold
Precious metals
Stocks
Holdings / positions
Buy / sell
Valuation
Profit / loss
Live/current market prices
Debt Domain:
Loans
Borrowing
Repayments
Schedules
Interest where supported
Settlements
Credit Cards
Reusable Installment Facilities
Single Installment Plans
Borrowed Money
Temporary Debt
Rotating Savings / Saving Circle lifecycle after actual receipt confirmation
Multi-Currency:
Base currency
Transaction currencies
Exchange rates
Currency conversion
FX gain/loss where applicable
SMS input/integration
Prediction / forecasting
Voice Typing / voice-assisted input
Imports
Synchronization
Categorization
Budgets
Analytics
Reports
Notifications
Integrations
Security and permissions
Authentication
Supabase cloud persistence
RLS and cloud security controls
Offline/local cache and synchronization
Premium/paid-feature foundation
Multi-device readiness
Cross-Cutting Requirements
Security & Permissions
Audit & Traceability
Data Integrity
Idempotency & Consistency
Observability & Monitoring
Performance & Scalability
Explicit Future / Out of Scope Unless Promoted

The following remain OUT OF SCOPE unless explicitly promoted by a later approved rule:

Bank integrations
Collaboration / shared finances
Advanced accounting beyond the approved financial accounting model
Additional authentication providers beyond the currently approved authentication plan
Other speculative capabilities not explicitly approved

Do not implement an OUT-OF-SCOPE capability merely because it appears in the architecture.

Do not treat an IN-SCOPE capability as future merely because an older rule or document described it as future.

Status:
[APPROVED]

CROSS-CUTTING CHANGE POLICY
Rule 54: Plan Before Big Cross-Cutting Features

Before implementing a project-wide feature such as:

Localization
RTL
Light Theme
Multi-currency
Supabase
Offline synchronization
Monetization
Authentication
Scheduled Financial Actions
Financial Projection
Investments
Debt
SMS input/integration
Prediction
Voice Typing
Live market data / pricing

first provide:

Scope
Affected layers/files
Migration strategy
Risks
Rollback considerations
Testing strategy

Then confirm before making broad changes.

Status:
[APPROVED]

SAFETY / RISK RULES
TESTING / FINANCIAL INTEGRITY RULES
Rule 55: Financial Integrity Testing

Any change that can affect:

Transactions
Ledger Entries
Balances
Transfers
Goals
Allocations
Commitments
Multi-currency calculations
Investment valuation
Financial projections
Exchange-rate and live market-price handling

must include or update automated tests appropriate to the affected behavior.

At minimum, financial-engine tests must verify invariants such as:

Every balanced double-entry transaction keeps total debits equal to total credits.
Transaction create/update/delete keeps Ledger Entries synchronized.
No orphan LedgerEntries remain after supported lifecycle operations.
Balance calculations remain consistent with the approved Ledger/Transaction source of truth.
Currency conversion tests explicitly verify precision and rounding behavior.
Investment valuation tests verify quantity × price and any currency conversion using the approved rounding policy.

A feature is not considered financially complete merely because the UI works.

Status:
[APPROVED]

Rule 56: Regression Testing for Financial Changes

When a financial rule or engine changes, tests covering existing behavior must be preserved and updated rather than replaced with only new happy-path tests.

High-risk changes require tests for:

Normal cases
Zero values where valid
Boundary values
Update/delete lifecycle
Failure/rollback behavior where applicable
Repeated execution/idempotency where applicable
Multi-currency rounding
Historical data compatibility

Status:
[APPROVED]

PRODUCTION OBSERVABILITY
Rule 57: Error Logging and Monitoring

Before production launch, Wafferly must have production error monitoring and logging appropriate for a financial application.

The monitoring solution may use a service such as Sentry or an equivalent approved platform.

Monitoring must cover, where technically appropriate:

Unhandled Flutter/Dart exceptions
Critical service/repository failures
Sync failures
Authentication failures
Payment/subscription failures
Database/API failures
Important financial-operation failures

Do NOT log:

Passwords
Authentication tokens
Private keys
Payment secrets
Sensitive financial data unnecessarily
Personally sensitive data unless required and protected

Monitoring must be privacy-conscious and must not become a second source of financial truth.

Status:
[APPROVED]

Rule 58: Production Monitoring Readiness

Before release, define:

What errors are monitored
What constitutes a critical financial error
Alert severity
Retention policy
Privacy/PII handling
Who reviews critical alerts
How incidents are investigated
How financial corruption/data-loss incidents are escalated

A monitoring SDK must not be added blindly; its privacy, performance, and data-capture configuration must be reviewed.

Status:
[APPROVED]

RULES FILE GOVERNANCE
Rule 59: Rules File Is the Project Source of Truth

Wafferly_Project_Rules.md is the canonical project-rules document.

It is the authoritative reference for architectural and product-scope decisions recorded in the file.

Other chats, temporary notes, generated code, or previous drafts do not override an approved rule automatically.

Status:
[APPROVED]

Rule 60: Adding or Changing a Rule

A new rule or a change to an approved rule must:

State the exact decision.
Identify whether it is:
[PROPOSED]
[APPROVED]
[DEPRECATED]
Explain any important affected areas.
Check for conflicts with existing rules.
Update the affected rule instead of silently creating a contradictory duplicate.
Preserve the history/intent where practical.

Do not silently rewrite project rules during implementation.

Status:
[APPROVED]

Rule 61: Conflict Resolution Between Rules

If two rules conflict:

STOP implementation of the conflicting part.
Identify the exact conflicting rules.
Determine which decision is newer and explicitly approved.
Update/deprecate the obsolete rule.
Record the resolved decision in this file.
Only then continue implementation.

A newer chat statement must not automatically be treated as an approved permanent project rule until it is deliberately incorporated into this file.

Status:
[APPROVED]

Rule 62: Scope Changes Must Be Explicit

Moving a feature between:

Current / In Scope
Future / Out of Scope

is a project decision.

Examples include:

Supabase
Multi-currency
Investments
Premium features
Bank integrations
Collaboration

Such changes must be reflected in this file before implementation begins across the project.

Status:
[APPROVED]

SAFETY / RISK RULES
Rule 63: Financial Risk Must Be Explicit

The owner is not expected to be a programmer.

When a change can affect:

Money
Transactions
Balances
Ledger
Data deletion
Synchronization
Security
Authentication
Payments

explicitly flag the risk before implementation.

Never silently make a potentially destructive architectural change.

Status:
[APPROVED]

Rule 64: Data Loss Prevention

Never perform destructive migration or deletion without first establishing:

What data is affected
Whether a backup exists
Whether the operation is reversible
What happens to related entities

Financial history must not be silently lost.

Status:
[APPROVED]

IMPLEMENTATION ORDER
Rule 65: Preferred Development Order

When building major capabilities, prefer:

Domain model / ownership
Existing engine verification
Service layer
Repository boundary where justified
Persistence
Controller / ViewModel
UI
Tests
Runtime verification

Do not begin with UI logic that later has to be extracted.

Status:
[APPROVED]

MASTER PRINCIPLE
Rule 66: Preserve the Source of Truth

Every important concept must have one authoritative owner.

Examples:

Transaction
→ actual financial movement

Ledger
→ accounting entries derived from transactions

Goal
→ goal purpose/lifecycle

Budget
→ spending-control policy

Allocation
→ reservation intent

Commitment
→ future financial event

Projection
→ calculated view of current state

Liability Account
→ current debt financial position

Manage
→ debt workflow / operational UX

Supabase
→ cloud persistence source of truth (current)

Hive
→ local cache/offline persistence

UI
→ presentation only

When two components appear to own the same truth, stop and resolve the ownership before adding more code.

Status:
[APPROVED]

DEBT DOMAIN / SCREEN OWNERSHIP RULES
Rule 67: Accounts and Manage Have Separate Responsibilities

Accounts is responsible for the structural financial network and current financial position. Manage is responsible for debt workflows and operational UX.

Where a debt concept requires a financial position, the approved Liability Account model remains the financial source of truth. Manage must not maintain an independent authoritative debt balance.

Credit Cards and Reusable Installment Facilities may be real operational liability Accounts. Loans, Borrowed Money, Temporary Debt, and other debt concepts requiring a liability position are represented internally through the approved liability Account architecture and are entered through their approved Manage workflows.

Status:
[APPROVED]

Rule 68: Debt Display Items Must Remain Navigable

Debt categories or rollups shown in Accounts may be display/navigation representations rather than direct CRUD entries. They must remain navigable when an approved underlying workflow exists.

Selecting a debt display item must reuse the underlying details/workflow and must not create a second CRUD implementation or financial source of truth.

The Accounts + Add flow must not expose duplicate generic Account-creation paths for workflow-owned debt concepts such as Loans, Borrowed Money, or Temporary Debt.

Status:
[APPROVED]

Rule 69: Debt Financial Mutations Use the Canonical Pipeline

Any debt workflow that creates an actual financial movement must use the approved Financial Operation Execution Engine and the authoritative Transaction / Ledger pipeline.

Manage, DebtsScreen, or any debt-specific UI must not directly mutate authoritative balances or Ledger records and must not create an independent debt balance store.

Future payment expectations remain distinct from executed Transactions and should be represented through the approved Commitment / Schedule architecture until actual execution occurs.

Status:
[APPROVED]

Rule 70: Debt Status Is Derived, Not Hardcoded

Debt status such as Overdue, Due Soon, and Upcoming is derived presentation state. It must be calculated from the approved future-payment information, including applicable Commitments, Schedule Rules, Schedule Occurrences, due dates, and settlement state.

Do not hardcode these statuses in the UI or maintain them as an independent financial source of truth.

Before introducing a new debt-status service, verify whether the existing Commitment / Schedule / Projection architecture already provides the required information.

Rotating Savings / Saving Circle must not automatically become an active liability merely because an expected date has arrived. Actual receipt requires the appropriate user confirmation and approved financial operation.

Status:
[APPROVED]

END OF RULES