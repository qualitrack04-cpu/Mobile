import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/spc_analysis.dart';
import '../widgets/add_spc.dart';
import '../widgets/recent_analysis.dart';
import '../widgets/spc_trend.dart';
import 'history_page.dart';

/// Halaman utama fitur SPC Analysis.
class SpcPage extends StatefulWidget {
  const SpcPage({super.key});

  @override
  State<SpcPage> createState() => _SpcPageState();
}

class _SpcPageState extends State<SpcPage> {
  /// Label periode beserta jumlah bulan yang ditampilkan.
  static const Map<String, int> _periods = {
    '3 Month': 3,
    '6 Month': 6,
    '1 Year': 12,
  };

  String _selectedPeriod = '3 Month';

  /// Data tren dipotong sesuai periode terpilih, diambil dari bulan terbaru.
  List<SpcAnalysisTrend> get _visibleTrends {
    final int months = _periods[_selectedPeriod] ?? _trends.length;
    if (_trends.length <= months) return _trends;
    return _trends.sublist(_trends.length - months);
  }

  // ---------------------------------------------------------------------
  // Data sementara. Hapus blok ini begitu SpcBloc terpasang.
  // ---------------------------------------------------------------------
  static const List<SpcAnalysisTrend> _trends = [
    SpcAnalysisTrend(
      monthLabel: 'Nov',
      capable: 6,
      marginal: 2,
      notCapable: 2,
      unstable: 1,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Des',
      capable: 8,
      marginal: 1.5,
      notCapable: 2,
      unstable: 1,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Jan',
      capable: 9,
      marginal: 2,
      notCapable: 1.5,
      unstable: 1.5,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Feb',
      capable: 7,
      marginal: 2.5,
      notCapable: 2,
      unstable: 2,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Mar',
      capable: 10,
      marginal: 1,
      notCapable: 2,
      unstable: 1,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Apr',
      capable: 8.5,
      marginal: 2,
      notCapable: 1.5,
      unstable: 2,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Mei',
      capable: 7,
      marginal: 0.5,
      notCapable: 3,
      unstable: 1.5,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Jun',
      capable: 10,
      marginal: 1,
      notCapable: 1.5,
      unstable: 1.5,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Jul',
      capable: 9.5,
      marginal: 2,
      notCapable: 1,
      unstable: 1.5,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Aug',
      capable: 11,
      marginal: 1.5,
      notCapable: 1,
      unstable: 1.5,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Sep',
      capable: 4,
      marginal: 3,
      notCapable: 0,
      unstable: 4,
    ),
    SpcAnalysisTrend(
      monthLabel: 'Okt',
      capable: 11,
      marginal: 1.5,
      notCapable: 1.5,
      unstable: 1,
    ),
  ];

  final List<SpcAnalysisSummary> _recentAnalyses = [
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
      status: SpcStatus.unstable,
    ),
    SpcAnalysisSummary(
      id: '3',
      title: 'Wall Thickness - Product B',
      analyzedAt: DateTime(2026, 10, 12, 23, 59),
      status: SpcStatus.notCapable,
    ),
  ];
  // --------------------------------------------------- akhir data sementara

  void _onCreateAnalysis() {
    // TODO: arahkan ke halaman form input SPC.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New SPC Analysis belum tersedia')),
    );
  }

  void _onViewAllAnalyses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalysesHistoryPage()),
    );
  }

  void _onOpenAnalysis(SpcAnalysisSummary analysis) {
    // TODO: arahkan ke halaman detail analisis.
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
          'SPC Analysis',
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
          SpcTrendCard(
            data: _visibleTrends,
            selectedPeriod: _selectedPeriod,
            periodOptions: _periods.keys.toList(),
            onPeriodChanged: (value) {
              setState(() => _selectedPeriod = value);
            },
          ),
          const SizedBox(height: 16),
          NewSpcAnalysisCard(onTap: _onCreateAnalysis),
          const SizedBox(height: 24),
          _buildRecentHeader(),
          const SizedBox(height: 12),
          ..._recentAnalyses.map(
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