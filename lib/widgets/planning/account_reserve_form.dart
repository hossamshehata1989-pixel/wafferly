import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/manual_reserve_application_service.dart';

/// Reserve money from a single account through the Planning Engine.
///
/// This widget owns presentation and validation only.
/// The actual reservation is delegated to
/// ManualReserveApplicationService.
class AccountReserveForm extends StatefulWidget {
  const AccountReserveForm({
    super.key,
    required this.accountId,
    required this.accountName,
    this.accountIcon,
    required this.available,
    required this.currency,
    required this.applicationService,
    required this.onSuccess,
    this.reserved = 0,
  });

  final String accountId;
  final String accountName;
  final String? accountIcon;
  final double available;

  /// Amount already reserved before this form opened.
  final double reserved;

  final String currency;
  final ManualReserveApplicationService applicationService;
  final VoidCallback onSuccess;

  @override
  State<AccountReserveForm> createState() => _AccountReserveFormState();
}

class _AccountReserveFormState extends State<AccountReserveForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  bool _saving = false;
  String? _errorMessage;

  double get _amount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  bool get _hasValidAmount =>
      _amount > 0 && _amount <= widget.available;

  double get _remaining =>
      (widget.available - _amount)
          .clamp(0, widget.available)
          .toDouble();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _setAmount(double value) {
    final amount = value.clamp(0, widget.available).toInt();

    _amountController.text = amount.toString();

    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );

    setState(() {
      _errorMessage = null;
    });

    _amountFocusNode.requestFocus();
  }

  Future<void> _reserve() async {
    if (_saving) return;

    final amount = _amount;

    if (amount <= 0) {
      setState(() {
        _errorMessage = 'Enter an amount greater than 0.';
      });

      _amountFocusNode.requestFocus();
      return;
    }

    if (amount > widget.available) {
      setState(() {
        _errorMessage =
            'You can reserve up to '
            '${_formatMoney(widget.available)} '
            '${widget.currency}.';
      });

      _amountFocusNode.requestFocus();
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.applicationService.reserve(
        accountId: widget.accountId,
        amount: amount,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      widget.onSuccess();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('Insufficient available balance')) {
      return 'The available balance changed. '
          'Please enter a lower amount.';
    }

    return 'Unable to reserve money right now. '
        'Please try again.';
  }

  String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final keyboardHeight = media.viewInsets.bottom;

    final usableHeight = (screenHeight - keyboardHeight)
        .clamp(420.0, screenHeight)
        .toDouble();

    /*
     * Responsive sheet height.
     *
     * We deliberately do not make the sheet huge.
     * On small devices it uses more of the available viewport,
     * while on larger devices it stays visually compact.
     */
    final sheetHeight = keyboardHeight > 0
        ? usableHeight.clamp(430.0, 650.0).toDouble()
        : usableHeight.clamp(500.0, 760.0).toDouble();

    final verySmall = screenHeight < 620;
    final compact = screenHeight < 720;
    final narrow = screenWidth < 380;

    final horizontalPadding = narrow
        ? 14.0
        : screenWidth < 600
            ? 18.0
            : 24.0;

    final sectionGap = verySmall
        ? 7.0
        : compact
            ? 10.0
            : 14.0;

    /*
     * When keyboard is visible, secondary information is hidden.
     * This keeps the amount field and action buttons accessible
     * without forcing the user into a long scroll.
     */
    final keyboardMode = keyboardHeight > 0;

    final showNameHelper = !verySmall && !keyboardMode;
    final showQuickAmounts = !verySmall;
    final showInfoCard = !verySmall && !keyboardMode;

    return SizedBox(
      height: sheetHeight,
      width: double.infinity,
      child: Material(
        color: const Color(0xFF071823),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(height: verySmall ? 5 : 7),

              _Header(
                compact: compact,
                veryCompact: verySmall,
              ),

              SizedBox(height: sectionGap),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IntroCard(
                        accountName: widget.accountName,
                        accountIcon: widget.accountIcon,
                        currency: widget.currency,
                        compact: compact,
                      ),

                      SizedBox(height: sectionGap),

                      _SectionLabel(
                        title: 'Reserve name',
                        trailing: 'Optional',
                        compact: compact,
                      ),

                      const SizedBox(height: 5),

                      _FieldContainer(
                        child: TextField(
                          controller: _nameController,
                          enabled: !_saving,
                          textInputAction: TextInputAction.next,
                          maxLength: 60,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            prefixIcon: Icon(
                              Icons.bookmark_border_rounded,
                              color: const Color(0xFFB995FF),
                              size: compact ? 19 : 21,
                            ),
                            hintText:
                                'Rent, Emergency Fund, New Laptop',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: compact ? 13 : 14,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: compact ? 9 : 12,
                            ),
                          ),
                        ),
                      ),

                      if (showNameHelper) ...[
                        const SizedBox(height: 3),
                        const Text(
                          'A short name helps you recognize this reserve later.',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                          ),
                        ),
                      ],

                      SizedBox(height: sectionGap),

                      _AvailableCard(
                        available: widget.available,
                        reserved: widget.reserved,
                        currency: widget.currency,
                        remaining: _remaining,
                        reservedAmount: _amount,
                        compact: compact,
                      ),

                      SizedBox(height: sectionGap),

                      _SectionLabel(
                        title: 'Amount to reserve',
                        compact: compact,
                      ),

                      const SizedBox(height: 5),

                      Focus(
                        onFocusChange: (_) {
                          setState(() {});
                        },
                        child: _FieldContainer(
                          focused: _amountFocusNode.hasFocus,
                          error: _errorMessage != null,
                          child: TextField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],

                            /*
                             * IMPORTANT:
                             *
                             * There is intentionally NO onSubmitted here.
                             *
                             * Pressing "Done" on the keyboard must NOT
                             * execute the reservation.
                             *
                             * The reservation can only happen through
                             * the explicit Reserve button.
                             */
                            textInputAction: TextInputAction.done,

                            onChanged: (_) {
                              setState(() {
                                _errorMessage = null;
                              });
                            },

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: verySmall
                                  ? 22
                                  : compact
                                      ? 25
                                      : 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                            ),

                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: Colors.white24,
                                fontSize: compact ? 25 : 28,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: const Color(0xFFB995FF),
                                size: compact ? 20 : 22,
                              ),
                              suffixText: widget.currency,
                              suffixStyle: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: compact ? 9 : 13,
                                horizontal: 4,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 5),
                        _ErrorMessage(
                          message: _errorMessage!,
                        ),
                      ] else if (showNameHelper) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Numbers only. No decimals.',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                          ),
                        ),
                      ],

                      if (showQuickAmounts) ...[
                        const SizedBox(height: 7),
                        _QuickAmounts(
                          available: widget.available,
                          enabled: !_saving,
                          onSelected: _setAmount,
                        ),
                      ],

                      if (showInfoCard) ...[
                        SizedBox(height: sectionGap),
                        const _InfoCard(),
                      ],
                    ],
                  ),
                ),
              ),

              _BottomActions(
                saving: _saving,
                enabled: _hasValidAmount,
                onCancel: () {
                  if (!_saving) {
                    Navigator.of(context).pop(false);
                  }
                },
                onReserve: _reserve,
                currency: widget.currency,
                amount: _amount,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _Header extends StatelessWidget {
  const _Header({
    this.compact = false,
    this.veryCompact = false,
  });

  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: veryCompact ? 36 : 44,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        SizedBox(
          height: veryCompact
              ? 8
              : compact
                  ? 11
                  : 15,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: veryCompact ? 18 : 20,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserve Money',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: veryCompact
                        ? 20
                        : compact
                            ? 21
                            : 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set money aside from this account.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: compact ? 12.5 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RESERVE ICON
// ============================================================================


// ============================================================================
// ACCOUNT CARD
// ============================================================================

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.accountName,
    required this.accountIcon,
    required this.currency,
    this.compact = false,
  });

  final String accountName;
  final String? accountIcon;
  final String currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = compact ? 38.0 : 42.0;
    final iconSize = compact ? 23.0 : 25.0;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: .07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            padding: EdgeInsets.all(compact ? 7 : 8),
            decoration: BoxDecoration(
              color: const Color(0xFF37D991).withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: accountIcon != null && accountIcon!.isNotEmpty
                ? SvgPicture.asset(
                    accountIcon!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF37D991),
                      size: iconSize,
                    ),
                  )
                : Icon(
                    Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF37D991),
                    size: iconSize,
                  ),
          ),
          SizedBox(width: compact ? 9 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'From account',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 14 : 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currency,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION LABEL
// ============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final String? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        if (trailing != null) ...[
          const SizedBox(width: 7),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFB995FF).withValues(alpha: .08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFB995FF).withValues(alpha: .25),
              ),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: Color(0xFFB995FF),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// FIELD CONTAINER
