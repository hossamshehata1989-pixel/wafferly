import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../application/credit_card/credit_card_payment_application_service.dart';
import '../../../application/credit_card/credit_card_statement_due_calculator.dart';
import '../../../core/money/money.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../financial_engine/results/operation_result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/account.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../services/transaction_application_service.dart';

class CreditCardPaymentScreen extends StatefulWidget {
  const CreditCardPaymentScreen({
    super.key,
    required this.account,
    required this.profile,
    required this.outstanding,
    required this.statementDue,
  });

  final Account account;
  final CreditCardProfile profile;
  final Money outstanding;
  final CreditCardStatementDueSummary statementDue;

  @override
  State<CreditCardPaymentScreen> createState() => _CreditCardPaymentScreenState();
}

class _CreditCardPaymentScreenState extends State<CreditCardPaymentScreen> {
  final _amountController = TextEditingController();
  final _idempotencyKey = 'cc-payment-${const Uuid().v4()}';
  late CreditCardPaymentApplicationService _paymentService;
  List<Account> _sources = const <Account>[];
  String? _selectedSourceId;
  bool _initialized = false;
  bool _saving = false;
  _PaymentAmountMode _amountMode = _PaymentAmountMode.statementDue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _paymentService = CreditCardPaymentApplicationService(
      transactionApplicationService: context.read<TransactionApplicationService>(),
    );
    _sources = _paymentService.eligiblePaymentSources(
      creditCardAccount: widget.account,
      profile: widget.profile,
    );
    if (_sources.isNotEmpty) _selectedSourceId = _sources.first.id;
    _amountMode = widget.statementDue.isConfigured &&
            widget.statementDue.amountDue > Money.zero
        ? _PaymentAmountMode.statementDue
        : _PaymentAmountMode.fullOutstanding;
    _amountController.text = _amountMode == _PaymentAmountMode.statementDue
        ? widget.statementDue.amountDue.toString()
        : widget.outstanding.toString();
    _initialized = true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;
    final hasOutstanding = widget.outstanding > Money.zero;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.creditCardPayment,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: m.text(20)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(m.spacing(16), m.spacing(8), m.spacing(16), m.spacing(24)),
          children: [
            Container(
              padding: EdgeInsets.all(m.spacing(16)),
              decoration: BoxDecoration(
                color: const Color(0xFF102333),
                borderRadius: BorderRadius.circular(m.radius.lg),
                border: Border.all(color: const Color(0xFF264456)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.account.name, style: TextStyle(color: Colors.white70, fontSize: m.text(14))),
                  SizedBox(height: m.spacing(6)),
                  Text(
                    '${widget.outstanding} ${widget.account.currency}',
                    style: TextStyle(color: Colors.white, fontSize: m.text(25), fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: m.spacing(4)),
                  Text(t.creditCardPaymentDescription, style: TextStyle(color: Colors.white60, fontSize: m.text(12), height: 1.35)),
                ],
              ),
            ),
            SizedBox(height: m.space.lg),
            Text(
              t.choosePaymentAmount,
              style: TextStyle(color: Colors.white70, fontSize: m.text(14), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: m.spacing(8)),
            _buildAmountModeTile(
              mode: _PaymentAmountMode.statementDue,
              title: t.payStatementDue,
              subtitle: widget.statementDue.isConfigured
                  ? '${_formatMoney(widget.statementDue.amountDue)} • ${t.statementClosedOn}: ${_formatDate(widget.statementDue.statementCloseDate!)} • ${t.paymentDueOn}: ${_formatDate(widget.statementDue.paymentDueDate!)}'
                  : t.statementDueUnavailable,
              enabled: widget.statementDue.isConfigured &&
                  widget.statementDue.amountDue > Money.zero &&
                  !_saving &&
                  hasOutstanding,
              metrics: m,
            ),
            _buildAmountModeTile(
              mode: _PaymentAmountMode.fullOutstanding,
              title: t.payFullOutstanding,
              subtitle: _formatMoney(widget.outstanding),
              enabled: !_saving && hasOutstanding,
              metrics: m,
            ),
            _buildAmountModeTile(
              mode: _PaymentAmountMode.custom,
              title: t.payCustomAmount,
              subtitle: t.enterCustomPaymentAmount,
              enabled: !_saving && hasOutstanding,
              metrics: m,
            ),
            if (widget.statementDue.isConfigured) ...[
              SizedBox(height: m.spacing(4)),
              Text(
                widget.statementDue.amountDue.isZero
                    ? t.noStatementAmountDue
                    : t.statementDueCalculatedHint,
                style: TextStyle(color: Colors.white54, fontSize: m.text(11), height: 1.35),
              ),
            ],
            SizedBox(height: m.spacing(14)),
            Text(t.amount, style: TextStyle(color: Colors.white70, fontSize: m.text(14), fontWeight: FontWeight.w600)),
            SizedBox(height: m.spacing(8)),
            TextField(
              controller: _amountController,
              enabled: hasOutstanding && !_saving,
              readOnly: _amountMode != _PaymentAmountMode.custom,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: Colors.white, fontSize: m.text(22), fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                suffixText: widget.account.currency,
                filled: true,
                fillColor: const Color(0xFF101B29),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(m.radius.md)),
              ),
            ),
            SizedBox(height: m.space.md),
            Text(t.paymentAccount, style: TextStyle(color: Colors.white70, fontSize: m.text(14), fontWeight: FontWeight.w600)),
            SizedBox(height: m.spacing(8)),
            if (_sources.isEmpty)
              Container(
                padding: EdgeInsets.all(m.spacing(14)),
                decoration: BoxDecoration(
                  color: const Color(0xFF101B29),
                  borderRadius: BorderRadius.circular(m.radius.md),
                  border: Border.all(color: const Color(0xFF354657)),
                ),
                child: Text(t.noEligiblePaymentAccounts, style: const TextStyle(color: Colors.white70)),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedSourceId,
                dropdownColor: const Color(0xFF101B29),
                style: TextStyle(color: Colors.white, fontSize: m.text(14)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF101B29),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(m.radius.md)),
                ),
                items: _sources.map((account) => DropdownMenuItem<String>(
                  value: account.id,
                  child: Text('${account.name} • ${account.currency}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: _saving ? null : (value) => setState(() => _selectedSourceId = value),
              ),
            SizedBox(height: m.space.xl),
            SizedBox(
              height: m.size(54),
              child: FilledButton(
                onPressed: _saving || !hasOutstanding || _sources.isEmpty || _selectedSourceId == null
                    ? null
                    : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7DFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(m.radius.lg)),
                ),
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t.confirmPayment, style: TextStyle(fontSize: m.text(15), fontWeight: FontWeight.w800)),
              ),
            ),
            if (!hasOutstanding) ...[
              SizedBox(height: m.spacing(12)),
              Text(t.noOutstandingPayment, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountModeTile({
    required _PaymentAmountMode mode,
    required String title,
    required String subtitle,
    required bool enabled,
    required ResponsiveMetrics metrics,
  }) {
    final selected = _amountMode == mode;
    return Padding(
      padding: EdgeInsets.only(bottom: metrics.spacing(6)),
      child: Material(
        color: selected ? const Color(0xFF172E46) : const Color(0xFF101B29),
        borderRadius: BorderRadius.circular(metrics.radius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(metrics.radius.md),
          onTap: !enabled ? null : () => _selectAmountMode(mode),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.spacing(12),
              vertical: metrics.spacing(10),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(metrics.radius.md),
              border: Border.all(
                color: selected ? const Color(0xFF2D7DFF) : const Color(0xFF26394D),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: !enabled
                      ? Colors.white24
                      : selected
                          ? const Color(0xFF65A1FF)
                          : Colors.white54,
                  size: metrics.size(20),
                ),
                SizedBox(width: metrics.spacing(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: enabled ? Colors.white : Colors.white38,
                          fontSize: metrics.text(13),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: metrics.spacing(2)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: enabled ? Colors.white60 : Colors.white24,
                          fontSize: metrics.text(10),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectAmountMode(_PaymentAmountMode mode) {
    setState(() {
      _amountMode = mode;
      if (mode == _PaymentAmountMode.statementDue) {
        _amountController.text = widget.statementDue.amountDue.toString();
      } else if (mode == _PaymentAmountMode.fullOutstanding) {
        _amountController.text = widget.outstanding.toString();
      }
    });
  }

  String _formatMoney(Money amount) => '${amount.toString()} ${widget.account.currency}';

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    final rawAmount = _amountController.text.trim();
    late final Money amount;
    try {
      amount = Money.parse(rawAmount);
    } catch (_) {
      _showMessage(t.enterValidAmount);
      return;
    }
    if (amount <= Money.zero) {
      _showMessage(t.enterValidAmount);
      return;
    }
    if (amount > widget.outstanding) {
      _showMessage(t.paymentExceedsOutstanding);
      return;
    }

    final sourceId = _selectedSourceId;
    if (sourceId == null) return;
    final paymentModeLabel = switch (_amountMode) {
      _PaymentAmountMode.statementDue => t.payStatementDue,
      _PaymentAmountMode.fullOutstanding => t.payFullOutstanding,
      _PaymentAmountMode.custom => t.payCustomAmount,
    };

    setState(() => _saving = true);
    try {
      final result = await _paymentService.pay(
        sourceAssetAccountId: sourceId,
        creditCardAccount: widget.account,
        amount: amount,
        occurredAt: DateTime.now(),
        note: '${t.creditCardPayment} • $paymentModeLabel',
        idempotencyKey: _idempotencyKey,
      );

      if (result is OperationSucceeded) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      if (!mounted) return;
      final message = switch (result) {
        DomainViolationResult(:final reason)
            when reason.startsWith('Insufficient balance') =>
          t.creditCardPaymentInsufficientBalance,
        DomainViolationResult(:final reason)
            when reason.contains('exceeds the current outstanding') =>
          t.paymentExceedsOutstanding,
        DomainViolationResult() => t.creditCardPaymentFailed,
        OperationRejected() => t.creditCardPaymentFailed,
        OperationFailed() => t.creditCardPaymentFailed,
        _ => t.creditCardPaymentFailed,
      };
      debugPrint('Credit Card payment failed: $result');
      _showMessage(message);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}


enum _PaymentAmountMode { statementDue, fullOutstanding, custom }
