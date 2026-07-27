import 'package:flutter/material.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Details')),
      body: Center(
        child: Text(
          'Account ID:\n$accountId\n\n(TODO: STEP 4)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