// ============================================================================

class _FieldContainer extends StatelessWidget {
  const _FieldContainer({
    required this.child,
    this.focused = false,
    this.error = false,
  });

  final Widget child;
  final bool focused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final borderColor = error
        ? const Color(0xFFFF667A)
        : focused
            ? const Color(0xFFB995FF)
            : Colors.white.withValues(alpha: .07);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: const Color(0xFF121D31),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
          width: focused || error ? 1.4 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: const Color(0xFFB995FF)
                      .withValues(alpha: .08),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

// ============================================================================
// AVAILABLE / RESERVED CARD
// ============================================================================

class _AvailableCard extends StatelessWidget {
  const _AvailableCard({
    required this.available,
    required this.reserved,
    required this.currency,
    required this.remaining,
    required this.reservedAmount,
    this.compact = false,
  });

  /// Current spendable amount before this reservation.
  final double available;

  /// Amount already reserved before this form opened.
  final double reserved;

  final String currency;
  final double remaining;

  /// Amount currently typed by the user.
  final double reservedAmount;

  final bool compact;

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    /*
     * Total capacity = currently available + already reserved.
     *
     * Example:
     * Available = 9098
     * Reserved  = 13500
     * Total     = 22598
     */
    final total = (available + reserved)
        .clamp(0.0, double.infinity)
        .toDouble();

