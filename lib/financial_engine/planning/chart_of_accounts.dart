import 'account_mapping.dart';

final class ChartOfAccounts {
  final List<AccountMapping> mappings;

  const ChartOfAccounts({this.mappings = const []});

  String? accountForCategory(String categoryId) {
    for (final mapping in mappings) {
      if (mapping.categoryId == categoryId) {
        return mapping.accountId;
      }
    }

    return null;
  }
}
