import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/spc_analysis.dart';
import '../widgets/control_chart.dart';
import '../widgets/spc_card.dart';
import '../widgets/spc_metric_card.dart';

/// Halaman hasil satu analisis SPC.
///
/// Menerima [SpcAnalysisResult] yang sudah jadi. Control chart hanya bisa
/// digambar kalau data mentahnya ada — dan itu hanya terjadi tepat setelah
/// upload, karena GET /api/Spc/{id} mengembalikan data kosong.
class AnalysisResultPage extends StatelessWidget {
  const AnalysisResultPage({super.key, required this.result});

  final SpcAnalysisResult result;

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _completedLabel {
    final d = result.analyzedAt;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour < 12 ? 'AM' : 'PM';
    final minute = d.minute.toString().padLeft(2, '0');
    return 'Analysis completed on ${_monthNames[d.month - 1]} ${d.day}, '
        '${d.year} \u00b7 ${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          'Analysis Result',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSectionTitle('Summary'),
          const SizedBox(height: 12),
          _buildSummary(),
          const SizedBox(height: 24),
          _buildSectionTitle('Control Chart'),
          const SizedBox(height: 12),
          _buildChart(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader() {
    return SpcCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.action.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.show_chart,
              size: 22,
              color: AppColors.action,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.parameterName,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _completedLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SpcMetricCard(
                  label: 'Mean',
                  value: result.mean.toStringAsFixed(2),
                  // Backend menyimpan unit tapi belum mengembalikannya,
                  // jadi bagian ini kosong sampai SpcResultDto diperbarui.
                  unit: result.unit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SpcMetricCard(
                  label: 'Status',
                  child: _StatusChip(status: result.status),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SpcMetricCard(
                  label: 'Cp',
                  labelUppercase: false,
                  caption: 'Process Capability',
                  value: result.cp.toStringAsFixed(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SpcMetricCard(
                  label: 'Cpk',
                  labelUppercase: false,
                  caption: 'Process Performance',
                  value: result.cpk.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (result.data.isEmpty) {
      return SpcCard(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          children: [
            const Icon(
              Icons.show_chart,
              size: 26,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              'Data pengukuran tidak tersimpan di server, '
              'jadi control chart hanya tersedia tepat setelah analisis dibuat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return SpcCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: ControlChart(
        data: result.data,
        ucl: result.ucl,
        lcl: result.lcl,
        centerLine: result.mean,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SpcStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.shortLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (status.needsAttention) ...[
              const SizedBox(width: 5),
              Icon(Icons.warning_amber_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}