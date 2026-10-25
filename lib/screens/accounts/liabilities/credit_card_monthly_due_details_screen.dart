import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../application/credit_card/credit_card_monthly_due_projection_calculator.dart';
import '../../../application/credit_card/credit_card_transaction_timing_policy.dart';
import '../../../config/category_config.dart';
import '../../../config/category_type.dart';
import '../../../constants/transaction_constants.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../models/account.dart';
import '../../../models/financing/financing_contract.dart';
import '../../../models/financing/financing_installment.dart';
import '../../../models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import 'credit_card_transaction_details_screen.dart';

const _pink = Color(0xFFFF3D81);
const _cyan = Color(0xFF42C9FF);
const _green = Color(0xFF00D99A);
const _panel = Color(0xFF0A1C29);
const _rowPanel = Color(0xFF102638);

class CreditCardMonthlyDueDetailsScreen extends StatefulWidget {
  const CreditCardMonthlyDueDetailsScreen({
    super.key,
    required this.monthProjection,
    required this.currency,
    required this.account,
    required this.profile,
    required this.transactions,
    required this.contracts,
    required this.installments,
  });

  final CreditCardMonthDueProjection monthProjection;
  final String currency;
  final Account account;
  final CreditCardProfile profile;
  final List<Transaction> transactions;
  final List<FinancingContract> contracts;
  final List<FinancingInstallment> installments;

  @override
  State<CreditCardMonthlyDueDetailsScreen> createState() =>
      _CreditCardMonthlyDueDetailsScreenState();
}

