import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/manual_reserve_application_service.dart';

class AccountReserveForm extends StatefulWidget {
  const AccountReserveForm({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.available,
    required this.currency,
    required this.applicationService,
    required this.onSuccess,
  });

  final String accountId;
  final String accountName;
  final double available;
  final String currency;
  final ManualReserveApplicationService applicationService;
  final VoidCallback onSuccess;

  @override
  State<AccountReserveForm> createState() => _AccountReserveFormState();
}

class _AccountReserveFormState extends State<AccountReserveForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  Future<void> _reserve() async {
    final amount = _amount;
    if (amount <= 0) {
      _showMessage('Enter a valid amount.');
      return;
    }
    if (amount > widget.available) {
      _showMessage(
        'Cannot reserve more than ${widget.available.toStringAsFixed(0)} ${widget.currency}.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.applicationService.reserve(
        accountId: widget.accountId,
        amount: amount,
        name: _nameController.text,
      );
      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e));
      setState(() => _saving = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('Insufficient available balance')) {
      return 'Cannot reserve more than the available balance.';
    }
    return 'Unable to reserve money. Please try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reserve Money',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set money aside from this account.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 22),
          const Text('Reserve Name', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 7),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            maxLength: 60,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. Rent, Emergency Fund, New Laptop',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available', style: TextStyle(color: Colors.white70)),
              Text(
                '${widget.available.toStringAsFixed(0)} ${widget.currency}',
                style: const TextStyle(
                  color: Color(0xFF39D98A),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Amount to Reserve', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 7),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: widget.currency,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _reserve,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reserve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
