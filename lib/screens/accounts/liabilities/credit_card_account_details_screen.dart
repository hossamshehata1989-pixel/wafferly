import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../application/credit_card/credit_card_details_projection_service.dart';
import '../../../application/credit_card/credit_card_financing_application_service.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../models/account.dart';
import '../../../models/financing/financing_installment.dart';
import '../../../models/financing/financing_contract.dart';
import '../../../models/transaction.dart';
import '../../../constants/transaction_constants.dart';
import '../../../services/transaction_query_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../widgets/shared/credit_card_visual.dart';
import '../../../widgets/shared/wafferly_card_visual_layout.dart';
import 'credit_card_installment_conversion_screen.dart';
import 'credit_card_transaction_entry_screen.dart';
import 'package:provider/provider.dart';

class CreditCardAccountDetailsScreen extends StatefulWidget {
  const CreditCardAccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  State<CreditCardAccountDetailsScreen> createState() =>
      _CreditCardAccountDetailsScreenState();
}

class _CreditCardAccountDetailsScreenState
    extends State<CreditCardAccountDetailsScreen> {
  int _tab = 0;

  Future<CreditCardDetailsProjection?> _projection() =>
      CreditCardDetailsProjectionService().project(widget.accountId);

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return FutureBuilder<CreditCardDetailsProjection?>(
      future: _projection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final projection = snapshot.data;
        if (projection == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text(t.creditCardNotFound)),
          );
        }

        final transactions = context
            .read<TransactionQueryService>()
            .getForAccount(widget.accountId)
            .where((tx) => tx.type == TransactionType.creditCardCharge)
            .toList();
        final installments = Hive.box<FinancingInstallment>('financing_installments')
            .values
            .where((item) => _belongsToCard(item))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        final thisMonth = installments
            .where((item) => item.dueDate.year == DateTime.now().year && item.dueDate.month == DateTime.now().month && item.status != 'settled')
            .fold<double>(0, (sum, item) => sum + item.amount.toDouble());

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: m.isCompactHeight ? m.h(48) : m.h(54),
            leadingWidth: m.isCompactHeight ? m.size(48) : m.size(52),
            leading: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: m.isCompactHeight ? m.size(22) : m.size(24),
              ),
            ),
            titleSpacing: 0,
            title: Text(
              'Credit Card',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: m.isCompactHeight ? m.text(20) : m.text(22),
              ),
            ),
            actions: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: m.isCompactHeight ? m.size(40) : m.size(44),
                  minHeight: m.isCompactHeight ? m.size(40) : m.size(44),
                ),
                onPressed: () => _showCardMenu(projection.account, projection.profile),
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: m.isCompactHeight ? m.size(22) : m.size(24),
                ),
              ),
              SizedBox(width: m.spacing(4)),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(m.spacing(16), 6, m.spacing(16), 28),
            children: [
              _CardSummaryVisual(
                account: projection.account,
                profile: projection.profile,
                available: projection.available.toDouble(),
                totalInstallment: installments.fold<double>(
                  0,
                  (sum, item) => sum + item.amount.toDouble(),
                ),
                thisMonthInstallment: thisMonth,
                utilization: projection.utilization,
                overdueDays: _overdueDays(installments),
              ),
              SizedBox(height: m.space.md),
              _ActionGrid(
                onAddTransaction: () => _openEntry(projection.account, projection.profile, CreditCardEntryMode.expense),
                onAddInstallment: () => _openEntry(projection.account, projection.profile, CreditCardEntryMode.installment),
                onConvert: () => _openConvert(projection.account),
                onPay: _showPaymentInfo,
              ),
              SizedBox(height: m.space.sm),
              _StatementImportCard(onTap: _showStatementComingSoon),
              SizedBox(height: m.space.md),
              _SegmentTabs(selected: _tab, onChanged: (value) => setState(() => _tab = value)),
              SizedBox(height: m.space.sm),
              if (_tab == 0) _TransactionsSection(transactions: transactions, currency: projection.account.currency)
              else if (_tab == 1) _InstallmentsSection(installments: installments, currency: projection.account.currency)
              else _StatementsSection(profile: projection.profile),
            ],
          ),
        );
      },
    );
  }

  bool _belongsToCard(FinancingInstallment item) {
    final contracts = Hive.box<FinancingContract>('financing_contracts');
    final contract = contracts.get(item.contractId);
    return contract?.liabilityAccountId == widget.accountId;
  }

  Future<void> _openEntry(Account account, CreditCardProfile profile, CreditCardEntryMode mode) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreditCardTransactionEntryScreen(account: account, profile: profile, initialMode: mode)),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _openConvert(Account account) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreditCardInstallmentConversionScreen(account: account)),
    );
    if (result == true && mounted) setState(() {});
  }

  void _showStatementComingSoon() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Icon(Icons.document_scanner_rounded, size: 72, color: Color(0xFF4D7CFF)),
            SizedBox(height: 14),
            Text('Monthly Statement Import', style: TextStyle(color: Colors.black, fontSize: 21, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('Automatically read your credit card statement and help you import and reconcile transactions.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.4)),
            SizedBox(height: 18),
            _ComingSoonLine(text: 'Supports PDF and images'),
            _ComingSoonLine(text: 'Detects transactions automatically'),
            _ComingSoonLine(text: 'Matches existing transactions'),
            _ComingSoonLine(text: 'Helps with installment detection'),
            SizedBox(height: 18),
            SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: null, child: Text('COMING SOON • PRO', style: TextStyle(fontWeight: FontWeight.w800)))),
          ],
        ),
      ),
    );
  }

  void _showPaymentInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A1C29),
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Card payment entry will use the existing Financial Operation Engine and linked debit account settings.'),
          ],
        ),
      ),
    );
  }

  void _showCardMenu(Account account, CreditCardProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A1C29),
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Card Settings'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.document_scanner_outlined), title: const Text('Import Monthly Statement'), subtitle: const Text('PRO • Coming Soon'), onTap: () { Navigator.pop(context); _showStatementComingSoon(); }),
        ]),
      ),
    );
  }
}

