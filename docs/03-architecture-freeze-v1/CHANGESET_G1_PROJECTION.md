# Gate G — Financial Action Projection Changeset

## Scope

This changeset implements the approved boundary between scheduled occurrences and the Financial Action Center projection.

## Runtime behavior

- `ScheduleOccurrence` remains the independent domain/execution identity.
- Multiple occurrences of the same actionable commitment may appear as one projected Action Center group.
- The group keeps all underlying occurrence contexts.
- A grouped action opens an explicit selection surface; selected occurrences are executed individually through the existing executor.
- Non-commitment actions remain individual projections.
- Schedule cursor advancement reloads the latest persisted rule before advancing.
- Cursor advancement catches up over already-completed future occurrence slots.

## Verification status

**Pending user-side `flutter test`.** The previous test failure was caused by the old UI assumption that every occurrence renders as a separate card. This changeset replaces that assumption with a projection contract and adds regression coverage.

## Expected Git commit

```bash
git add .
git commit -m "group scheduled actions by commitment"
```
