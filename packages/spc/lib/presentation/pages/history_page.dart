import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/spc_analysis.dart';
import '../bloc/spc_history_bloc.dart';
import '../bloc/spc_history_event.dart';
import '../bloc/spc_history_state.dart';
import '../bloc/spc_state.dart';
import '../widgets/recent_analysis.dart';
import '../widgets/spc_card.dart';
import '../widgets/spc_section_placeholder.dart';

/// Daftar seluruh analisis SPC, dengan filter status dan periode.
///
/// Penyaringan dilakukan server lewat query parameter di GET /api/Spc/history,
/// bukan di sisi mobile, supaya tidak perlu mengunduh seluruh data.
class AnalysesHistoryPage extends StatefulWidget {
  const AnalysesHistoryPage({super.key});

  @override
  State<AnalysesHistoryPage> createState() => _AnalysesHistoryPageState();
}

class _AnalysesHistoryPageState extends State<AnalysesHistoryPage> {
  late final SpcHistoryBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<SpcHistoryBloc>();
    _bloc.add(const LoadAnalysesHistory());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onOpenAnalysis(SpcAnalysisSummary analysis) {
    // TODO: arahkan ke halaman detail analisis.
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpcHistoryBloc>.value(
      value: _bloc,
      child: Scaffold(
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
        body: BlocBuilder<SpcHistoryBloc, SpcHistoryState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                _bloc.add(const LoadAnalysesHistory());
              },
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildFilterBar(state),
                  const SizedBox(height: 16),
                  _buildList(state),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(SpcHistoryState state) {
    if (state.isLoading) {
      return const SpcSectionPlaceholder.loading();
    }

    if (state.status == SectionStatus.failure) {
      return SpcSectionPlaceholder.message(
        message: state.errorMessage ?? 'Gagal memuat riwayat analisis.',
        icon: Icons.cloud_off_outlined,
        onRetry: () => _bloc.add(const LoadAnalysesHistory()),
      );
    }

    if (state.analyses.isEmpty) {
      return const SpcSectionPlaceholder.message(
        message: 'Tidak ada analisis yang cocok dengan filter ini.',
        icon: Icons.filter_alt_off_outlined,
      );
    }

    return Column(
      children: state.analyses
          .map(
            (analysis) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SpcAnalysisTile(
                analysis: analysis,
                onTap: () => _onOpenAnalysis(analysis),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFilterBar(SpcHistoryState state) {
    return SpcCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<SpcStatus?>(
              label: 'Analysis Status',
              icon: Icons.filter_alt_outlined,
              value: state.statusFilter,
              displayText: state.statusFilter?.shortLabel ?? 'All status',
              options: <SpcStatus?>[null, ...SpcStatus.values],
              optionLabel: (status) => status?.shortLabel ?? 'All status',
              onChanged: (value) => _bloc.add(ChangeHistoryStatus(value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterDropdown<SpcPeriod>(
              label: 'Period',
              icon: Icons.calendar_today_outlined,
              value: state.period,
              displayText: state.period.label,
              options: SpcPeriod.values,
              optionLabel: (period) => period.label,
              onChanged: (value) => _bloc.add(ChangeHistoryPeriod(value)),
            ),
          ),
        ],
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
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
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
