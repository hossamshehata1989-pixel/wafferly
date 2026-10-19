# Wafferly — Synthetic SMS Semantic Test Corpus V1

**Status:** First synthetic golden set for review and parser development; not provider-verified templates.  
**Date:** 2026-10-18  
**Corpus ID:** `wafferly_sms_synthetic_semantic_corpus_v1`

## Why this corpus exists

This corpus gives the SMS/IFUP implementation expected semantic outcomes before writing institution-specific regex/templates. It tests classification, amount/currency selection, event state, ambiguity handling, non-financial filtering and duplicate-match safeguards. Every message is invented for tests. No real customer SMS was used. Provider IDs are test labels only; wording does **not** claim to reproduce the real SMS format of CIB, NBE, Banque Misr, Vodafone Cash or InstaPay.

## Files

- `test/fixtures/sms/synthetic_sms_corpus_v1.json` — canonical machine-readable corpus including expected results and safety assertions.
- `test/fixtures/sms/synthetic_sms_corpus_v1.csv` — spreadsheet-friendly view for reviewing fixtures.
- `test/support/sms_synthetic_corpus.dart` — test-only JSON reader and structural/safety validator.
- `test/financial_understanding/sms_synthetic_corpus_reader_test.dart` — tests for the reader and corpus invariants.
- This document — scope, invariants, review rules and implementation gates.

## Coverage

- **72 cases** total.
- Cases are distributed across the five named provider-context groups and a cross-provider `unknown` group; the named counts include a few provider-bound reconciliation/status-transition tests.
- Both Arabic-Egyptian and English message scenarios (**36 each**).
- Includes completed events, pending authorizations/transfers, refunds, reversals, fees, card purchases/payments, transfer and cash movement semantics, missing fields, multiple amounts, balance-only messages, OTP, promotions, reminders, failed transactions, future intent, exact replay, and existing-transaction matching safeguards.

### Counts by provider label

| Provider label | Cases |
|---|---:|
| `banque_misr` | 12 |
| `cib` | 13 |
| `instapay` | 12 |
| `nbe` | 15 |
| `unknown` | 8 |
| `vodafone_cash` | 12 |

### Counts by expected disposition

| Disposition | Cases | Meaning |
|---|---:|---|
| `clarify` | 25 | Missing, conflicting or risky semantics require clarification. |
| `ignore` | 16 | Do not create a financial transaction draft from this message alone. |
| `match_existing` | 2 | A duplicate/reconciliation scenario; never create a second financial effect. |
| `propose` | 29 | A semantic draft can be proposed, still requires user review. |

## Non-negotiable assertions

1. `financial_write_allowed_from_fixture` is `false` for every case. The fixture runner must never call `FinancialOperationEngine` or save real transactions.
2. A `propose` result is not permission to save. It must produce only a reviewable proposal/draft.
3. An ambiguous or unsupported case must remain unresolved; do not force it into an expense/income.
4. `pending` is event status and is not a draft lifecycle state. Do not treat a pending authorization as a final posted expense.
5. An amount in an available-balance sentence is not the transaction amount. The amount-only test does not show proof of a transaction.
6. Same amount is insufficient for deduplication. Use provider/account, event type, amount, currency, payee, event date/time, reference if available, and other verified fields. Uncertain matches require review.
7. Incoming deposits/transfers and cash withdrawals/top-ups can be movements between the user’s own money pools; avoid inflating income/expenses without context.
8. A canceled card authorization with no final debit is not automatically a reversal of a posted financial transaction; clarify whether it should update an earlier pending record.
9. A reversal proposal must keep the original transaction unresolved until safely matched; amount-only matching is not sufficient.
10. Refund/reversal is not a new purchase and must not silently delete or overwrite the original transaction.
11. Credit-card payments can be understood as proposals but command mapping remains blocked until project documents and implementation explicitly support the operation.
12. OTP values in this set are fictional. The implementation should ignore OTP/security codes and must not store/log them.

## Data model mapping

The corpus uses the same semantic vocabulary as the initial IFUP foundation patch:
- `event_type`: `expense`, `income`, `transfer`, `creditCardPurchase`, `creditCardPayment`, `fee`, `installment`, `refund`, `reversal`, `unknown`.
- `direction`: `debit`, `credit`, `transfer`, `unknown`.
- `event_status`: `pending`, `posted`, `reversed`, `unknown`.
- `disposition`: test-harness decision for proposing, clarification, ignoring, or recognizing an existing match; this is not a `FinancialDraftStatus` value.
- `unresolved_fields`: fields that cannot safely be set without a user or deterministic clarification; `originalTransaction` marks the required link to an original event before a reversal can be mapped.

## How to use it

1. Keep all fixtures under `test/fixtures/sms/`; never bundle these samples as actual provider templates in a production registry.
2. Start by testing `FinancialTextNormalizer` against Arabic-Indic/Persian digits, separators, whitespace and diacritics.
3. Use the corpus loader/validator in `test/support/sms_synthetic_corpus.dart`. It checks unique IDs, supported enum values, exact decimal strings, references such as `replay_of`, synthetic provenance, unverified provider status, review invariants, and that no fixture allows direct financial writes.
4. Add deterministic recognizers only for messages covered by verified specifications or well-tested templates. The expected outcomes below are semantic targets; they do not imply that a regex parser already exists.
5. For any provider template claimed to mirror real formats, maintain a separate source/verification record: provider, sample provenance and consent/sanitization, known template version, positive fixtures, negative fixtures, last review, and change-detection plan.
6. Run `flutter test test/financial_understanding` and `flutter analyze` in the full current project after integrating any source/test changes. The reader tests were authored but could not be executed in the preparation environment because the Flutter/Dart SDK was not available in that environment. Run `flutter test test/financial_understanding/sms_synthetic_corpus_reader_test.dart` and `flutter analyze` in the complete project before relying on them.

## Known limits / not covered yet

- The set does not establish actual current SMS message formats for any named institution.
- No native Android inbox reader, permissions or broadcast receiver is included.
- No live AI provider, local model or cloud AI request is included.
- No production draft persistence, message HMAC fingerprinting, Android Keystore integration, or actual transaction matching engine is implemented by the corpus itself.
- No live financial write or SMS-to-command mapping is authorized by these fixtures.
- This is a first V1 semantic set, not a statistically representative model evaluation set. Expand negatives and include anonymized user-approved samples only after privacy and release-policy review.
