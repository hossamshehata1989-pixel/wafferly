import 'package:hive/hive.dart';
part 'commitment_type.g.dart';

@HiveType(typeId: 91)
enum CommitmentType {
  @HiveField(0)
  income,

  @HiveField(1)
  expense,

  @HiveField(2)
  transfer,

  @HiveField(3)
  liabilityPayment,
}
