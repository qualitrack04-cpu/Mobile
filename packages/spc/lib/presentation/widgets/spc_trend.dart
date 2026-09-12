import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/spc_analysis.dart';
import 'spc_card.dart';

/// Kartu tren analisis SPC: judul, pemilih periode, chart, dan legend.
///
/// Chart-nya digambar manual dengan widget bawaan Flutter supaya package ini
/// tidak perlu dependensi chart. Kalau nanti butuh tooltip, animasi, atau
/// sumbu dinamis, ganti bagian [_TrendChart] dengan library chart.
class SpcTrendCard extends StatelessWidget {
  const SpcTrendCard({
    super.key,
    required this.data,
    required this.selectedPeriod,
    required this.periodOptions,
    required this.onPeriodChanged,
  });

  final List<SpcAnalysisTrend> data;
  final String selectedPeriod;
  final List<String> periodOptions;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPC Analyses Over Time',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Analysis trends by status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PeriodSelector(
                value: selectedPeriod,
                options: periodOptions,
                onChanged: onPeriodChanged,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _TrendChart(data: data),
          const SizedBox(height: 16),
          const _TrendLegend(),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: onChanged,
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data});

  final List<SpcAnalysisTrend> data;

  static const List<int> _axisTicks = [20, 15, 10, 5, 0];
  static const double _chartHeight = 180;
  static const double _maxY = 20;
  static const double _labelHeight = 16;
  static const double _barWidth = 22;

  /// Jumlah bar yang muat di layar. Kalau data lebih banyak dari ini,
  /// area chart bisa digeser ke samping.
  static const int _visibleBars = 6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartHeight + _labelHeight + 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sumbu Y sengaja di luar area geser supaya tetap diam.
          _buildYAxis(),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final int slotCount = data.length < _visibleBars
                    ? data.length
                    : _visibleBars;
                final double slotWidth = slotCount == 0
                    ? constraints.maxWidth
                    : constraints.maxWidth / slotCount;

                return Stack(
                  children: [
                    // Garis grid ikut diam, menempel pada sumbu Y.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _chartHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          _axisTicks.length,
                          (_) => Container(
                            height: 1,
                            color: AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                    // Bar dan label bulan digeser bersamaan.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(
                            height: _chartHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: data
                                  .map(
                                    (trend) => SizedBox(
                                      width: slotWidth,
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: _buildBar(trend),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: _labelHeight,
                            child: Row(
                              children: data
                                  .map(
                                    (trend) => SizedBox(
                                      width: slotWidth,
                                      child: Center(
                                        child: Text(
                                          trend.monthLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Label sumbu Y digeser setengah tinggi teks ke atas supaya titik
  /// tengahnya sejajar dengan garis grid.
  Widget _buildYAxis() {
    return SizedBox(
      width: 22,
      height: _chartHeight + _labelHeight,
      child: Transform.translate(
        offset: const Offset(0, -_labelHeight / 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _axisTicks
              .map(
                (tick) => SizedBox(
                  height: _labelHeight,
                  child: Text(
                    '$tick',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBar(SpcAnalysisTrend trend) {
    // Urutan dari atas ke bawah, kebalikan dari urutan tumpukan visual.
    final segments = <MapEntry<SpcStatus, double>>[
      MapEntry(SpcStatus.unstable, trend.unstable),
      MapEntry(SpcStatus.notCapable, trend.notCapable),
      MapEntry(SpcStatus.marginal, trend.marginal),
      MapEntry(SpcStatus.capable, trend.capable),
    ].where((segment) => segment.value > 0).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      child: SizedBox(
        width: _barWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: segments
              .map(
                (segment) => Container(
                  height: (segment.value / _maxY) * _chartHeight,
                  color: segment.key.color,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TrendLegend extends StatelessWidget {
  const _TrendLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: SpcStatus.values
          .map(
            (status) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}