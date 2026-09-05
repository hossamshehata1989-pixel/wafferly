# Wafferly — Cross-Cutting Implementation Preparation

**Last synced with `Wafferly_Project_Rules.md`:** Rules through Rule 70
(Debt Domain / Screen Ownership) — 2026-09-05.
When the Rules file changes in a way that adds/renumbers rules or moves
scope, update this line and re-check every section below against it.

## Purpose

This file is a compact implementation checklist for project-wide
capabilities that must be considered while building individual screens
and domains.

It does NOT replace `Wafferly_Project_Rules.md` or the approved ADRs.
Those documents remain the authoritative source of project rules and
architecture. If anything here conflicts with them, the Rules file wins
(see Rule 61).

---

## 0. Data Access Boundary (check this first, every screen)

Screens and widgets must never call `Hive.box(...)` or a Supabase client
directly, and business/money calculations must never live inside
`build()`, a widget callback, or a `State` class. (Rule 12–14.)

Required flow:

UI → Controller / ViewModel → Service / Use Case → Repository → Data Source

If you're about to add a data-loading method straight on a screen's
State class, or read a Hive box "just this once" from a widget — stop
and route it through a service first. This was the actual bug found in
the first `ManageScreen` review; check for it explicitly, don't assume
it won't recur.

---

## 1. Money Representation (check this before adding any money field)

Money type is under an active, project-wide migration decision — do
**not** assume `double` is final for any new money-bearing field,
calculation, or persisted value. (Rule 24–25.)

Before adding a new field that holds an amount, quantity, price, or
exchange rate:
- Flag it explicitly rather than defaulting to `double` silently.
- Non-financial `double`s (UI opacity, animation, coordinates) are fine
  and out of scope for this rule — the distinction is semantic meaning,
  not the type keyword itself.
- Do not perform a partial/local Decimal conversion for one feature;
  this is a whole-project migration (Rule 24).

---

## 2. Localization & RTL

The application is planned for:
- English
- Arabic

New screens and components must be designed so they can support
localization and RTL without structural rewrites.

Consider:
- Text direction
- Alignment
- Directional icons
- Padding/margins
- Dates
- Numbers
- Currency formatting
- Dialogs
- Lists
- Text wrapping

Do not hard-code architecture around English-only assumptions.

---

## 3. Supabase Readiness

Supabase is part of the pre-launch architecture.

New code should preserve:

UI → Controller / ViewModel → Service / Use Case → Repository → Data Source

Do not couple UI directly to Hive, Supabase, or database tables.

Supabase is the cloud persistence source of truth where cloud-backed
data is implemented. Hive remains part of the local/offline strategy.

Do not design new features in a way that requires rewriting their
domain logic when persistence moves to Supabase.

---

## 4. Authentication & User Ownership

Cloud-backed financial data must have explicit user ownership.

The planned authentication direction uses Supabase Auth.

New domain entities and persistence decisions must leave a clear path
for:
- `user_id`
- Authentication
- Row Level Security (RLS)
- Multi-device access

Authentication concerns must remain separated from financial-domain
logic.

---

## 5. Security & Secure Storage

Never place:
- Supabase service-role keys
- Payment secrets
- Private API credentials
- Encryption secrets

inside the Flutter client.

Sensitive local data must use an approved secure/encrypted storage
strategy where required.

Hive encryption and secure platform storage are separate concerns.

Cloud communication must use secure transport.

Do not introduce security shortcuts for convenience.

---

## 6. Offline & Synchronization

Wafferly follows an offline-first direction.

Conceptually:

UI → Services → Repository → Local Cache → Sync → Supabase

Synchronization is a data-consistency mechanism. It must NOT become a
second Financial Engine or duplicate financial logic.

Future sync must account for:
- Operation identity
- Ordering where required
- Retry safety
- Idempotency
- Conflict resolution
- Delete/archive conflicts

---

## 7. Premium / Paid Features

Premium functionality must be based on product entitlements, not
scattered UI flags.

Preferred direction:

Subscription / Entitlement → Feature Access Policy → UI + Services

Do not rely only on hiding buttons.

Server-backed premium capabilities must also be protected server-side
where applicable.

Payment-provider secrets remain server-side.

---

## 8. Multi-Device Readiness

Architecture should allow one authenticated user to access the same
cloud-backed financial data from multiple devices.

Do not introduce local-only architectural decisions that would make
future synchronization or multi-device support impossible.

---

## 9. Dark Theme & Responsive UI

Current priority is the existing Wafferly Dark Theme.

New screens should follow the established visual language and existing
widgets/components.

Use `ResponsiveMetrics` where the project already provides it.

Avoid arbitrary fixed dimensions when responsive metrics are
appropriate.

Light Theme is a separate future implementation phase and must not be
created by simply replacing dark backgrounds with white.

---

## 10. Debt Domain / Screen Ownership (new — see Rule 67–70)

Accounts owns the structural financial network and current financial
position. Manage owns debt workflows and operational UX — it must
never keep an independent authoritative debt balance.

Before touching a debt screen or workflow, check:
- Does this debt concept need a financial position? → it must be
  represented as a Liability Account, not a second balance store.
- Is this a debt display/rollup item? → it must stay navigable to the
  real underlying workflow, not become a second CRUD path.
- Does this mutate actual money? → it must go through the Financial
  Operation Execution Engine / Transaction / Ledger pipeline, never a
  direct write from Manage/DebtsScreen UI.
- Is a status (Overdue/Due Soon/Upcoming) being shown? → it must be
  derived from Commitments/Schedules/Projection, never hardcoded or
  stored as an independent fact.

---

## 11. Cross-Cutting Features

The approved pre-launch direction includes:
- SMS input/integration
- Prediction / forecasting
- Voice Typing / voice-assisted input
- Notifications
- Imports
- Categorization
- Analytics
- Reports
- Integrations
- Budgets
- Investments
- Multi-Currency
- Live FX / market data
- Premium features
- Authentication
- Supabase
- Offline synchronization
- Multi-device readiness

When implementing a cross-cutting capability, first define:
- Scope
- Affected layers/files
- Migration strategy
- Risks
- Rollback considerations
- Testing strategy

---

## 12. Financial Safety Boundary

All financial features must preserve the project's engine ownership.

Actual financial movement:
Financial Operation Execution Engine → Transaction / Ledger → Balance

Future planning state:
Planning Engine → Commitments / Allocations / Schedules / Projections

UI must not become a financial engine or create an independent source
of truth.

---

## 13. Quality & Production Readiness

Financial changes require appropriate:
- Automated tests
- Regression tests
- Integrity checks
- Idempotency checks where applicable
- Audit / traceability consideration
- Error monitoring
- Privacy-conscious logging
- Performance consideration

A feature is not financially complete merely because its UI works.

---

## Authority

This checklist is an implementation aid, not a rules source.

Authoritative documents, in order:
1. `Wafferly_Project_Rules.md`
2. Approved ADRs (including the Debt Domain ADR)
3. `AGENTS.md` — how Codex/Claude Code must operate while implementing
   the above (no domain rules duplicated there either)

If this file conflicts with any authoritative source, stop and follow
the conflict-resolution process defined by the Master Rules File
(Rule 61) — do not silently trust whichever document you opened first.
