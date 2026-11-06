import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Checklist kekuatan password (4 kriteria sesuai [PasswordPolicy]).
/// Tidak tampil selama [password] masih kosong.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('At least ${PasswordPolicy.minLength} characters',
              PasswordPolicy.hasMinLength(password)),
          _row('Uppercase and lowercase letters',
              PasswordPolicy.hasUpperLower(password)),
          _row('At least one number', PasswordPolicy.hasNumber(password)),
          _row('At least one special character',
              PasswordPolicy.hasSpecial(password)),
        ],
      ),
    );
  }

  Widget _row(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: ok ? AppColors.success : AppColors.textDisabled,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ok ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}