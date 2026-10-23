import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/money/money.dart';
import '../../../application/credit_card/credit_card_details_projection_service.dart';
import '../../../application/credit_card/credit_card_monthly_due_projection_calculator.dart';
import '../../../application/credit_card/credit_card_statement_due_calculator.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../models/account.dart';
import '../../../models/financing/financing_installment.dart';
import '../../../models/financing/financing_contract.dart';
import '../../../models/transaction.dart';
import '../../../constants/transaction_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../widgets/shared/credit_card_visual.dart';
import '../../../widgets/shared/wafferly_card_visual_layout.dart';
import 'credit_card_installment_conversion_screen.dart';
import 'credit_card_payment_screen.dart';
import 'credit_card_installment_month_screen.dart';
import '../../expenses_screen.dart';

class CreditCardAccountDetailsScreen extends StatefulWidget {
  const CreditCardAccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  State<CreditCardAccountDetailsScreen> createState() =>
      _CreditCardAccountDetailsScreenState();
}

class _CreditCardAccountDetailsScreenState
    extends State<CreditCardAccountDetailsScreen> {
  // Open the card on the monthly installment overview, matching the approved design.
  int _tab = 1;

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

        final transactions = projection.transactions;
        final installments = projection.installments;

        final now = DateTime.now();
        final dueBreakdown =
            const CreditCardMonthlyDueProjectionCalculator().calculate(
          liabilityAccountId: projection.account.id,
          charges: transactions,
          payments: projection.payments,
          contracts: projection.contracts,
          installments: installments,
          statementDay: projection.profile.statementDay,
          paymentDueDay: projection.profile.paymentDueDay,
          currentOutstanding: projection.outstanding,
          now: now,
        );

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
                creditExposureLabel: t.creditExposure,
                creditExposureValue: projection.outstanding.toDouble(),
                outstanding: (projection.profile.creditLimit.toDouble() -
                        projection.available.toDouble())
                    .clamp(0.0, double.infinity),
                thisMonthDue: projection.statementDue.isConfigured
                    ? projection.statementDue.amountDue.toDouble()
                    : dueBreakdown.thisMonthTotal.toDouble(),
                thisMonthExpenses: projection.statementDue.isConfigured
                    ? projection.statementDue.chargeAmountDue.toDouble()
                    : dueBreakdown.thisMonthExpenses.toDouble(),
                thisMonthInstallments: projection.statementDue.isConfigured
                    ? projection.statementDue.installmentAmountDue.toDouble()
                    : dueBreakdown.thisMonthInstallments.toDouble(),
                nextMonthDue: dueBreakdown.nextMonthTotal.toDouble(),
                nextMonthExpenses: dueBreakdown.nextMonthExpenses.toDouble(),
                nextMonthInstallments: dueBreakdown.nextMonthInstallments.toDouble(),
                onMoreDue: () => _showFutureInstallmentMonths(
                  projection.account.currency,
                  installments,
                  projection.contracts,
                  transactions,
                ),
              ),
              SizedBox(height: m.space.md),
              _ActionGrid(
                onAddTransaction: () => _openEntry(
                  projection.account,
                  installmentOnly: false,
                ),
                onAddInstallment: () => _openEntry(
                  projection.account,
                  installmentOnly: true,
                ),
                onConvert: () => _openConvert(projection.account, projection.profile),
                onPay: () => _openPayment(
                  projection.account,
                  projection.profile,
                  projection.outstanding,
                  projection.statementDue,
                  dueBreakdown.thisMonthTotal,
                  dueBreakdown.thisMonthInstallments,
                ),
              ),
              SizedBox(height: m.space.sm),
              _StatementImportCard(onTap: _showStatementComingSoon),
              SizedBox(height: m.space.md),
              _SegmentTabs(selected: _tab, onChanged: (value) => setState(() => _tab = value)),
              SizedBox(height: m.space.sm),
              if (_tab == 0) _TransactionsSection(
                transactions: transactions,
                payments: projection.payments,
                currency: projection.account.currency,
              )
              else if (_tab == 1) _InstallmentsSection(
                installments: installments,
                contracts: projection.contracts,
                transactions: transactions,
                currency: projection.account.currency,
                onMonthTap: (month, monthInstallments) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreditCardInstallmentMonthScreen(
                      month: month,
                      monthInstallments: monthInstallments,
                      allInstallments: installments,
                      contracts: projection.contracts,
                      transactions: transactions,
                      currency: projection.account.currency,
                    ),
                  ),
                ),
              )
              else _StatementsSection(profile: projection.profile),
            ],
          ),
        );
      },
    );
  }

  void _showFutureInstallmentMonths(
    String currency,
    List<FinancingInstallment> installments,
    List<FinancingContract> contracts,
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    final firstFutureMonth = DateTime(now.year, now.month + 2, 1);
    final future = installments.where((item) {
      final status = item.status.trim().toLowerCase();
      final due = DateTime(item.dueDate.year, item.dueDate.month, 1);
      return !due.isBefore(firstFutureMonth) &&
          status != 'settled' && status != 'cancelled' &&
          status != 'canceled' && status != 'superseded' &&
          status != 'terminated';
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final groups = <DateTime, List<FinancingInstallment>>{};
    for (final item in future) {
      final month = DateTime(item.dueDate.year, item.dueDate.month, 1);
      (groups[month] ??= <FinancingInstallment>[]).add(item);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1C29),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Future Due Months', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              Expanded(
                child: groups.isEmpty
                    ? const Center(child: Text('No future installments scheduled', style: TextStyle(color: Colors.white70)))
                    : ListView(
                        children: groups.entries.map((entry) {
                          final month = entry.key;
                          final items = entry.value;
                          final total = items.fold<double>(0, (sum, item) => sum + item.amount.toDouble());
                          return ListTile(
                            title: Text(DateFormat.yMMMM().format(month), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: Text('${items.length} installments', style: const TextStyle(color: Colors.white60)),
                            trailing: Text(_money(total, currency), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => CreditCardInstallmentMonthScreen(
                                  month: month,
                                  monthInstallments: items,
                                  allInstallments: installments,
                                  contracts: contracts,
                                  transactions: transactions,
                                  currency: currency,
                                ),
                              ));
                            },
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEntry(
    Account account, {
    required bool installmentOnly,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpensesScreen(
          creditCardAccount: account,
          creditCardInstallmentOnly: installmentOnly,
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _openConvert(
    Account account,
    CreditCardProfile profile,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardInstallmentConversionScreen(
          account: account,
          profile: profile,
        ),
      ),
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

  Future<void> _openPayment(
    Account account,
    CreditCardProfile profile,
    Money outstanding,
    CreditCardStatementDueSummary statementDue,
    Money fallbackAmountDue,
    Money fallbackInstallmentAmountDue,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreditCardPaymentScreen(
          account: account,
          profile: profile,
          outstanding: outstanding,
          statementDue: statementDue,
          fallbackAmountDue: fallbackAmountDue,
          fallbackInstallmentAmountDue: fallbackInstallmentAmountDue,
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
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

/// Card text colour. The card artwork is dark/saturated, so text is white.
/// (It used to be near-black, which was unreadable on the blue artwork.)
const Color _kCardInk = Color(0xFFFFFFFF);

/// Soft shadow so text stays readable where the artwork gets lighter.
const List<Shadow> _kCardShadow = <Shadow>[
  Shadow(color: Color(0x73000000), blurRadius: 3, offset: Offset(0, 1)),
];

/// Translucent dark backing for numbers that sit over the light network
/// circles. White text on the circles alone is unreadable; this keeps the
/// contrast stable on any artwork.
class _CardScrim extends StatelessWidget {
  const _CardScrim({required this.child, this.alignment});

  final Widget child;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x66020B1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// Credit-card dashboard artwork layout. This intentionally differs from the
/// generic card-management layout: the main card prioritizes the two due
/// summaries and statement/payment days, without the extra Used/Available bar.
CardVisualLayout _creditCardDashboardLayout(String visualId) =>
    CardVisualLayout(
      visualId: visualId,
      aspectRatio: 1.55,
      slots: <CardTextSlot, CardVisualSlot>{
        CardTextSlot.cardName: CardVisualSlot(
          zone: CardZone.identity,
          area: CardVisualZone(x: .05, y: .075, width: .48, height: .105),
        ),
        CardTextSlot.issuer: CardVisualSlot(
          zone: CardZone.identity,
          area: CardVisualZone(x: .05, y: .175, width: .49, height: .075),
          minFontScale: .65,
        ),
        CardTextSlot.outstanding: CardVisualSlot(
          zone: CardZone.financialSecondary,
          area: CardVisualZone(
            // Reserve enough room for the complete label and amount while
            // keeping the outstanding block in the card's upper-right corner.
            x: .62,
            y: .035,
            width: .35,
            height: .24,
            alignment: Alignment.centerRight,
          ),
          maxLines: 2,
          minFontScale: .55,
        ),
        // Due-period rows: lower on the card, with a small gap (.025) between
        // them. Footer starts at .795, so there is no overlap.
        CardTextSlot.thisMonthDue: CardVisualSlot(
          zone: CardZone.financialPrimary,
          // Stop the due panel before the independent More control.
          area: CardVisualZone(x: .27, y: .34, width: .60, height: .22),
          maxLines: 2,
          minFontScale: .60,
        ),
        CardTextSlot.nextMonthDue: CardVisualSlot(
          zone: CardZone.financialPrimary,
          // Stop the due panel before the independent More control.
          area: CardVisualZone(x: .27, y: .57, width: .60, height: .22),
          maxLines: 2,
          minFontScale: .60,
        ),
        CardTextSlot.statementCycle: CardVisualSlot(
          zone: CardZone.footer,
          area: CardVisualZone(x: .05, y: .80, width: .90, height: .18),
          maxLines: 2,
          minFontScale: .62,
        ),
      },
    );

class _CardSummaryVisual extends StatelessWidget {
  const _CardSummaryVisual({
    required this.account,
    required this.profile,
    required this.creditExposureLabel,
    required this.creditExposureValue,
    required this.outstanding,
    required this.thisMonthDue,
    required this.thisMonthExpenses,
    required this.thisMonthInstallments,
    required this.nextMonthDue,
    required this.nextMonthExpenses,
    required this.nextMonthInstallments,
    required this.onMoreDue,
  });

  final Account account;
  final CreditCardProfile profile;
  final String creditExposureLabel;
  final double creditExposureValue;
  final double outstanding;
  final double thisMonthDue;
  final double thisMonthExpenses;
  final double thisMonthInstallments;
  final double nextMonthDue;
  final double nextMonthExpenses;
  final double nextMonthInstallments;
  final VoidCallback onMoreDue;

  @override
  Widget build(BuildContext context) {
    final layout = _creditCardDashboardLayout(profile.cardVisual);

    final m = ResponsiveMetrics.of(context);
    // Small/compact screens: enlarge the complete card + all of its contents
    // by about 20% relative to the current compact presentation.
    final cardScale = m.isCompactHeight ? 0.98 : 1.0;

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
            // The card overlay is laid out on a fixed design canvas and then
            // scaled to the real card size. Without this, fonts keep their
            // pixel size while the slots shrink on small phones (iPhone SE),
            // which caused the "bottom overflowed" errors.
            const designWidth = 376.0;
            final size = Size(designWidth, designWidth / layout.aspectRatio);

            Widget slot(CardTextSlot field, Widget child) {
              final definition = layout.slot(field);
              if (definition == null) return const SizedBox.shrink();

              final rect = definition.area.resolve(size);
              return Positioned.fromRect(
                rect: rect,
                child: Padding(
                  padding: definition.area.padding,
                  // Keep the slot's real bounded constraints. Wrapping composite
                  // Rows in FittedBox makes their Expanded children unbounded, so
                  // the due rows can fail layout and disappear from the card.
                  child: SizedBox(
                    width: rect.width,
                    height: rect.height,
                    child: child,
                  ),
                ),
              );
            }

            return FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: size.width,
                height: size.height,
                // Artwork text must not follow the system font scale: the
                // slots are fixed-size, so a large font setting would overflow.
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.noScaling),
                  child: Stack(
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
                    account.name.trim().isEmpty ? 'Credit Card' : account.name.trim(),
                    size: 20,
                    weight: FontWeight.w900,
                  ),
                ),
                slot(
                  CardTextSlot.issuer,
                  _CardOverlayText(
                    '${account.provider ?? 'Credit Card'} • ${profile.cardNetwork ?? 'Network not set'}',
                    size: 9,
                    color: _kCardInk,
                    maxLines: 1,
                  ),
                ),

                // Total outstanding replaces Available / Credit Limit.
                slot(
                  CardTextSlot.outstanding,
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: '$creditExposureLabel: $creditExposureValue',
                      child: _CardScrim(
                        child: _CardOverlayMoneyStat(
                          label: 'Total Outstanding',
                          value: _money(outstanding, account.currency),
                          color: _kCardInk,
                          alignRight: true,
                        ),
                      ),
                    ),
                  ),
                ),
                slot(
                  CardTextSlot.thisMonthDue,
                  _CardDueStat(
                    label: 'This Month Due',
                    total: _money(thisMonthDue, account.currency),
                    expenses: _money(thisMonthExpenses, account.currency),
                    installments: _money(thisMonthInstallments, account.currency),
                    color: _kCardInk,
                  ),
                ),
                slot(
                  CardTextSlot.nextMonthDue,
                  _CardDueStat(
                    label: 'Next Month Due',
                    total: _money(nextMonthDue, account.currency),
                    expenses: _money(nextMonthExpenses, account.currency),
                    installments: _money(nextMonthInstallments, account.currency),
                    color: _kCardInk,
                  ),
                ),
                Positioned(
                  // The More control has its own column. It begins after the
                  // two due panels, so it never overlays either panel.
                  left: 330,
                  top: size.height * .34,
                  width: 39,
                  height: size.height * .45,
                  child: Material(
                    color: const Color(0x66020B1A),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onMoreDue,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF2D8D),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFFF2D8D),
                              size: 23,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'More',
                              style: TextStyle(
                                color: Color(0xFFFF2D8D),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                slot(
                  CardTextSlot.statementCycle,
                  _CardCycleInfo(
                    statementDay: profile.statementDay,
                    dueDay: profile.paymentDueDay,
                  ),
                ),

              ],
                  ),
                ),
              ),
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
    this.color = _kCardInk,
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
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          shadows: _kCardShadow,
        ),
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
            color: _kCardInk,
            fontSize: 10, // تم التكبير
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
              color: _kCardInk,
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
    this.alignRight = false,
  });

  final String label;
  final String value;
  final Color color;
  final String? secondary;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kCardInk,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignRight
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: TextStyle(
              color: _kCardInk,
              fontSize: 18,
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
                color: _kCardInk,
                fontSize: 10, // تم التكبير
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _CardDueStat extends StatelessWidget {
  const _CardDueStat({
    required this.label,
    required this.total,
    required this.expenses,
    required this.installments,
    required this.color,
  });

  final String label;
  final String total;
  final String expenses;
  final String installments;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // One compact horizontal row per due period: label + total at the start,
    // and the expense/installment breakdown beside them.
    return _CardScrim(
      alignment: Alignment.center,
      child: Row(
      // Card labels are authored in English; keep their order stable even if
      // the surrounding app is running in an RTL locale.
      textDirection: ui.TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kCardInk,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  total,
                  maxLines: 1,
                  style: TextStyle(
                    color: _kCardInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 1,
          height: 34,
          color: Colors.white.withValues(alpha: .42),
        ),
        const SizedBox(width: 7),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFFFF2D8D), size: 7),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Expenses',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kCardInk,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Text(
                  expenses,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kCardInk,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF42C9FF), size: 7),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Installments',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF42C9FF),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Text(
                  installments,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kCardInk,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

class _CardCycleInfo extends StatelessWidget {
  const _CardCycleInfo({required this.statementDay, required this.dueDay});

  final int? statementDay;
  final int? dueDay;

  @override
  Widget build(BuildContext context) {
    // Each block is as wide as its explanation line (IntrinsicWidth), so the
    // label starts exactly where the explanation starts and the day number
    // ends exactly where the explanation ends.
    Widget dayBlock({
      required String label,
      required int? day,
      required String hint,
    }) =>
        IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: ui.TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _kCardInk,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      shadows: _kCardShadow,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    day == null ? '—' : 'Day $day',
                    maxLines: 1,
                    style: const TextStyle(
                      color: _kCardInk,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      shadows: _kCardShadow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  shadows: _kCardShadow,
                ),
              ),
            ],
          ),
        );

    return Row(
      // Card labels are authored in English; keep their order stable in RTL.
      textDirection: ui.TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        dayBlock(
          label: 'Statement Day',
          day: statementDay,
          hint: 'New bill cycle starts after this day',
        ),
        dayBlock(
          label: 'Due Day',
          day: dueDay,
          hint: 'Pay the bill by this day',
        ),
      ],
    );
  }
}

