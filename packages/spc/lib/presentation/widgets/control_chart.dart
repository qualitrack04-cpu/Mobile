import 'dart:math' as math;

import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Control chart: titik pengukuran dengan garis UCL, CL, dan LCL.
///
/// Digambar dengan CustomPainter agar tidak perlu dependensi chart.
/// Titik di luar batas kendali diberi warna berbeda supaya langsung terlihat.
class ControlChart extends StatelessWidget {
  const ControlChart({
    super.key,
    required this.data,
    required this.ucl,
    required this.lcl,
    required this.centerLine,
    this.height = 230,
  });

  final List<double> data;
  final double ucl;
  final double lcl;

  /// Garis tengah, yaitu mean.
  final double centerLine;

  final double height;

  static const Color _uclColor = Color(0xFF12B76A);
  static const Color _clColor = Color(0xFF2E5AAC);
  static const Color _lclColor = Color(0xFFE02B20);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _legend('UCL', ucl, _uclColor),
            _legend('CL', centerLine, _clColor),
            _legend('LCL', lcl, _lclColor),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _ControlChartPainter(
              data: data,
              ucl: ucl,
              lcl: lcl,
              centerLine: centerLine,
              uclColor: _uclColor,
              clColor: _clColor,
              lclColor: _lclColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 2,
          child: CustomPaint(painter: _DashLinePainter(color)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value.toStringAsFixed(2),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DashLinePainter extends CustomPainter {
  _DashLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 4, size.width), size.height / 2),
        paint,
      );
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ControlChartPainter extends CustomPainter {
  _ControlChartPainter({
    required this.data,
    required this.ucl,
    required this.lcl,
    required this.centerLine,
    required this.uclColor,
    required this.clColor,
    required this.lclColor,
  });

  final List<double> data;
  final double ucl;
  final double lcl;
  final double centerLine;
  final Color uclColor;
  final Color clColor;
  final Color lclColor;

  static const double _leftPadding = 42;
  static const double _bottomPadding = 22;
  static const double _topPadding = 10;
  static const double _rightPadding = 8;
  static const int _tickCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final plotWidth = size.width - _leftPadding - _rightPadding;
    final plotHeight = size.height - _topPadding - _bottomPadding;

    // Rentang sumbu Y mencakup seluruh titik sekaligus ketiga garis batas,
    // lalu diberi ruang 8% supaya titik ekstrem tidak menempel di tepi.
    final values = [...data, ucl, lcl, centerLine];
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    final span = (maxY - minY).abs();
    final margin = span == 0 ? 1.0 : span * 0.08;
    minY -= margin;
    maxY += margin;

    double toY(double value) =>
        _topPadding + plotHeight - ((value - minY) / (maxY - minY)) * plotHeight;

    double toX(int index) {
      if (data.length == 1) return _leftPadding + plotWidth / 2;
      final step = plotWidth / (data.length + 1);
      return _leftPadding + step * (index + 1);
    }

    _drawAxis(canvas, size, minY, maxY, plotHeight, toY);
    _drawLimitLine(canvas, size, toY(ucl), uclColor);
    _drawLimitLine(canvas, size, toY(centerLine), clColor);
    _drawLimitLine(canvas, size, toY(lcl), lclColor);
    _drawPoints(canvas, toX, toY);
    _drawXLabels(canvas, toX, size);
  }

  void _drawAxis(
    Canvas canvas,
    Size size,
    double minY,
    double maxY,
    double plotHeight,
    double Function(double) toY,
  ) {
    final gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;

    for (int i = 0; i < _tickCount; i++) {
      final value = maxY - (maxY - minY) * i / (_tickCount - 1);
      final y = toY(value);

      canvas.drawLine(
        Offset(_leftPadding, y),
        Offset(size.width - _rightPadding, y),
        gridPaint,
      );

      _text(
        canvas,
        value.toStringAsFixed(2),
        Offset(_leftPadding - 6, y),
        alignRight: true,
      );
    }
  }

  void _drawLimitLine(Canvas canvas, Size size, double y, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;

    double x = _leftPadding;
    while (x < size.width - _rightPadding) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 5, size.width - _rightPadding), y),
        paint,
      );
      x += 9;
    }
  }

  void _drawPoints(
    Canvas canvas,
    double Function(int) toX,
    double Function(double) toY,
  ) {
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final isOutOfControl = value > ucl || value < lcl;

      canvas.drawCircle(
        Offset(toX(i), toY(value)),
        5,
        Paint()..color = isOutOfControl ? lclColor : clColor,
      );
    }
  }

  void _drawXLabels(Canvas canvas, double Function(int) toX, Size size) {
    // Label dijarangkan kalau titiknya banyak, supaya tidak saling tumpuk.
    final step = (data.length / 10).ceil();
    for (int i = 0; i < data.length; i += step) {
      _text(
        canvas,
        '${i + 1}',
        Offset(toX(i), size.height - _bottomPadding + 6),
        center: true,
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset, {
    bool alignRight = false,
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: GoogleFonts.inter(
          fontSize: 9,
          color: AppColors.textDisabled,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    var dx = offset.dx;
    if (alignRight) dx -= painter.width;
    if (center) dx -= painter.width / 2;

    final dy = center ? offset.dy : offset.dy - painter.height / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _ControlChartPainter old) =>
      old.data != data ||
      old.ucl != ucl ||
      old.lcl != lcl ||
      old.centerLine != centerLine;
}