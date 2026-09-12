import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/spc_analysis.dart';
import 'spc_card.dart';

/// Satu baris pada daftar Recent Analyses.
class SpcAnalysisTile extends StatelessWidget {
  const SpcAnalysisTile({
    super.key,
    required this.analysis,
    required this.onTap,
  });

  final SpcAnalysisSummary analysis;
  final VoidCallback onTap;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Format "12 October 2026 - 23.59" tanpa perlu paket intl.
  String get _dateLabel {
    final date = analysis.analyzedAt;
    final month = _monthNames[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} $month ${date.year} \u2022 $hour.$minute';
  }

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      onTap: onTap,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusChip(status: analysis.status),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textDisabled,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SpcStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.shortLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (status.needsAttention) ...[
            const SizedBox(width: 5),
            Icon(Icons.warning_amber_rounded, size: 13, color: color),
          ],
        ],
      ),
    );
  }
}