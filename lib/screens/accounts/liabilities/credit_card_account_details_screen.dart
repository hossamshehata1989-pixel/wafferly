import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/money/money.dart';
import '../../../application/credit_card/credit_card_details_projection_service.dart';
import '../../../application/credit_card/credit_card_transaction_timing_policy.dart';
import '../../../application/credit_card/credit_card_monthly_due_projection_calculator.dart';
import '../../../application/credit_card/credit_card_statement_due_calculator.dart';
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
import 'credit_card_monthly_due_details_screen.dart';
import 'credit_card_transaction_details_screen.dart';
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
  // Open the card on Transactions by default, matching the approved design.
  int _tab = 0;

  Future<CreditCardDetailsProjection?> _projection() =>
      CreditCardDetailsProjectionService().project(widget.accountId);

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;
    // Compact the vertical layout on typical phone-sized viewports so the
    // transaction list gets more of the first screen without changing data.
    final compactPhoneLayout =
        m.isMobile && (m.height < 900 || m.width < 400);

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
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final currentDueLabel = t.thisMonthDue;
        final nextDueLabel = t.nextMonthDue;
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
              dueDateCalculationMethod: projection.profile.dueDateCalculationMethod,
              dueDaysAfterStatement: projection.profile.dueDaysAfterStatement,
              weekendHolidayPolicy: projection.profile.weekendHolidayPolicy,
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
                  onPressed: _showCardMenu,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: m.isCompactHeight ? m.size(22) : m.size(24),
                  ),
                ),
                SizedBox(width: m.spacing(4)),
              ],
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(
                m.spacing(16),
                compactPhoneLayout ? m.spacing(1) : 6,
                m.spacing(16),
                compactPhoneLayout ? m.spacing(10) : 28,
              ),
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
                  thisMonthDueLabel: currentDueLabel,
                  nextMonthDueLabel: nextDueLabel,
                  nextMonthDue: dueBreakdown.nextMonthTotal.toDouble(),
                  nextMonthExpenses: dueBreakdown.nextMonthExpenses.toDouble(),
                  nextMonthInstallments: dueBreakdown.nextMonthInstallments
                      .toDouble(),
                  onMoreDue: () => _showMonthlyDueBreakdown(
                    projection,
                    dueBreakdown.months,
                  ),
                ),
                SizedBox(
                  height: compactPhoneLayout ? m.spacing(5) : m.space.md,
                ),
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
                // Keep a clear breathing gap between quick actions and the tab panel.
                SizedBox(
                  height: compactPhoneLayout ? m.spacing(8) : m.spacing(6),
                ),
                // Keep the tabs and their selected content inside one shared panel.
                // This is a presentation-only change: tab selection and data flows
                // remain unchanged.
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF061A27),
                    borderRadius: BorderRadius.circular(m.radius.lg),
                    border: Border.all(
                      color: const Color(0xFF284356),
                      width: m.size(1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SegmentTabs(
                        selected: _tab,
                        onChanged: (value) => setState(() => _tab = value),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          m.spacing(3),
                          compactPhoneLayout ? m.spacing(2) : m.spacing(3),
                          m.spacing(3),
                          compactPhoneLayout ? m.spacing(2) : m.spacing(4),
                        ),
                        child: _tab == 0
                            ? _TransactionsSection(
                                transactions: transactions,
                                payments: projection.payments,
                                currency: projection.account.currency,
                                profile: projection.profile,
                                contracts: projection.contracts,
                                installments: installments,
                                convertedChargeIds: projection.convertedChargeIds,
                                onTransactionTap: (transaction) =>
                                    _openTransactionDetails(projection, transaction),
                                onViewAll: (groupByPaymentMonth) =>
                                    _openAllTransactions(
                                      projection,
                                      groupByPaymentMonth: groupByPaymentMonth,
                                    ),
                              )
                            : _tab == 1
                                ? _InstallmentsSection(
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
                                : _StatementsSection(
                                    profile: projection.profile,
                                    summary: projection.statementDue,
                                    currency: projection.account.currency,
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthlyDueBreakdown(
    CreditCardDetailsProjection projection,
    List<CreditCardMonthDueProjection> months,
  ) {
    final currency = projection.account.currency;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // This sheet is a forecast: show the nearest due month first, then later months.
    final visibleMonths = months
        .where((month) => month.total > Money.zero)
        .toList()
      ..sort((a, b) => a.monthStart.compareTo(b.monthStart));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1C29),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 8, 20, 14),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    isArabic ? 'المدفوعات المتوقعة حسب الشهر' : 'Monthly Due Forecast',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: visibleMonths.isEmpty
                    ? Center(
                        child: Text(
                          isArabic
                              ? 'لا توجد مستحقات متوقعة في الفترة القادمة'
                              : 'No projected dues in the upcoming months',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: visibleMonths.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (itemContext, index) {
                          final month = visibleMonths[index];
                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => CreditCardMonthlyDueDetailsScreen(
                                      monthProjection: month,
                                      currency: currency,
                                      account: projection.account,
                                      profile: projection.profile,
                                      transactions: projection.transactions,
                                      contracts: projection.contracts,
                                      installments: projection.installments,
                                    ),
                                  ),
                                ).then((changed) {
                                  if (changed == true && mounted) setState(() {});
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF13283A),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            DateFormat.yMMMM(locale).format(month.monthStart),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _money(month.total.toDouble(), currency),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isArabic ? 'المشتريات العادية' : 'Regular expenses',
                                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                                          ),
                                        ),
                                        Text(
                                          _money(month.expenses.toDouble(), currency),
                                          style: const TextStyle(color: Color(0xFFFF6D9D), fontWeight: FontWeight.w700, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isArabic ? 'الأقساط' : 'Installments',
                                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                                          ),
                                        ),
                                        Text(
                                          _money(month.installments.toDouble(), currency),
                                          style: const TextStyle(color: Color(0xFF42C9FF), fontWeight: FontWeight.w700, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTransactionDetails(
    CreditCardDetailsProjection projection,
    Transaction transaction,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreditCardTransactionDetailsScreen(
          transaction: transaction,
          account: projection.account,
          profile: projection.profile,
          contracts: projection.contracts,
          installments: projection.installments,
        ),
      ),
    );
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _openAllTransactions(
    CreditCardDetailsProjection projection, {
    required bool groupByPaymentMonth,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreditCardAllTransactionsScreen(
          projection: projection,
          initialGroupByPaymentMonth: groupByPaymentMonth,
        ),
      ),
    );
    if (changed == true && mounted) setState(() {});
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
                      ? 'قريبًا'
                      : 'COMING SOON',
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

  void _showCardMenu() {
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
              subtitle: const Text('Coming Soon'),
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
  String visualId, {
  required bool isArabic,
}) => CardVisualLayout(
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
      // Arabic keeps the approved layout. English moves the due panels left
      // so the More control can occupy the right-hand position.
      area: CardVisualZone(
        x: isArabic ? .404 : .25,
        y: .325,
        width: isArabic ? .548 : .53,
        height: .225,
      ),
      maxLines: 2,
      minFontScale: .60,
    ),
    CardTextSlot.nextMonthDue: CardVisualSlot(
      zone: CardZone.financialPrimary,
      // Match the same language-specific column positions as this month's panel.
      area: CardVisualZone(
        x: isArabic ? .404 : .25,
        y: .565,
        width: isArabic ? .548 : .53,
        height: .225,
      ),
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
    required this.thisMonthDueLabel,
    required this.nextMonthDueLabel,
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
  final String thisMonthDueLabel;
  final String nextMonthDueLabel;
  final double nextMonthDue;
  final double nextMonthExpenses;
  final double nextMonthInstallments;
  final VoidCallback onMoreDue;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final layout = _creditCardDashboardLayout(
      profile.cardVisual,
      isArabic: isArabic,
    );
    // Use the same palette and accent as the selected card artwork.
    final cardVisualSpec = WafferlyCardVisuals.resolve(
      profile.cardVisual,
      WafferlyCardKind.credit,
    );

    final m = ResponsiveMetrics.of(context);
    final compactPhoneLayout =
        m.isMobile && (m.height < 900 || m.width < 400);
    // Reduce the visual card height on smaller phones; the FittedBox scales the
    // complete card artwork and overlay together, without changing any values.
    final cardScale = !compactPhoneLayout
        ? 1.0
        : m.height < 760
            ? 0.87
            : 0.91;

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
                                    label: thisMonthDueLabel,
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
                                    label: nextMonthDueLabel,
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
  // Arabic keeps More on the left; English moves it to the right of the due panels.
  left: isArabic ? 94 : size.width - 70,
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

// Polished quick actions. Only presentation and language-aware ordering change.
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final compactPhoneLayout =
        m.isMobile && (m.height < 900 || m.width < 400);
    final gap = m.spacing(compactPhoneLayout ? 4 : 7);

    // Use the locale's natural reading direction. The same actions and callbacks
    // are kept in the same logical order; their visual order mirrors in Arabic.
    return Directionality(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: _Action(
              icon: Icons.add_rounded,
              label: AppLocalizations.of(context)!.addTransaction,
              accent: const Color(0xFFFF3D81),
              onTap: onAddTransaction,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Action(
              icon: Icons.calendar_month_rounded,
              label: AppLocalizations.of(context)!.addInstallment,
              accent: const Color(0xFF42C9FF),
              onTap: onAddInstallment,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Action(
              icon: Icons.autorenew_rounded,
              label: AppLocalizations.of(context)!.convertToInstallment,
              accent: const Color(0xFFB68CFF),
              onTap: onConvert,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Action(
              icon: Icons.credit_card_rounded,
              label: AppLocalizations.of(context)!.payCard,
              accent: const Color(0xFFFFC857),
              onTap: onPay,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final compactPhoneLayout =
        m.isMobile && (m.height < 900 || m.width < 400);
    final radius = BorderRadius.circular(m.radius.md);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          height: m.h(compactPhoneLayout ? 61 : 76),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102B3B), Color(0xFF071925)],
            ),
            borderRadius: radius,
            border: Border.all(
              color: accent.withValues(alpha: .35),
              width: m.size(1),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .07),
                blurRadius: m.size(10),
                offset: Offset(0, m.size(3)),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: m.spacing(12),
                right: m.spacing(12),
                child: Container(
                  height: m.size(2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .8),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(m.size(2)),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: m.spacing(2),
                    // The compact action tiles have a tight height. Reduce only
                    // their internal vertical padding to avoid RenderFlex overflow.
                    vertical: m.spacing(compactPhoneLayout ? 1 : 4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: m.size(compactPhoneLayout ? 25 : 29),
                        height: m.size(compactPhoneLayout ? 25 : 29),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: .13),
                          border: Border.all(
                            color: accent.withValues(alpha: .48),
                            width: m.size(1),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: accent,
                          size: m.size(compactPhoneLayout ? 16 : 18),
                        ),
                      ),
                      SizedBox(
                        height: m.spacing(compactPhoneLayout ? 2 : 3),
                      ),
                      Text(
                        label,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: m.text(compactPhoneLayout ? 8 : 9),
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
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
    final compactPhoneLayout =
        m.isMobile && (m.height < 900 || m.width < 400);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(2),
        compactPhoneLayout ? m.spacing(2) : m.spacing(3),
        m.spacing(2),
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _seg(
            m,
            compactPhoneLayout,
            AppLocalizations.of(context)!.transactionsTab,
            Icons.format_list_bulleted_rounded,
            0,
          ),
          _seg(
            m,
            compactPhoneLayout,
            AppLocalizations.of(context)!.installments,
            Icons.pie_chart_outline_rounded,
            1,
          ),
          _seg(
            m,
            compactPhoneLayout,
            AppLocalizations.of(context)!.statements,
            Icons.description_outlined,
            2,
          ),
        ],
      ),
    );
  }

  Widget _seg(
    ResponsiveMetrics m,
    bool compactPhoneLayout,
    String label,
    IconData icon,
    int value,
  ) {
    final active = selected == value;
    final accent = const Color(0xFFFF2D6F);
    final edge = active ? accent : const Color(0xFF284356);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: m.spacing(1)),
          padding: EdgeInsets.symmetric(
            horizontal: m.spacing(1),
            vertical: m.spacing(compactPhoneLayout ? 4 : 7),
          ),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF35152C) : const Color(0xFF0A2030),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A1B38), Color(0xFF2D142A)],
                  )
                : null,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(m.radius.md),
            ),
            border: Border(
              top: BorderSide(color: edge, width: active ? m.size(1.3) : m.size(1)),
              left: BorderSide(color: edge, width: active ? m.size(1.3) : m.size(1)),
              right: BorderSide(color: edge, width: active ? m.size(1.3) : m.size(1)),
              // The selected tab has no bottom stroke, so it visually joins
              // the shared content panel like a folder tab.
              bottom: active
                  ? BorderSide.none
                  : BorderSide(color: const Color(0xFF284356), width: m.size(1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: m.size(compactPhoneLayout ? 14 : 17),
                color: active ? accent : Colors.white60,
              ),
              SizedBox(width: m.spacing(2)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: m.text(compactPhoneLayout ? 8.5 : 10),
                  ),
                ),
              ),
            ],
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