class _CreditCardMonthlyDueDetailsScreenState
    extends State<CreditCardMonthlyDueDetailsScreen> {
  int _activeTab = 0; // Installments first, matching the approved design.

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  bool _isInactiveStatus(String status) {
    final value = status.trim().toLowerCase();
    return value == 'settled' ||
        value == 'paid' ||
        value == 'cancelled' ||
        value == 'canceled' ||
        value == 'superseded' ||
        value == 'terminated';
  }

  FinancingContract? _contractForCharge(String chargeId) {
    final matches = widget.contracts.where((contract) {
      final state = contract.lifecycleState.trim().toLowerCase();
      return contract.originReference == chargeId &&
          state != 'cancelled' &&
          state != 'canceled';
    }).toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    return matches.isEmpty ? null : matches.first;
  }

  Transaction? _transactionForContract(FinancingContract contract) {
    for (final transaction in widget.transactions) {
      if (transaction.id == contract.originReference) return transaction;
    }
    return null;
  }

  bool _originalChargeRemainsInStatement(Transaction transaction) {
    final closeDate = CreditCardTransactionTimingPolicy.statementDateForPurchase(
      purchaseDate: transaction.date,
      statementDay: widget.profile.statementDay,
    );
    final contract = _contractForCharge(transaction.id);
    if (contract == null) return true;
    // Match the existing projection rule: a conversion before/on cycle close
    // replaces the purchase charge; a later conversion cannot rewrite a closed cycle.
    return _dateOnly(contract.effectiveDate).isAfter(_dateOnly(closeDate));
  }

  DateTime _regularPurchasePaymentDate(Transaction transaction) {
    final closeDate = CreditCardTransactionTimingPolicy.statementDateForPurchase(
      purchaseDate: transaction.date,
      statementDay: widget.profile.statementDay,
    );
    return CreditCardTransactionTimingPolicy.paymentDateForStatementClose(
      purchaseDate: transaction.date,
      statementCloseDate: closeDate,
      statementDay: widget.profile.statementDay,
      paymentDueDay: widget.profile.paymentDueDay,
      dueDateCalculationMethod: widget.profile.dueDateCalculationMethod,
      dueDaysAfterStatement: widget.profile.dueDaysAfterStatement,
      weekendHolidayPolicy: widget.profile.weekendHolidayPolicy,
    );
  }

  List<FinancingInstallment> get _installmentsForMonth {
    final month = widget.monthProjection.monthStart;
    final items = widget.installments.where((item) {
      final contract = widget.contracts.where((c) => c.contractId == item.contractId).toList();
      if (contract.isEmpty || contract.first.lifecycleState.trim().toLowerCase() == 'terminated') {
        return false;
      }
      return _sameMonth(item.dueDate, month) && !_isInactiveStatus(item.status);
    }).toList()
      ..sort((a, b) {
        final byDate = a.dueDate.compareTo(b.dueDate);
        return byDate != 0 ? byDate : a.sequence.compareTo(b.sequence);
      });
    return items;
  }

  List<Transaction> get _regularPurchasesForMonth {
    final month = widget.monthProjection.monthStart;
    final today = _dateOnly(DateTime.now());
    final items = widget.transactions.where((transaction) {
      if (transaction.type != TransactionType.creditCardCharge ||
          transaction.toAccountId != widget.account.id ||
          _dateOnly(transaction.date).isAfter(today) ||
          !_originalChargeRemainsInStatement(transaction)) {
        return false;
      }
      return _sameMonth(_regularPurchasePaymentDate(transaction), month);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> _openTransactionDetails(Transaction transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreditCardTransactionDetailsScreen(
          transaction: transaction,
          account: widget.account,
          profile: widget.profile,
          contracts: widget.contracts,
          installments: widget.installments,
        ),
      ),
    );
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = widget.monthProjection.monthStart;
    final monthLabel = DateFormat.yMMMM(locale).format(month);
    final installmentRows = _installmentsForMonth;
    final regularRows = _regularPurchasesForMonth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: m.text(19))),
            Text(
              isArabic ? 'تفاصيل المستحقات الشهرية' : 'Monthly Due Details',
              style: TextStyle(color: Colors.white60, fontSize: m.text(10)),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(m.spacing(16), m.spacing(4), m.spacing(16), m.spacing(24)),
        children: [
          Row(
            children: [
              Expanded(
                child: _MonthTypeCard(
                  selected: _activeTab == 0,
                  icon: Icons.layers_rounded,
                  title: isArabic ? 'الأقساط' : 'Installments',
                  amount: widget.monthProjection.installments.toDouble(),
                  count: installmentRows.length,
                  currency: widget.currency,
                  color: _cyan,
                  onTap: () => setState(() => _activeTab = 0),
                ),
              ),
              SizedBox(width: m.spacing(8)),
              Expanded(
                child: _MonthTypeCard(
                  selected: _activeTab == 1,
                  icon: Icons.shopping_bag_outlined,
                  title: isArabic ? 'المشتريات العادية' : 'Regular Purchases',
                  amount: widget.monthProjection.expenses.toDouble(),
                  count: regularRows.length,
                  currency: widget.currency,
                  color: _pink,
                  onTap: () => setState(() => _activeTab = 1),
                ),
              ),
            ],
          ),
          SizedBox(height: m.spacing(10)),
          Container(
            padding: EdgeInsets.all(m.spacing(14)),
            decoration: BoxDecoration(
              color: _rowPanel,
              borderRadius: BorderRadius.circular(m.radius.md),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isArabic ? 'إجمالي مستحقات الشهر' : 'Total Due This Month', style: TextStyle(color: Colors.white60, fontSize: m.text(10))),
                      SizedBox(height: m.spacing(3)),
                      Text(_money(widget.monthProjection.total.toDouble(), widget.currency), style: TextStyle(fontSize: m.text(20), fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Container(width: 1, height: m.size(42), color: Colors.white12),
                SizedBox(width: m.spacing(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${installmentRows.length + regularRows.length}', style: TextStyle(fontSize: m.text(18), fontWeight: FontWeight.w900)),
                    Text(isArabic ? 'عملية مسجلة' : 'Recorded items', style: TextStyle(color: Colors.white60, fontSize: m.text(9))),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: m.spacing(18)),
          Row(
            children: [
              Expanded(
                child: Text(
                  _activeTab == 0
                      ? (isArabic ? 'الأقساط المستحقة' : 'Installments Due')
                      : (isArabic ? 'المشتريات العادية' : 'Regular Purchases'),
                  style: TextStyle(fontSize: m.text(16), fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _money(
                  (_activeTab == 0
                      ? widget.monthProjection.installments
                      : widget.monthProjection.expenses).toDouble(),
                  widget.currency,
                ),
                style: TextStyle(fontSize: m.text(12), fontWeight: FontWeight.w800, color: _activeTab == 0 ? _cyan : _pink),
              ),
            ],
          ),
          SizedBox(height: m.spacing(9)),
          if (_activeTab == 0) ...[
            if (installmentRows.isEmpty)
              _EmptyDueList(message: isArabic ? 'لا توجد أقساط مسجلة لهذا الشهر.' : 'No scheduled installments for this month.')
            else
              ...installmentRows.map((item) {
                final contractMatches = widget.contracts.where((c) => c.contractId == item.contractId).toList();
                final contract = contractMatches.isEmpty ? null : contractMatches.first;
                final purchase = contract == null ? null : _transactionForContract(contract);
                final installmentCountText = contract?.installmentCount.toString() ?? '?';
                return _DueTransactionRow(
                  title: purchase == null ? (isArabic ? 'قسط بطاقة ائتمان' : 'Credit Card Installment') : _transactionTitle(context, purchase),
                  subtitle: purchase == null
                      ? DateFormat('dd MMM yyyy', locale).format(item.dueDate)
                      : '${_transactionCategoryTitle(context, purchase.categoryId) ?? ''}${_transactionCategoryTitle(context, purchase.categoryId) == null ? '' : ' • '}${DateFormat('dd/MM/yy', locale).format(purchase.date)}',
                  amount: item.amount.toDouble(),
                  currency: widget.currency,
                  leading: purchase == null
                      ? const Icon(Icons.receipt_long_rounded, color: _cyan)
                      : _categoryIcon(purchase.categoryId, m.size(22)),
                  typeLabel: isArabic ? 'قسط ${item.sequence}/$installmentCountText' : 'Installment ${item.sequence}/$installmentCountText',
                  typeColor: _cyan,
                  dueLabel: DateFormat('dd MMM yyyy', locale).format(item.dueDate),
                  onTap: purchase == null ? null : () => _openTransactionDetails(purchase),
                );
              }),
          ] else ...[
            if (regularRows.isEmpty)
              _EmptyDueList(message: isArabic ? 'لا توجد مشتريات عادية مسجلة لهذا الشهر.' : 'No regular purchases scheduled for this month.')
            else
              ...regularRows.map((transaction) {
                final dueDate = _regularPurchasePaymentDate(transaction);
                return _DueTransactionRow(
                  title: _transactionTitle(context, transaction),
                  subtitle: '${_transactionCategoryTitle(context, transaction.categoryId) ?? ''}${_transactionCategoryTitle(context, transaction.categoryId) == null ? '' : ' • '}${DateFormat('dd/MM/yy', locale).format(transaction.date)}',
                  amount: transaction.amount,
                  currency: widget.currency,
                  leading: _categoryIcon(transaction.categoryId, m.size(22)),
                  typeLabel: isArabic ? 'شراء عادي' : 'Regular',
                  typeColor: _green,
                  dueLabel: DateFormat('dd MMM yyyy', locale).format(dueDate),
                  onTap: () => _openTransactionDetails(transaction),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _MonthTypeCard extends StatelessWidget {
  const _MonthTypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.amount,
    required this.count,
    required this.currency,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final double amount;
  final int count;
  final String currency;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Material(
      color: const Color(0xFF0B2030),
      borderRadius: BorderRadius.circular(m.radius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(m.radius.md),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(m.spacing(10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(m.radius.md),
            border: Border.all(color: selected ? color : Colors.white.withValues(alpha: .10), width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: m.size(20)),
                  SizedBox(width: m.spacing(6)),
                  Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: m.text(10), fontWeight: FontWeight.w800))),
                ],
              ),
              SizedBox(height: m.spacing(8)),
              Text(_money(amount, currency), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: m.text(14), color: color, fontWeight: FontWeight.w900)),
              SizedBox(height: m.spacing(3)),
              Text('$count ${isArabic ? 'عملية' : (count == 1 ? 'transaction' : 'transactions')}', style: TextStyle(color: Colors.white60, fontSize: m.text(9))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueTransactionRow extends StatelessWidget {
  const _DueTransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.leading,
    required this.typeLabel,
    required this.typeColor,
    required this.dueLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final Widget leading;
  final String typeLabel;
  final Color typeColor;
  final String dueLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: m.spacing(7)),
      child: Material(
        color: const Color(0xFF071D2B),
        borderRadius: BorderRadius.circular(m.radius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(m.radius.md),
          child: Container(
            padding: EdgeInsets.all(m.spacing(11)),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(m.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .08))),
            child: Row(
              children: [
                Container(width: m.size(42), height: m.size(42), alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFF182B45), shape: BoxShape.circle), child: leading),
                SizedBox(width: m.spacing(9)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: m.text(12), fontWeight: FontWeight.w800)),
                      SizedBox(height: m.spacing(2)),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54, fontSize: m.text(9))),
                      SizedBox(height: m.spacing(5)),
                      Text(typeLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: typeColor, fontSize: m.text(9), fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                SizedBox(width: m.spacing(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_money(amount, currency), maxLines: 1, style: TextStyle(fontWeight: FontWeight.w900, fontSize: m.text(11))),
                    SizedBox(height: m.spacing(4)),
                    Text(dueLabel, maxLines: 1, style: TextStyle(color: Colors.white54, fontSize: m.text(8))),
                    Icon(Icons.chevron_right_rounded, size: m.size(18), color: Colors.white38),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDueList extends StatelessWidget {
  const _EmptyDueList({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .07))),
    child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
  );
}

String _transactionTitle(BuildContext context, Transaction transaction) {
  final subcategory = _transactionSubcategoryTitle(context, transaction);
  if (subcategory != null) return subcategory;
  final category = _transactionCategoryTitle(context, transaction.categoryId);
  if (category != null) return category;
  final note = transaction.note?.split(' • ').first.trim();
  if (note != null && note.isNotEmpty) return note;
  return Localizations.localeOf(context).languageCode == 'ar' ? 'عملية بطاقة' : 'Card Purchase';
}

String? _transactionCategoryTitle(BuildContext context, String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) return null;
  for (final type in CategoryType.values) {
    for (final category in getCategories(type)) {
      if (category.id == categoryId) {
        // Localised category resolver is the same one used in the card transaction list.
        return category.resolveTitle(AppLocalizations.of(context)!);
      }
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

Widget _categoryIcon(String? categoryId, double size) {
  if (categoryId == null || categoryId.isEmpty) {
    return Icon(Icons.shopping_cart_outlined, color: const Color(0xFF8CB3FF), size: size);
  }
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

String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';
