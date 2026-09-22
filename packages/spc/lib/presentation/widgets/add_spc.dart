import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import 'spc_card.dart';

/// Kartu ajakan membuat analisis baru.
class NewSpcAnalysisCard extends StatelessWidget {
  const NewSpcAnalysisCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New SPC Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload your data and set the parameters to start the analysis.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.action,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: AppColors.surface, size: 26),
          ),
        ],
      ),
    );
  }
}
