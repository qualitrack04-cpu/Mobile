import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/spc_analysis.dart';
import '../widgets/recent_analysis.dart';
import '../widgets/spc_card.dart';

/// Daftar seluruh analisis SPC, dengan filter status dan periode.
class AnalysesHistoryPage extends StatefulWidget {
  const AnalysesHistoryPage({super.key});

  @override
  State<AnalysesHistoryPage> createState() => _AnalysesHistoryPageState();
}

class _AnalysesHistoryPageState extends State<AnalysesHistoryPage> {
  /// Label periode beserta jumlah bulan ke belakang. Null berarti tanpa batas.
  static const Map<String, int?> _periods = {
    'All Time': null,
    '3 Month': 3,
    '6 Month': 6,
    '1 Year': 12,
  };

  /// Null berarti semua status.
  SpcStatus? _selectedStatus;
  String _selectedPeriod = 'All Time';

  // ---------------------------------------------------------------------
  // Data sementara. Hapus blok ini begitu SpcBloc terpasang.
  // ---------------------------------------------------------------------
  final List<SpcAnalysisSummary> _analyses = [
    SpcAnalysisSummary(
      id: '1',
      title: 'Wall Thickness - Product B',
      analyzedAt: DateTime(2026, 10, 12, 23, 59),
      status: SpcStatus.capable,
    ),
    SpcAnalysisSummary(
      id: '2',
      title: 'Wall Thickness - Product B',
      analyzedAt: DateTime(2026, 10, 12, 23, 59),
      status: SpcStatus.notCapable,
    ),
    SpcAnalysisSummary(
      id: '3',
      title: 'Wall Thickness - Product B',
      analyzedAt: DateTime(2026, 10, 12, 23, 59),
      status: SpcStatus.unstable,
    ),
    SpcAnalysisSummary(
      id: '4',
      title: 'Wall Thickness - Product B',
      analyzedAt: DateTime(2026, 10, 12, 23, 59),
      status: SpcStatus.marginal,
    ),
    SpcAnalysisSummary(
      id: '5',
      title: 'Wall Thickness - Product B',
      analyzedAt: DateTime(2026, 10, 12, 23, 59),
      status: SpcStatus.notCapable,
    ),
    SpcAnalysisSummary(
      id: '6',
      title: 'Wall Thickness - Product B',
      analyzedAt: DateTime(2026, 10, 12, 23, 59),
      status: SpcStatus.capable,
    ),
  ];
  // --------------------------------------------------- akhir data sementara

  List<SpcAnalysisSummary> get _filteredAnalyses {
    final int? months = _periods[_selectedPeriod];
    final DateTime? cutoff = months == null
        ? null
        : DateTime.now().subtract(Duration(days: months * 30));

    return _analyses.where((analysis) {
      final matchStatus =
          _selectedStatus == null || analysis.status == _selectedStatus;
      final matchPeriod =
          cutoff == null || analysis.analyzedAt.isAfter(cutoff);
      return matchStatus && matchPeriod;
    }).toList();
  }

  void _onOpenAnalysis(SpcAnalysisSummary analysis) {
    // TODO: arahkan ke halaman detail analisis.
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredAnalyses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          'Analyses History',
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
          _buildFilterBar(),
          const SizedBox(height: 16),
          if (results.isEmpty)
            _buildEmptyState()
          else
            ...results.map(
              (analysis) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SpcAnalysisTile(
                  analysis: analysis,
                  onTap: () => _onOpenAnalysis(analysis),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SpcCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<SpcStatus?>(
              label: 'Analysis Status',
              icon: Icons.filter_alt_outlined,
              value: _selectedStatus,
              displayText: _selectedStatus?.shortLabel ?? 'All status',
              options: <SpcStatus?>[null, ...SpcStatus.values],
              optionLabel: (status) => status?.shortLabel ?? 'All status',
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterDropdown<String>(
              label: 'Period',
              icon: Icons.calendar_today_outlined,
              value: _selectedPeriod,
              displayText: _selectedPeriod,
              options: _periods.keys.toList(),
              optionLabel: (period) => period,
              onChanged: (value) => setState(() => _selectedPeriod = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SpcCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Text(
          'No analyses match this filter.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

/// Dropdown filter dengan label di atas kotaknya.
class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.displayText,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final String displayText;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        PopupMenuButton<T>(
          initialValue: value,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onSelected: onChanged,
          itemBuilder: (context) => options
              .map(
                (option) => PopupMenuItem<T>(
                  value: option,
                  child: Text(
                    optionLabel(option),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}