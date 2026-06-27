import 'package:hive/hive.dart';

part 'commitment_amount_mode.g.dart';

@HiveType(typeId: 93)
enum CommitmentAmountMode {
  @HiveField(0)
  fixed,

  @HiveField(1)
  variable,
}
