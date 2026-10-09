import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'quality_trend_chart.dart';

/// Kartu tren skor kualitas dengan pemilih periode.
class QualityTrendCard extends StatelessWidget {
  const QualityTrendCard({
    super.key,
    required this.trend,
    required this.periods,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final QualityTrendResponse trend;
  final List<String> periods;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final isUp = trend.change >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quality Trend',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              _buildPeriodDropdown(),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${trend.currentScore.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${isUp ? '↗' : '↘'} ${trend.change.abs().toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUp ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'vs previous month',
            style: GoogleFonts.inter(
              fontSize: 8,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 160, child: QualityTrendChart(trend: trend)),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.primaryMuted),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPeriod,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          items: [
            for (final period in periods)
              DropdownMenuItem<String>(value: period, child: Text(period)),
          ],
          onChanged: (value) {
            if (value != null) onPeriodChanged(value);
          },
        ),
      ),
    );
  }
}