String? _installmentProgressLabel(
  String chargeId,
  List<FinancingContract> contracts,
  List<FinancingInstallment> installments,
) {
  final linked = contracts.where((contract) {
    final state = contract.lifecycleState.trim().toLowerCase();
    return contract.originReference == chargeId &&
        state != 'cancelled' &&
        state != 'canceled' &&
        state != 'terminated';
  }).toList()
    ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
  if (linked.isEmpty) return null;
  final contract = linked.first;
  final rows = installments.where((item) => item.contractId == contract.contractId).toList()
    ..sort((a, b) {
      final bySequence = a.sequence.compareTo(b.sequence);
      return bySequence != 0 ? bySequence : a.dueDate.compareTo(b.dueDate);
    });
  if (rows.isEmpty) return null;
  final outstanding = rows.where((item) {
    final status = item.status.trim().toLowerCase();
    return status != 'settled' && status != 'paid' && status != 'cancelled' &&
        status != 'canceled' && status != 'superseded' && status != 'terminated';
  }).toList();
  final sequence = outstanding.isNotEmpty ? outstanding.first.sequence : contract.installmentCount;
  return '$sequence/${contract.installmentCount}';
}

class _TransactionPaymentMonthRow {
  const _TransactionPaymentMonthRow({
    required this.transaction,
    required this.isPayment,
    required this.isInstallment,
    required this.paymentDate,
    required this.month,
  });

