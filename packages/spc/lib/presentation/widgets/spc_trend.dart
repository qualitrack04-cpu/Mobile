import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/spc_analysis.dart';
import 'spc_card.dart';

/// Kartu tren analisis SPC: judul, pemilih periode, chart, dan legend.
///
/// Pemilih periode sengaja tetap tampil saat loading maupun error, supaya
/// pengguna bisa mengganti periode tanpa harus menunggu atau keluar halaman.
class SpcTrendCard extends StatelessWidget {
  const SpcTrendCard({
    super.key,
    required this.data,
    required this.selectedPeriod,
    required this.periodOptions,
    required this.onPeriodChanged,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<SpcAnalysisTrend> data;
  final SpcPeriod selectedPeriod;
  final List<SpcPeriod> periodOptions;
  final ValueChanged<SpcPeriod> onPeriodChanged;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

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
          _buildChartArea(),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    const double areaHeight = _TrendChart.totalHeight;

    if (isLoading) {
      return const SizedBox(
        height: areaHeight,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: areaHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 28,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'Coba lagi',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.action,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _TrendChart(data: data),
        const SizedBox(height: 16),
        const _TrendLegend(),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final SpcPeriod value;
  final List<SpcPeriod> options;
  final ValueChanged<SpcPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SpcPeriod>(
      initialValue: value,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: onChanged,
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<SpcPeriod>(
              value: option,
              child: Text(
                option.label,
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
              value.label,
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

  static const double _chartHeight = 180;
  static const double _labelHeight = 16;
  static const double _barWidth = 22;
  static const double totalHeight = _chartHeight + _labelHeight + 8;

  /// Jumlah bar yang muat di layar. Kalau data lebih banyak dari ini,
  /// area chart bisa digeser ke samping.
  static const int _visibleBars = 6;

  /// Banyaknya jarak antar garis grid. Label sumbu = jumlah ini + 1.
  static const int _intervalCount = 4;

  /// Jarak antar garis grid, dibulatkan ke angka yang enak dibaca.
  double get _interval {
    double maxTotal = 0;
    for (final trend in data) {
      if (trend.total > maxTotal) maxTotal = trend.total;
    }
    if (maxTotal <= 0) return 1;

    final raw = maxTotal / _intervalCount;
    const steps = [1, 2, 5, 10, 20, 25, 50, 100, 250, 500, 1000];
    for (final step in steps) {
      if (raw <= step) return step.toDouble();
    }
    return (raw / 1000).ceilToDouble() * 1000;
  }

  double get _maxY => _interval * _intervalCount;

  List<int> get _axisTicks => List.generate(
        _intervalCount + 1,
        (i) => (_maxY - i * _interval).round(),
      );

  @override
  Widget build(BuildContext context) {
    final ticks = _axisTicks;
    final maxY = _maxY;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sumbu Y sengaja di luar area geser supaya tetap diam.
          _buildYAxis(ticks),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final int slotCount =
                    data.length < _visibleBars ? data.length : _visibleBars;
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
                          ticks.length,
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
                                        child: _buildBar(trend, maxY),
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
  Widget _buildYAxis(List<int> ticks) {
    return SizedBox(
      width: 24,
      height: _chartHeight + _labelHeight,
      child: Transform.translate(
        offset: const Offset(0, -_labelHeight / 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: ticks
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

  Widget _buildBar(SpcAnalysisTrend trend, double maxY) {
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
                  height: (segment.value / maxY) * _chartHeight,
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