class _CardSummaryVisual extends StatelessWidget {
  const _CardSummaryVisual({
    required this.account,
    required this.profile,
    required this.available,
    required this.totalInstallment,
    required this.thisMonthInstallment,
    required this.utilization,
    required this.overdueDays,
  });

  final Account account;
  final CreditCardProfile profile;
  final double available;
  final double totalInstallment;
  final double thisMonthInstallment;
  final double utilization;
  final int overdueDays;

  @override
  Widget build(BuildContext context) {
    final layout = wafferlyCardLayoutForVisual(profile.cardVisual);

    final m = ResponsiveMetrics.of(context);
    final cardScale = m.isCompactHeight ? 0.80 : 1.0;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final cardWidth = outerConstraints.maxWidth;
        final cardHeight = cardWidth / layout.aspectRatio;

        return SizedBox(
          width: cardWidth,
          height: cardHeight * cardScale,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: cardWidth / cardScale,
              child: AspectRatio(
                aspectRatio: layout.aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(m.size(22)),
                  child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;

            Widget slot(CardTextSlot field, Widget child,
                {bool fillWidth = false}) {
              final definition = layout.slot(field);
              if (definition == null) return const SizedBox.shrink();

              final rect = definition.area.resolve(size);
              return Positioned.fromRect(
                rect: rect,
                child: Padding(
                  padding: definition.area.padding,
                  child: SizedBox(
                    width: rect.width,
                    height: rect.height,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: definition.area.alignment,
                      child: fillWidth
                          ? SizedBox(width: rect.width, child: child)
                          : child,
                    ),
                  ),
                ),
              );
            }

            final usedPercent = (utilization * 100).clamp(0.0, 100.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                CreditCardVisual(
                  key: ValueKey(profile.cardVisual),
                  visual: profile.cardVisual,
                  fit: BoxFit.fill,
                ),

                // Identity: these occupy the safe area above the chip.
                slot(
                  CardTextSlot.cardName,
                  _CardOverlayText(
                    account.name,
                    size: 18,
                    weight: FontWeight.w900,
                  ),
                ),
                slot(
                  CardTextSlot.issuer,
                  _CardOverlayText(
                    '${account.provider ?? 'Credit Card'} • ${profile.cardNetwork ?? 'Network not set'}',
                    size: 9,
                    color: Colors.white70,
                    maxLines: 1,
                  ),
                ),

                // Card number: the data model currently stores the last 4 digits
                // on Account.accountNumber, so keep the visual PAN-safe.
                if ((account.accountNumber ?? '').trim().isNotEmpty)
                  slot(
                    CardTextSlot.maskedNumber,
                    _CardOverlayText(
                      _displayCardNumber(account.accountNumber),
                      size: 13,
                      weight: FontWeight.w700,
                      maxLines: 1,
                    ),
                  ),

                // Financial secondary data
                slot(
                  CardTextSlot.available,
                  _CardCompactStat(
                    label: 'Available',
                    value: _money(available, account.currency),
                    color: const Color(0xFF22E6A8),
                  ),
                ),
                slot(
                  CardTextSlot.creditLimit,
                  _CardCompactStat(
                    label: 'Credit Limit',
                    value: _money(profile.creditLimit.toDouble(), account.currency),
                    color: Colors.white,
                  ),
                ),

                slot(
                  CardTextSlot.monthlyInstallment,
                  _CardOverlayMoneyStat(
                    label: 'This Month Installment',
                    value: _money(thisMonthInstallment, account.currency),
                    color: const Color(0xFFFF2D6F),
                    secondary: overdueDays > 0 ? '$overdueDays days overdue' : null,
                  ),
                ),
                slot(
                  CardTextSlot.totalInstallment,
                  _CardOverlayMoneyStat(
                    label: 'Total Installment',
                    value: _money(totalInstallment, account.currency),
                    color: Colors.white,
                  ),
                ),

                slot(
                  CardTextSlot.statementCycle,
                  _CardCycleInfo(
                    statementDay: profile.statementDay,
                    dueDay: profile.paymentDueDay,
                  ),
                ),

                slot(
                  CardTextSlot.usedPercent,
                  _CardUsageOverlay(
                    utilization: utilization,
                    usedPercent: usedPercent,
                    available: available,
                    currency: account.currency,
                  ),
                  fillWidth: true,
                ),
              ],
            );
                  },
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}

