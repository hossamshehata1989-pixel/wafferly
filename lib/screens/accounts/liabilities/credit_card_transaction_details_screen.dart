import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../application/credit_card/credit_card_transaction_timing_policy.dart';
import '../../../config/category_config.dart';
import '../../../config/category_type.dart';
import '../../../constants/transaction_constants.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../financial_engine/results/operation_result.dart';
import '../../../models/account.dart';
import '../../../models/financing/financing_contract.dart';
import '../../../models/financing/financing_installment.dart';
import '../../../models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/transaction_application_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../expenses_screen.dart';
import 'credit_card_installment_conversion_screen.dart';
import 'credit_card_installment_month_screen.dart';

const _pink = Color(0xFFFF3D81);
const _cyan = Color(0xFF42C9FF);
const _green = Color(0xFF00D99A);
const _panel = Color(0xFF0A1C29);
const _rowPanel = Color(0xFF102638);

class CreditCardTransactionDetailsScreen extends StatefulWidget {
  const CreditCardTransactionDetailsScreen({
    super.key,
    required this.transaction,
    required this.account,
    required this.profile,
    required this.contracts,
    required this.installments,
  });

  final Transaction transaction;
  final Account account;
  final CreditCardProfile profile;
  final List<FinancingContract> contracts;
  final List<FinancingInstallment> installments;

  @override
  State<CreditCardTransactionDetailsScreen> createState() =>
      _CreditCardTransactionDetailsScreenState();
}

