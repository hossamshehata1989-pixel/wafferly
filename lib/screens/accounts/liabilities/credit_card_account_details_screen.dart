import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/money/money.dart';
import '../../../application/credit_card/credit_card_details_projection_service.dart';
import '../../../application/credit_card/credit_card_monthly_due_projection_calculator.dart';
import '../../../application/credit_card/credit_card_statement_due_calculator.dart';
import '../../../application/credit_card/credit_card_transaction_timing_policy.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../models/account.dart';
import '../../../models/financing/financing_installment.dart';
import '../../../models/financing/financing_contract.dart';
import '../../../models/transaction.dart';
import '../../../constants/transaction_constants.dart';
import '../../../config/category_config.dart';
import '../../../config/category_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../widgets/shared/credit_card_visual.dart';
import '../../../widgets/shared/wafferly_financial_card.dart'
    show WafferlyCardVisuals, WafferlyCardKind;
import '../../../widgets/shared/wafferly_card_visual_layout.dart' hide WafferlyCardKind;
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
        final dueBreakdown = const CreditCardMonthlyDueProjectionCalculator()
            .calculate(
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

        return Directionality(
          textDirection: Localizations.localeOf(context).languageCode == 'ar'
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Scaffold(
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
                t.creditCardTitle,
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
                  onPressed: () =>
                      _showCardMenu(projection.account, projection.profile),
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
                  outstanding:
                      (projection.profile.creditLimit.toDouble() -
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
                  nextMonthInstallments: dueBreakdown.nextMonthInstallments
                      .toDouble(),
                  onMoreDue: () => _showFutureInstallmentMonths(
                    projection.account.currency,
                    installments,
                    projection.contracts,
                    transactions,
                  ),
                ),
                SizedBox(height: m.space.md),
                _ActionGrid(
                  onAddTransaction: () =>
                      _openEntry(projection.account, installmentOnly: false),
                  onAddInstallment: () =>
                      _openEntry(projection.account, installmentOnly: true),
                  onConvert: () =>
                      _openConvert(projection.account, projection.profile),
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
                _SegmentTabs(
                  selected: _tab,
                  onChanged: (value) => setState(() => _tab = value),
                ),
                SizedBox(height: m.space.sm),
                if (_tab == 0)
                  _TransactionsSection(
                    transactions: transactions,
                    payments: projection.payments,
                    currency: projection.account.currency,
                    statementDay: projection.profile.statementDay,
                    convertedChargeIds: projection.convertedChargeIds,
                    contracts: projection.contracts,
                    installments: installments,
                  )
                else if (_tab == 1)
                  _InstallmentsSection(
                    installments: installments,
                    contracts: projection.contracts,
                    transactions: transactions,
                    currency: projection.account.currency,
                    onMonthTap: (month, monthInstallments) =>
                        Navigator.of(context).push(
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
                else
                  _StatementsSection(profile: projection.profile),
              ],
            ),
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
          status != 'settled' &&
          status != 'cancelled' &&
          status != 'canceled' &&
          status != 'superseded' &&
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Localizations.localeOf(sheetContext).languageCode == 'ar'
                        ? 'الاستحقاقات القادمة'
                        : 'Future Due Months',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: groups.isEmpty
                    ? Center(
                        child: Text(
                          Localizations.localeOf(sheetContext).languageCode ==
                                  'ar'
                              ? 'لا توجد أقساط مستقبلية مجدولة'
                              : 'No future installments scheduled',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView(
                        children: groups.entries.map((entry) {
                          final month = entry.key;
                          final items = entry.value;
                          final total = items.fold<double>(
                            0,
                            (sum, item) => sum + item.amount.toDouble(),
                          );
                          return ListTile(
                            title: Text(
                              DateFormat.yMMMM().format(month),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? '${items.length} أقساط'
                                  : '${items.length} installments',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            trailing: Text(
                              _money(total, currency),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreditCardInstallmentMonthScreen(
                                        month: month,
                                        monthInstallments: items,
                                        allInstallments: installments,
                                        contracts: contracts,
                                        transactions: transactions,
                                        currency: currency,
                                      ),
                                ),
                              );
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

  Future<void> _openConvert(Account account, CreditCardProfile profile) async {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Icon(
              Icons.document_scanner_rounded,
              size: 72,
              color: Color(0xFF4D7CFF),
            ),
            SizedBox(height: 14),
            Text(
              AppLocalizations.of(sheetContext)!.importMonthlyStatement,
              style: TextStyle(
                color: Colors.black,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              Localizations.localeOf(sheetContext).languageCode == 'ar'
                  ? 'اقرأ كشف حساب بطاقتك الائتمانية واستورد العمليات وطابقها بسهولة.'
                  : 'Automatically read your credit card statement and help you import and reconcile transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            SizedBox(height: 18),
            _ComingSoonLine(
              text: Localizations.localeOf(sheetContext).languageCode == 'ar'
                  ? 'يدعم ملفات PDF والصور'
                  : 'Supports PDF and images',
            ),
            _ComingSoonLine(
              text: Localizations.localeOf(sheetContext).languageCode == 'ar'
                  ? 'يكتشف العمليات تلقائيًا'
                  : 'Detects transactions automatically',
            ),
            _ComingSoonLine(
              text: Localizations.localeOf(sheetContext).languageCode == 'ar'
                  ? 'يطابق العمليات المسجلة بالفعل'
                  : 'Matches existing transactions',
            ),
            _ComingSoonLine(
              text: Localizations.localeOf(sheetContext).languageCode == 'ar'
                  ? 'يساعد على اكتشاف عمليات التقسيط'
                  : 'Helps with installment detection',
            ),
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: null,
                child: Text(
                  Localizations.localeOf(sheetContext).languageCode == 'ar'
                      ? 'قريبًا • PRO'
                      : 'COMING SOON • PRO',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(AppLocalizations.of(context)!.cardSettings),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(AppLocalizations.of(context)!.importMonthlyStatement),
              subtitle: const Text('PRO • Coming Soon'),
              onTap: () {
                Navigator.pop(context);
                _showStatementComingSoon();
              },
            ),
          ],
        ),
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
CardVisualLayout _creditCardDashboardLayout(
  String visualId,
) => CardVisualLayout(
  visualId: visualId,
  aspectRatio: 1.55,
  slots: <CardTextSlot, CardVisualSlot>{
    CardTextSlot.cardName: CardVisualSlot(
      zone: CardZone.identity,
      area: CardVisualZone(
        x: .50,
        y: .075,
        width: .45,
        height: .105,
        alignment: Alignment.centerRight,
      ),
    ),
    CardTextSlot.issuer: CardVisualSlot(
      zone: CardZone.identity,
      area: CardVisualZone(
        x: .50,
        y: .175,
        width: .45,
        height: .075,
        alignment: Alignment.centerRight,
      ),
      minFontScale: .65,
    ),
    CardTextSlot.outstanding: CardVisualSlot(
      zone: CardZone.financialSecondary,
      area: CardVisualZone(
        // Reserve enough room for the complete label and amount while
        // Place the outstanding block on the upper-left, opposite the card identity.
        x: .05,
        y: .035,
        width: .39,
        height: .24,
        alignment: Alignment.centerLeft,
      ),
      maxLines: 2,
      minFontScale: .55,
    ),
    // Due-period rows: lower on the card, with a small gap (.025) between
    // them. Footer starts at .795, so there is no overlap.
    CardTextSlot.thisMonthDue: CardVisualSlot(
      zone: CardZone.financialPrimary,
      // Widen due panels to the left while preserving their right edge and keeping a small gap after More.
      area: CardVisualZone(x: .404, y: .325, width: .548, height: .225),
      maxLines: 2,
      minFontScale: .60,
    ),
    CardTextSlot.nextMonthDue: CardVisualSlot(
      zone: CardZone.financialPrimary,
      // Widen due panels to the left while preserving their right edge and keeping a small gap after More.
      area: CardVisualZone(x: .404, y: .565, width: .548, height: .225),
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
    // Use the same palette and accent as the selected card artwork.
    final cardVisualSpec = WafferlyCardVisuals.resolve(
      profile.cardVisual,
      WafferlyCardKind.credit,
    );

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
                      final size = Size(
                        designWidth,
                        designWidth / layout.aspectRatio,
                      );

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
                            data: MediaQuery.of(
                              context,
                            ).copyWith(textScaler: TextScaler.noScaling),
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
                                    account.name.trim().isEmpty
                                        ? 'Credit Card'
                                        : account.name.trim(),
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
                                    alignment: Alignment.centerLeft,
                                    child: Semantics(
                                      label:
                                          '$creditExposureLabel: $creditExposureValue',
                                      child: _CardScrim(
                                        child: _CardOverlayMoneyStat(
                                          label:
                                              Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'إجمالي المستحق'
                                              : 'Total Outstanding',
                                          value: _money(
                                            outstanding,
                                            account.currency,
                                          ),
                                          color: _kCardInk,
                                          alignRight: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Shared visual frame behind the due panels and More control.
                                Positioned(
                                  // Frame follows the adjusted due group, between the chip and card edge.
                                  left: 88,
                                  right: 14,
                                  top: size.height * .30,
                                  height: size.height * .50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0x22020B1A),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: .20),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                slot(
                                  CardTextSlot.thisMonthDue,
                                  _CardDueStat(
                                    label: AppLocalizations.of(
                                      context,
                                    )!.thisMonthDue,
                                    total: _money(
                                      thisMonthDue,
                                      account.currency,
                                    ),
                                    expenses: _money(
                                      thisMonthExpenses,
                                      account.currency,
                                    ),
                                    installments: _money(
                                      thisMonthInstallments,
                                      account.currency,
                                    ),
                                    color: _kCardInk,
                                  ),
                                ),
                                slot(
                                  CardTextSlot.nextMonthDue,
                                  _CardDueStat(
                                    label: AppLocalizations.of(
                                      context,
                                    )!.nextMonthDue,
                                    total: _money(
                                      nextMonthDue,
                                      account.currency,
                                    ),
                                    expenses: _money(
                                      nextMonthExpenses,
                                      account.currency,
                                    ),
                                    installments: _money(
                                      nextMonthInstallments,
                                      account.currency,
                                    ),
                                    color: _kCardInk,
                                  ),
                                ),
                                Positioned(
  left: 94,
  top: size.height * .325,
  width: 52,
  height: size.height * .465,
  child: Material(
    color: cardVisualSpec.colors.first,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
                                      onTap: onMoreDue,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              cardVisualSpec.colors.first.withValues(alpha: .96),
                                              cardVisualSpec.colors.last.withValues(alpha: .94),
                                              cardVisualSpec.colors.first,
                                            ],
                                          ),
                                          border: Border.all(
                                            color: (cardVisualSpec.accent ?? cardVisualSpec.colors.last).withValues(alpha: .95),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (cardVisualSpec.accent ?? cardVisualSpec.colors.last).withValues(alpha: .20),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.more_vert_rounded,
                                              color: ui.Color.fromARGB(255, 247, 245, 246),
                                              size: 23,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.more,
                                              style: TextStyle(
                                                color: ui.Color.fromARGB(255, 246, 244, 245),
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
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // One compact horizontal row per due period: label + total at the start,
    // and the expense/installment breakdown beside them.
    return _CardScrim(
      alignment: Alignment.center,
      child: Row(
        // Card labels are authored in English; keep their order stable even if
        // the surrounding app is running in an RTL locale.
        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            // Arabic due labels are longer, so reserve extra width for them.
            flex: isArabic ? 7 : 6,
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
            flex: isArabic ? 5 : 5,
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
                        t.expensesLabel,
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
                      color: ui.Color.fromARGB(255, 240, 239, 237),
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
                        t.installmentsLabel,
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

    // One compact horizontal row per due period: label + total at the start,
    // and the expense/installment breakdown beside them.

    Widget dayBlock({
      required String label,
      required int? day,
      required String hint,
    }) => IntrinsicWidth(
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
                day == null
                    ? '—'
                    : Localizations.localeOf(context).languageCode == 'ar'
                    ? 'يوم $day'
                    : 'Day $day',
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
          label: Localizations.localeOf(context).languageCode == 'ar'
              ? 'يوم كشف الحساب'
              : 'Statement Day',
          day: statementDay,
          hint: Localizations.localeOf(context).languageCode == 'ar'
              ? 'تبدأ دورة الفاتورة الجديدة بعد هذا اليوم'
              : 'New bill cycle starts after this day',
        ),
        dayBlock(
          label: Localizations.localeOf(context).languageCode == 'ar'
              ? 'يوم الاستحقاق'
              : 'Due Day',
          day: dueDay,
          hint: Localizations.localeOf(context).languageCode == 'ar'
              ? 'يجب سداد الفاتورة في هذا اليوم'
              : 'Pay the bill by this day',
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

    return Directionality(
      // Keep each action and its callback in the same visual slot in Arabic
      // and English; only the text itself follows the selected locale.
      textDirection: ui.TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: _Action(
              icon: Icons.add_rounded,
              label: '${AppLocalizations.of(context)!.addTransaction}',
              onTap: onAddTransaction,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Action(
              icon: Icons.calendar_month_rounded,
              label: '${AppLocalizations.of(context)!.addInstallment}',
              onTap: onAddInstallment,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Action(
              icon: Icons.autorenew_rounded,
              label: '${AppLocalizations.of(context)!.convertToInstallment}',
              onTap: onConvert,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Action(
              icon: Icons.credit_card_rounded,
              label: '${AppLocalizations.of(context)!.payCard}',
              onTap: onPay,
            ),
          ),
        ],
      ),
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
                child: Icon(
                  Icons.document_scanner_outlined,
                  color: const Color(0xFF7DA4FF),
                  size: m.size(22),
                ),
              ),
              SizedBox(width: m.spacing(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Import Monthly Statement',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: m.text(16),
                      ),
                    ),
                    SizedBox(height: m.spacing(2)),
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: const Color(0xFFFF6D9D),
                        fontSize: m.text(10),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: m.spacing(8),
                  vertical: m.spacing(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB21A),
                  borderRadius: BorderRadius.circular(m.radius.sm),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: m.text(9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
                size: m.size(22),
              ),
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
        _seg(m, AppLocalizations.of(context)!.transactionsTab, 0),
        _seg(m, AppLocalizations.of(context)!.installments, 1),
        _seg(m, AppLocalizations.of(context)!.statements, 2),
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

String? _transactionCategoryTitle(BuildContext context, String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) return null;
  final t = AppLocalizations.of(context)!;
  for (final type in CategoryType.values) {
    for (final category in getCategories(type)) {
      if (category.id == categoryId) return category.resolveTitle(t);
    }
  }
  return null;
}

class _TransactionCategoryIcon extends StatelessWidget {
  const _TransactionCategoryIcon({
    required this.categoryId,
    required this.size,
  });
  final String? categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (categoryId == null || categoryId!.isEmpty) {
      return Icon(
        Icons.shopping_cart_outlined,
        color: const Color(0xFF8CB3FF),
        size: size,
      );
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
    if (found == null)
      return Icon(
        Icons.shopping_cart_outlined,
        color: const Color(0xFF8CB3FF),
        size: size,
      );
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SvgPicture.asset(
        found.icon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(
          Icons.category_outlined,
          color: const Color(0xFF8CB3FF),
          size: size,
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
    required this.statementDay,
    required this.convertedChargeIds,
    required this.contracts,
    required this.installments,
  });

  final List<Transaction> transactions;
  final List<Transaction> payments;
  final String currency;
  final int? statementDay;
  final Set<String> convertedChargeIds;
  final List<FinancingContract> contracts;
  final List<FinancingInstallment> installments;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final events = <Transaction>[...transactions, ...payments]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (events.isEmpty) {
      return _EmptySection(
        title: AppLocalizations.of(context)!.noTransactionsYet,
        subtitle: AppLocalizations.of(context)!.creditCardTransactionsAppearHere,
      );
    }

    Widget header(String text, {TextAlign align = TextAlign.center}) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        color: Colors.white70,
        fontSize: m.isCompactHeight ? m.text(9) : m.text(10),
        fontWeight: FontWeight.w800,
      ),
    );

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: m.spacing(5),
            vertical: m.spacing(7),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF101E2D),
            borderRadius: BorderRadius.circular(m.radius.sm),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
          ),
          child: Row(
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            children: [
              Expanded(flex: 11, child: header(isArabic ? 'المعاملة' : 'Transaction')),
              Expanded(flex: 10, child: header(isArabic ? 'النوع' : 'Type')),
              Expanded(flex: 12, child: header(isArabic ? 'كشف / قسط' : 'Statement / Due')),
              Expanded(flex: 10, child: header(isArabic ? 'القيمة' : 'Amount')),
            ],
          ),
        ),
        SizedBox(height: m.spacing(2)),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(m.radius.md),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Column(
            children: events.take(12).map((tx) {
              final isPayment = tx.source == TransactionSource.creditCardPayment;
              final isInstallment = !isPayment && convertedChargeIds.contains(tx.id);
              final title = isPayment
                  ? AppLocalizations.of(context)!.creditCardPayment
                  : _transactionSubcategoryTitle(context, tx) ??
                      _transactionCategoryTitle(context, tx.categoryId) ??
                      (tx.note?.split(' • ').first ?? AppLocalizations.of(context)!.creditCardPurchase);
              final installmentDueDate = isInstallment
                  ? CreditCardTransactionTimingPolicy
                      .firstOutstandingInstallmentDueDateForCharge(
                        chargeId: tx.id,
                        contracts: contracts,
                        installments: installments,
                      )
                  : null;
              final timingDate = isPayment
                  ? tx.date
                  : isInstallment
                      ? installmentDueDate
                      : CreditCardTransactionTimingPolicy.statementDateForPurchase(
                          purchaseDate: tx.date,
                          statementDay: statementDay,
                        );
              final timing = isPayment
                  ? (isArabic ? 'سداد البطاقة' : 'Card payment')
                  : isInstallment
                      ? (isArabic ? 'القسط القادم' : 'Next installment')
                      : (isArabic ? 'كشف الحساب' : 'Statement');
              final timingMonth = timingDate == null
                  ? (isArabic ? 'غير محدد' : 'Not scheduled')
                  : DateFormat.yMMM(locale).format(timingDate);
              final amountText =
                  '${isPayment ? '+' : '-'}${tx.amount.toStringAsFixed(2)}';
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: m.spacing(5),
                  vertical: m.isCompactHeight ? m.spacing(5) : m.spacing(7),
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: .08)),
                  ),
                ),
                child: Row(
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: m.isCompactHeight ? m.size(10) : m.size(11),
                            backgroundColor: const Color(0xFF182B45),
                            child: isPayment
                                ? Icon(Icons.payments_outlined,
                                    color: const Color(0xFF8CB3FF), size: m.size(12))
                                : _TransactionCategoryIcon(
                                    categoryId: tx.categoryId,
                                    size: m.size(13),
                                  ),
                          ),
                          SizedBox(width: m.spacing(3)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: m.isCompactHeight ? m.text(10) : m.text(11),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yy').format(tx.date),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: m.text(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: m.spacing(4),
                            vertical: m.spacing(4),
                          ),
                          decoration: BoxDecoration(
                            color: isPayment
                                ? const Color(0xFF183B35)
                                : isInstallment
                                    ? const Color(0xFF102D50)
                                    : const Color(0xFF123D34),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPayment
                                  ? const Color(0xFF58D6A2)
                                  : isInstallment
                                      ? const Color(0xFF329DFF)
                                      : const Color(0xFF18B88A),
                            ),
                          ),
                          child: Text(
                            isPayment
                                ? (isArabic ? 'سداد' : 'Payment')
                                : isInstallment
                                    ? (isArabic ? 'تقسيط' : 'Installment')
                                    : (isArabic ? 'شراء عادي' : 'Regular'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isInstallment
                                  ? const Color(0xFF58B9FF)
                                  : const Color(0xFF4DDEAA),
                              fontWeight: FontWeight.w800,
                              fontSize: m.text(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule_rounded,
                              color: const Color(0xFFFFBD3F), size: m.size(13)),
                          SizedBox(width: m.spacing(2)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timing,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFFFFBD3F),
                                    fontWeight: FontWeight.w700,
                                    fontSize: m.text(8),
                                  ),
                                ),
                                Text(
                                  timingMonth,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: m.text(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        amountText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isArabic ? TextAlign.left : TextAlign.right,
                        style: TextStyle(
                          color: isPayment ? const Color(0xFF58D6A2) : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: m.isCompactHeight ? m.text(9) : m.text(10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

String? _transactionSubcategoryTitle(BuildContext context, Transaction tx) {
  final subCategoryId = tx.subCategoryId;
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
  final void Function(DateTime month, List<FinancingInstallment> items)
  onMonthTap;

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
          padding: EdgeInsets.fromLTRB(
            m.spacing(2),
            m.spacing(8),
            m.spacing(2),
            m.spacing(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: const Color(0xFFFF3D81),
                size: m.size(20),
              ),
              SizedBox(width: m.spacing(8)),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.installmentsByMonth,
                  style: TextStyle(
                    fontSize: m.text(15),
                    fontWeight: FontWeight.w800,
                  ),
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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${months.length} ${AppLocalizations.of(context)!.monthsLeft}',
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
          final items = grouped[month]!
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final total = items.fold<Money>(
            Money.zero,
            (sum, item) => sum + item.amount,
          );
          final locale = Localizations.localeOf(context).toLanguageTag();
          final monthLabel = DateFormat('MMM yyyy', locale).format(month);
          return Padding(
            padding: EdgeInsets.only(bottom: m.spacing(8)),
            child: Material(
              color: const Color(0xFF071D2B),
              borderRadius: BorderRadius.circular(m.radius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(m.radius.md),
                onTap: () => onMonthTap(
                  month,
                  List<FinancingInstallment>.unmodifiable(items),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: m.spacing(12),
                    vertical: m.spacing(12),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(m.radius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .07),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: m.size(42),
                        height: m.size(42),
                        decoration: const BoxDecoration(
                          color: Color(0x1FFF3D81),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: const Color(0xFFFF3D81),
                          size: m.size(21),
                        ),
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
                          Text(
                            _money(total.toDouble(), currency),
                            style: TextStyle(
                              fontSize: m.text(13),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: m.spacing(4)),
                          Text(
                            '${items.length} ${items.length == 1 ? 'installment' : 'installments'}',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: m.text(10),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: m.spacing(4)),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white60,
                        size: m.size(22),
                      ),
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
      title: Localizations.localeOf(context).languageCode == 'ar'
          ? 'كشوف الحساب'
          : 'Statements',
      subtitle: profile.statementDay == null
          ? (Localizations.localeOf(context).languageCode == 'ar'
                ? 'لم يتم تحديد يوم كشف الحساب.'
                : 'Statement day is not configured.')
          : (Localizations.localeOf(context).languageCode == 'ar'
                ? 'يُغلق كشف الحساب يوم ${profile.statementDay}. استيراد كشف الحساب الشهري قريبًا.'
                : 'Statement closes on day ${profile.statementDay}. Monthly statement import is coming soon.'),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFFFF3D81), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.color,
  });
  final String title;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );
}

String _money(double value, String currency) =>
    '${value.toStringAsFixed(2)} $currency';
