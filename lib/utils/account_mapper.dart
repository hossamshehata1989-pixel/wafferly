import '../models/enums/account_enums.dart';
import '../models/enums/account_type_definition.dart';

AccountNature resolveNature(String type) {
  return getNature(type);
}

AccountGroup resolveGroup(String type) {
  return getGroup(type);
}