import 'dart:convert';
import 'dart:io';

/// Test-only reader for the synthetic SMS semantic corpus.
///
/// Keep this under test/support: it deliberately has no dependency on the
/// FinancialOperationEngine or any production persistence component.
/// The corpus must never be treated as a real provider-template registry.
enum SmsFixtureDisposition { propose, clarify, ignore, matchExisting }

enum SmsFixtureEventType {
  expense,
  income,
  transfer,
  creditCardPurchase,
  creditCardPayment,
  fee,
  installment,
  refund,
  reversal,
  unknown,
}

enum SmsFixtureDirection { debit, credit, transfer, unknown }

enum SmsFixtureEventStatus { pending, posted, reversed, unknown }

final class SmsSyntheticCorpus {
  SmsSyntheticCorpus._({
    required this.corpusId,
    required this.version,
    required this.createdOn,
    required this.cases,
  });

  final String corpusId;
  final String version;
  final DateTime createdOn;
  final List<SmsSyntheticCase> cases;

  static Future<SmsSyntheticCorpus> loadFile(String path) async {
    final String source;
    try {
      source = await File(path).readAsString();
    } on FileSystemException catch (error) {
      throw FormatException('Could not read SMS corpus at "$path": $error');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('SMS corpus is not valid JSON: ${error.message}');
    }
    return fromJson(decoded);
  }

  static SmsSyntheticCorpus fromJson(Object? value) {
    final root = _stringMap(value, r'$');
    final corpusId = _requiredString(root, 'corpus_id', r'$');
    final version = _requiredString(root, 'version', r'$');
    final createdOnText = _requiredString(root, 'created_on', r'$');
    final DateTime createdOn;
    try {
      createdOn = DateTime.parse(createdOnText);
    } on FormatException {
      throw FormatException(r'$.created_on must be a valid ISO date.');
    }

    if (_requiredBool(root, 'synthetic_only', r'$') != true) {
      throw FormatException(r'$.synthetic_only must be true for this test reader.');
    }
    _validateSourcePolicy(root);
    _validateSchema(root);

    final rawCases = root['cases'];
    if (rawCases is! List) {
      throw FormatException(r'$.cases must be a JSON array.');
    }
    if (rawCases.isEmpty) {
      throw FormatException(r'$.cases must not be empty.');
    }

    final cases = <SmsSyntheticCase>[];
    final ids = <String>{};
    for (var index = 0; index < rawCases.length; index++) {
      final path = r'$.cases[' + '$index]';
      final fixture = SmsSyntheticCase._fromJson(rawCases[index], path);
      if (!ids.add(fixture.id)) {
        throw FormatException('$path.id duplicates fixture ID "${fixture.id}".');
      }
      cases.add(fixture);
    }

    final byId = <String, SmsSyntheticCase>{for (final item in cases) item.id: item};
    for (final fixture in cases) {
      final replayId = fixture.replayOf;
      if (replayId != null) {
        if (replayId == fixture.id) {
          throw FormatException('${fixture.id}.replay_of cannot refer to itself.');
        }
        final original = byId[replayId];
        if (original == null) {
          throw FormatException('${fixture.id}.replay_of refers to unknown ID "$replayId".');
        }
        if (fixture.syntheticMessage != original.syntheticMessage) {
          throw FormatException(
            '${fixture.id} declares a replay of "$replayId" but the message text differs.',
          );
        }
        if (fixture.providerId != original.providerId) {
          throw FormatException(
            '${fixture.id} declares a replay of "$replayId" but the provider test label differs.',
          );
        }
      }

      if (fixture.expected.disposition == SmsFixtureDisposition.matchExisting &&
          fixture.replayOf == null && fixture.existingTransactionFixture == null) {
        throw FormatException(
          '${fixture.id} has disposition match_existing but provides no replay_of or existing transaction fixture.',
        );
      }
    }

    return SmsSyntheticCorpus._(
      corpusId: corpusId,
      version: version,
      createdOn: createdOn,
      cases: List<SmsSyntheticCase>.unmodifiable(cases),
    );
  }

  static void _validateSourcePolicy(Map<String, Object?> root) {
    final policy = _stringMap(root['source_policy'], r'$.source_policy');
    const mustBeTrue = <String>[
      'all_messages_are_invented',
      'not_copied_from_real_sms',
      'provider_labels_are_test_context_only',
      'no_raw_live_sms_should_be_added_without_privacy_review',
    ];
    for (final key in mustBeTrue) {
      if (_requiredBool(policy, key, r'$.source_policy') != true) {
        throw FormatException(r'$.source_policy.' + key + ' must be true.');
      }
    }
    if (_requiredBool(policy, 'contains_real_customer_data', r'$.source_policy')) {
      throw FormatException(r'$.source_policy.contains_real_customer_data must be false.');
    }
  }

