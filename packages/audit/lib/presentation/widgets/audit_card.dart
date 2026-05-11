import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/audit_entity.dart';

class AuditCard extends StatelessWidget {
  final AuditEntity audit;
  final VoidCallback? onEdit;
  final VoidCallback? onChecklist;
  final VoidCallback? onDelete;

  const AuditCard({
    super.key,
    required this.audit,
    this.onEdit,
    this.onChecklist,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFinished = audit.isFinished;
    final bool isPriority = audit.isPriority;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          _buildDateSection(isFinished, isPriority),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _buildTitleRow(isFinished),
                  const SizedBox(height: 14),
                  _buildMetaRow(isFinished),
                  const SizedBox(height: 18),
                  _buildActionRow(isFinished),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(bool isFinished, bool isPriority) {
    Color sectionColor;

    if (isFinished) {
      sectionColor = AppColors.primaryMuted;
    } else if (isPriority) {
      sectionColor = AppColors.primaryLight;
    } else {
      sectionColor = const Color(0xFF7D8494);
    }

    return Container(
      width: 82,
      height: 175,

      decoration: BoxDecoration(
        color: sectionColor,

        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          bottomLeft: Radius.circular(18),
        ),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            _monthAbbr(audit.date.month),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            audit.date.day.toString(),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            audit.date.year.toString(),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(bool isFinished) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Expanded(
          child: Text(
            audit.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isFinished
                  ? const Color(0xFF7A93AA)
                  : AppColors.primary,
              height: 1.2,
            ),
          ),
        ),

        if (!isFinished)
          GestureDetector(
            onTap: onDelete,

            child: Container(
              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),

              child: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetaRow(bool isFinished) {
    final Color metaColor = isFinished
        ? const Color(0xFFB0B7C3)
        : Colors.grey;

    return Row(
      children: [
        Icon(Icons.apartment_outlined, size: 16, color: metaColor),
        const SizedBox(width: 6),

        Text(
          audit.department,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: metaColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 18),

        Icon(Icons.person_outline, size: 16, color: metaColor),
        const SizedBox(width: 6),

        Expanded(
          child: Text(
            audit.auditorName,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: metaColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(bool isFinished) {
    if (isFinished) {
      return Align(
        alignment: Alignment.centerRight,

        child: SizedBox(
          width: 170,
          height: 46,

          child: ElevatedButton(
            onPressed: null,

            style: ElevatedButton.styleFrom(
              elevation: 3,
              disabledBackgroundColor: AppColors.primaryMuted,
              disabledForegroundColor: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            child: Text(
              'Finished',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,

          child: SizedBox(
            height: 46,

            child: ElevatedButton(
              onPressed: onEdit,

              style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: const Color(0xFFE9EEF3),
                foregroundColor: Colors.black87,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: Text(
                'Edit',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 4,

          child: SizedBox(
            height: 46,

            child: ElevatedButton(
              onPressed: onChecklist,

              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: Text(
                'Audit Checklist',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ pindah ke static method yang lebih bersih
  static String _monthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return months[month - 1];
  }
}