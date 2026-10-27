import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'audit_report_row.dart';

/// Kartu "Latest Report": daftar laporan audit yang sudah selesai.
class AuditReportList extends StatelessWidget {
  const AuditReportList({
    super.key,
    required this.reports,
    required this.onView,
    required this.onDownload,
    this.onViewAll,
  });

  final List<CompletedAuditReport> reports;
  final ValueChanged<CompletedAuditReport> onView;
  final ValueChanged<CompletedAuditReport> onDownload;

  /// Jika null, tautan "View all reports" disembunyikan.
  final VoidCallback? onViewAll;

  static const int _maxItems = 3;

  @override
  Widget build(BuildContext context) {
    final shown = reports.take(_maxItems).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Latest Report',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF172033),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No completed audit reports yet.',
                  style: GoogleFonts.inter(color: AppColors.textDisabled),
                ),
              ),
            )
          else
            for (var i = 0; i < shown.length; i++) ...[
              AuditReportRow(
                report: shown[i],
                onView: () => onView(shown[i]),
                onDownload: () => onDownload(shown[i]),
              ),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
            ],
          if (onViewAll != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all reports',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.action,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: AppColors.action,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}