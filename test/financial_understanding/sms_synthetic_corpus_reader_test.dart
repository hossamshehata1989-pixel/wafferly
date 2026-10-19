import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/sms_synthetic_corpus.dart';

const _corpusPath = 'test/fixtures/sms/synthetic_sms_corpus_v1.json';

void main() {
  late Map<String, Object?> rawCorpus;
  late SmsSyntheticCorpus corpus;

  setUpAll(() async {
    final decoded = jsonDecode(await File(_corpusPath).readAsString());
    rawCorpus = _asStringMap(decoded);
    corpus = SmsSyntheticCorpus.fromJson(rawCorpus);
  });

  test('loads the full V1 corpus and balances Arabic and English cases', () {
    expect(corpus.corpusId, 'wafferly_sms_synthetic_semantic_corpus_v1');
    expect(corpus.version, '1.0.0');
    expect(corpus.cases, hasLength(72));
    expect(corpus.cases.where((c) => c.locale == 'ar-EG'), hasLength(36));
    expect(corpus.cases.where((c) => c.locale == 'en'), hasLength(36));
  });

  test('IDs are stable and unique', () {
    final ids = corpus.cases.map((fixture) => fixture.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.every((id) => id.trim().isNotEmpty), isTrue);
  });

  test('every item is explicitly synthetic and no provider format is verified', () {
    expect(corpus.cases.every((c) => c.sourceType == 'synthetic'), isTrue);
    expect(corpus.cases.every((c) => !c.providerFormatVerified), isTrue);
  });

  test('fixtures never authorize financial writes', () {
    expect(
      corpus.cases.every((c) => !c.expected.financialWriteAllowedFromFixture),
      isTrue,
    );
  });

  test('all proposal, clarification, and existing-match outcomes require review', () {
    for (final fixture in corpus.cases) {
      final disposition = fixture.expected.disposition;
      if (disposition == SmsFixtureDisposition.ignore) {
        expect(fixture.expected.requiresUserReview, isFalse, reason: fixture.id);
      } else {
        expect(fixture.expected.requiresUserReview, isTrue, reason: fixture.id);
      }
    }
  });

  test('every clarification has unresolved fields and other outcomes do not', () {
    for (final fixture in corpus.cases) {
      expect(
        fixture.expected.unresolvedFields.isNotEmpty,
        fixture.expected.disposition == SmsFixtureDisposition.clarify,
        reason: fixture.id,
      );
    }
  });

  test('replay links resolve and point to identical synthetic message text', () {
    final byId = {for (final fixture in corpus.cases) fixture.id: fixture};
    for (final fixture in corpus.cases.where((c) => c.replayOf != null)) {
      final original = byId[fixture.replayOf];
      expect(original, isNotNull, reason: fixture.id);
      expect(fixture.syntheticMessage, original!.syntheticMessage, reason: fixture.id);
      expect(fixture.providerId, original.providerId, reason: fixture.id);
    }
  });

  test('exact monetary amounts are represented as decimal strings', () {
    for (final fixture in corpus.cases) {
      final amount = fixture.expected.amount;
      if (amount != null) {
        expect(amount, matches(RegExp(r'^\d+(?:\.\d+)?$')), reason: fixture.id);
      }
    }
  });

  test('reversal drafts require a reference to the original transaction', () {
    final reversals = corpus.cases.where(
      (c) => c.expected.eventType == SmsFixtureEventType.reversal,
    );
    expect(reversals, isNotEmpty);
    for (final fixture in reversals) {
      expect(
        fixture.expected.unresolvedFields,
        contains('originalTransaction'),
        reason: fixture.id,
      );
      expect(fixture.expected.disposition, SmsFixtureDisposition.clarify, reason: fixture.id);
    }
  });

  test('same amount alone is not treated as an existing match', () {
    final sameAmountOnly = corpus.cases.singleWhere(
      (c) => c.expected.duplicateOrMatchExpectation == 'same_amount_is_not_duplicate',
    );
    expect(sameAmountOnly.expected.disposition, SmsFixtureDisposition.propose);
    expect(sameAmountOnly.expected.requiresUserReview, isTrue);
  });

  test('duplicate IDs are rejected', () {
    final broken = _copyCorpus(rawCorpus);
    final cases = broken['cases'] as List<Object?>;
    final first = _asStringMap(cases.first);
    cases[1] = {..._asStringMap(cases[1]), 'id': first['id']};
    expect(() => SmsSyntheticCorpus.fromJson(broken), throwsFormatException);
  });

  test('a fixture that enables financial writing is rejected', () {
    final broken = _copyCorpus(rawCorpus);
    final cases = broken['cases'] as List<Object?>;
    cases[0] = {
      ..._asStringMap(cases[0]),
      'expected': {
        ..._asStringMap(_asStringMap(cases[0])['expected']),
        'financial_write_allowed_from_fixture': true,
      },
    };
    expect(() => SmsSyntheticCorpus.fromJson(broken), throwsFormatException);
  });

  test('numeric JSON amounts are rejected instead of silently converted to doubles', () {
    final broken = _copyCorpus(rawCorpus);
    final cases = broken['cases'] as List<Object?>;
    cases[0] = {
      ..._asStringMap(cases[0]),
      'expected': {
        ..._asStringMap(_asStringMap(cases[0])['expected']),
        'amount': 245.0,
      },
    };
    expect(() => SmsSyntheticCorpus.fromJson(broken), throwsFormatException);
  });

  test('replay references to absent cases are rejected', () {
    final broken = _copyCorpus(rawCorpus);
    final cases = broken['cases'] as List<Object?>;
    cases[10] = {..._asStringMap(cases[10]), 'replay_of': 'missing_case'};
    expect(() => SmsSyntheticCorpus.fromJson(broken), throwsFormatException);
  });

  test('malformed existing-transaction matching fixtures are rejected', () {
    final broken = _copyCorpus(rawCorpus);
    final cases = broken['cases'] as List<Object?>;
    final index = cases.indexWhere((raw) => _asStringMap(raw)['existing_transaction_fixture'] != null);
    final current = _asStringMap(cases[index]);
    final existing = _asStringMap(current['existing_transaction_fixture']);
    cases[index] = {
      ...current,
      'existing_transaction_fixture': {...existing, 'amount': 245.0},
    };
    expect(() => SmsSyntheticCorpus.fromJson(broken), throwsFormatException);
  });

  test('provider labels cannot be presented as verified templates', () {
    final broken = _copyCorpus(rawCorpus);
    final cases = broken['cases'] as List<Object?>;
    cases[0] = {..._asStringMap(cases[0]), 'provider_format_verified': true};
    expect(() => SmsSyntheticCorpus.fromJson(broken), throwsFormatException);
  });
}

Map<String, Object?> _copyCorpus(Map<String, Object?> original) =>
    _asStringMap(jsonDecode(jsonEncode(original)));

Map<String, Object?> _asStringMap(Object? value) {
  if (value is! Map) throw const FormatException('Expected JSON object in test helper.');
  return <String, Object?>{
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}
