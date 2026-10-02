import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/credit_card/credit_card_financing_application_service.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../models/account.dart';
import '../../../models/enums/account_enums.dart';
import '../../../services/account_service.dart';
import '../../../services/transaction_application_service.dart';
import '../../../services/transaction_query_service.dart';
import '../../../models/transaction.dart';
import '../../../financial_engine/results/operation_result.dart';
import '../../../config/category_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import 'credit_card_installment_conversion_screen.dart';

class CreditCardTransactionEntryScreen extends StatefulWidget {
  const CreditCardTransactionEntryScreen({
    super.key,
    required this.account,
    required this.profile,
    this.initialMode = CreditCardEntryMode.expense,
  });

  final Account account;
  final CreditCardProfile profile;
  final CreditCardEntryMode initialMode;

  @override
  State<CreditCardTransactionEntryScreen> createState() =>
      _CreditCardTransactionEntryScreenState();
}

enum CreditCardEntryMode { expense, installment, payment }

class _CreditCardTransactionEntryScreenState
    extends State<CreditCardTransactionEntryScreen> {
  late CreditCardEntryMode _mode;
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  String _categoryId = 'supermarket';
  int _installmentCount = 12;
  DateTime _firstPaymentDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            m.spacing(16),
            m.spacing(6),
            m.spacing(16),
            m.spacing(24),
          ),
          children: [
            _ModeTabs(
              mode: _mode,
              onChanged: (mode) {
                if (mode == CreditCardEntryMode.payment) {
                  _showPaymentInfo();
                  return;
                }
                setState(() => _mode = mode);
              },
            ),
            SizedBox(height: m.space.lg),
            _AmountField(
              controller: _amountController,
              currency: widget.account.currency,
            ),
            SizedBox(height: m.space.md),
            _FieldTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Merchant',
              value: _merchantController.text.isEmpty
                  ? 'Add merchant'
                  : _merchantController.text,
              onTap: _editMerchant,
            ),
            SizedBox(height: m.space.sm),
            _FieldTile(
              icon: Icons.category_outlined,
              title: t.category,
              value: _categoryName(context),
              onTap: _pickCategory,
            ),
            SizedBox(height: m.space.sm),
            _FieldTile(
              icon: Icons.calendar_month_outlined,
              title: t.date,
              value: _formatDate(_date),
              onTap: _pickDate,
            ),
            SizedBox(height: m.space.sm),
            _FieldTile(
              icon: Icons.repeat_rounded,
              title: 'Recurring',
              value: 'Does not repeat',
              onTap: () {},
            ),
            SizedBox(height: m.space.sm),
            _FieldTile(
              icon: Icons.notes_outlined,
              title: 'Note',
              value: _noteController.text.isEmpty
                  ? 'Add a note (optional)'
                  : _noteController.text,
              onTap: _editNote,
            ),
            if (_mode == CreditCardEntryMode.installment) ...[
              SizedBox(height: m.space.lg),
              _InstallmentOptions(
                count: _installmentCount,
                firstPaymentDate: _firstPaymentDate,
                onCountChanged: (value) => setState(() => _installmentCount = value),
                onDateChanged: (value) => setState(() => _firstPaymentDate = value),
              ),
              SizedBox(height: m.space.md),
              _InstallmentSummary(
                amount: double.tryParse(_amountController.text) ?? 0,
                count: _installmentCount,
                currency: widget.account.currency,
              ),
            ],
            SizedBox(height: m.space.xl),
            SizedBox(
              height: m.size(56),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D6F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(m.radius.lg),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _mode == CreditCardEntryMode.installment
                            ? 'Add Installment'
                            : 'Add Transaction',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Enter a valid amount.');
      return;
    }

    setState(() => _saving = true);
    try {
      final txService = context.read<TransactionApplicationService>();
      final result = await txService.addCreditCardCharge(
        creditCardAccountId: widget.account.id,
        amount: amount,
        categoryId: _categoryId,
        occurredAt: _date,
        currencyCode: widget.account.currency,
        note: _combinedNote(),
      );

      if (result is! OperationSucceeded) {
        final reason = result is DomainViolationResult
            ? result.reason
            : result is OperationRejected
                ? result.reason
                : result is OperationFailed
                    ? result.error.toString()
                    : 'Unable to save the transaction.';
        _snack(reason);
        return;
      }

      if (_mode == CreditCardEntryMode.installment) {
        final transactionIds = result.summary.createdTransactionIds;
        if (transactionIds.isNotEmpty) {
          final transactionId = transactionIds.first;
          final financing = context.read<CreditCardFinancingApplicationService>();
          final tx = context.read<TransactionQueryService>().getById(transactionId);
          if (tx != null) {
            await financing.convertCharge(
              charge: tx,
              installmentCount: _installmentCount,
              firstDueDate: _firstPaymentDate,
            );
          }
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  String? _combinedNote() {
    final merchant = _merchantController.text.trim();
    final note = _noteController.text.trim();
    if (merchant.isEmpty) return note.isEmpty ? null : note;
    if (note.isEmpty) return merchant;
    return '$merchant • $note';
  }

  String _categoryName(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final category = expenseCategories.firstWhere(
      (item) => item.id == _categoryId,
      orElse: () => expenseCategories.first,
    );
    return category.resolveTitle(t);
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0A1C29),
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: expenseCategories.take(10).map((category) {
            return ListTile(
              leading: const Icon(Icons.category_outlined, color: Colors.white70),
              title: Text(category.resolveTitle(AppLocalizations.of(context)!)),
              trailing: category.id == _categoryId
                  ? const Icon(Icons.check_rounded, color: Color(0xFFFF2D6F))
                  : null,
              onTap: () => Navigator.pop(context, category.id),
            );
          }).toList(),
        );
      },
    );
    if (selected != null) setState(() => _categoryId = selected);
  }

  Future<void> _editMerchant() async {
    final value = await _textDialog('Merchant', _merchantController.text);
    if (value != null) setState(() => _merchantController.text = value);
  }

  Future<void> _editNote() async {
    final value = await _textDialog('Note', _noteController.text);
    if (value != null) setState(() => _noteController.text = value);
  }

  Future<String?> _textDialog(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1C29),
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (value != null) setState(() => _date = value);
  }

  void _showPaymentInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A1C29),
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Card payments use the existing Financial Operation Engine. The payment flow will be connected here.'),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime value) => '${value.day} ${_month(value.month)} ${value.year}';

  String _month(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});
  final CreditCardEntryMode mode;
  final ValueChanged<CreditCardEntryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab('Expense', CreditCardEntryMode.expense),
        _tab('Installment', CreditCardEntryMode.installment),
        _tab('Payment', CreditCardEntryMode.payment),
      ],
    );
  }

  Widget _tab(String title, CreditCardEntryMode value) {
    final active = mode == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FilledButton(
          onPressed: () => onChanged(value),
          style: FilledButton.styleFrom(
            backgroundColor: active ? const Color(0xFFFF2D6F) : const Color(0xFFEFF2F8),
            foregroundColor: active ? Colors.white : const Color(0xFF24324A),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.currency});
  final TextEditingController controller;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.black),
              decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
            ),
          ),
          Text(currency, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.icon, required this.title, required this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF243B63)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700))),
              Text(value, style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallmentOptions extends StatelessWidget {
  const _InstallmentOptions({required this.count, required this.firstPaymentDate, required this.onCountChanged, required this.onDateChanged});
  final int count;
  final DateTime firstPaymentDate;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF243B63)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Number of installments', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700))),
            IconButton(onPressed: count > 1 ? () => onCountChanged(count - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
            Text('$count', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
            IconButton(onPressed: () => onCountChanged(count + 1), icon: const Icon(Icons.add_circle_outline)),
          ]),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded, color: Color(0xFF243B63)),
            title: const Text('First payment date', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
            trailing: Text('${firstPaymentDate.day}/${firstPaymentDate.month}/${firstPaymentDate.year}', style: const TextStyle(color: Colors.black54)),
            onTap: () async {
              final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2100), initialDate: firstPaymentDate);
              if (date != null) onDateChanged(date);
            },
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.repeat_rounded, color: Color(0xFF243B63)),
            title: Text('Recurring', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
            trailing: Text('Monthly', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

class _InstallmentSummary extends StatelessWidget {
  const _InstallmentSummary({required this.amount, required this.count, required this.currency});
  final double amount;
  final int count;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final monthly = count <= 0 ? 0 : amount / count;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFEAF1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _summary('Monthly installment', '${monthly.toStringAsFixed(2)} $currency')),
          Expanded(child: _summary('Total amount', '${amount.toStringAsFixed(2)} $currency')),
        ],
      ),
    );
  }

  Widget _summary(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900))]);
}