  static void _validateSchema(Map<String, Object?> root) {
    final schema = _stringMap(root['schema'], r'$.schema');
    _validateEnumSchema(schema, 'expected.disposition', SmsFixtureDisposition.values.map((e) => _enumJsonName(e)).toSet());
    _validateEnumSchema(schema, 'event_type', SmsFixtureEventType.values.map((e) => e.name).toSet());
    _validateEnumSchema(schema, 'direction', SmsFixtureDirection.values.map((e) => e.name).toSet());
    _validateEnumSchema(schema, 'event_status', SmsFixtureEventStatus.values.map((e) => e.name).toSet());

    final sourceTypes = _requiredStringList(schema, 'source_type', r'$.schema').toSet();
    if (sourceTypes.length != 1 || !sourceTypes.contains('synthetic')) {
      throw FormatException(r'$.schema.source_type must contain only "synthetic".');
    }
    _requiredString(schema, 'amount', r'$.schema');
    _requiredString(schema, 'unresolved_fields', r'$.schema');
    _requiredString(schema, 'financial_write_allowed_from_fixture', r'$.schema');
    _requiredString(schema, 'provider_format_verified', r'$.schema');
  }

  static void _validateEnumSchema(
    Map<String, Object?> schema,
    String key,
    Set<String> expectedValues,
  ) {
    final values = _requiredStringList(schema, key, r'$.schema').toSet();
    if (values.length != expectedValues.length || !values.containsAll(expectedValues)) {
      throw FormatException(r'$.schema.' + key + ' does not match the supported reader values.');
    }
  }

  static String _enumJsonName(SmsFixtureDisposition value) =>
      value == SmsFixtureDisposition.matchExisting ? 'match_existing' : value.name;
}

final class SmsSyntheticCase {
  SmsSyntheticCase._({
    required this.id,
    required this.sourceType,
    required this.providerFormatVerified,
    required this.providerId,
    required this.locale,
    required this.scenario,
    required this.syntheticMessage,
    required this.expected,
    required this.replayOf,
    required this.existingTransactionFixture,
    required this.notes,
  });

  final String id;
  final String sourceType;
  final bool providerFormatVerified;
  final String providerId;
  final String locale;
  final String scenario;
  final String syntheticMessage;
  final SmsSyntheticExpected expected;
  final String? replayOf;
  final Map<String, Object?>? existingTransactionFixture;
  final String notes;

