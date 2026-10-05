import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spc_card.dart';

/// Kartu satu angka ringkasan hasil analisis.
///
/// [caption] dipakai untuk penjelasan kecil di bawah label, [unit] untuk
/// satuan yang ditempel di samping angka, dan [child] untuk isi non-angka
/// seperti chip status.
class SpcMetricCard extends StatelessWidget {
  const SpcMetricCard({
    super.key,
    required this.label,
    this.caption,
    this.value,
    this.unit,
    this.child,
    this.labelUppercase = true,
  });

  final String label;
  final String? caption;
  final String? value;
  final String? unit;
  final Widget? child;
  final bool labelUppercase;

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelUppercase ? label.toUpperCase() : label,
            style: GoogleFonts.inter(
              fontSize: labelUppercase ? 11 : 15,
              fontWeight: FontWeight.w700,
              letterSpacing: labelUppercase ? 0.4 : 0,
              color: labelUppercase
                  ? AppColors.textSecondary
                  : AppColors.primary,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textDisabled,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (child != null)
            child!
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (unit != null && unit!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    unit!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}