  final Transaction transaction;
  final bool isPayment;
  final bool isInstallment;
  final DateTime? paymentDate;
  final DateTime month;
}

class _TransactionsSection extends StatefulWidget {
  const _TransactionsSection({
    required this.transactions,
    required this.payments,
    required this.currency,
    required this.profile,
    required this.contracts,
    required this.installments,
    required this.convertedChargeIds,
    required this.onTransactionTap,
    this.onViewAll,
    this.showAllMonths = false,
    this.initialGroupByPaymentMonth = false,
  });

  final List<Transaction> transactions;
  final List<Transaction> payments;
  final String currency;
  final CreditCardProfile profile;
  final List<FinancingContract> contracts;
  final List<FinancingInstallment> installments;
  final Set<String> convertedChargeIds;
  final ValueChanged<Transaction> onTransactionTap;
  final ValueChanged<bool>? onViewAll;
  final bool showAllMonths;
  final bool initialGroupByPaymentMonth;

  @override
  State<_TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<_TransactionsSection> {
  static const int _initialVisibleMonthCount = 2;
  static const int _initialVisibleTransactionCount = 8;

  late bool _groupByPaymentMonth;

  @override
  void initState() {
    super.initState();
    _groupByPaymentMonth = widget.initialGroupByPaymentMonth;
  }

  DateTime? _paymentDateFor({
    required Transaction transaction,
    required bool isPayment,
    required bool isInstallment,
  }) {
    if (isPayment) return transaction.date;

    if (isInstallment) {
      return CreditCardTransactionTimingPolicy
          .firstOutstandingInstallmentDueDateForCharge(
        chargeId: transaction.id,
        contracts: widget.contracts,
        installments: widget.installments,
      );
    }

    // Keep the statement-cycle policy explicit, then resolve the corresponding
    // payment date through the same shared policy. This keeps the Payment Month
    // column aligned with the expected bill payment month.
    final statementCloseDate =
        CreditCardTransactionTimingPolicy.statementDateForPurchase(
      purchaseDate: transaction.date,
      statementDay: widget.profile.statementDay,
    );
    return CreditCardTransactionTimingPolicy.paymentDateForStatementClose(
      purchaseDate: transaction.date,
      statementCloseDate: statementCloseDate,
      statementDay: widget.profile.statementDay,
      paymentDueDay: widget.profile.paymentDueDay,
      dueDateCalculationMethod: widget.profile.dueDateCalculationMethod,
      dueDaysAfterStatement: widget.profile.dueDaysAfterStatement,
      weekendHolidayPolicy: widget.profile.weekendHolidayPolicy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final t = AppLocalizations.of(context)!;
    final compactPhoneLayout =
        m.isMobile && (m.height < 900 || m.width < 400);

    // The source records are always ordered by transaction date, newest first.
    // This is the default view. Grouping by payment month is an optional UI mode
    // and does not change the dates or values supplied by the timing policy.
    final events = <Transaction>[...widget.transactions, ...widget.payments]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (events.isEmpty) {
      return _EmptySection(
        title: t.noTransactionsYet,
        subtitle: t.creditCardTransactionsAppearHere,
      );
    }

    final rows = events.map((tx) {
      final isPayment = tx.source == TransactionSource.creditCardPayment;
      final isInstallment =
          !isPayment && widget.convertedChargeIds.contains(tx.id);
      final paymentDate = _paymentDateFor(
        transaction: tx,
        isPayment: isPayment,
        isInstallment: isInstallment,
      );
      // Legacy installments without a linked schedule remain visible. Their
      // Payment Month is shown as not scheduled, while grouping (when selected)
      // falls back to the transaction month as before.
      final groupingDate = paymentDate ?? tx.date;
      final month = DateTime(groupingDate.year, groupingDate.month);
      return _TransactionPaymentMonthRow(
        transaction: tx,
        isPayment: isPayment,
        isInstallment: isInstallment,
        paymentDate: paymentDate,
        month: month,
      );
    }).toList(growable: false);

    final grouped = <DateTime, List<_TransactionPaymentMonthRow>>{};
    for (final row in rows) {
      (grouped[row.month] ??= <_TransactionPaymentMonthRow>[]).add(row);
    }
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final groupRows in grouped.values) {
      groupRows.sort(
        (a, b) => b.transaction.date.compareTo(a.transaction.date),
      );
    }

    final visibleMonths = widget.showAllMonths
        ? months
        : months.take(_initialVisibleMonthCount).toList();
    final visibleRows = widget.showAllMonths
        ? rows
        : rows.take(_initialVisibleTransactionCount).toList();
    // Keep View All visible on the main card screen, even when the preview
    // currently contains only a few transactions. The destination screen
    // displays the complete list; this is navigation-only and does not alter
    // transaction, payment-month, or installment calculations.
    final showViewAll = !widget.showAllMonths && widget.onViewAll != null;

    Widget header(String text, {TextAlign align = TextAlign.center}) => Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            color: Colors.white70,
            fontSize: m.text(compactPhoneLayout ? 8.5 : 10),
            fontWeight: FontWeight.w800,
          ),
        );

