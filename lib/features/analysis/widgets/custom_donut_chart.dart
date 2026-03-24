// ==========================================
// 🍩 STABLE DONUT CHART (FIXED ROTATION)
// ==========================================

import 'dart:math';
import 'package:flutter/material.dart';

class DonutData {
  final String name;
  final double value;

  DonutData(this.name, this.value);
}

class CustomDonutChart extends StatelessWidget {
  final List<DonutData> data;
  final Color baseColor;

  const CustomDonutChart({
    super.key,
    required this.data,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(data, baseColor),
      size: const Size(160, 160),
    );
  }
}

// ==========================================
// 🎨 Painter
// ==========================================

class _DonutPainter extends CustomPainter {
  final List<DonutData> data;
  final Color baseColor;

  _DonutPainter(this.data, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 🔥 ترتيب ثابت (أكبر قيمة تبدأ من فوق)
    final sortedData = [...data]
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sortedData.fold(0.0, (sum, e) => sum + e.value);

    if (total == 0) return;

    const strokeWidth = 22.0;
    const gap = 0.03; // حجم الفاصل

    final totalGap = gap * sortedData.length;
    final availableAngle = (2 * pi) - totalGap;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 🔥 ثابت دائمًا (12 o'clock)
    double startAngle = -pi / 2;

    for (int i = 0; i < sortedData.length; i++) {
      final item = sortedData[i];

      final sweep = (item.value / total) * availableAngle;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt // يمنع التداخل
        ..color = baseColor.withOpacity(
          1 - (i * 0.15), // gradient بسيط
        );

      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep + gap;
    }

    // ======================================
    // 🧠 CENTER TEXT
    // ======================================
    final centerText = TextPainter(
      text: TextSpan(
        text: total.toInt().toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    centerText.layout();

    centerText.paint(
      canvas,
      Offset(
        center.dx - centerText.width / 2,
        center.dy - centerText.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}