class _CardOverlayText extends StatelessWidget {
  const _CardOverlayText(
    this.text, {
    required this.size,
    this.weight = FontWeight.w600,
    this.color = Colors.white,
    this.maxLines = 1,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
    );
  }
}

// تم إلغاء الخلفية السوداء وتكبير الخطوط
class _CardCompactStat extends StatelessWidget {
  const _CardCompactStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9, // تم التكبير
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15, // تم التكبير
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

// تم إلغاء الخلفية السوداء وتكبير الخطوط
class _CardOverlayMoneyStat extends StatelessWidget {
  const _CardOverlayMoneyStat({
    required this.label,
    required this.value,
    required this.color,
    this.secondary,
  });

  final String label;
  final String value;
  final Color color;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9, // تم التكبير
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18, // تم التكبير
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (secondary != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              secondary!,
              style: TextStyle(
                color: color,
                fontSize: 9, // تم التكبير
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _CardCycleInfo extends StatelessWidget {
  const _CardCycleInfo({required this.statementDay, required this.dueDay});

  final int? statementDay;
  final int? dueDay;

  @override
  Widget build(BuildContext context) {
    Widget line(String label, int? day) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label ',
                style: const TextStyle(color: Colors.white70, fontSize: 8)),
            Text(day == null ? '—' : 'day $day',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800)),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line('Statement', statementDay),
        const SizedBox(height: 3),
        line('Due', dueDay),
      ],
    );
  }
}

