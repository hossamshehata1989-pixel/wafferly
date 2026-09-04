# Wafferly — Codex Agent Instructions

## 1. Purpose

You are working on the Wafferly project.

This file defines **how you must operate while working on the repository**.

It does NOT define the project's architecture, financial rules, product scope, or domain decisions.

Those decisions are defined in:

`Wafferly_Project_Rules.md`

---

## 2. Project Rules Are the Source of Truth

Before making meaningful changes, read and follow:

`Wafferly_Project_Rules.md`

The Rules file is the authoritative source for:

* Architecture
* Domain ownership
* Financial behavior
* Product scope
* ADR decisions
* Security requirements
* Data integrity
* Migration requirements
* Testing requirements
* Cross-cutting project decisions

Do NOT duplicate those rules in this file.

### Conflict Priority

If this file and `Wafferly_Project_Rules.md` ever appear to conflict:

**`Wafferly_Project_Rules.md` takes precedence.**

Do not silently reinterpret or modify the Rules file to resolve a conflict.

If an approved rule prevents the requested implementation:

1. Stop the conflicting part.
2. Identify the relevant rule.
3. Explain the conflict.
4. Ask for a project decision when necessary.

---

# 3. Inspect Before You Change

Never start modifying code based only on the user's description of the existing implementation.

First inspect the repository.

Before introducing or changing architecture:

* Search for existing implementations.
* Locate the relevant models.
* Locate existing services.
* Locate existing repositories.
* Locate existing engines.
* Locate existing controllers/ViewModels.
* Locate persistence code.
* Locate related tests.
* Understand the current data flow.

Prefer modifying or reusing existing architecture over creating parallel implementations.

Do not create new architecture simply because it appears theoretically cleaner.

---

# 4. Do Not Guess

When working on the repository:

* Do not assume a method exists.
* Do not assume a class has a particular responsibility.
* Do not assume a data flow without verifying it.
* Do not assume a screen is the source of truth.
* Do not assume a service is unused.
* Do not assume a migration is safe.
* Do not assume an old implementation can simply be deleted.

Verify first.

If repository evidence is insufficient, inspect further rather than inventing an implementation.

---

# 5. Respect Existing User Changes

Before making changes, inspect the repository state.

Do not overwrite, revert, delete, or modify unrelated work that already exists.

If the working tree contains user changes:

* Preserve them.
* Do not reset them.
* Do not clean them.
* Do not rewrite them.
* Do not assume they are mistakes.

Only modify files relevant to the requested task unless a broader change has been explicitly approved.

---

# 6. Cross-Cutting Changes Require Planning

For major or project-wide changes, follow the planning requirements defined in `Wafferly_Project_Rules.md`.

Before broad implementation:

1. Inspect the repository.
2. Identify the scope.
3. Identify affected files/layers.
4. Identify dependencies.
5. Identify migration requirements.
6. Identify risks.
7. Identify rollback considerations.
8. Identify the testing strategy.
9. Present the implementation plan.

Do not immediately perform a large cross-cutting modification simply because the requested feature is clear.

For high-risk changes, wait for explicit approval of the implementation plan before broad execution.

---

# 7. Controlled Implementation

When implementing an approved plan:

* Work in logical stages.
* Keep changes focused.
* Avoid unrelated refactoring.
* Validate after meaningful stages.
* Do not silently expand scope.
* Do not introduce speculative features.

If implementation reveals that the original plan is unsafe or incompatible with the existing architecture:

STOP.

Explain the discovery before continuing with a substantially different approach.

---

# 8. Financial and High-Risk Work

The financial rules themselves are defined in:

`Wafferly_Project_Rules.md`

When a task touches financial behavior, treat it as high-risk.

Examples include:

* Money
* Transactions
* Ledger
* Balances
* Transfers
* Goals
* Allocations
* Commitments
* Financial projections
* Investments
* Multi-currency
* Exchange rates
* Persistence
* Data migration
* Synchronization
* Authentication
* Security
* Payments

Before making such changes:

* Inspect the existing implementation.
* Identify the authoritative source of truth.
* Identify affected components.
* Identify data-integrity risks.
* Identify required tests.
* Follow the applicable Rules.

Never silently make a destructive or potentially irreversible financial change.

---

# 9. Migrations

Treat migrations as controlled operations.

Before changing persisted data or performing a structural migration:

* Identify affected data.
* Identify affected entities and relationships.
* Determine whether a backup exists.
* Determine whether rollback is possible.
* Determine how the migration will be validated.
* Preserve compatibility with existing data where required.

Never perform destructive migration merely to make the new implementation compile.

Never delete historical financial data without explicit justification and approval.

---

# 10. No Blind Global Replacement

Do not perform broad search-and-replace operations merely because a pattern appears frequently.

Examples:

* Replacing every `double`
* Renaming every matching identifier
* Replacing every occurrence of a class name
* Changing every UI value with a similar type

First determine the semantic meaning of each occurrence.

A syntactically similar value may have a completely different responsibility.

Use repository-wide searches as an inventory tool, not as permission for blind replacement.

---

