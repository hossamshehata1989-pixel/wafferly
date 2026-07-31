import 'package:flutter/material.dart';

class AccountFormController {
  final nameController = TextEditingController();
  final balanceController = TextEditingController();
  final notesController = TextEditingController();

  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    notesController.dispose();
  }
}