  static SmsSyntheticCase _fromJson(Object? value, String path) {
    final map = _stringMap(value, path);
    final id = _requiredString(map, 'id', path);
    final sourceType = _requiredString(map, 'source_type', path);
    if (sourceType != 'synthetic') {
      throw FormatException('$path.source_type must be "synthetic".');
    }
    final providerVerified = _requiredBool(map, 'provider_format_verified', path);
    if (providerVerified) {
      throw FormatException(
        '$path.provider_format_verified must be false in a synthetic-only corpus.',
      );
    }

    final providerId = _requiredString(map, 'provider_id', path);
    const knownProviderLabels = <String>{
      'cib', 'nbe', 'banque_misr', 'vodafone_cash', 'instapay', 'unknown',
    };
    if (!knownProviderLabels.contains(providerId)) {
      throw FormatException('$path.provider_id "$providerId" is not a supported test label.');
    }

    final locale = _requiredString(map, 'locale', path);
    if (locale != 'ar-EG' && locale != 'en') {
      throw FormatException('$path.locale must be "ar-EG" or "en".');
    }
    final scenario = _requiredString(map, 'scenario', path);
    final message = _requiredString(map, 'synthetic_message', path);
    final expected = SmsSyntheticExpected._fromJson(map['expected'], '$path.expected');
    final replayOf = _nullableString(map, 'replay_of', path);
    final transaction = _nullableMap(map, 'existing_transaction_fixture', path);
    if (transaction != null) {
      _validateExistingTransactionFixture(transaction, '$path.existing_transaction_fixture');
    }
    final notes = _requiredString(map, 'notes', path);

    if (expected.financialWriteAllowedFromFixture) {
      throw FormatException(
        '$path.expected.financial_write_allowed_from_fixture must always be false.',
      );
    }
    if ((expected.disposition == SmsFixtureDisposition.propose ||
            expected.disposition == SmsFixtureDisposition.clarify ||
            expected.disposition == SmsFixtureDisposition.matchExisting) &&
        !expected.requiresUserReview) {
      throw FormatException(
        '$path.expected.requires_user_review must be true for non-ignore outcomes.',
      );
    }
    if (expected.disposition == SmsFixtureDisposition.ignore && expected.requiresUserReview) {
      throw FormatException(
        '$path.expected.requires_user_review must be false for ignore outcomes.',
      );
    }
    if ((expected.disposition == SmsFixtureDisposition.clarify) !=
        expected.unresolvedFields.isNotEmpty) {
      throw FormatException(
        '$path must have unresolved_fields exactly when disposition is clarify.',
      );
    }
    if (expected.eventType == SmsFixtureEventType.reversal &&
        expected.disposition != SmsFixtureDisposition.ignore &&
        !expected.unresolvedFields.contains('originalTransaction')) {
      throw FormatException(
        '$path must mark originalTransaction unresolved before a reversal can be mapped.',
      );
    }
    if (expected.disposition == SmsFixtureDisposition.matchExisting &&
        (expected.duplicateOrMatchExpectation == null ||
            expected.duplicateOrMatchExpectation!.trim().isEmpty)) {
      throw FormatException(
        '$path.expected.duplicate_or_match_expectation is required for match_existing.',
      );
    }

    return SmsSyntheticCase._(
      id: id,
      sourceType: sourceType,
      providerFormatVerified: providerVerified,
      providerId: providerId,
      locale: locale,
      scenario: scenario,
      syntheticMessage: message,
      expected: expected,
      replayOf: replayOf,
      existingTransactionFixture: transaction == null
          ? null
          : Map<String, Object?>.unmodifiable(transaction),
      notes: notes,
    );
  }
}

final class SmsSyntheticExpected {
  SmsSyntheticExpected._({
    required this.disposition,
    required this.eventType,
    required this.direction,
    required this.amount,
    required this.currencyCode,
    required this.eventStatus,
    required this.unresolvedFields,
    required this.requiresUserReview,
    required this.financialWriteAllowedFromFixture,
    required this.duplicateOrMatchExpectation,
  });

  final SmsFixtureDisposition disposition;
  final SmsFixtureEventType eventType;
  final SmsFixtureDirection direction;
  /// Exact decimal string; never parsed through binary floating point.
  final String? amount;
  final String? currencyCode;
  final SmsFixtureEventStatus eventStatus;
  final List<String> unresolvedFields;
  final bool requiresUserReview;
  final bool financialWriteAllowedFromFixture;
  final String? duplicateOrMatchExpectation;

  static SmsSyntheticExpected _fromJson(Object? value, String path) {
    final map = _stringMap(value, path);
    final disposition = _enumFromJson(
      SmsFixtureDisposition.values,
      _requiredString(map, 'disposition', path),
      path + '.disposition',
      aliases: const {'match_existing': SmsFixtureDisposition.matchExisting},
    );
    final eventType = _enumFromJson(
      SmsFixtureEventType.values,
      _requiredString(map, 'event_type', path),
      path + '.event_type',
    );
    final direction = _enumFromJson(
      SmsFixtureDirection.values,
      _requiredString(map, 'direction', path),
      path + '.direction',
    );
    final amount = _nullableString(map, 'amount', path);
    if (amount != null) {
      if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(amount)) {
        throw FormatException('$path.amount must be a positive decimal string or null; do not use doubles.');
      }
      if (amount.replaceAll('.', '').split('').every((digit) => digit == '0')) {
        throw FormatException('$path.amount must be greater than zero when present.');
      }
    }
    final currency = _nullableString(map, 'currency_code', path);
    if (currency != null && !RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw FormatException('$path.currency_code must be a three-letter uppercase currency code or null.');
    }
    final eventStatus = _enumFromJson(
      SmsFixtureEventStatus.values,
      _requiredString(map, 'event_status', path),
      path + '.event_status',
    );
    const allowedUnresolved = <String>{
      'eventType', 'direction', 'amount', 'currencyCode', 'occurredAt',
      'payee', 'sourceAccount', 'destinationAccount', 'eventStatus',
      'originalTransaction',
    };
    final unresolved = _requiredStringList(map, 'unresolved_fields', path);
    final seenFields = <String>{};
    for (final field in unresolved) {
      if (!allowedUnresolved.contains(field)) {
        throw FormatException('$path.unresolved_fields contains unknown field "$field".');
      }
      if (!seenFields.add(field)) {
        throw FormatException('$path.unresolved_fields contains duplicate field "$field".');
      }
    }
    final requiresReview = _requiredBool(map, 'requires_user_review', path);
    final writeAllowed = _requiredBool(map, 'financial_write_allowed_from_fixture', path);
    final duplicateExpectation = _nullableString(map, 'duplicate_or_match_expectation', path);

