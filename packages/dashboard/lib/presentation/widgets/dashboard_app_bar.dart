import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppBar halaman dashboard: logo QualiTrack dan avatar profil.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.photoPath,
    required this.onProfileTap,
  });

  /// Path foto profil dari backend. Kosong jika belum ada foto.
  final String photoPath;
  final VoidCallback onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icon/Q.png',
            height: (screenWidth * 0.08).clamp(32.0, 42.0),
            fit: BoxFit.contain,
          ),
          // Teks digeser sedikit agar sejajar dengan huruf Q pada logo.
          Transform.translate(
            offset: const Offset(-3, 3),
            child: Text(
              'ualiTrack',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: (screenWidth * 0.06).clamp(24.0, 30.0),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 2.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: photoPath.isNotEmpty
                      ? NetworkImage(ApiService.fixImageUrl(photoPath))
                      : null,
                  child: photoPath.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: AppColors.surface,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}