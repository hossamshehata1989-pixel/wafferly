import 'package:flutter/material.dart';
import 'account_form_data.dart';

class AccountFormController {
  final nameController = TextEditingController();
  final balanceController = TextEditingController();
  final notesController = TextEditingController();

  String get name => nameController.text.trim();

  double get balance => double.tryParse(balanceController.text) ?? 0;

  String? get notes {
    final value = notesController.text.trim();
    return value.isEmpty ? null : value;
  }

  bool validate(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    notesController.dispose();
  }

  AccountFormData get data {
    return AccountFormData(name: name, balance: balance, notes: notes);
  }
}