    return SmsSyntheticExpected._(
      disposition: disposition,
      eventType: eventType,
      direction: direction,
      amount: amount,
      currencyCode: currency,
      eventStatus: eventStatus,
      unresolvedFields: List<String>.unmodifiable(unresolved),
      requiresUserReview: requiresReview,
      financialWriteAllowedFromFixture: writeAllowed,
      duplicateOrMatchExpectation: duplicateExpectation,
    );
  }
}

T _enumFromJson<T extends Enum>(
  List<T> values,
  String name,
  String path, {
  Map<String, T> aliases = const {},
}) {
  final alias = aliases[name];
  if (alias != null) return alias;
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$path has unsupported value "$name".');
}

void _validateExistingTransactionFixture(Map<String, Object?> map, String path) {
  // This is matching context only; it is never persisted or sent to the engine.
  final eventType = _requiredString(map, 'event_type', path);
  _enumFromJson(
    SmsFixtureEventType.values,
    eventType,
    '$path.event_type',
  );
  final amount = _requiredString(map, 'amount', path);
  if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(amount) ||
      amount.replaceAll('.', '').split('').every((digit) => digit == '0')) {
    throw FormatException('$path.amount must be a positive decimal string.');
  }
  final currency = _requiredString(map, 'currency_code', path);
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
    throw FormatException('$path.currency_code must be a three-letter uppercase currency code.');
  }
  final providerId = map['provider_id'];
  const knownProviderLabels = <String>{
    'cib', 'nbe', 'banque_misr', 'vodafone_cash', 'instapay', 'unknown',
  };
  if (providerId != null) {
    if (providerId is! String || !knownProviderLabels.contains(providerId)) {
      throw FormatException('$path.provider_id must be a known test label or omitted.');
    }
  }
  final payee = map['payee'];
  if (payee != null && (payee is! String || payee.trim().isEmpty)) {
    throw FormatException('$path.payee must be a non-empty string or omitted.');
  }
  final eventDate = map['event_date'];
  if (eventDate != null) {
    if (eventDate is! String) throw FormatException('$path.event_date must be a date string.');
    try {
      DateTime.parse(eventDate);
    } on FormatException {
      throw FormatException('$path.event_date must be a valid ISO date.');
    }
  }
  final eventStatus = map['event_status'];
  if (eventStatus != null) {
    if (eventStatus is! String) throw FormatException('$path.event_status must be a status string.');
    _enumFromJson(SmsFixtureEventStatus.values, eventStatus, '$path.event_status');
  }
}

Map<String, Object?> _stringMap(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be a JSON object.');
  final output = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) throw FormatException('$path contains a non-string key.');
    output[entry.key as String] = entry.value;
  }
  return output;
}

String _requiredString(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path.$key must be a non-empty string.');
  }
  return value;
}

String? _nullableString(Map<String, Object?> map, String key, String path) {
  if (!map.containsKey(key)) throw FormatException('$path.$key is required (use null when absent).');
  final value = map[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('$path.$key must be a string or null; numeric amounts must be strings.');
  }
  if (key != 'amount' && value.trim().isEmpty) {
    throw FormatException('$path.$key must be null or a non-empty string.');
  }
  return value;
}

bool _requiredBool(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! bool) throw FormatException('$path.$key must be a boolean.');
  return value;
}

List<String> _requiredStringList(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! List) throw FormatException('$path.$key must be an array of strings.');
  final output = <String>[];
  for (var index = 0; index < value.length; index++) {
    final item = value[index];
    if (item is! String || item.trim().isEmpty) {
      throw FormatException('$path.$key[$index] must be a non-empty string.');
    }
    output.add(item);
  }
  return output;
}

Map<String, Object?>? _nullableMap(Map<String, Object?> map, String key, String path) {
  if (!map.containsKey(key)) throw FormatException('$path.$key is required (use null when absent).');
  final value = map[key];
  if (value == null) return null;
  final result = _stringMap(value, '$path.$key');
  if (result.isEmpty) throw FormatException('$path.$key must be null or a non-empty object.');
  return result;
}
