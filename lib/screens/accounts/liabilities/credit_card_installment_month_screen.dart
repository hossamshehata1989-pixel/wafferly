import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/money/money.dart';
import '../../../models/financing/financing_contract.dart';
import '../../../models/financing/financing_installment.dart';
import '../../../models/transaction.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';

const _pink = Color(0xFFFF3D81);
const _green = Color(0xFF00D99A);
const _blue = Color(0xFF168BFF);
const _muted = Color(0xFF536A80);
const _panel = Color(0xFF071D2B);

/// Monthly drill-down for credit-card installments. Each contract appears once
/// if it has at least one installment due in the selected month.
class CreditCardInstallmentMonthScreen extends StatelessWidget {
  const CreditCardInstallmentMonthScreen({
    super.key,
    required this.month,
    required this.monthInstallments,
    required this.allInstallments,
    required this.contracts,
    required this.transactions,
    required this.currency,
  });

  final DateTime month;
  final List<FinancingInstallment> monthInstallments;
  final List<FinancingInstallment> allInstallments;
  final List<FinancingContract> contracts;
  final List<Transaction> transactions;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat('MMM yyyy', locale).format(month);
    final monthTotal = monthInstallments.fold<Money>(
      Money.zero,
      (sum, item) => sum + item.amount,
    );
    final paidCount = monthInstallments.where(_isSettled).length;
    final groupedContracts = <String, FinancingContract>{};
    for (final item in monthInstallments) {
      final contract = _contractById(item.contractId);
      if (contract != null) groupedContracts[contract.contractId] = contract;
    }
    final purchases = groupedContracts.values.toList()
      ..sort((a, b) => a.firstDueDate.compareTo(b.firstDueDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: metrics.text(20))),
            Text(
              '${purchases.length} ${purchases.length == 1 ? 'installment purchase' : 'installment purchases'}',
              style: TextStyle(color: Colors.white60, fontSize: metrics.text(11)),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(metrics.spacing(16), metrics.spacing(4), metrics.spacing(16), metrics.spacing(24)),
        children: [
          _MonthProgressCard(
            monthTotal: monthTotal.toDouble(),
            currency: currency,
            total: monthInstallments.length,
            paid: paidCount,
            installments: monthInstallments,
            metrics: metrics,
          ),
          SizedBox(height: metrics.spacing(22)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Installment Purchases (${purchases.length})',
                  style: TextStyle(fontSize: metrics.text(17), fontWeight: FontWeight.w800),
                ),
              ),
              Text(_money(monthTotal.toDouble(), currency), style: TextStyle(color: Colors.white70, fontSize: metrics.text(12), fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: metrics.spacing(10)),
          if (purchases.isEmpty)
            const _EmptyPanel(message: 'No installment purchases due this month.')
          else
            ...purchases.map((contract) {
              final contractInstallments = allInstallments
                  .where((item) => item.contractId == contract.contractId)
                  .toList()
                ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
              final dueInMonth = monthInstallments
                  .where((item) => item.contractId == contract.contractId)
                  .toList();
              final paid = contractInstallments.where(_isSettled).length;
              final transaction = _transactionFor(contract);
              final name = _operationName(transaction);
              return Padding(
                padding: EdgeInsets.only(bottom: metrics.spacing(9)),
                child: Material(
                  color: _panel,
                  borderRadius: BorderRadius.circular(metrics.radius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(metrics.radius.md),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreditCardInstallmentContractScreen(
                          contract: contract,
                          installments: contractInstallments,
                          transaction: transaction,
                          currency: currency,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(metrics.spacing(12)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(metrics.radius.md),
                        border: Border.all(color: Colors.white.withValues(alpha: .07)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: metrics.size(46), height: metrics.size(46),
                            decoration: BoxDecoration(color: _pink.withValues(alpha: .13), shape: BoxShape.circle),
                            child: Icon(Icons.shopping_bag_outlined, color: _pink, size: metrics.size(23)),
                          ),
                          SizedBox(width: metrics.spacing(11)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: metrics.text(14), fontWeight: FontWeight.w800)),
                                SizedBox(height: metrics.spacing(3)),
                                Text(
                                  '${dueInMonth.length} due this month • $paid / ${contractInstallments.length} paid',
                                  style: TextStyle(color: Colors.white60, fontSize: metrics.text(10.5)),
                                ),
                                SizedBox(height: metrics.spacing(8)),
                                _MiniTimeline(installments: contractInstallments, metrics: metrics),
                              ],
                            ),
                          ),
                          SizedBox(width: metrics.spacing(8)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_money(contract.principal.toDouble(), currency), style: TextStyle(fontSize: metrics.text(12), fontWeight: FontWeight.w800)),
                              SizedBox(height: metrics.spacing(5)),
                              Text('${contractInstallments.length} installments', style: TextStyle(color: Colors.white60, fontSize: metrics.text(10))),
                              Icon(Icons.chevron_right_rounded, color: Colors.white60, size: metrics.size(22)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          SizedBox(height: metrics.spacing(12)),
          _TotalsPanel(
            total: monthTotal.toDouble(),
            paid: monthInstallments.where(_isSettled).fold<Money>(Money.zero, (sum, item) => sum + item.amount).toDouble(),
            current: _currentMonthAmount(monthInstallments).toDouble(),
            remaining: monthInstallments.where((item) => !_isSettled(item) && !_isCurrent(item, monthInstallments)).fold<Money>(Money.zero, (sum, item) => sum + item.amount).toDouble(),
            currency: currency,
            metrics: metrics,
          ),
        ],
      ),
    );
  }

  FinancingContract? _contractById(String id) {
    for (final contract in contracts) {
      if (contract.contractId == id) return contract;
    }
    return null;
  }

  Transaction? _transactionFor(FinancingContract contract) {
    for (final transaction in transactions) {
      if (transaction.id == contract.originReference) return transaction;
    }
    return null;
  }

  String _operationName(Transaction? transaction) {
    final note = transaction?.note?.trim();
    if (note != null && note.isNotEmpty &&
        note.toLowerCase() != 'installment purchase') {
      return note;
    }
    return 'Credit Card Purchase';
  }
}

class CreditCardInstallmentContractScreen extends StatefulWidget {
  const CreditCardInstallmentContractScreen({
    super.key,
    required this.contract,
    required this.installments,
    required this.transaction,
    required this.currency,
  });

  final FinancingContract contract;
  final List<FinancingInstallment> installments;
  final Transaction? transaction;
  final String currency;

  @override
  State<CreditCardInstallmentContractScreen> createState() => _CreditCardInstallmentContractScreenState();
}

class _CreditCardInstallmentContractScreenState extends State<CreditCardInstallmentContractScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final items = [...widget.installments]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final paidCount = items.where(_isSettled).length;
    final currentIndex = items.indexWhere((item) => !_isSettled(item));
    final visibleItems = _showAll || items.length <= 5 ? items : items.take(5).toList();
    final note = widget.transaction?.note?.trim();
    final operationName = note != null && note.isNotEmpty &&
            note.toLowerCase() != 'installment purchase'
        ? note
        : 'Credit Card Purchase';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text('Installment Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: metrics.text(20))),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(metrics.spacing(16), metrics.spacing(4), metrics.spacing(16), metrics.spacing(24)),
        children: [
          Container(
            padding: EdgeInsets.all(metrics.spacing(14)),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(metrics.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .07))),
            child: Row(
              children: [
                Container(width: metrics.size(48), height: metrics.size(48), decoration: BoxDecoration(color: const Color(0xFF713CE7).withValues(alpha: .22), shape: BoxShape.circle), child: Icon(Icons.shopping_bag_outlined, color: const Color(0xFFB69AFF), size: metrics.size(24))),
                SizedBox(width: metrics.spacing(12)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(operationName, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: metrics.text(15))), SizedBox(height: metrics.spacing(4)), Text('${widget.contract.installmentCount} installments • ${widget.contract.paymentFrequency}', style: TextStyle(color: Colors.white60, fontSize: metrics.text(11)))])),
                SizedBox(width: metrics.spacing(8)),
                Text(_money(widget.contract.principal.toDouble(), widget.currency), textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w800, fontSize: metrics.text(13))),
              ],
            ),
          ),
          SizedBox(height: metrics.spacing(12)),
          Container(
            padding: EdgeInsets.all(metrics.spacing(14)),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(metrics.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .07))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('Installment Timeline', style: TextStyle(fontSize: metrics.text(16), fontWeight: FontWeight.w800))), if (items.length > 5) TextButton(onPressed: () => setState(() => _showAll = !_showAll), child: Text(_showAll ? 'Show Less' : 'View All', style: const TextStyle(color: Color(0xFF00C8F0))))]),
              SizedBox(height: metrics.spacing(12)),
              _TimelineRail(installments: items, currentIndex: currentIndex, metrics: metrics, locale: locale),
              SizedBox(height: metrics.spacing(12)),
              Divider(color: Colors.white.withValues(alpha: .09)),
              ...visibleItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isPaid = _isSettled(item);
                final isCurrent = !isPaid && index == currentIndex;
                final color = isPaid ? _green : (isCurrent ? _blue : _muted);
                final status = isPaid ? 'Paid' : (isCurrent ? 'Next Payment' : 'Upcoming');
                return Container(
                  padding: EdgeInsets.symmetric(vertical: metrics.spacing(10), horizontal: metrics.spacing(2)),
                  decoration: BoxDecoration(color: isCurrent ? _blue.withValues(alpha: .08) : Colors.transparent, border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .06)))),
                  child: Row(children: [Icon(isPaid ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.circle_outlined), color: color, size: metrics.size(19)), SizedBox(width: metrics.spacing(10)), Expanded(child: Text(DateFormat.yMMMd(locale).format(item.dueDate), style: TextStyle(fontSize: metrics.text(12), color: Colors.white.withValues(alpha: .86)))), SizedBox(width: metrics.spacing(6)), Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: metrics.text(11))), SizedBox(width: metrics.spacing(8)), Text(_money(item.amount.toDouble(), widget.currency), style: TextStyle(fontSize: metrics.text(12), fontWeight: FontWeight.w800))]),
                );
              }),
              if (!_showAll && items.length > visibleItems.length)
                TextButton.icon(onPressed: () => setState(() => _showAll = true), icon: const Icon(Icons.keyboard_arrow_down_rounded), label: Text('+${items.length - visibleItems.length} more installments')),
            ]),
          ),
          SizedBox(height: metrics.spacing(12)),
          Container(
            padding: EdgeInsets.all(metrics.spacing(14)),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(metrics.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .07))),
            child: Column(children: [
              _DetailRow(label: 'Original Amount', value: _money(widget.contract.principal.toDouble(), widget.currency)),
              _DetailRow(label: 'Installment Amount', value: items.isEmpty ? '—' : _money(items.first.amount.toDouble(), widget.currency)),
              _DetailRow(label: 'Total Installments', value: '${widget.contract.installmentCount}'),
              _DetailRow(label: 'Paid Installments', value: '$paidCount'),
              _DetailRow(label: 'Remaining Installments', value: '${items.length - paidCount}'),
              _DetailRow(label: 'Next Due Date', value: currentIndex < 0 ? '—' : DateFormat.yMMMd(locale).format(items[currentIndex].dueDate)),
              _DetailRow(label: 'Status', value: paidCount == items.length ? 'Completed' : (currentIndex >= 0 && items[currentIndex].dueDate.isBefore(DateTime.now()) ? 'Overdue' : 'Active'), last: true),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MonthProgressCard extends StatelessWidget {
  const _MonthProgressCard({required this.monthTotal, required this.currency, required this.total, required this.paid, required this.installments, required this.metrics});
  final double monthTotal;
  final String currency;
  final int total;
  final int paid;
  final List<FinancingInstallment> installments;
  final ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final current = installments.indexWhere((item) => !_isSettled(item));
    return Container(
      padding: EdgeInsets.all(metrics.spacing(15)),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(metrics.radius.lg), border: Border.all(color: const Color(0xFF00BBD4).withValues(alpha: .25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.calendar_month_rounded, color: Color(0xFF7FE8F2)), SizedBox(width: metrics.spacing(9)), Expanded(child: Text('Month Progress', style: TextStyle(fontSize: metrics.text(15), fontWeight: FontWeight.w800))), Text('$paid / $total paid', style: TextStyle(color: Colors.white70, fontSize: metrics.text(11)))]),
        SizedBox(height: metrics.spacing(22)),
        _TimelineRail(installments: installments, currentIndex: current, metrics: metrics, locale: Localizations.localeOf(context).toLanguageTag(), compact: true),
        SizedBox(height: metrics.spacing(16)),
        Row(children: [Expanded(child: _LegendDot(color: _green, label: 'Paid')), Expanded(child: _LegendDot(color: _blue, label: 'Current')), Expanded(child: _LegendDot(color: _muted, label: 'Upcoming'))]),
        SizedBox(height: metrics.spacing(12)),
        Divider(color: Colors.white.withValues(alpha: .08)),
        Row(children: [const Icon(Icons.payments_outlined, color: _pink), SizedBox(width: metrics.spacing(8)), Expanded(child: Text('Month Total', style: TextStyle(color: Colors.white70, fontSize: metrics.text(12)))), Text(_money(monthTotal, currency), style: TextStyle(fontWeight: FontWeight.w900, fontSize: metrics.text(15)))]),
      ]),
    );
  }
}

