import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/spc_analysis.dart';
import '../bloc/spc_bloc.dart';
import '../bloc/spc_event.dart';
import '../bloc/spc_state.dart';
import '../widgets/add_spc.dart';
import '../widgets/recent_analysis.dart';
import '../widgets/spc_section_placeholder.dart';
import '../widgets/spc_trend.dart';
import 'history_page.dart';
import 'new_spc_page.dart';
import 'analysis_result_page.dart';
import 'analysis_detail_page.dart';

/// Halaman utama fitur SPC Analysis.
class SpcPage extends StatefulWidget {
  const SpcPage({super.key});

  @override
  State<SpcPage> createState() => _SpcPageState();
}

class _SpcPageState extends State<SpcPage> {
  static const SpcPeriod _initialPeriod = SpcPeriod.threeMonths;

  /// Bloc dibuat sebagai field, bukan lewat BlocProvider(create:), supaya
  /// handler bisa dipanggil dari initState tanpa butuh BuildContext yang
  /// sudah punya provider di atasnya.
  late final SpcBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<SpcBloc>();
    _loadTrends(_initialPeriod);
    _loadRecent();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _loadTrends(SpcPeriod period) {
    _bloc.add(LoadSpcTrends(period: period));
  }

  void _loadRecent() {
    _bloc.add(const LoadRecentAnalyses());
  }

  Future<void> _onCreateAnalysis() async {
    final result = await Navigator.push<SpcAnalysisResult>(
      context,
      MaterialPageRoute(builder: (_) => const NewSpcAnalysisPage()),
    );
    if (!mounted || result == null) return;

    _loadTrends(_bloc.state.period);
    _loadRecent();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisResultPage(result: result)),
    );
  }

  Future<void> _onViewAllAnalyses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalysesHistoryPage()),
    );
    // Daftar dimuat ulang saat kembali, karena analisis bisa saja dibuka
    // atau berubah di halaman sebelah.
    if (mounted) _loadRecent();
  }

  void _onOpenAnalysis(SpcAnalysisSummary analysis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisDetailPage(analysisId: analysis.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpcBloc>.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.primary),
          title: Text(
            'SPC Analysis',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final period = _bloc.state.period;
            _loadTrends(period);
            _loadRecent();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildTrendSection(),
              const SizedBox(height: 16),
              NewSpcAnalysisCard(onTap: _onCreateAnalysis),
              const SizedBox(height: 24),
              _buildRecentHeader(),
              const SizedBox(height: 12),
              _buildRecentSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendSection() {
    return BlocBuilder<SpcBloc, SpcState>(
      buildWhen: (a, b) =>
          a.trendStatus != b.trendStatus ||
          a.trends != b.trends ||
          a.period != b.period,
      builder: (context, state) {
        return SpcTrendCard(
          data: state.trends,
          selectedPeriod: state.period,
          periodOptions: SpcPeriod.chartOptions,
          isLoading: state.isTrendLoading,
          errorMessage: state.trendError,
          onRetry: () => _loadTrends(state.period),
          onPeriodChanged: _loadTrends,
        );
      },
    );
  }

  Widget _buildRecentSection() {
    return BlocBuilder<SpcBloc, SpcState>(
      buildWhen: (a, b) =>
          a.recentStatus != b.recentStatus ||
          a.recentAnalyses != b.recentAnalyses,
      builder: (context, state) {
        if (state.isRecentLoading) {
          return const SpcSectionPlaceholder.loading();
        }

        if (state.recentStatus == SectionStatus.failure) {
          return SpcSectionPlaceholder.message(
            message:
                state.recentError ?? 'Failed to load the latest analysis..',
            icon: Icons.cloud_off_outlined,
            onRetry: _loadRecent,
          );
        }

        if (state.recentAnalyses.isEmpty) {
          return const SpcSectionPlaceholder.message(
            message: 'There is no SPC analysis yet..',
            icon: Icons.inbox_outlined,
          );
        }

        return Column(
          children: state.recentAnalyses
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
      },
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Analyses',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        InkWell(
          onTap: _onViewAllAnalyses,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All Analyses',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.action,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.action,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
