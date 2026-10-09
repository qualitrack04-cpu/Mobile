import 'package:core_services/core_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Grafik garis skor kualitas per bulan.
class QualityTrendChart extends StatelessWidget {
  const QualityTrendChart({super.key, required this.trend});

  final QualityTrendResponse trend;

  static const Color _lineColor = Color(0xFF1689E8);
  static const Color _dotColor = Color(0xFF087FD0);
  static const Color _gridColor = Color(0xFFE5E7EB);
  static const Color _labelColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final months = trend.data.map((item) => item.monthName).toList();
    final spots = [
      for (final entry in trend.data.asMap().entries)
        FlSpot(entry.key.toDouble(), entry.value.score),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: trend.data.isEmpty ? 0 : (trend.data.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: _gridColor, strokeWidth: 1);
          },
        ),
        // Hanya garis atas (100%) yang diberi border.
        borderData: FlBorderData(
          border: const Border(top: BorderSide(color: _gridColor)),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: 25,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${value.toInt()}%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: _labelColor,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  _buildMonthLabel(value, months),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: _lineColor,
            barWidth: 1.7,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: _dotColor,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _lineColor.withValues(alpha: 0.25),
                  _lineColor.withValues(alpha: 0.10),
                  _lineColor.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) {
              return touched.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()}%',
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthLabel(double value, List<String> months) {
    final index = value.toInt();
    if (index < 0 || index >= months.length) return const SizedBox.shrink();

    final label = Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Text(
        months[index],
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: _labelColor,
        ),
      ),
    );

    // Bulan terakhir digeser ke kiri supaya tidak keluar dari area grafik.
    if (index == months.length - 1) {
      return Transform.translate(offset: const Offset(-10, 0), child: label);
    }
    return label;
  }
}