    Widget modeOption({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: selected ? const Color(0xFF183A51) : Colors.transparent,
          borderRadius: BorderRadius.circular(m.radius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(m.radius.sm),
            child: Container(
              constraints: BoxConstraints(
                minHeight: m.size(compactPhoneLayout ? 29 : 32),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: m.spacing(compactPhoneLayout ? 2 : 4),
                vertical: m.spacing(compactPhoneLayout ? 3 : 5),
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(m.radius.sm),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF42C9FF)
                      : Colors.white.withValues(alpha: .05),
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: m.text(compactPhoneLayout ? 8.5 : 10),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildColumnHeader() => Container(
          padding: EdgeInsets.symmetric(
            horizontal: m.spacing(5),
            vertical: m.spacing(compactPhoneLayout ? 4 : 7),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF101E2D),
            borderRadius: BorderRadius.circular(m.radius.sm),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
          ),
          child: Row(
            textDirection:
                isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            children: [
              Expanded(
                flex: 15,
                child: header(
                  isArabic ? 'المعاملة' : 'Transaction',
                  align: TextAlign.start,
                ),
              ),
              SizedBox(width: m.spacing(3)),
              Expanded(
                flex: 8,
                child: header(isArabic ? 'النوع' : 'Type'),
              ),
              // A deliberately wider gap separates Type from Payment Month.
              SizedBox(width: m.spacing(6)),
              Expanded(
                flex: 11,
                child: header(
                  isArabic ? 'شهر الدفع' : 'Payment Month',
                  align: TextAlign.start,
                ),
              ),
              // Keep Amount close to the payment-month column, not far away.
              SizedBox(width: m.spacing(2)),
              Expanded(
                flex: 5,
                child: header(
                  isArabic ? 'القيمة' : 'Amount',
                  align: TextAlign.end,
                ),
              ),
            ],
          ),
        );

    Widget buildTransactionRow(_TransactionPaymentMonthRow row) {
      final tx = row.transaction;
      final isPayment = row.isPayment;
      final isInstallment = row.isInstallment;
      final categoryTitle = _transactionCategoryTitle(context, tx.categoryId);
      final subcategoryTitle = _transactionSubcategoryTitle(context, tx);
      final title = isPayment
          ? t.creditCardPayment
          : subcategoryTitle ??
              categoryTitle ??
              (tx.note?.split(' • ').first ?? t.creditCardPurchase);
      final paymentMonth = row.paymentDate == null
          ? (isArabic ? 'غير محدد' : 'Not scheduled')
          : DateFormat.yMMM(locale).format(row.paymentDate!);
      final transactionDate = DateFormat('dd/MM/yy', locale).format(tx.date);
      final secondaryText = !isPayment &&
              subcategoryTitle != null &&
              categoryTitle != null &&
              subcategoryTitle != categoryTitle
          ? '$categoryTitle • $transactionDate'
          : transactionDate;
      final amountText =
          '${isPayment ? '+' : '-'}${tx.amount.toStringAsFixed(2)}';

      return InkWell(
        onTap: () => widget.onTransactionTap(tx),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: m.spacing(5),
            vertical: m.spacing(compactPhoneLayout ? 2.5 : 6),
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
          ),
          child: Row(
            textDirection:
                isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 14,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: m.size(compactPhoneLayout ? 10 : 11),
                      backgroundColor: const Color(0xFF182B45),
                      child: isPayment
                          ? Icon(
                              Icons.payments_outlined,
                              color: const Color(0xFF8CB3FF),
                              size: m.size(12),
                            )
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
                              fontSize: m.text(compactPhoneLayout ? 9.5 : 11),
                            ),
                          ),
                          Text(
                            secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: m.text(compactPhoneLayout ? 7.5 : 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: m.spacing(3)),
              Expanded(
                flex: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isPayment
                          ? (isArabic ? 'سداد' : 'Payment')
                          : isInstallment
                              ? (isArabic ? 'تقسيط' : 'Installment')
                              : (isArabic ? 'شراء عادي' : 'Regular'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPayment
                            ? const Color(0xFF58D6A2)
                            : isInstallment
                                ? const Color(0xFF42C9FF)
                                : const Color(0xFF00D99A),
                        fontWeight: FontWeight.w800,
                        fontSize: m.text(compactPhoneLayout ? 8 : 8.5),
                      ),
                    ),
                    if (isInstallment) ...[
                      SizedBox(height: m.spacing(1)),
                      Text(
                        _installmentProgressLabel(
                              tx.id,
                              widget.contracts,
                              widget.installments,
                            ) ??
                            '',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: m.text(compactPhoneLayout ? 7.5 : 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: m.spacing(13)),
              Expanded(
                flex: 8,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    paymentMonth,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: row.paymentDate == null
                          ? Colors.white54
                          : const Color(0xFFFFBD3F),
                      fontWeight: FontWeight.w700,
                      fontSize: m.text(compactPhoneLayout ? 8.5 : 9),
                    ),
                  ),
                ),
              ),
              SizedBox(width: m.spacing(0)),
              Expanded(
                flex: 7,
                child: Text(
                  amountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isArabic ? TextAlign.left : TextAlign.right,
                  style: TextStyle(
                    color: isPayment ? const Color(0xFF58D6A2) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: m.text(compactPhoneLayout ? 10 : 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildMonthGroup(DateTime month) {
      final groupRows = grouped[month]!;
      return Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: m.spacing(compactPhoneLayout ? 6 : 10),
              vertical: m.spacing(compactPhoneLayout ? 4 : 8),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF19374F), Color(0xFF142638)],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(m.radius.md),
              ),
              border: Border.all(color: const Color(0xFF31516A)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: const Color(0xFFFF3D81),
                  size: m.size(compactPhoneLayout ? 13 : 15),
                ),
                SizedBox(width: m.spacing(compactPhoneLayout ? 3 : 5)),
                Expanded(
                  child: Text(
                    DateFormat.yMMMM(locale).format(month),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: m.text(compactPhoneLayout ? 10 : 11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  isArabic
                      ? '${groupRows.length} عمليات'
                      : '${groupRows.length} ${groupRows.length == 1 ? 'transaction' : 'transactions'}',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: m.text(compactPhoneLayout ? 7.5 : 8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              bottom: m.spacing(compactPhoneLayout ? 4 : 8),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(m.radius.md),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Column(
              children: groupRows.map(buildTransactionRow).toList(),
            ),
          ),
        ],
      );
    }

    final sectionTitle = _groupByPaymentMonth
        ? (isArabic ? 'العمليات حسب شهر الدفع' : 'Transactions by Payment Month')
        : (isArabic ? 'العمليات حسب تاريخها' : 'Transactions by Date');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            m.spacing(2),
            compactPhoneLayout ? m.spacing(2) : m.spacing(5),
            m.spacing(2),
            compactPhoneLayout ? m.spacing(2) : m.spacing(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: m.text(compactPhoneLayout ? 10 : 11),
                  ),
                ),
              ),
              if (showViewAll)
                TextButton(
                  onPressed: () => widget.onViewAll?.call(_groupByPaymentMonth),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3D81),
                    padding: EdgeInsets.symmetric(
                      horizontal: m.spacing(compactPhoneLayout ? 2 : 4),
                    ),
                    minimumSize: Size(0, m.size(compactPhoneLayout ? 28 : 32)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isArabic ? 'عرض الكل' : 'View All',
                    style: TextStyle(
                      fontSize: m.text(compactPhoneLayout ? 9 : 10),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(
            m.spacing(compactPhoneLayout ? 2 : 3),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1C29),
            borderRadius: BorderRadius.circular(m.radius.md),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              modeOption(
                label: isArabic ? 'تاريخ العملية' : 'Transaction Date',
                selected: !_groupByPaymentMonth,
                onTap: () {
                  if (_groupByPaymentMonth) {
                    setState(() => _groupByPaymentMonth = false);
                  }
                },
              ),
              SizedBox(width: m.spacing(compactPhoneLayout ? 2 : 3)),
              modeOption(
                label: isArabic ? 'شهر الدفع' : 'Payment Month',
                selected: _groupByPaymentMonth,
                onTap: () {
                  if (!_groupByPaymentMonth) {
                    setState(() => _groupByPaymentMonth = true);
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: m.spacing(compactPhoneLayout ? 2 : 4),
        ),
        buildColumnHeader(),
        SizedBox(
          height: m.spacing(compactPhoneLayout ? 2 : 3),
        ),
        if (_groupByPaymentMonth)
          ...visibleMonths.map(buildMonthGroup)
        else
          Container(
            margin: EdgeInsets.only(
              bottom: m.spacing(compactPhoneLayout ? 4 : 8),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(m.radius.md),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(m.radius.md),
              child: Column(
                children: visibleRows.map(buildTransactionRow).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

String? _transactionSubcategoryTitle(BuildContext context, Transaction tx) {
  final subCategoryId = tx.subCategoryId?.trim();
  if (subCategoryId == null || subCategoryId.isEmpty) return null;

  final t = AppLocalizations.of(context)!;
  final parentCategoryId = tx.categoryId;

  // Prefer the subcategory under the transaction's stored parent category.
  // This avoids resolving a duplicate subcategory ID from another category.
  if (parentCategoryId != null && parentCategoryId.isNotEmpty) {
    for (final type in CategoryType.values) {
      for (final category in getCategories(type)) {
        if (category.id != parentCategoryId) continue;
        for (final sub in category.subCategories ?? const <SubCategoryConfig>[]) {
          if (sub.id == subCategoryId) return sub.title(t);
        }
      }
    }
  }

  // Backward-compatible fallback for older records that may have a subcategory
  // ID but no parent category ID.
  for (final type in CategoryType.values) {
    for (final category in getCategories(type)) {
      for (final sub in category.subCategories ?? const <SubCategoryConfig>[]) {
        if (sub.id == subCategoryId) return sub.title(t);
      }
    }
  }
  return null;
}

class CreditCardAllTransactionsScreen extends StatelessWidget {
  const CreditCardAllTransactionsScreen({
    super.key,
    required this.projection,
    this.initialGroupByPaymentMonth = false,
  });

  final CreditCardDetailsProjection projection;
  final bool initialGroupByPaymentMonth;

  Future<void> _openDetails(BuildContext context, Transaction transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreditCardTransactionDetailsScreen(
          transaction: transaction,
          account: projection.account,
          profile: projection.profile,
          contracts: projection.contracts,
          installments: projection.installments,
        ),
      ),
    );
    if (changed == true && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final m = ResponsiveMetrics.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isArabic ? 'كل العمليات' : 'All Transactions', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(m.spacing(16), 4, m.spacing(16), 24),
        children: [
          _TransactionsSection(
            transactions: projection.transactions,
            payments: projection.payments,
            currency: projection.account.currency,
            profile: projection.profile,
            contracts: projection.contracts,
            installments: projection.installments,
            convertedChargeIds: projection.convertedChargeIds,
            onTransactionTap: (tx) => _openDetails(context, tx),
            showAllMonths: true,
            initialGroupByPaymentMonth: initialGroupByPaymentMonth,
          ),
        ],
      ),
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
  const _StatementsSection({required this.profile, required this.summary, required this.currency});
  final CreditCardProfile profile;
  final CreditCardStatementDueSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final m = ResponsiveMetrics.of(context);

    if (!summary.isConfigured) {
      return _EmptySection(
        title: isArabic ? 'كشوف الحساب' : 'Statements',
        subtitle: isArabic
            ? 'حدد يوم كشف الحساب وموعد السداد لعرض تقدير الاستحقاق.'
            : 'Configure the statement and due days to see the current due estimate.',
      );
    }

    final closeDate = summary.statementCloseDate!;
    final dueDate = summary.paymentDueDate!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(m.spacing(2), m.spacing(8), m.spacing(2), m.spacing(8)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'كشوف الحساب' : 'Statements',
                  style: TextStyle(fontSize: m.text(16), fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: m.spacing(8), vertical: m.spacing(4)),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C382F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00D99A).withValues(alpha: .45)),
                ),
                child: Text(
                  isArabic ? 'تقديري' : 'Estimate',
                  style: TextStyle(color: const Color(0xFF00D99A), fontSize: m.text(9), fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(m.spacing(13)),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1C29),
            borderRadius: BorderRadius.circular(m.radius.md),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: m.size(42),
                    height: m.size(42),
                    decoration: const BoxDecoration(color: Color(0x22FF3D81), shape: BoxShape.circle),
                    child: Icon(Icons.calendar_month_rounded, color: const Color(0xFFFF3D81), size: m.size(21)),
                  ),
                  SizedBox(width: m.spacing(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMM(locale).format(closeDate),
                          style: TextStyle(fontSize: m.text(14), fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: m.spacing(2)),
                        Text(
                          isArabic ? 'تقدير كشف الحساب الحالي' : 'Current statement estimate',
                          style: TextStyle(color: Colors.white60, fontSize: m.text(10)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _money(summary.amountDue.toDouble(), currency),
                    style: TextStyle(fontSize: m.text(13), fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              SizedBox(height: m.spacing(12)),
              Divider(color: Colors.white.withValues(alpha: .08), height: 1),
              SizedBox(height: m.spacing(10)),
              Row(
                children: [
                  Expanded(
                    child: _StatementMeta(
                      label: isArabic ? 'تاريخ قفل الكشف' : 'Statement Date',
                      value: DateFormat('dd MMM yyyy', locale).format(closeDate),
                    ),
                  ),
                  SizedBox(width: m.spacing(8)),
                  Expanded(
                    child: _StatementMeta(
                      label: isArabic ? 'موعد السداد' : 'Due Date',
                      value: DateFormat('dd MMM yyyy', locale).format(dueDate),
                    ),
                  ),
                ],
              ),
              SizedBox(height: m.spacing(12)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(m.spacing(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFF13283A),
                  borderRadius: BorderRadius.circular(m.radius.sm),
                ),
                child: Text(
                  isArabic
                      ? 'هذا تقدير مبني على العمليات المسجلة، وليس كشفًا رسميًا مستوردًا من البنك. دورة الكشف يوم ${profile.statementDay} والاستحقاق يوم ${profile.paymentDueDay}.'
                      : 'This estimate is based on recorded activity, not an imported official bank statement. Statement day: ${profile.statementDay}; due day: ${profile.paymentDueDay}.',
                  style: TextStyle(color: Colors.white60, fontSize: m.text(10), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: m.spacing(8)),
        Text(
          isArabic
              ? 'الكشوف التاريخية ستظهر عند توفر بيانات كشوف البنك داخل التطبيق.'
              : 'Historical statement cards will appear once bank statement records are available in the app.',
          style: TextStyle(color: Colors.white38, fontSize: m.text(10)),
        ),
      ],
    );
  }
}

class _StatementMeta extends StatelessWidget {
  const _StatementMeta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: m.text(9))),
        SizedBox(height: m.spacing(3)),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: m.text(10))),
      ],
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