class _CreditCardTransactionDetailsScreenState
    extends State<CreditCardTransactionDetailsScreen> {
  bool _busy = false;

  bool get _isCardPayment =>
      widget.transaction.source == TransactionSource.creditCardPayment;

  FinancingContract? get _contract {
    final matches = widget.contracts.where((contract) {
      final state = contract.lifecycleState.trim().toLowerCase();
      return contract.originReference == widget.transaction.id &&
          state != 'cancelled' &&
          state != 'canceled';
    }).toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    return matches.isEmpty ? null : matches.first;
  }

  bool get _hasInstallmentPlan {
    final contract = _contract;
    if (contract == null) return false;
    return contract.lifecycleState.trim().toLowerCase() != 'terminated';
  }

  List<FinancingInstallment> get _planRows {
    final contract = _contract;
    if (contract == null) return <FinancingInstallment>[];
    return widget.installments.where((item) => item.contractId == contract.contractId).toList()
      ..sort((a, b) {
        final bySequence = a.sequence.compareTo(b.sequence);
        return bySequence != 0 ? bySequence : a.dueDate.compareTo(b.dueDate);
      });
  }

  bool _isSettled(FinancingInstallment item) {
    final status = item.status.trim().toLowerCase();
    return status == 'settled' || status == 'paid';
  }

  bool _isOutstanding(FinancingInstallment item) {
    final status = item.status.trim().toLowerCase();
    return status != 'settled' && status != 'paid' && status != 'cancelled' &&
        status != 'canceled' && status != 'superseded' && status != 'terminated';
  }

  DateTime? get _paymentDate {
    if (_isCardPayment) return widget.transaction.date;
    if (_hasInstallmentPlan) {
      return CreditCardTransactionTimingPolicy.firstOutstandingInstallmentDueDateForCharge(
        chargeId: widget.transaction.id,
        contracts: widget.contracts,
        installments: widget.installments,
      );
    }
    final closeDate = CreditCardTransactionTimingPolicy.statementDateForPurchase(
      purchaseDate: widget.transaction.date,
      statementDay: widget.profile.statementDay,
    );
    return CreditCardTransactionTimingPolicy.paymentDateForStatementClose(
      purchaseDate: widget.transaction.date,
      statementCloseDate: closeDate,
      statementDay: widget.profile.statementDay,
      paymentDueDay: widget.profile.paymentDueDay,
      dueDateCalculationMethod: widget.profile.dueDateCalculationMethod,
      dueDaysAfterStatement: widget.profile.dueDaysAfterStatement,
      weekendHolidayPolicy: widget.profile.weekendHolidayPolicy,
    );
  }

  String get _currency => widget.account.currency;

  double get _originalAmount => widget.transaction.amount.abs();

  double get _financedAmount => _hasInstallmentPlan
      ? _contract!.principal.toDouble()
      : _originalAmount;

  double get _downPayment => (_originalAmount - _financedAmount).clamp(0.0, double.infinity).toDouble();

  double get _monthlyInstallment {
    final rows = _planRows;
    if (rows.isNotEmpty) return rows.first.amount.toDouble();
    final contract = _contract;
    if (contract == null || contract.installmentCount <= 0) return 0;
    return contract.principal.toDouble() / contract.installmentCount;
  }

  double get _remainingBalance {
    // Sum only this transaction's outstanding financing installments.
    // Keep this separate from account-level debt totals owned by DebtQueryService.
    var remaining = 0.0;
    for (final item in _planRows) {
      if (_isOutstanding(item)) {
        remaining += item.amount.toDouble();
      }
    }
    return remaining;
  }

  int get _paidCount => _planRows.where(_isSettled).length;

  int get _remainingCount => _planRows.where(_isOutstanding).length;

  String _title(BuildContext context) {
    if (_isCardPayment) {
      return Localizations.localeOf(context).languageCode == 'ar'
          ? 'سداد بطاقة ائتمان'
          : 'Credit Card Payment';
    }
    final subcategory = _transactionSubcategoryTitle(context, widget.transaction);
    if (subcategory != null) return subcategory;
    final category = _transactionCategoryTitle(context, widget.transaction.categoryId);
    if (category != null) return category;
    final note = widget.transaction.note?.split(' • ').first.trim();
    if (note != null && note.isNotEmpty) return note;
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'عملية بطاقة ائتمان'
        : 'Credit Card Purchase';
  }

  Future<void> _editTransaction() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpensesScreen(
          transactionToEdit: widget.transaction,
          creditCardAccount: widget.account,
        ),
      ),
    );
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _convertToInstallment() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreditCardInstallmentConversionScreen(
          account: widget.account,
          profile: widget.profile,
        ),
      ),
    );
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _viewInstallmentPlan() async {
    final contract = _contract;
    if (contract == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreditCardInstallmentContractScreen(
          contract: contract,
          installments: _planRows,
          transaction: widget.transaction,
          currency: _currency,
        ),
      ),
    );
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _deleteTransaction() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _rowPanel,
        title: Text(isArabic ? 'حذف العملية؟' : 'Delete transaction?'),
        content: Text(
          isArabic
              ? 'سيتحقق التطبيق من إمكانية حذف العملية قبل تنفيذ الطلب.'
              : 'The app will validate whether this transaction can be deleted before processing the request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: _pink)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await context.read<TransactionApplicationService>().delete(widget.transaction.id);
      if (!mounted) return;
      if (result is OperationSucceeded) {
        Navigator.of(context).pop(true);
      } else {
        final message = result is OperationRejected
            ? result.reason
            : result is DomainViolationResult
                ? result.reason
                : isArabic
                    ? 'تعذر حذف العملية وفق قواعد النظام الحالية.'
                    : 'The transaction could not be deleted under the current rules.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final transaction = widget.transaction;
    final contract = _contract;
    final planRows = _planRows;
    final outstandingPlanRows = planRows.where(_isOutstanding).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final firstOutstandingSequence = outstandingPlanRows.isNotEmpty
        ? outstandingPlanRows.first.sequence
        : contract?.installmentCount ?? 0;
    final installmentProgress = contract == null
        ? null
        : '$firstOutstandingSequence/${contract.installmentCount}';
    final paymentDate = _paymentDate;
    final categoryTitle = _transactionCategoryTitle(context, transaction.categoryId);
    final subcategoryTitle = _transactionSubcategoryTitle(context, transaction);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(isArabic ? 'تفاصيل العملية' : 'Transaction Details', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(m.spacing(16), 4, m.spacing(16), 24),
        children: [
          Container(
            padding: EdgeInsets.all(m.spacing(14)),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(m.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .08))),
            child: Row(
              children: [
                Container(width: m.size(48), height: m.size(48), alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFF182B45), shape: BoxShape.circle), child: _categoryIcon(transaction.categoryId, m.size(25), isPayment: _isCardPayment)),
                SizedBox(width: m.spacing(11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title(context), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: m.text(15), fontWeight: FontWeight.w900)),
                      SizedBox(height: m.spacing(4)),
                      Text(DateFormat('dd MMM yyyy', locale).format(transaction.date), style: TextStyle(color: Colors.white60, fontSize: m.text(10))),
                      if (subcategoryTitle != null && categoryTitle != null && subcategoryTitle != categoryTitle) ...[
                        SizedBox(height: m.spacing(3)),
                        Text(categoryTitle, style: TextStyle(color: Colors.white54, fontSize: m.text(9))),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: m.spacing(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_originalAmount.toStringAsFixed(2)} $_currency', maxLines: 1, style: TextStyle(fontSize: m.text(13), fontWeight: FontWeight.w900)),
                    if (_hasInstallmentPlan) ...[
                      SizedBox(height: m.spacing(4)),
                      Text(
                        'Installment ${installmentProgress ?? '—'}',
                        style: TextStyle(color: _cyan, fontSize: m.text(9), fontWeight: FontWeight.w800),
                      ),
                    ] else if (!_isCardPayment) ...[
                      SizedBox(height: m.spacing(4)),
                      Text(isArabic ? 'شراء عادي' : 'Regular', style: TextStyle(color: _green, fontSize: m.text(9), fontWeight: FontWeight.w800)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: m.spacing(18)),
          Text(isArabic ? 'الملخص المالي' : 'Financial Summary', style: TextStyle(fontSize: m.text(16), fontWeight: FontWeight.w900)),
          SizedBox(height: m.spacing(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: m.spacing(13), vertical: m.spacing(3)),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(m.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .08))),
            child: Column(
              children: [
                if (_hasInstallmentPlan) ...[
                  _DetailValueRow(label: isArabic ? 'قيمة الشراء الأصلية' : 'Original purchase', value: _money(_originalAmount, _currency)),
                  _DetailValueRow(label: isArabic ? 'الدفعة المقدمة' : 'Down payment', value: _money(_downPayment, _currency)),
                  _DetailValueRow(label: isArabic ? 'المبلغ المموّل' : 'Financed amount', value: _money(_financedAmount, _currency)),
                  _DetailValueRow(label: isArabic ? 'القسط الشهري' : 'Monthly installment', value: _money(_monthlyInstallment, _currency)),
                  _DetailValueRow(label: isArabic ? 'الأقساط المسددة' : 'Paid installments', value: '${_paidCount} of ${contract!.installmentCount}'),
                  _DetailValueRow(label: isArabic ? 'الأقساط المتبقية' : 'Remaining installments', value: '${_remainingCount} of ${contract!.installmentCount}'),
                  _DetailValueRow(label: isArabic ? 'الرصيد المتبقي' : 'Remaining balance', value: _money(_remainingBalance, _currency), last: true),
                ] else ...[
                  _DetailValueRow(label: isArabic ? 'قيمة العملية' : 'Transaction amount', value: _money(_originalAmount, _currency)),
                  _DetailValueRow(label: isArabic ? 'تاريخ العملية' : 'Transaction date', value: DateFormat('dd MMM yyyy', locale).format(transaction.date)),
                  _DetailValueRow(label: isArabic ? 'شهر الدفع المتوقع' : 'Payment month', value: paymentDate == null ? (isArabic ? 'غير محدد' : 'Not scheduled') : DateFormat.yMMM(locale).format(paymentDate)),
                  _DetailValueRow(label: isArabic ? 'الفئة الرئيسية' : 'Main category', value: categoryTitle ?? '—'),
                  _DetailValueRow(label: isArabic ? 'الفئة الفرعية' : 'Subcategory', value: subcategoryTitle ?? '—', last: true),
                ],
              ],
            ),
          ),
          SizedBox(height: m.spacing(18)),
          Text(isArabic ? 'الإجراءات' : 'Actions', style: TextStyle(fontSize: m.text(16), fontWeight: FontWeight.w900)),
          SizedBox(height: m.spacing(8)),
          Container(
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(m.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .08))),
            child: Column(
              children: [
                if (_hasInstallmentPlan)
                  _ActionItem(
                    icon: Icons.calendar_month_rounded,
                    label: isArabic ? 'عرض خطة الأقساط' : 'View installment plan',
                    onTap: _busy ? null : _viewInstallmentPlan,
                  ),
                _ActionItem(
                  icon: Icons.edit_outlined,
                  label: isArabic ? 'تعديل العملية' : 'Edit transaction',
                  onTap: _busy ? null : _editTransaction,
                ),
                if (!_hasInstallmentPlan && !_isCardPayment)
                  _ActionItem(
                    icon: Icons.autorenew_rounded,
                    label: isArabic ? 'تحويل إلى أقساط' : 'Convert to installment',
                    onTap: _busy ? null : _convertToInstallment,
                  ),
                _ActionItem(
                  icon: Icons.delete_outline_rounded,
                  label: _busy
                      ? (isArabic ? 'جارٍ الحذف...' : 'Deleting...')
                      : (isArabic ? 'حذف العملية' : 'Delete transaction'),
                  destructive: true,
                  onTap: _busy ? null : _deleteTransaction,
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailValueRow extends StatelessWidget {
  const _DetailValueRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: m.spacing(11)),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08)))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white70, fontSize: m.text(10.5)))),
          SizedBox(width: m.spacing(8)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontSize: m.text(11), fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label, required this.onTap, this.destructive = false, this.last = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final color = destructive ? const Color(0xFFFF405C) : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: m.spacing(13), vertical: m.spacing(13)),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08)))),
        child: Row(
          children: [
            Icon(icon, color: destructive ? const Color(0xFFFF405C) : Colors.white70, size: m.size(21)),
            SizedBox(width: m.spacing(11)),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: m.text(12), fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded, color: destructive ? const Color(0xFFFF405C) : Colors.white54, size: m.size(21)),
          ],
        ),
      ),
    );
  }
}

