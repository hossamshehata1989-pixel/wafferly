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

    // حجم زر الحاسبة — responsive بالارتفاع
    // مرجع 36px → iPhone SE: 27px | Pixel 4: 35px
    // لما الكيبورد يفتح: يصغر أكتر لأن المساحة بتقل
    final double buttonSize = metrics.h(isKeyboardOpen ? 28 : 32);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(16),
        vertical: metrics.h(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // حقل عرض المبلغ
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.spacing(2),
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
                      vertical: metrics.h(3),
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
                                // الخط يتبع العرض (text) مش الارتفاع — صح
                                fontSize: metrics.text(20),
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
                    _topActionButton(metrics, Icons.check),
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
              Expanded(child: _infoButton(metrics, Icons.person_outline, 'Me')),
              SizedBox(width: metrics.spacing(6)),
              Expanded(child: _infoButton(metrics, Icons.repeat, 'Recurring')),
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
    );
  }

  // ======================== الحاسبة ========================
  Widget _buildCalculator(ResponsiveMetrics metrics, double buttonSize) {
    // spacing بين الصفوف responsive بالارتفاع
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
    // الخط يتبع حجم الزر (رأسي) — clamp لضمان قراءة مريحة
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
                    ? AppColors.cardSecondary
                    : AppColors.background,
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

  // ======================== أزرار علوية (Note, Check) ========================
  Widget _topActionButton(ResponsiveMetrics metrics, IconData icon) {
    // h() بدل size() — لأن الزر له ارتفاع ثابت في الشاشة
    final double buttonSize = metrics.h(44);
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: metrics.size(16)),
    );
  }

  // ======================== أزرار المعلومات ========================
  Widget _infoButton(ResponsiveMetrics metrics, IconData icon, String text) {
    final double height = metrics.h(30);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
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
    final double height = metrics.h(30);
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
