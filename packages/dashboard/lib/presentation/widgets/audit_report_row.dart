import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu baris laporan audit pada kartu "Latest Report".
class AuditReportRow extends StatelessWidget {
  const AuditReportRow({
    super.key,
    required this.report,
    required this.onView,
    required this.onDownload,
  });

  final CompletedAuditReport report;
  final VoidCallback onView;
  final VoidCallback onDownload;

  static const Color _actionColor = Color(0xFF0B5CAD);

  @override
  Widget build(BuildContext context) {
    final department = DepartmentStyle.normalize(report.department);
    final color = DepartmentStyle.colorOf(department);
    final title = report.planTitle.isEmpty ? 'Audit report' : report.planTitle;
    final subtitle = report.fileInfoLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.picture_as_pdf_outlined, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.visibility_outlined,
            tooltip: 'View report',
            onTap: onView,
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.file_download_outlined,
            tooltip: 'Download report',
            onTap: onDownload,
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFEAF1FB),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: AuditReportRow._actionColor),
          ),
        ),
      ),
    );
  }
}
