// lib/widgets/expense_entry/amount_input_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';

class AmountInputPanel extends StatelessWidget {
  final TransactionEntryController controller;

  const AmountInputPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // ✅ يظل محسوباً من ارتفاع الشاشة فقط (بدون metrics.size)
    double buttonSize = screenHeight * 0.04;
    buttonSize = buttonSize.clamp(32.0, 42.0);

    if (keyboardHeight > 0) {
      buttonSize = buttonSize.clamp(34.0, 48.0);
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(16),
        vertical: metrics.spacing(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // شريط الإشارة العلوي (ثابت الأبعاد، غير responsive)
          Center(
            child: Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(20), // ثابت
              ),
            ),
          ),
          SizedBox(height: metrics.spacing(2)),
          // حقل عرض المبلغ
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.spacing(2),
              vertical: metrics.spacing(2),
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16), // ثابت
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.spacing(16),
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16), // ثابت
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              controller.amount,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: metrics.text(42),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: metrics.spacing(8)),
                        Text(
                          controller.currentCurrency,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: metrics.text(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: metrics.spacing(4)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _topActionButton(metrics, Icons.note_alt_outlined),
                    SizedBox(width: metrics.spacing(8)),
                    _topActionButton(metrics, Icons.check),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: metrics.spacing(4)),
          _buildCalculator(metrics, buttonSize),
          SizedBox(height: metrics.spacing(8)),
          // صف أزرار المعلومات
          Row(
            children: [
              Expanded(
                child: _infoButton(
                  metrics,
                  Icons.account_balance_wallet_outlined,
                  'Cash',
                ),
              ),
              SizedBox(width: metrics.spacing(6)),
              Expanded(
                child: _infoButton(
                  metrics,
                  Icons.calendar_today_outlined,
                  'Today',
                ),
              ),
              SizedBox(width: metrics.spacing(6)),
              Expanded(child: _infoButton(metrics, Icons.person_outline, 'Me')),
              SizedBox(width: metrics.spacing(6)),
              Expanded(child: _infoButton(metrics, Icons.repeat, 'Recurring')),
            ],
          ),
          SizedBox(height: metrics.spacing(8)),
          // صف الأزرار السفلية
          Row(
            children: [
              Expanded(
                child: _bottomActionButton(
                  metrics,
                  'Exceptional',
                  Icons.star_outline,
                ),
              ),
              SizedBox(width: metrics.spacing(6)),
              SizedBox(
                width: 56, // ثابت (غير responsive)
                child: _bottomActionButton(metrics, '', Icons.mic),
              ),
              SizedBox(width: metrics.spacing(6)),
              Expanded(child: _bottomActionButton(metrics, 'Add', Icons.add)),
            ],
          ),
        ],
      ),
    );
  }

  // ======================== أزرار الحاسبة ========================
  Widget _buildCalculator(ResponsiveMetrics metrics, double buttonSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _calcButton(metrics, "1", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "2", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "3", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "C", buttonSize, isOperator: true),
          ],
        ),
        SizedBox(height: metrics.spacing(2)),
        Row(
          children: [
            _calcButton(metrics, "4", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "5", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "6", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "⌫", buttonSize, isOperator: true),
          ],
        ),
        SizedBox(height: metrics.spacing(2)),
        Row(
          children: [
            _calcButton(metrics, "7", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "8", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "9", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "+", buttonSize, isOperator: true),
          ],
        ),
        SizedBox(height: metrics.spacing(2)),
        Row(
          children: [
            _calcButton(metrics, ".", buttonSize, isOperator: true),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "0", buttonSize),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(
              metrics,
              "=",
              buttonSize,
              isOperator: true,
              isPrimary: true,
            ),
            SizedBox(width: metrics.spacing(1)),
            _calcButton(metrics, "x", buttonSize, isOperator: true),
          ],
        ),
      ],
    );
  }

  Widget _calcButton(
    ResponsiveMetrics metrics,
    String text,
    double size, {
    bool isOperator = false,
    bool isPrimary = false,
    bool isDisabled = false,
    bool invisible = false,
  }) {
    final double fontSize = (size * 0.4).clamp(20.0, 24.0);
    final double responsiveFontSize = metrics.text(fontSize);
    return Expanded(
      child: SizedBox(
        height: size,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.spacing(2)),
          child: InkWell(
            onTap: isDisabled || invisible
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    controller.onCalculatorTap(text);
                  },
            borderRadius: BorderRadius.circular(12), // ثابت
            child: Container(
              decoration: BoxDecoration(
                color: invisible
                    ? Colors.transparent
                    : isDisabled
                    ? Colors.transparent
                    : isPrimary
                    ? Colors.blue
                    : (isOperator
                          ? AppColors.cardSecondary
                          : AppColors.background),
                borderRadius: BorderRadius.circular(12), // ثابت
              ),
              alignment: Alignment.center,
              child: text.isEmpty
                  ? null
                  : Text(
                      text,
                      style: TextStyle(
                        color: isDisabled || invisible
                            ? Colors.transparent
                            : isPrimary
                            ? Colors.white
                            : (isOperator ? Colors.blue : Colors.white),
                        fontSize: responsiveFontSize,
                        fontWeight: isOperator
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================== أزرار علوية (Note, Check) ========================
  Widget _topActionButton(ResponsiveMetrics metrics, IconData icon) {
    final double buttonSize = metrics.size(52);
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(10), // ثابت
      ),
      child: Icon(icon, color: Colors.white, size: metrics.size(18)),
    );
  }

  // ======================== أزرار المعلومات (Cash, Today, Me, Recurring) ========================
  Widget _infoButton(ResponsiveMetrics metrics, IconData icon, String text) {
    final double height = metrics.size(40);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(12), // ثابت
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: metrics.size(20), color: Colors.white70),
          SizedBox(width: metrics.spacing(4)),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: metrics.text(11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================== أزرار سفلية (Exceptional, Mic, Add) ========================
  Widget _bottomActionButton(
    ResponsiveMetrics metrics,
    String text,
    IconData icon,
  ) {
    final double height = metrics.size(40);
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: metrics.spacing(8)),
        ),
        child: FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: metrics.size(20)),
              if (text.isNotEmpty) ...[
                SizedBox(width: metrics.spacing(4)),
                Text(text, style: TextStyle(fontSize: metrics.text(14))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
