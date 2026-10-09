import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'audit_report_card.dart';

/// Daftar horizontal laporan audit yang sudah selesai.
class AuditReportList extends StatelessWidget {
  const AuditReportList({
    super.key,
    required this.reports,
    required this.onView,
    required this.onDownload,
  });

  final List<CompletedAuditReport> reports;
  final ValueChanged<CompletedAuditReport> onView;
  final ValueChanged<CompletedAuditReport> onDownload;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No completed audit reports yet.',
            style: GoogleFonts.inter(color: AppColors.textDisabled),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reports.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final report = reports[index];
          return AuditReportCard(
            report: report,
            onView: () => onView(report),
            onDownload: () => onDownload(report),
          );
        },
      ),
    );
  }
}