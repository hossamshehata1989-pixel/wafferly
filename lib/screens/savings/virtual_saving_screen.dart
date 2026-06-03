import 'package:flutter/material.dart';

class VirtualSavingScreen extends StatelessWidget {
  const VirtualSavingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('Virtual Saving'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Virtual Saving Details',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
