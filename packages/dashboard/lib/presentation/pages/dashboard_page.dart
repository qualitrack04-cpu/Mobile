import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:auth/presentation/pages/profile_page.dart';
import 'package:core_services/core_services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audit/presentation/bloc/audit_bloc.dart';
import 'package:audit/presentation/bloc/audit_state.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_state.dart';
import 'package:get_it/get_it.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;
  late Future<DashboardSummary> _summaryFuture;
  DashboardSummary? _lastSummary;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(apiService: ApiService());
    _refresh();
  }

  void _refresh({bool showSkeleton = false}) {
    if (!mounted) return;
    setState(() {
      if (showSkeleton) {
        _lastSummary = null;
      }
      _summaryFuture = _dashboardService.getSummary().then((summary) {
        _lastSummary = summary;
        return summary;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuditBloc, AuditState>(
          bloc: GetIt.instance<AuditBloc>(),
          listener: (context, state) {
            if (state is AuditLoaded || state is AuditCreated || state is AuditDeleted || state is AuditMarkedFinished) {
              _refresh();
            }
          },
        ),
        BlocListener<FindingBloc, FindingState>(
          bloc: GetIt.instance<FindingBloc>(),
          listener: (context, state) {
            if (state is FindingLoaded) _refresh();
          },
        ),
        BlocListener<CapaBloc, CapaState>(
          bloc: GetIt.instance<CapaBloc>(),
          listener: (context, state) {
            if (state is CapaLoaded) _refresh();
          },
        ),
      ],
      child: Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Q — tinggi disesuaikan dengan cap-height huruf
            Image.asset(
              'assets/icon/QualiTrack.png',
              height: (screenWidth * 0.075).clamp(26.0, 34.0),
              fit: BoxFit.contain,
            ),
            // Tanpa SizedBox — langsung sambung ke "Track"
            Text(
              'Track',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: (screenWidth * 0.06).clamp(20.0, 26.0),
                height: 1.0,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 2.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, size: 20, color: AppColors.surface),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          _refresh(showSkeleton: true);
          await _summaryFuture;
        },
        child: FutureBuilder<DashboardSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting && _lastSummary == null;

            // Error
            if (snapshot.hasError && !isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load data',
                      style: GoogleFonts.inter(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            // Data berhasil dimuat atau cache
            final summary = snapshot.data ?? _lastSummary ?? DashboardSummary(
              totalAudit: 0,
              totalFinding: 0,
              totalCapa: 0,
            );

            return Skeletonizer(
              enabled: isLoading,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  Text(
                    'Summary',
                    style: GoogleFonts.inter(
                      fontSize: (screenWidth * 0.055).clamp(18.0, 22.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    count: summary.totalAudit.toString(),
                    title: 'Audit',
                    icon: Icons.assignment_outlined,
                  ),
                  _SummaryCard(
                    count: summary.totalFinding.toString(),
                    title: 'Findings',
                    icon: Icons.search,
                  ),
                  _SummaryCard(
                    count: summary.totalCapa.toString(),
                    title: 'CAPA',
                    icon: Icons.checklist_rtl,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ));
  }
}

class _SummaryCard extends StatelessWidget {
  final String count;
  final String title;
  final IconData icon;

  const _SummaryCard({
    required this.count,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final leftColumnWidth = (screenWidth * 0.2).clamp(64.0, 90.0);
    final cardHeight = (screenWidth * 0.22).clamp(80.0, 100.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: leftColumnWidth,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              count,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: (screenWidth * 0.065).clamp(22.0, 30.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: (screenWidth * 0.05).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    icon,
                    size: (screenWidth * 0.09).clamp(28.0, 40.0),
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}