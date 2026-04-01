// lib/features/analysis/widgets/custom_donut_chart.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DonutData {
  final String name;
  final double value;
  final Color? customColor;

  DonutData(this.name, this.value, {this.customColor});
}

class CustomDonutChart extends StatefulWidget {
  final List<DonutData> data;
  final Color baseColor;
  final double size;

  const CustomDonutChart({
    super.key,
    required this.data,
    required this.baseColor,
    this.size = 160,
  });

  @override
  State<CustomDonutChart> createState() => _CustomDonutChartState();
}

class _CustomDonutChartState extends State<CustomDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold(0.0, (sum, e) => sum + e.value);
    final formatter = NumberFormat("#,###");

    if (widget.data.isEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            "No data",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _DonutPainter(
                  widget.data,
                  widget.baseColor,
                  progress: _animation.value,
                ),
                size: Size(widget.size, widget.size),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatter.format(total.toInt()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black26,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const Text(
                "EGP",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutData> data;
  final Color baseColor;
  final double progress;

  _DonutPainter(this.data, this.baseColor, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final sortedData = [...data]..sort((a, b) => b.value.compareTo(a.value));
    
    final total = sortedData.fold(0.0, (sum, e) => sum + e.value);
    if (total == 0) return;

    final strokeWidth = size.width * 0.22;
    const gap = 0.04; // ✅ فاصل أكبر بين الأجزاء (4%)
    final totalGap = gap * sortedData.length;
    final availableAngle = (2 * pi) - totalGap;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (int i = 0; i < sortedData.length; i++) {
      final item = sortedData[i];
      final sweep = (item.value / total) * availableAngle;
      final drawSweep = sweep * progress;

      final baseColor = item.customColor ?? _getDefaultColor(i);
      
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt // ✅ حواف مستقيمة للفاصل
        ..color = baseColor;

      canvas.drawArc(rect, startAngle, drawSweep, false, paint);

      startAngle += sweep + gap;
    }
  }

  Color _getDefaultColor(int index) {
    final colors = [
      const Color(0xFFFF6B6B), // أحمر
      const Color(0xFF4ECDC4), // فيروزي
      const Color(0xFFFFE66D), // أصفر
      const Color(0xFFA8E6CF), // أخضر فاتح
      const Color(0xFFFF8B94), // وردي
      const Color(0xFFAA96DA), // بنفسجي
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}