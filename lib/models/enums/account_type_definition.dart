// lib/models/enums/account_type_definition.dart

import 'account_enums.dart';
import '../account_type.dart';

/// Single Source of Truth for Account Type Classification.
///
/// Important:
/// - AccountType is the persisted technical type.
/// - AccountTypeDefinition is the canonical classification layer.
/// - UI labels must not create new AccountTypes.
/// - Legacy types may resolve to an existing canonical definition.
class AccountTypeDefinition {
  final AccountType type;
  final AccountNature nature;
  final AccountGroup group;

  const AccountTypeDefinition({
    required this.type,
    required this.nature,
    required this.group,
  });

  String get typeString => type.string;
  String get natureString => nature.string;
  String get groupString => group.string;

  /// Liability accounts represent debt.
  bool get isDebt => nature == AccountNature.liability;

  /// Investment accounts are determined by their group.
  bool get isInvestment => group == AccountGroup.investments;

  /// Liquid accounts are immediately available money accounts.
  bool get isLiquid {
    switch (type) {
      case AccountType.cash:
      case AccountType.bank:
      case AccountType.wallet:
      case AccountType.debitCard:
        return true;

      default:
        return false;
    }
  }

  /// Receivable accounts represent money expected from others.
  bool get isReceivable => group == AccountGroup.receivable;
}

/// ============================================================
/// MASTER ACCOUNT TYPE CLASSIFICATION
/// ============================================================

const List<AccountTypeDefinition> accountTypeDefinitions = [
  // ==========================================================
  // LIQUIDITY
  // ==========================================================

  AccountTypeDefinition(
    type: AccountType.cash,
    nature: AccountNature.asset,
    group: AccountGroup.liquidity,
  ),

  AccountTypeDefinition(
    type: AccountType.bank,
    nature: AccountNature.asset,
    group: AccountGroup.liquidity,
  ),

  AccountTypeDefinition(
    type: AccountType.wallet,
    nature: AccountNature.asset,
    group: AccountGroup.liquidity,
  ),

  AccountTypeDefinition(
    type: AccountType.debitCard,
    nature: AccountNature.asset,
    group: AccountGroup.liquidity,
  ),

  // ==========================================================
  // INVESTMENTS
  // ==========================================================

  AccountTypeDefinition(
    type: AccountType.investment,
    nature: AccountNature.asset,
    group: AccountGroup.investments,
  ),

  AccountTypeDefinition(
    type: AccountType.gold,
    nature: AccountNature.asset,
    group: AccountGroup.investments,
  ),

  AccountTypeDefinition(
    type: AccountType.stocks,
    nature: AccountNature.asset,
    group: AccountGroup.investments,
  ),

  AccountTypeDefinition(
    type: AccountType.certificates,
    nature: AccountNature.asset,
    group: AccountGroup.investments,
  ),

  // ==========================================================
  // LIABILITIES
  // ==========================================================

  AccountTypeDefinition(
    type: AccountType.debt,
    nature: AccountNature.liability,
    group: AccountGroup.liabilities,
  ),

  AccountTypeDefinition(
    type: AccountType.loan,
    nature: AccountNature.liability,
    group: AccountGroup.liabilities,
  ),

  AccountTypeDefinition(
    type: AccountType.creditCard,
    nature: AccountNature.liability,
    group: AccountGroup.liabilities,
  ),

  AccountTypeDefinition(
    type: AccountType.installment,
    nature: AccountNature.liability,
    group: AccountGroup.liabilities,
  ),

  // ==========================================================
  // RECEIVABLE
  // ==========================================================

  AccountTypeDefinition(
    type: AccountType.lent,
    nature: AccountNature.asset,
    group: AccountGroup.receivable,
  ),

  // Legacy technical type.
  //
  // User-facing concept = Money Circle.
  // It must NOT become a separate UI option.
  AccountTypeDefinition(
    type: AccountType.rosca,
    nature: AccountNature.asset,
    group: AccountGroup.receivable,
  ),

  // ==========================================================
  // SAVINGS
  // ==========================================================

  AccountTypeDefinition(
    type: AccountType.realSaving,
    nature: AccountNature.asset,
    group: AccountGroup.savings,
  ),

  // Legacy technical type.
  //
  // User-facing concept = Money Circle.
  // Kept only for compatibility with existing stored accounts.
  //
  // NOTE:
  // This remains a legacy technical type, not a second UI option.
  AccountTypeDefinition(
    type: AccountType.savingCircle,
    nature: AccountNature.asset,
    group: AccountGroup.receivable,
  ),
];

/// ============================================================
/// LOOKUP MAPS
/// ============================================================

final Map<AccountType, AccountTypeDefinition> _definitionByTypeEnum = {
  for (final definition in accountTypeDefinitions)
    definition.type: definition,
};

final Map<String, AccountTypeDefinition> _definitionByTypeString = {
  for (final definition in accountTypeDefinitions)
    definition.typeString: definition,
};

/// ============================================================
/// LEGACY / CANONICAL NORMALIZATION
/// ============================================================
///
/// moneyBorrowed is a legacy technical type when present in the
/// current AccountType enum.
///
/// Canonical classification is always `debt`.
AccountType _normalizeAccountType(AccountType type) {
  if (type == AccountType.moneyBorrowed) {
    return AccountType.debt;
  }

  return type;
}

String _normalizeTypeString(String type) {
  if (type == 'moneyBorrowed') {
    return 'debt';
  }

  return type;
}

/// ============================================================
/// PUBLIC API
/// ============================================================

AccountTypeDefinition getDefinition(AccountType type) {
  final normalizedType = _normalizeAccountType(type);
  final definition = _definitionByTypeEnum[normalizedType];

  if (definition == null) {
    throw UnsupportedError(
      'Missing AccountTypeDefinition for enum: $type',
    );
  }

  return definition;
}

AccountTypeDefinition getDefinitionByString(String type) {
  final normalizedType = _normalizeTypeString(type);
  final definition = _definitionByTypeString[normalizedType];

  if (definition == null) {
    throw UnsupportedError(
      'Missing AccountTypeDefinition for type string: $type',
    );
  }

  return definition;
}

AccountNature getNature(String type) {
  return getDefinitionByString(type).nature;
}

AccountGroup getGroup(String type) {
  return getDefinitionByString(type).group;
}

bool isDebtType(String type) {
  return getDefinitionByString(type).isDebt;
}

bool isInvestmentType(String type) {
  return getDefinitionByString(type).isInvestment;
}

bool isLiquidType(String type) {
  return getDefinitionByString(type).isLiquid;
}

bool isReceivableType(String type) {
  return getDefinitionByString(type).isReceivable;
}