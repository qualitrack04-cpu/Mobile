import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sapaan di bagian atas dashboard.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.userName});

  /// Nama pengguna yang sedang login. Kosong jika belum termuat.
  final String userName;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final greeting = userName.trim().isEmpty ? 'Hello! 👋' : 'Hello, $userName! 👋';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            greeting,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back to your dashboard',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}