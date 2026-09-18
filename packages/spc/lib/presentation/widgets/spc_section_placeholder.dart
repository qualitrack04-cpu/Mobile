import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spc_card.dart';

/// Kartu pengganti saat sebuah daftar sedang dimuat, gagal, atau kosong.
///
/// Dipakai bersama oleh daftar Recent Analyses dan halaman Analyses History
/// supaya ketiga kondisi itu tampil seragam.
class SpcSectionPlaceholder extends StatelessWidget {
  const SpcSectionPlaceholder.loading({super.key})
      : isLoading = true,
        message = null,
        icon = null,
        onRetry = null;

  const SpcSectionPlaceholder.message({
    super.key,
    required this.message,
    this.icon,
    this.onRetry,
  }) : isLoading = false;

  final bool isLoading;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 26, color: AppColors.textDisabled),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: Text(
                        'Coba lagi',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.action,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
