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
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isSmallScreen = metrics.width < 360;
    final double buttonSize = metrics.h(isKeyboardOpen ? 28 : 45);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(4),
        vertical: metrics.h(6),
      ),
      child: Container(
        // الحاوية الخارجية للبانل
        padding: EdgeInsets.all(
          isSmallScreen ? metrics.spacing(6) : metrics.spacing(10),
        ),
        decoration: BoxDecoration(
          color: AppColors.inputPanel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.spacing(1),
                vertical: metrics.h(2),
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.spacing(12),
                        vertical: metrics.h(5), // تمت الزيادة من 3 إلى 5
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
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
                                  fontSize: metrics.text(
                                    24,
                                  ), // تمت الزيادة من 20 إلى 24
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
                              fontSize: metrics.text(14),
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
                      SizedBox(width: metrics.spacing(6)),
                      _topActionButton(
                        metrics,
                        Icons.repeat,
                      ), // تم التغيير من Icons.check إلى Icons.repeat
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: metrics.h(4)),

            _buildCalculator(metrics, buttonSize),

            SizedBox(height: metrics.h(3)),

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
                Expanded(
                  child: _infoButton(metrics, Icons.person_outline, 'Me'),
                ),
                SizedBox(width: metrics.spacing(6)),
                Expanded(
                  child: _infoButton(
                    metrics,
                    Icons.check_circle_outline, // تم التغيير من Icons.repeat
                    'Done', // النص الجديد
                  ),
                ),
              ],
            ),

            SizedBox(height: metrics.h(6)),

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
                  width: metrics.size(52),
                  child: _bottomActionButton(metrics, '', Icons.mic),
                ),
                SizedBox(width: metrics.spacing(6)),
                Expanded(child: _bottomActionButton(metrics, 'Add', Icons.add)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ======================== الحاسبة ========================
  Widget _buildCalculator(ResponsiveMetrics metrics, double buttonSize) {
    final double rowSpacing = metrics.h(3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _calcRow(metrics, buttonSize, ["1", "2", "3", "C"]),
        SizedBox(height: rowSpacing),
        _calcRow(metrics, buttonSize, ["4", "5", "6", "⌫"]),
        SizedBox(height: rowSpacing),
        _calcRow(metrics, buttonSize, ["7", "8", "9", "+"]),
        SizedBox(height: rowSpacing),
        _calcRow(metrics, buttonSize, [".", "0", "=", "x"]),
      ],
    );
  }

  Widget _calcRow(
    ResponsiveMetrics metrics,
    double buttonSize,
    List<String> keys,
  ) {
    const operators = {"C", "⌫", "+", "x", ".", "="};
    const primary = {"="};

    return Row(
      children: keys.map((key) {
        return _calcButton(
          metrics,
          key,
          buttonSize,
          isOperator: operators.contains(key),
          isPrimary: primary.contains(key),
        );
      }).toList(),
    );
  }

  Widget _calcButton(
    ResponsiveMetrics metrics,
    String text,
    double size, {
    bool isOperator = false,
    bool isPrimary = false,
  }) {
    final double fontSize = (size * 0.44).clamp(11.0, 22.0);

    return Expanded(
      child: SizedBox(
        height: size,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.spacing(2)),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.onCalculatorTap(text);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.blue
                    : isOperator
                    ? AppColors.calculatorButton
                    : AppColors
                          .cardSecondary, // تم التغيير من AppColors.background إلى cardSecondary
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : isOperator
                      ? Colors.blue
                      : Colors.white,
                  fontSize: fontSize,
                  fontWeight: isOperator ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================== أزرار علوية (Note, Repeat) ========================
  Widget _topActionButton(ResponsiveMetrics metrics, IconData icon) {
    final double buttonSize = metrics.h(50);
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: AppColors.calculatorButton,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: metrics.size(16)),
    );
  }

  // ======================== أزرار المعلومات ========================
  Widget _infoButton(ResponsiveMetrics metrics, IconData icon, String text) {
    final isSmallScreen = metrics.width < 360;

    final double height = isSmallScreen ? metrics.h(38) : metrics.h(45);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.calculatorButton,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: metrics.size(15), color: Colors.white70),
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

  // ======================== أزرار سفلية ========================
  Widget _bottomActionButton(
    ResponsiveMetrics metrics,
    String text,
    IconData icon,
  ) {
    final isSmallScreen = metrics.width < 360;

    final double height = isSmallScreen ? metrics.h(38) : metrics.h(45);
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
              Icon(icon, size: metrics.size(15)),
              if (text.isNotEmpty) ...[
                SizedBox(width: metrics.spacing(4)),
                Text(text, style: TextStyle(fontSize: metrics.text(13))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