    final currentRatio = total <= 0
        ? 0.0
        : (reserved / total).clamp(0.0, 1.0).toDouble();

    final pendingRatio = total <= 0
        ? 0.0
        : (reservedAmount / total)
            .clamp(0.0, 1.0 - currentRatio)
            .toDouble();

    final projectedReserved = reserved + reservedAmount;
    final projectedRemaining = remaining;

    final freeRatio =
        (1 - currentRatio - pendingRatio).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1E29),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: .07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------------
          // HEADER
          // ------------------------------------------------------------------

          Row(
            children: [
              Container(
                width: compact ? 36 : 38,
                height: compact ? 36 : 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF37D991)
                      .withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF37D991),
                  size: compact ? 18 : 19,
                ),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'Available to reserve',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '${_money(available)} $currency',
                style: TextStyle(
                  color: const Color(0xFF37D991),
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 10 : 13),

          // ------------------------------------------------------------------
          // CAPACITY BAR
          // ------------------------------------------------------------------

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: compact ? 8 : 9,
              child: Row(
                children: [
                  if (currentRatio > 0)
                    Expanded(
                      flex: (currentRatio * 1000)
                          .round()
                          .clamp(1, 1000),
                      child: Container(
                        color: const Color(0xFFFFAA2C),
                      ),
                    ),

                  if (pendingRatio > 0)
                    Expanded(
                      flex: (pendingRatio * 1000)
                          .round()
                          .clamp(1, 1000),
                      child: Container(
                        color: const Color(0xFFB995FF),
                      ),
                    ),

                  if (freeRatio > 0)
                    Expanded(
                      flex: (freeRatio * 1000)
                          .round()
                          .clamp(1, 1000),
                      child: Container(
                        color: Colors.white10,
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: compact ? 8 : 10),

          // ------------------------------------------------------------------
          // LEGEND
          // ------------------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CapacityLegend(
                  color: const Color(0xFFFFAA2C),
                  label: 'Currently reserved',
                  amount:
                      '${_money(reserved)} $currency',
                ),
              ),

              if (reservedAmount > 0)
                Expanded(
                  child: _CapacityLegend(
                    color: const Color(0xFFB995FF),
                    label: 'This reserve',
                    amount:
                        '+${_money(reservedAmount)} $currency',
                  ),
                ),

              Expanded(
                child: _CapacityLegend(
                  color: Colors.white38,
                  label: 'Remaining',
                  amount:
                      '${_money(projectedRemaining)} $currency',
                  alignEnd: true,
                ),
              ),
            ],
          ),

          // ------------------------------------------------------------------
          // PROJECTED RESULT
          // ------------------------------------------------------------------

          if (reservedAmount > 0) ...[
            SizedBox(height: compact ? 8 : 10),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: compact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFB995FF)
                    .withValues(alpha: .06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFB995FF)
                      .withValues(alpha: .12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFB995FF),
                    size: 15,
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      'After reserve: '
                      '${_money(projectedReserved)} '
                      '$currency reserved',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// CAPACITY LEGEND
