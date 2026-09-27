import 'package:hive/hive.dart';

import '../domain/credit_card_profile.dart';
import '../domain/credit_card_profile_repository.dart';

final class HiveCreditCardProfileRepository
    implements CreditCardProfileRepository {
  final Box<CreditCardProfile> _box;

  const HiveCreditCardProfileRepository(this._box);

  @override
  Future<CreditCardProfile?> findByAccountId(String accountId) async {
    for (final profile in _box.values) {
      if (profile.accountId == accountId) {
        return profile;
      }
    }
    return null;
  }
}