// تم تكبير الخطوط الخاصة بشريط الحالة
class _CardUsageOverlay extends StatelessWidget {
  const _CardUsageOverlay({
    required this.utilization,
    required this.usedPercent,
    required this.available,
    required this.currency,
  });

  final double utilization;
  final double usedPercent;
  final double available;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Used',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10, // تم التكبير
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${usedPercent.round()}% used',
              style: const TextStyle(
                color: Color(0xFFFF3D81),
                fontSize: 10, // تم التكبير
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: utilization.clamp(0.0, 1.0),
            minHeight: 8, // تم زيادة السماكة
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3D81)),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            '${_money(available, currency)} available',
            style: const TextStyle(
              color: Colors.white70, // تم تفتيح اللون قليلاً
              fontSize: 10, // تم التكبير
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onAddTransaction,
    required this.onAddInstallment,
    required this.onConvert,
    required this.onPay,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onAddInstallment;
  final VoidCallback onConvert;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final gap = m.spacing(8);

    return Row(
      children: [
        Expanded(child: _Action(icon: Icons.add_rounded, label: 'Add\nTransaction', onTap: onAddTransaction)),
        SizedBox(width: gap),
        Expanded(child: _Action(icon: Icons.calendar_month_rounded, label: 'Add\nInstallment', onTap: onAddInstallment)),
        SizedBox(width: gap),
        Expanded(child: _Action(icon: Icons.autorenew_rounded, label: 'Convert to\nInstallment', onTap: onConvert)),
        SizedBox(width: gap),
        Expanded(child: _Action(icon: Icons.credit_card_rounded, label: 'Pay\nCard', onTap: onPay)),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Material(
      color: const Color(0xFF0A1C29),
      borderRadius: BorderRadius.circular(m.radius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(m.radius.md),
        child: SizedBox(
          height: m.isCompactHeight ? m.h(68) : m.h(74),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFF3D81), size: m.size(20)),
              SizedBox(height: m.spacing(4)),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: m.text(9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatementImportCard extends StatelessWidget {
  const _StatementImportCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Material(
      color: const Color(0xFF3A182E),
      borderRadius: BorderRadius.circular(m.radius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(m.radius.md),
        child: Padding(
          padding: EdgeInsets.all(m.spacing(12)),
          child: Row(
            children: [
              Container(
                width: m.size(38),
                height: m.size(38),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B2B55),
                  borderRadius: BorderRadius.circular(m.radius.sm),
                ),
                child: Icon(Icons.document_scanner_outlined, color: const Color(0xFF7DA4FF), size: m.size(22)),
              ),
              SizedBox(width: m.spacing(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Import Monthly Statement',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: m.text(16)),
                    ),
                    SizedBox(height: m.spacing(2)),
                    Text(
                      'Coming Soon',
                      style: TextStyle(color: const Color(0xFFFF6D9D), fontSize: m.text(10)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: m.spacing(8), vertical: m.spacing(4)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB21A),
                  borderRadius: BorderRadius.circular(m.radius.sm),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(color: Colors.black, fontSize: m.text(9), fontWeight: FontWeight.w900),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white54, size: m.size(22)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Row(
      children: [
        _seg(m, 'Transactions', 0),
        _seg(m, 'Installments', 1),
        _seg(m, 'Statements', 2),
      ],
    );
  }

  Widget _seg(ResponsiveMetrics m, String label, int value) {
    final active = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: m.isCompactHeight ? m.spacing(5) : m.spacing(6),
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFFFF2D6F) : Colors.white12,
                width: active ? m.size(2) : m.size(1),
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? const Color(0xFFFF2D6F) : Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: m.isCompactHeight ? m.text(10) : m.text(11),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({required this.transactions, required this.currency});
  final List<Transaction> transactions;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    if (transactions.isEmpty) {
      return const _EmptySection(
        title: 'No transactions yet',
        subtitle: 'Credit card transactions will appear here.',
      );
    }

    return Column(
      children: transactions.take(12).map((tx) {
        return ListTile(
          dense: true,
          visualDensity: VisualDensity(
            horizontal: 0,
            vertical: m.isCompactHeight ? -3 : -2,
          ),
          minVerticalPadding: m.isCompactHeight ? 2 : 4,
          contentPadding: EdgeInsets.symmetric(
            horizontal: m.spacing(2),
            vertical: 0,
          ),
          leading: CircleAvatar(
            radius: m.isCompactHeight ? m.size(14) : m.size(15),
            backgroundColor: const Color(0xFF182B45),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: const Color(0xFF8CB3FF),
              size: m.isCompactHeight ? m.size(15) : m.size(16),
            ),
          ),
          title: Text(
            tx.note?.split(' • ').first ?? 'Credit Card purchase',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: m.isCompactHeight ? m.text(14) : m.text(15),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${tx.date.day}/${tx.date.month}/${tx.date.year}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: m.isCompactHeight ? m.text(9) : m.text(10),
            ),
          ),
          trailing: Text(
            '-${tx.amount.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: m.isCompactHeight ? m.text(12) : m.text(13),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InstallmentsSection extends StatelessWidget {
  const _InstallmentsSection({required this.installments, required this.currency});
  final List<FinancingInstallment> installments;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    if (installments.isEmpty) {
      return const _EmptySection(
        title: 'No installments yet',
        subtitle: 'Converted and new installment purchases will appear here.',
      );
    }

    return Column(
      children: installments.take(12).map((item) {
        return ListTile(
          dense: true,
          visualDensity: VisualDensity(
            horizontal: 0,
            vertical: m.isCompactHeight ? -3 : -2,
          ),
          minVerticalPadding: m.isCompactHeight ? 2 : 4,
          contentPadding: EdgeInsets.symmetric(
            horizontal: m.spacing(2),
            vertical: 0,
          ),
          leading: CircleAvatar(
            radius: m.isCompactHeight ? m.size(14) : m.size(15),
            backgroundColor: const Color(0xFF182B45),
            child: Icon(
              Icons.event_repeat_rounded,
              color: const Color(0xFF8CB3FF),
              size: m.isCompactHeight ? m.size(15) : m.size(16),
            ),
          ),
          title: Text(
            'Installment ${item.sequence}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: m.isCompactHeight ? m.text(14) : m.text(15),
            ),
          ),
          subtitle: Text(
            '${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year} • ${item.status}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: m.isCompactHeight ? m.text(9) : m.text(10),
            ),
          ),
          trailing: Text(
            '${item.amount.toDouble().toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: m.isCompactHeight ? m.text(12) : m.text(13),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatementsSection extends StatelessWidget {
  const _StatementsSection({required this.profile});
  final CreditCardProfile profile;

  @override
  Widget build(BuildContext context) {
    return _EmptySection(
      title: 'Statements',
      subtitle: profile.statementDay == null
          ? 'Statement day is not configured.'
          : 'Statement closes on day ${profile.statementDay}. Monthly statement import is coming soon.',
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Container(
      padding: EdgeInsets.all(m.spacing(14)),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1C29),
        borderRadius: BorderRadius.circular(m.radius.md),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: m.text(15)),
          ),
          SizedBox(height: m.spacing(4)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: m.text(11)),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonLine extends StatelessWidget {
  const _ComingSoonLine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFFFF3D81), size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: Colors.black87)))]));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.color});
  final String title;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)), const SizedBox(height: 5), FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)))]));
}

int _overdueDays(List<FinancingInstallment> installments) {
  final now = DateTime.now();
  var maxDays = 0;
  for (final item in installments) {
    if (item.status == 'settled') continue;
    if (item.dueDate.isBefore(now)) {
      final days = now.difference(item.dueDate).inDays;
      if (days > maxDays) maxDays = days;
    }
  }
  return maxDays;
}

String _displayCardNumber(String? raw) {
  final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final last4 = digits.length > 4 ? digits.substring(digits.length - 4) : digits;
  return '•••• •••• •••• $last4';
}

String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';