String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';

String? _transactionCategoryTitle(BuildContext context, String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) return null;
  for (final type in CategoryType.values) {
    for (final category in getCategories(type)) {
      if (category.id == categoryId) return category.resolveTitle(AppLocalizations.of(context)!);
    }
  }
  return null;
}

String? _transactionSubcategoryTitle(BuildContext context, Transaction transaction) {
  final subCategoryId = transaction.subCategoryId;
  if (subCategoryId == null || subCategoryId.isEmpty) return null;
  final t = AppLocalizations.of(context)!;
  for (final type in CategoryType.values) {
    for (final category in getCategories(type)) {
      for (final sub in category.subCategories ?? const <SubCategoryConfig>[]) {
        if (sub.id == subCategoryId) return sub.title(t);
      }
    }
  }
  return null;
}

Widget _categoryIcon(String? categoryId, double size, {bool isPayment = false}) {
  if (isPayment) return Icon(Icons.payments_outlined, color: const Color(0xFF8CB3FF), size: size);
  if (categoryId == null || categoryId.isEmpty) return Icon(Icons.shopping_cart_outlined, color: const Color(0xFF8CB3FF), size: size);
  CategoryConfig? found;
  for (final type in CategoryType.values) {
    for (final category in getCategories(type)) {
      if (category.id == categoryId) {
        found = category;
        break;
      }
    }
    if (found != null) break;
  }
  if (found == null) return Icon(Icons.shopping_cart_outlined, color: const Color(0xFF8CB3FF), size: size);
  return Padding(
    padding: const EdgeInsets.all(3),
    child: SvgPicture.asset(found.icon, width: size, height: size, fit: BoxFit.contain, placeholderBuilder: (_) => Icon(Icons.category_outlined, color: const Color(0xFF8CB3FF), size: size)),
  );
}
