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
    final double sw = MediaQuery.of(context).size.width;
    final double hMargin = sw * 0.05; // ~18px di 360px, ~21px di 420px

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 10),

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

      // ✅ IntrinsicHeight: tinggi card mengikuti konten, tidak hardcoded
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateSection(isFinished, isPriority, sw),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(sw * 0.035),

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
      ),
    );
  }

  Widget _buildDateSection(bool isFinished, bool isPriority, double sw) {
    Color sectionColor;

    if (audit.id.isEmpty) {
      sectionColor = Colors.grey.shade300; // Skeleton color
    } else if (isFinished) {
      sectionColor = AppColors.primaryMuted;
    } else if (isPriority) {
      sectionColor = AppColors.primaryLight;
    } else {
      sectionColor = const Color(0xFF7D8494);
    }

    return Container(
      // ✅ Hapus width & height hardcoded, pakai constraints minimum saja
      constraints: const BoxConstraints(minWidth: 72),

      decoration: BoxDecoration(
        color: sectionColor,

        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          bottomLeft: Radius.circular(18),
        ),
      ),

      padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.035).clamp(10.0, 16.0),
        vertical: 20,
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            _monthAbbr(audit.date.month),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            audit.date.day.toString(),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            audit.date.year.toString(),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isFinished
                  ? const Color(0xFF7A93AA)
                  : AppColors.primary,
              height: 1.2,
            ),
          ),
        ),

        if (!isFinished && audit.id.isNotEmpty)
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
                size: 20,
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

        Flexible(
          child: Text(
            audit.department == 'Produksi' ? 'Production' : audit.department,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: metaColor,
              fontWeight: FontWeight.w500,
            ),
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
          // ✅ Hapus fixed width 170, biarkan tombol expand natural
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    if (audit.id.isEmpty) {
      return const SizedBox(height: 46); // Sembunyikan tombol saat skeleton loading
    }

    return Row(
      children: [
        // ✅ flex 2→3 supaya "Edit" tidak kepotong di layar sempit
        Expanded(
          flex: 3,

          child: SizedBox(
            height: 46,

            child: ElevatedButton(
              onPressed: onEdit,

              style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: const Color(0xFFE9EEF3),
                foregroundColor: Colors.black87,
                // ✅ padding horizontal dikurangi supaya teks tidak terpotong
                padding: const EdgeInsets.symmetric(horizontal: 8),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: Text(
                'Edit',
                // ✅ font size dikecilkan sedikit & maxLines: 1 + ellipsis
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          flex: 5,

          child: SizedBox(
            height: 46,

            child: ElevatedButton(
              onPressed: onChecklist,

              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                // ✅ padding dikurangi supaya teks tidak terpotong di layar sempit
                padding: const EdgeInsets.symmetric(horizontal: 8),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: Text(
                'Audit Checklist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _monthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return months[month - 1];
  }
}