// تم تكبير الخطوط الخاصة بشريط الحالة
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
  const _TransactionsSection({
    required this.transactions,
    required this.payments,
    required this.currency,
  });

  /// Charge transactions only; they drive statement and due calculations.
  final List<Transaction> transactions;
  final List<Transaction> payments;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;
    final events = <Transaction>[...transactions, ...payments]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (events.isEmpty) {
      return const _EmptySection(
        title: 'No transactions yet',
        subtitle: 'Credit card transactions will appear here.',
      );
    }

    return Column(
      children: events.take(12).map((tx) {
        final isPayment = tx.source == TransactionSource.creditCardPayment;
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
              isPayment ? Icons.payments_outlined : Icons.shopping_cart_outlined,
              color: const Color(0xFF8CB3FF),
              size: m.isCompactHeight ? m.size(15) : m.size(16),
            ),
          ),
          title: Text(
            isPayment ? t.creditCardPayment : (tx.note?.split(' • ').first ?? 'Credit Card purchase'),
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
            '${isPayment ? '+' : '-'}${tx.amount.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isPayment ? const Color(0xFF58D6A2) : Colors.white,
              fontSize: m.isCompactHeight ? m.text(12) : m.text(13),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InstallmentsSection extends StatelessWidget {
  const _InstallmentsSection({
    required this.installments,
    required this.contracts,
    required this.transactions,
    required this.currency,
    required this.onMonthTap,
  });

  final List<FinancingInstallment> installments;
  final List<FinancingContract> contracts;
  final List<Transaction> transactions;
  final String currency;
  final void Function(DateTime month, List<FinancingInstallment> items) onMonthTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    if (installments.isEmpty) {
      return _EmptySection(
        title: t.installments,
        subtitle: t.installmentsSubtitle,
      );
    }

    final grouped = <DateTime, List<FinancingInstallment>>{};
    for (final item in installments) {
      final month = DateTime(item.dueDate.year, item.dueDate.month);
      (grouped[month] ??= <FinancingInstallment>[]).add(item);
    }
    final months = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(m.spacing(2), m.spacing(8), m.spacing(2), m.spacing(8)),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: const Color(0xFFFF3D81), size: m.size(20)),
              SizedBox(width: m.spacing(8)),
              Expanded(
                child: Text(
                  'Installments by Month',
                  style: TextStyle(fontSize: m.text(15), fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: m.spacing(10),
                  vertical: m.spacing(6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1C29),
                  borderRadius: BorderRadius.circular(m.radius.sm),
                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${months.length} months left',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: m.text(10),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: m.spacing(4)),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: m.size(16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...months.map((month) {
          final items = grouped[month]!..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final total = items.fold<Money>(Money.zero, (sum, item) => sum + item.amount);
          final locale = Localizations.localeOf(context).toLanguageTag();
          final monthLabel = DateFormat('MMM yyyy', locale).format(month);
          return Padding(
            padding: EdgeInsets.only(bottom: m.spacing(8)),
            child: Material(
              color: const Color(0xFF071D2B),
              borderRadius: BorderRadius.circular(m.radius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(m.radius.md),
                onTap: () => onMonthTap(month, List<FinancingInstallment>.unmodifiable(items)),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: m.spacing(12), vertical: m.spacing(12)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(m.radius.md),
                    border: Border.all(color: Colors.white.withValues(alpha: .07)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: m.size(42), height: m.size(42),
                        decoration: const BoxDecoration(color: Color(0x1FFF3D81), shape: BoxShape.circle),
                        child: Icon(Icons.calendar_month_rounded, color: const Color(0xFFFF3D81), size: m.size(21)),
                      ),
                      SizedBox(width: m.spacing(10)),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            monthLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: m.text(14),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: m.spacing(8)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_money(total.toDouble(), currency), style: TextStyle(fontSize: m.text(13), fontWeight: FontWeight.w800)),
                          SizedBox(height: m.spacing(4)),
                          Text('${items.length} ${items.length == 1 ? 'installment' : 'installments'}', style: TextStyle(color: Colors.white54, fontSize: m.text(10))),
                        ],
                      ),
                      SizedBox(width: m.spacing(4)),
                      Icon(Icons.chevron_right_rounded, color: Colors.white60, size: m.size(22)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
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

String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';