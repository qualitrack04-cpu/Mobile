import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:auth/presentation/pages/profile_page.dart';
import 'package:core_services/core_services.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;
  late Future<DashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(apiService: ApiService());
    _summaryFuture = _dashboardService.getSummary();
  }

  void _refresh() {
    setState(() {
      _summaryFuture = _dashboardService.getSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          'QualiTrack',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
          ),
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
        onRefresh: () async => _refresh(),
        child: FutureBuilder<DashboardSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            // Error
            if (snapshot.hasError && !isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat data',
                      style: GoogleFonts.inter(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            // Data berhasil dimuat atau skeleton
            final summary = snapshot.data ?? DashboardSummary(
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
                    title: 'Finding',
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
    );
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