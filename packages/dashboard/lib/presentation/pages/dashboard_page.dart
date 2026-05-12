import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'Summary',
              style: GoogleFonts.inter(
                // ✅ Font size dinamis
                fontSize: (screenWidth * 0.055).clamp(18.0, 22.0),
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            _SummaryCard(count: '24', title: 'Audit', icon: Icons.assignment_outlined),
            _SummaryCard(count: '12', title: 'Finding', icon: Icons.search),
            _SummaryCard(count: '4', title: 'Capa\nDone', icon: Icons.checklist_rtl),
            _SummaryCard(count: '0', title: 'Capa\nOverdue', icon: Icons.warning_amber_rounded),
          ],
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

    // ✅ Lebar kolom kiri & tinggi card dinamis
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
          // Kolom kiri: angka count
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
                // ✅ Font size count dinamis
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
                      // ✅ Font size title dinamis
                      fontSize: (screenWidth * 0.05).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Icon(
                    icon,
                    // ✅ Icon size dinamis
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