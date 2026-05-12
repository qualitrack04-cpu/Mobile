import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/checklist_entity.dart';

class ChecklistCard extends StatelessWidget {
  final ChecklistEntity checklist;
  final VoidCallback? onPass;
  final VoidCallback? onFail;
  final VoidCallback? onAddFinding;
  final VoidCallback? onEditFinding;

  const ChecklistCard({
    super.key,
    required this.checklist,
    this.onPass,
    this.onFail,
    this.onAddFinding,
    this.onEditFinding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPass = checklist.isPassed == true;
    final bool isFail = checklist.isPassed == false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: isFail
              ? AppColors.danger
              : isPass
                  ? AppColors.success
                  : AppColors.borderLight,
          width: isFail || isPass ? 2 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildHeader(isFail),
          const SizedBox(height: 10),
          _buildDescription(),
          const SizedBox(height: 15),
          _buildButtons(isPass, isFail),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isFail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Expanded(
          child: Text(
            checklist.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
        ),

        if (isFail && checklist.hasFinding)
          GestureDetector(
            onTap: onEditFinding,

            child: Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),

              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.danger,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      checklist.description,
      style: GoogleFonts.inter(
        fontSize: 12,
        height: 1.7,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildButtons(bool isPass, bool isFail) {
    return Row(
      children: [
        if (isFail && !checklist.hasFinding)
          SizedBox(
            height: 45,

            child: OutlinedButton.icon(
              onPressed: onAddFinding,

              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: const BorderSide(color: AppColors.primaryLight),
                backgroundColor: AppColors.surface,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              icon: const Icon(
                Icons.add,
                size: 18,
                color: AppColors.primaryLight,
              ),

              label: Text(
                'ADD FINDING',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),

        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,

            children: [
              _buildPassButton(isPass, isFail),
              const SizedBox(width: 10),
              _buildFailButton(isFail),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassButton(bool isPass, bool isFail) {
    // ✅ Kalau sudah fail, tombol PASS di-disable — tidak bisa diubah ke pass
    // Kalau sudah pass, tetap bisa diklik (untuk ganti ke fail)
    return SizedBox(
      height: 45,

      child: ElevatedButton.icon(
        onPressed: isFail ? null : onPass,

        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: isPass
              ? AppColors.successLight
              : isFail
                  ? const Color(0xFFF3F4F6) // disabled saat fail
                  : const Color(0xFFF3F4F6),
          foregroundColor: isPass ? AppColors.success : AppColors.textDisabled,
          disabledBackgroundColor: const Color(0xFFF3F4F6),
          disabledForegroundColor: AppColors.textDisabled,

          side: BorderSide(
            color: isPass ? AppColors.success : const Color(0xFFD1D5DB),
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        icon: Icon(
          Icons.check_circle,
          size: 18,
          color: isPass
              ? AppColors.success
              : AppColors.textDisabled,
        ),

        label: Text(
          'PASS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFailButton(bool isFail) {
    return SizedBox(
      height: 45,

      child: ElevatedButton.icon(
        onPressed: onFail,

        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: isFail ? AppColors.dangerLight : const Color(0xFFF3F4F6),
          foregroundColor: isFail ? AppColors.danger : AppColors.textDisabled,

          side: BorderSide(
            color: isFail ? AppColors.danger : const Color(0xFFD1D5DB),
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        icon: Icon(
          Icons.cancel,
          size: 18,
          color: isFail ? AppColors.danger : AppColors.textDisabled,
        ),

        label: Text(
          'FAIL',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}