# 11. Architecture Preservation

Preserve the project's existing separation of responsibilities.

Before adding a new component, determine whether an existing component already owns the responsibility.

Do not introduce duplicate:

* Business logic
* Financial calculations
* Sources of truth
* Persistence paths
* Domain engines
* Synchronization logic
* Validation systems

If an existing engine/service already owns the required behavior, use it unless the approved project architecture explicitly requires a change.

---

# 12. UI Changes

Before changing or creating UI:

* Inspect existing screens.
* Inspect existing reusable widgets.
* Inspect existing spacing and sizing conventions.
* Inspect existing theme conventions.
* Inspect responsive helpers.
* Follow the applicable Rules.

Do not redesign unrelated screens.

Do not introduce a separate visual system for a single feature.

UI should consume application/domain state rather than becoming the location of business logic.

---

# 13. Tests Are Part of the Implementation

When a change affects behavior, determine what existing tests cover it.

When appropriate:

* Add tests.
* Update affected tests.
* Preserve existing regression coverage.
* Test important edge cases.
* Test failure behavior where relevant.

For financial or migration work, testing is part of the implementation—not an optional final step.

Follow the detailed testing requirements in `Wafferly_Project_Rules.md`.

---

# 14. Validation

After implementation, validate the result.

For Flutter/Dart changes, use the appropriate project commands, including where applicable:

```bash
flutter analyze
flutter test
```

Also inspect the repository state:

```bash
git status
git diff
```

Check for:

* Analyzer errors
* Analyzer warnings
* Failed tests
* Unused imports
* Broken references
* Unexpected files
* Unintended architectural changes
* Debug code
* Secrets
* Accidental migrations
* Duplicate business logic
* Changes outside the approved scope

Do not claim completion merely because the application launches successfully.

---

# 15. Git Safety

Before major changes:

* Check `git status`.
* Prefer a dedicated branch for major migrations when appropriate.
* Keep the change isolated.
* Review the final diff.

Never use destructive Git commands such as:

```bash
git reset --hard
git clean
```

or equivalent destructive operations unless explicitly authorized.

Never discard user work to resolve a problem.

---

# 16. Dependencies

Do not add a package merely because it appears convenient.

Before adding or replacing a dependency:

1. Determine whether the existing project already provides the required capability.
2. Determine whether the dependency is actually necessary.
3. Consider its effect on architecture and maintenance.
4. Explain the reason for adding it when the change is meaningful.
5. Avoid unnecessary dependency growth.

Do not replace an existing implementation with a package without understanding the consequences.

---

# 17. Scope Discipline

Implement the requested task within the approved project scope.

Do not add unrelated:

* Features
* Refactors
* Architecture
* UI redesigns
* Dependencies
* Infrastructure
* Abstractions

Do not implement an out-of-scope capability merely because it would be useful.

Do not move an approved capability into future scope without following the project's rule-governed process.

---

# 18. When to Stop and Ask

Stop and ask for clarification or approval when:

* Two approved architectural decisions appear incompatible.
* The requested implementation would violate an approved Rule.
* A destructive migration is required.
* Existing user changes would be affected.
* The safest implementation requires a major architectural decision.
* The requested behavior is ambiguous and cannot be safely inferred.
* Repository evidence contradicts the assumed architecture.
* The implementation would substantially expand the approved scope.
* A financial-data integrity risk cannot be resolved safely.

Do not guess when the consequence can affect financial correctness or user data.

---

# 19. Final Review Before Completion

Before reporting a task as complete, verify:

### Implementation

* The requested behavior is implemented.
* Existing architecture has been respected.
* No unnecessary architecture was introduced.

### Scope

* Only relevant areas were changed.
* No unrelated refactoring was introduced.

### Quality

* Code is consistent with the existing project.
* No obvious dead code or debugging artifacts remain.

### Validation

* Relevant tests were executed.
* `flutter analyze` was executed where applicable.
* `flutter test` was executed where applicable.
* `git diff` was reviewed.
* `git status` was reviewed.

### Safety

* No user changes were overwritten.
* No secrets were introduced.
* No destructive migration was performed without authorization.
* Financial integrity was considered for financial changes.

If an important validation could not be performed, explicitly state that in the final report.

---

# 20. Final Report

When the task is complete, report concisely:

### Changed

What was actually changed.

### Verified

What commands/tests were executed and their results.

### Not Changed

Important areas deliberately left untouched.

### Remaining Risks

Any unresolved issue, limitation, or follow-up requirement.

Do not claim something was tested if it was not actually tested.

Do not claim something was implemented if it was only planned.

---

# 21. Operating Principle

The project Rules define **what Wafferly must be**.

This file defines **how Codex must work while changing it**.

Therefore:

**Inspect before changing.**

**Verify before assuming.**

**Plan before broad changes.**

**Preserve user work.**

**Protect financial and user data.**

**Reuse existing architecture before creating new architecture.**

**Test before claiming completion.**

**Review the final diff.**

When uncertainty affects architecture, financial correctness, data integrity, security, or irreversible changes:

**STOP AND ASK.**
