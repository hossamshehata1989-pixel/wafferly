import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/credit_card/credit_card_financing_application_service.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';
import '../../../constants/transaction_constants.dart';
import '../../../services/transaction_query_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';

class CreditCardInstallmentConversionScreen extends StatefulWidget {
  const CreditCardInstallmentConversionScreen({super.key, required this.account});
  final Account account;

  @override
  State<CreditCardInstallmentConversionScreen> createState() =>
      _CreditCardInstallmentConversionScreenState();
}

class _CreditCardInstallmentConversionScreenState
    extends State<CreditCardInstallmentConversionScreen> {
  int _step = 1;
  Transaction? _selected;
  final _searchController = TextEditingController();
  int _count = 12;
  DateTime _firstDueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final all = context
        .read<TransactionQueryService>()
        .getForAccount(widget.account.id)
        .where((tx) => tx.type == TransactionType.creditCardCharge)
        .toList();
    final query = _searchController.text.trim().toLowerCase();
    final transactions = query.isEmpty
        ? all
        : all.where((tx) => (tx.note ?? '').toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Convert to Installment', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(m.spacing(16), 6, m.spacing(16), 28),
          children: [
            _StepHeader(step: _step),
            SizedBox(height: m.space.lg),
            if (_step == 1) ...[
              const Text('Select a transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Choose a Credit Card transaction to convert into installments.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              _SearchBox(controller: _searchController, onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              ...transactions.map((tx) => _TransactionChoice(
                transaction: tx,
                currency: widget.account.currency,
                selected: _selected?.id == tx.id,
                onTap: () => setState(() => _selected = tx),
              )),
              const SizedBox(height: 18),
              _PrimaryButton(
                label: 'Continue',
                enabled: _selected != null,
                onPressed: () => setState(() => _step = 2),
              ),
            ] else ...[
              Text(
                _selected?.note?.split(' • ').first ?? 'Selected transaction',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${_selected?.amount.toStringAsFixed(2) ?? '0.00'} ${widget.account.currency}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),
              _OptionCard(
                title: 'Number of installments',
                value: '$_count',
                leading: Icons.calendar_month_rounded,
                onMinus: _count > 1 ? () => setState(() => _count--) : null,
                onPlus: () => setState(() => _count++),
              ),
              const SizedBox(height: 10),
              _DateOption(
                title: 'First payment date',
                date: _firstDueDate,
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: _firstDueDate,
                  );
                  if (value != null) setState(() => _firstDueDate = value);
                },
              ),
              const SizedBox(height: 14),
              _ConversionSummary(
                amount: _selected?.amount ?? 0,
                count: _count,
                currency: widget.account.currency,
              ),
              const SizedBox(height: 22),
              _PrimaryButton(
                label: _saving ? 'Converting…' : 'Confirm Conversion',
                enabled: !_saving && _selected != null,
                onPressed: _convert,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _convert() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _saving = true);
    try {
      await context.read<CreditCardFinancingApplicationService>().convertCharge(
        charge: selected,
        installmentCount: _count,
        firstDueDate: _firstDueDate,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _step(1, 'Select'),
      const Expanded(child: Divider(color: Colors.white24)),
      _step(2, 'Details'),
      const Expanded(child: Divider(color: Colors.white24)),
      _step(3, 'Confirm'),
    ]);
  }
  Widget _step(int number, String label) {
    final active = number <= step;
    return Column(children: [
      CircleAvatar(radius: 14, backgroundColor: active ? const Color(0xFFFF2D6F) : const Color(0xFF18273A), child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 11)),
    ]);
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: 'Search transactions',
      prefixIcon: const Icon(Icons.search_rounded),
      filled: true,
      fillColor: const Color(0xFF132236),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );
}

class _TransactionChoice extends StatelessWidget {
  const _TransactionChoice({required this.transaction, required this.currency, required this.selected, required this.onTap});
  final Transaction transaction;
  final String currency;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF0A1C29),
    child: ListTile(
      onTap: onTap,
      leading: Radio<bool>(value: true, groupValue: selected ? true : null, onChanged: (_) => onTap()),
      title: Text(transaction.note?.split(' • ').first ?? 'Credit Card purchase', style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${transaction.date.day} ${transaction.date.month} ${transaction.date.year}', style: const TextStyle(color: Colors.white54)),
      trailing: Text('-${transaction.amount.toStringAsFixed(2)} $currency', style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.title, required this.value, required this.leading, required this.onMinus, required this.onPlus});
  final String title;
  final String value;
  final IconData leading;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFF0A1C29), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [Icon(leading, color: Colors.white70), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))), IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_rounded)), Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded))]),
  );
}

class _DateOption extends StatelessWidget {
  const _DateOption({required this.title, required this.date, required this.onTap});
  final String title;
  final DateTime date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: const Color(0xFF0A1C29),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    leading: const Icon(Icons.event_rounded, color: Colors.white70),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: Colors.white60)),
    onTap: onTap,
  );
}

class _ConversionSummary extends StatelessWidget {
  const _ConversionSummary({required this.amount, required this.count, required this.currency});
  final double amount;
  final int count;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final monthly = count == 0 ? 0 : amount / count;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF3A1930), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFF2D6F).withValues(alpha: .25))),
      child: Row(children: [
        Expanded(child: _metric('Monthly installment', '${monthly.toStringAsFixed(2)} $currency')),
        Expanded(child: _metric('Total amount', '${amount.toStringAsFixed(2)} $currency')),
      ]),
    );
  }
  Widget _metric(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)), const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]);
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.enabled, required this.onPressed});
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(height: 54, child: FilledButton(onPressed: enabled ? onPressed : null, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF2D6F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))));
}
