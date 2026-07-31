import 'package:wafferly/models/account.dart';

class AccountFactory {
  static Account update({
    required Account original,
    required String bookId,
    required String name,
    required String type,
    required String currency,
    required String? notes,
    required String? icon,
  }) {
    return Account(
      id: original.id,
      bookId: bookId,
      memberId: original.memberId,
      name: name,
      type: type,
      currency: currency,
      createdAt: original.createdAt,
      group: original.group,
      isArchived: original.isArchived,
      notes: notes,
      icon: icon,
      nature: original.nature,
    );
  }
}
