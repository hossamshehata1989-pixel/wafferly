import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_account_application_service.dart';
import '../../../models/account.dart';
import '../../../services/account_service.dart';
import '../../../models/enums/account_enums.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';

class AddCreditCardScreen extends StatefulWidget {
  const AddCreditCardScreen({super.key});

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankController = TextEditingController();
  final _limitController = TextEditingController();
  final _last4Controller = TextEditingController();
  final _notesController = TextEditingController();

  String _currency = 'EGP';
  String _cardKind = 'physical';
  String? _cardNetwork;
  int? _statementDay;
  int? _paymentDueDay;
  String? _linkedDebitCardAccountId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _limitController.dispose();
    _last4Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final account = await CreditCardAccountApplicationService().create(
        name: _nameController.text,
        bank: _bankController.text,
        currency: _currency,
        creditLimitValue: _limitController.text,
        last4Digits: _last4Controller.text,
        cardKind: _cardKind,
        notes: _notesController.text.trim(),
        cardNetwork: _cardNetwork,
        statementDay: _statementDay,
        paymentDueDay: _paymentDueDay,
        linkedDebitCardAccountId: _linkedDebitCardAccountId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${account.name} created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create credit card: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Account> get _debitCardAccounts => AccountService()
      .getAllActiveAccounts()
      .where((account) => account.type == 'debitCard' && account.group == AccountGroup.liquidity)
      .toList();

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Credit Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  m.spacing(18),
                  m.spacing(8),
                  m.spacing(18),
                  m.spacing(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Basic information'),
                    _field(
                      controller: _nameController,
                      label: 'Card name',
                      hint: 'e.g. CIB Credit Card',
                      icon: Icons.credit_card_rounded,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter the card name'
                          : null,
                    ),
                    SizedBox(height: m.spacing(12)),
                    _field(
                      controller: _bankController,
                      label: 'Bank / Issuer',
                      hint: 'e.g. CIB',
                      icon: Icons.account_balance_rounded,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter the bank / issuer'
                          : null,
                    ),
                    SizedBox(height: m.spacing(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: _limitController,
                            label: 'Credit limit',
                            hint: '30,000',
                            icon: Icons.payments_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final amount = double.tryParse(value?.trim() ?? '');
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid limit';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: m.spacing(10)),
                        SizedBox(
                          width: m.size(92),
                          child: _dropdown(
                            label: 'Currency',
                            value: _currency,
                            items: const ['EGP', 'USD', 'EUR'],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _currency = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: m.spacing(20)),
                    _sectionTitle('Card details'),
                    _field(
                      controller: _last4Controller,
                      label: 'Last 4 digits (optional)',
                      hint: '5678',
                      icon: Icons.password_rounded,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isNotEmpty &&
                            (text.length != 4 || int.tryParse(text) == null)) {
                          return 'Enter exactly 4 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: m.spacing(12)),
                    Text(
                      'Card type',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: m.spacing(8)),
                    Row(
                      children: [
                        Expanded(child: _cardKindOption('physical', 'Physical', Icons.credit_card_rounded)),
                        SizedBox(width: m.spacing(10)),
                        Expanded(child: _cardKindOption('virtual', 'Virtual', Icons.devices_rounded)),
                      ],
                    ),
                    _dropdown(
                      label: 'Card network (optional)',
                      value: _cardNetwork,
                      items: const ['Visa', 'Mastercard', 'American Express', 'Other'],
                      allowNull: true,
                      onChanged: (value) => setState(() => _cardNetwork = value),
                    ),
                    SizedBox(height: m.spacing(12)),
                    _dropdown(
                      label: 'Linked debit card (optional)',
                      value: _linkedDebitCardAccountId,
                      items: _debitCardAccounts.map((a) => a.id).toList(),
                      labels: _debitCardAccounts.map((a) => a.name).toList(),
                      allowNull: true,
                      onChanged: (value) => setState(() => _linkedDebitCardAccountId = value),
                    ),
                    SizedBox(height: m.spacing(20)),
                    _sectionTitle('Statement & payment (optional)'),
                    Row(
                      children: [
                        Expanded(
                          child: _dayDropdown(
                            label: 'Statement day',
                            value: _statementDay,
                            onChanged: (value) => setState(() => _statementDay = value),
                          ),
                        ),
                        SizedBox(width: m.spacing(10)),
                        Expanded(
                          child: _dayDropdown(
                            label: 'Payment due day',
                            value: _paymentDueDay,
                            onChanged: (value) => setState(() => _paymentDueDay = value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: m.spacing(18)),
                    _field(
                      controller: _notesController,
                      label: 'Notes (optional)',
                      hint: 'Anything you want to remember',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    SizedBox(height: m.spacing(18)),
                    Container(
                      padding: EdgeInsets.all(m.spacing(13)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1C28),
                        borderRadius: BorderRadius.circular(m.radius.lg),
                        border: Border.all(
                          color: const Color(0xFF35E0B5).withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF35E0B5), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A new card starts with zero outstanding balance. The credit limit is configuration; current debt is calculated from real transactions.',
                              style: TextStyle(color: Colors.white70, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(m.spacing(16)),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF35E0B5),
                    foregroundColor: Colors.black,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Credit Card',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0B1C28),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF35E0B5)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    List<String>? labels,
    bool allowNull = false,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF0B1C28),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF0B1C28),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        if (allowNull)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Not set'),
          ),
        ...items.asMap().entries.map(
          (entry) => DropdownMenuItem<String>(
            value: entry.value,
            child: Text(labels != null ? labels[entry.key] : entry.value),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _dayDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      dropdownColor: const Color(0xFF0B1C28),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF0B1C28),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Not set')),
        ...List.generate(31, (index) {
          final day = index + 1;
          return DropdownMenuItem<int>(value: day, child: Text('$day'));
        }),
      ],
      onChanged: onChanged,
    );
  }

  Widget _cardKindOption(String value, String label, IconData icon) {
    final selected = _cardKind == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _cardKind = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF35E0B5).withValues(alpha: 0.12)
              : const Color(0xFF0B1C28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF35E0B5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF35E0B5) : Colors.white54),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
