# Gate G1 — Last Change Set

## Files changed in this gate

### Production code — 4 files
1. `lib/services/providers/commitment_action_provider.dart`
   - Only active commitments create actions.
   - Completed occurrences are suppressed.
   - Missed recurring occurrences are materialized under the Stack policy.
   - Each occurrence is evaluated using its own due date.

2. `lib/services/commitment_action_provider.dart`
   - Removed the second implementation.
   - Kept only a compatibility export to the production provider.

3. `lib/services/schedule_occurrence_service.dart`
   - Added `getOrCreateOccurrencesThroughDate()`.
   - Added stacked missed-occurrence generation.
   - Added recurrence cursor catch-up over already-completed stacked occurrences.

4. `lib/services/schedule_evaluator.dart`
   - Added `evaluateDueDate()` so each occurrence can be evaluated independently.

### Tests — 2 files
5. `test/services/commitment_action_provider_integration_test.dart`
   - Now imports the production provider.
   - Added inactive-status coverage.
   - Added completed one-time suppression coverage.
   - Added stacked missed-occurrence coverage.

6. `test/services/schedule_occurrence_service_test.dart`
   - Added stacked occurrence generation regression coverage.

### Documentation — updated
7. `docs/03-architecture-freeze-v1/06-PRE-CREDIT-CARD-IMPLEMENTATION-CHECKLIST.md`
   - Updated immediately after Gate G1.
8. `docs/03-architecture-freeze-v1/IMPLEMENTATION_LOG_V1.1.md`
   - Records Gate G1 and the verification limitation.

## Verification status

The supplied source archive does not contain `pubspec.yaml`, and Flutter/Dart are unavailable in this review environment. Therefore the new tests have been added but not executed here. The gate must be locally verified in the user's full project before being considered fully closed.
