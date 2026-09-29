# Wafferly — Accounts UI V1 Checklist

## Scope

This pass prepares the Accounts module for the Credit Card account creation and testing flow.

The Financial Foundation remains frozen. This pass does not implement deferred Credit Card Payment/Settlement functionality.

## Completed in this pass

- [x] Accounts overview labels clarified by financial group.
- [x] Group account cards show user-facing account type labels instead of persisted technical IDs.
- [x] Group account cards navigate to the existing Account Details screen.
- [x] Dedicated one-page Credit Card creation screen added.
- [x] Credit Card creation creates a real liability `Account` with type `creditCard`.
- [x] Credit Card creation persists a linked `CreditCardProfile`.
- [x] Credit limit remains `Money`-native in the Credit Card profile.
- [x] New Credit Card starts with zero outstanding exposure without creating a fake opening-balance transaction.
- [x] Bank/issuer and optional last-four digits are stored on the Account metadata.
- [x] Physical/Virtual card kind is stored as Credit Card profile configuration.
- [x] Existing Account edit flow preserves provider and account-number metadata.

## Verification pending on the user's Flutter environment

- [ ] Targeted Credit Card account creation test.
- [ ] Full `flutter analyze` — 0 errors.
- [ ] `flutter test test/accounts/credit_card_account_creation_test.dart` — PASS.
- [ ] `flutter test test/architecture` — PASS.
- [ ] `flutter test` — PASS.
- [ ] UI smoke: Accounts → Money You Owe → Create Account → Credit Card → Create → Account Details.

## Intentionally not included

- Credit Card Payment Operation.
- Payment allocation integration.
- Overpayment enforcement runtime.
- Early settlement.
- Late fees.
- Restructuring / refinancing.
- Statement close lifecycle.

These remain Financing Phase 2 unless separately promoted into scope.