class _MiniTimeline extends StatelessWidget {
  const _MiniTimeline({required this.installments, required this.metrics});
  final List<FinancingInstallment> installments;
  final ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final current = installments.indexWhere((item) => !_isSettled(item));
    return SizedBox(height: metrics.size(12), child: Row(children: [for (var i = 0; i < installments.length; i++) ...[
      Container(width: metrics.size(9), height: metrics.size(9), decoration: BoxDecoration(shape: BoxShape.circle, color: _isSettled(installments[i]) ? _green : (i == current ? _blue : _muted), border: Border.all(color: Colors.white.withValues(alpha: .1)))),
      if (i < installments.length - 1) Expanded(child: Container(height: 2, color: i < current ? _green : _muted.withValues(alpha: .7))),
    ]])) ;
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({
    required this.installments,
    required this.currentIndex,
    required this.metrics,
    required this.locale,
    this.compact = false,
  });

  final List<FinancingInstallment> installments;
  final int currentIndex;
  final ResponsiveMetrics metrics;
  final String locale;
  final bool compact;

  List<int> _visibleIndices() {
    final length = installments.length;
    final maxNodes = compact ? 7 : 5;
    if (length <= maxNodes) {
      return List<int>.generate(length, (index) => index);
    }

    // Keep the beginning, current installment, and end of the timeline visible.
    // Indices remain tied to the original list so status and labels never drift.
    final selected = <int>{0, 1, length - 2, length - 1};
    if (currentIndex >= 0) selected.add(currentIndex);

    // Fill remaining slots at regular intervals when the current item overlaps
    // one of the anchors above.
    for (var i = 1; selected.length < maxNodes && i < maxNodes * 3; i++) {
      selected.add(((length - 1) * i / (maxNodes - 1)).round());
    }
    final result = selected.where((i) => i >= 0 && i < length).toList()..sort();
    if (result.length > maxNodes) {
      // Preserve the current marker and endpoints; remove interior points first.
      while (result.length > maxNodes) {
        final removable = result.indexWhere(
          (i) => i != 0 && i != length - 1 && i != currentIndex && i != 1 && i != length - 2,
        );
        if (removable < 0) break;
        result.removeAt(removable);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (installments.isEmpty) return const SizedBox.shrink();
    final indices = _visibleIndices();
    final shown = indices.map((index) => installments[index]).toList();

    return Column(
      children: [
        SizedBox(
          height: metrics.size(compact ? 30 : 38),
          child: Row(
            children: [
              for (var slot = 0; slot < shown.length; slot++) ...[
                Builder(builder: (_) {
                  final originalIndex = indices[slot];
                  final item = shown[slot];
                  final paid = _isSettled(item);
                  final isCurrent = !paid && originalIndex == currentIndex;
                  final color = paid ? _green : (isCurrent ? _blue : const Color(0xFF263D52));
                  final borderColor = paid ? _green : (isCurrent ? _blue : const Color(0xFF526A80));
                  return Container(
                    width: metrics.size(compact ? 21 : 27),
                    height: metrics.size(compact ? 21 : 27),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: paid
                        ? Icon(Icons.check_rounded, size: metrics.size(compact ? 13 : 17), color: Colors.white)
                        : null,
                  );
                }),
                if (slot < shown.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      color: indices[slot] < currentIndex ? _green : const Color(0xFF43596D),
                    ),
                  ),
              ],
            ],
          ),
        ),
        SizedBox(height: metrics.spacing(6)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var slot = 0; slot < shown.length; slot++)
              Expanded(
                child: Builder(builder: (_) {
                  final originalIndex = indices[slot];
                  final item = shown[slot];
                  final paid = _isSettled(item);
                  final isCurrent = !paid && originalIndex == currentIndex;
                  final statusColor = paid ? _green : (isCurrent ? _blue : Colors.white70);
                  return Column(
                    children: [
                      Text(
                        compact ? '${originalIndex + 1}' : '${item.sequence}',
                        style: TextStyle(fontSize: metrics.text(compact ? 10 : 12), fontWeight: FontWeight.w800),
                      ),
                      if (!compact) ...[
                        SizedBox(height: metrics.spacing(3)),
                        Text(
                          DateFormat('d MMM', locale).format(item.dueDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: metrics.text(10), color: Colors.white70),
                        ),
                        Text(
                          paid ? 'Paid' : (isCurrent ? 'Current' : 'Upcoming'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: metrics.text(10), color: statusColor, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({required this.total, required this.paid, required this.current, required this.remaining, required this.currency, required this.metrics});
  final double total, paid, current, remaining;
  final String currency;
  final ResponsiveMetrics metrics;
  @override
  Widget build(BuildContext context) => Container(padding: EdgeInsets.all(metrics.spacing(13)), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(metrics.radius.md), border: Border.all(color: Colors.white.withValues(alpha: .07))), child: Column(children: [Row(children: [const Icon(Icons.calendar_month_rounded, color: _pink), SizedBox(width: metrics.spacing(8)), Expanded(child: Text('Month Total', style: TextStyle(color: Colors.white70, fontSize: metrics.text(12)))), Text(_money(total, currency), style: TextStyle(fontWeight: FontWeight.w800, fontSize: metrics.text(13)))]), SizedBox(height: metrics.spacing(12)), Row(children: [Expanded(child: _TotalColumn(label: 'Paid', value: paid, currency: currency, color: _green, metrics: metrics)), Expanded(child: _TotalColumn(label: 'Current', value: current, currency: currency, color: _blue, metrics: metrics)), Expanded(child: _TotalColumn(label: 'Remaining', value: remaining, currency: currency, color: _pink, metrics: metrics))]) ]));
}

class _TotalColumn extends StatelessWidget {
  const _TotalColumn({required this.label, required this.value, required this.currency, required this.color, required this.metrics});
  final String label, currency;
  final double value;
  final Color color;
  final ResponsiveMetrics metrics;
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: TextStyle(color: Colors.white60, fontSize: metrics.text(10))), SizedBox(height: metrics.spacing(5)), FittedBox(child: Text(_money(value, currency), style: TextStyle(color: color, fontSize: metrics.text(12), fontWeight: FontWeight.w900)))]);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Flexible(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)))]);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.last = false});
  final String label, value;
  final bool last;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .07)))), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))), const SizedBox(width: 8), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))]));
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)));
}

bool _isSettled(FinancingInstallment item) => item.status.trim().toLowerCase() == 'settled';
bool _isCurrent(FinancingInstallment item, List<FinancingInstallment> items) => items.indexWhere((candidate) => !_isSettled(candidate)) == items.indexOf(item);
Money _currentMonthAmount(List<FinancingInstallment> items) {
  final index = items.indexWhere((item) => !_isSettled(item));
  return index < 0 ? Money.zero : items[index].amount;
}
String _money(double amount, String currency) => '${amount.toStringAsFixed(2)} $currency';
