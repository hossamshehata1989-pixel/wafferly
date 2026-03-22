// ==========================================
// 🔥 ULTRA REALISTIC DONUT CHART
// ==========================================

import 'dart:math';
import 'package:flutter/material.dart';

class DonutData {
  final String name;
  final double value;

  DonutData(this.name, this.value);
}

class CustomDonutChart extends StatefulWidget {
  final List<DonutData> data;
  final Color baseColor;

  const CustomDonutChart({
    super.key,
    required this.data,
    required this.baseColor,
  });

  @override
  State<CustomDonutChart> createState() => _CustomDonutChartState();
}

class _CustomDonutChartState extends State<CustomDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // 🔥 light rotation
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _DonutPainter(
            widget.data,
            widget.baseColor,
            controller.value,
          ),
          size: const Size(160, 160),
        );
      },
    );
  }
}

// ==========================================
// 🎨 Painter
// ==========================================

class _DonutPainter extends CustomPainter {
  final List<DonutData> data;
  final Color baseColor;
  final double rotation;

  _DonutPainter(this.data, this.baseColor, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0.0, (sum, e) => sum + e.value);

    final strokeWidth = 22.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweep = (item.value / total) * 2 * pi;

      // ==================================
      // 🌟 BASE ARC
      // ==================================
      final basePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = baseColor.withOpacity(1 - (i * 0.2));

      canvas.drawArc(rect, startAngle, sweep, false, basePaint);

      // ==================================
      // 🔥 OUTER GLOW
      // ==================================
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..color = baseColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(rect, startAngle, sweep, false, glowPaint);

      // ==================================
      // ✨ MOVING HIGHLIGHT (Realistic Light)
      // ==================================
      final highlightAngle = startAngle + sweep * rotation;

      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = SweepGradient(
          startAngle: highlightAngle,
          endAngle: highlightAngle + 0.3,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweep, false, highlightPaint);

      // ==================================
      // 🌑 INNER SHADOW (Depth)
      // ==================================
      final innerShadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.black.withOpacity(0.2);

      canvas.drawArc(rect, startAngle, sweep, false, innerShadow);

      // ==================================
      // 🎯 LINE
      // ==================================
      final mid = startAngle + sweep / 2;

      final p1 = Offset(
        center.dx + cos(mid) * radius,
        center.dy + sin(mid) * radius,
      );

      final p2 = Offset(
        center.dx + cos(mid) * (radius + 14),
        center.dy + sin(mid) * (radius + 14),
      );

      canvas.drawLine(
        p1,
        p2,
        Paint()..color = Colors.white24..strokeWidth = 1,
      );

      // ==================================
      // 📝 LABEL
      // ==================================
      final percent = ((item.value / total) * 100).toStringAsFixed(0);

      final tp = TextPainter(
        text: TextSpan(
          text: "${item.name}\n$percent%",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      tp.layout();

      tp.paint(
        canvas,
        Offset(
          center.dx + cos(mid) * (radius + 28) - tp.width / 2,
          center.dy + sin(mid) * (radius + 28) - tp.height / 2,
        ),
      );

      startAngle += sweep;
    }

    // ==================================
    // 💰 CENTER TEXT
    // ==================================
    final centerPainter = TextPainter(
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

    centerPainter.layout();

    centerPainter.paint(
      canvas,
      Offset(
        center.dx - centerPainter.width / 2,
        center.dy - centerPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}