// ============================================================================

class _CapacityLegend extends StatelessWidget {
  const _CapacityLegend({
    required this.color,
    required this.label,
    required this.amount,
    this.alignEnd = false,
  });

  final Color color;
  final String label;
  final String amount;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 5),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign:
                    alignEnd ? TextAlign.end : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign:
              alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK AMOUNTS
// ============================================================================

class _QuickAmounts extends StatelessWidget {
  const _QuickAmounts({
    required this.available,
    required this.enabled,
    required this.onSelected,
  });

  final double available;
  final bool enabled;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    const candidates = <double>[
      100,
      500,
      1000,
      2000,
    ];

    final values = candidates
        .where((value) => value < available)
        .toList();

    if (available > 0 && !values.contains(available)) {
      values.add(available);
    }

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final value in values)
          _QuickAmountChip(
            label: value == available
                ? 'Max'
                : '+${value.toStringAsFixed(0)}',
            enabled: enabled,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }
}

// ============================================================================
// QUICK AMOUNT CHIP
// ============================================================================

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF121D31),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB995FF),
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INFO CARD
// ============================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12162A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: .06),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB995FF),
            size: 20,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good to know',
                  style: TextStyle(
                    color: Color(0xFFD2B9FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Reserved money stays protected from accidental spending. '
                  'You can release it later.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11.5,
                    height: 1.35,
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

// ============================================================================
// ERROR
// ============================================================================

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFFF667A),
          size: 16,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFFF8A98),
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BOTTOM ACTIONS
// ============================================================================

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.saving,
    required this.enabled,
    required this.onCancel,
    required this.onReserve,
    required this.currency,
    required this.amount,
    this.compact = false,
  });

  final bool saving;
  final bool enabled;
  final VoidCallback onCancel;
  final VoidCallback onReserve;
  final String currency;
  final double amount;
  final bool compact;

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = compact ? 35.0 : 42.0;

    final buttonColor = enabled
        ? const Color(0xFFB995FF)
        : const Color(0xFF5B526C);

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 7 : 9,
        compact ? 12 : 16,
        compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF071823),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: .06),
          ),
        ),
      ),
      child: Row(
        children: [
          // ------------------------------------------------------------------
          // CANCEL
          // ------------------------------------------------------------------

          Expanded(
            child: SizedBox(
              height: buttonHeight,
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD2B9FF),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: .45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      compact ? 13 : 15,
                    ),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ------------------------------------------------------------------
          // RESERVE
          // ------------------------------------------------------------------

          Expanded(
            child: SizedBox(
              height: buttonHeight,
              child: FilledButton(
                onPressed:
                    (!saving && enabled) ? onReserve : null,
                style: FilledButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: const Color(0xFF24173B),
                  disabledBackgroundColor:
                      const Color(0xFF2A2630),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      compact ? 13 : 15,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              enabled
                                  ? 'Reserve '
                                      '${_money(amount)} '
                                      '$currency'
                                  : 'Reserve Money',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          if (enabled) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}