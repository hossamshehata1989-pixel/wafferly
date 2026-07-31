import 'package:wafferly/models/enums/section_type.dart';

class CreateAccountRequest {
  final String name;
  final String type;
  final String currency;
  final String? icon;
  final String? notes;
  final double balance;
  final SectionType sectionType;

  const CreateAccountRequest({
    required this.name,
    required this.type,
    required this.currency,
    required this.icon,
    required this.notes,
    required this.balance,
    required this.sectionType,
  });
}
