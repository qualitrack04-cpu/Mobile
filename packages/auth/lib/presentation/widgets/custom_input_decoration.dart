import 'package:flutter/material.dart';
import 'package:core/core.dart';

InputDecoration customInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Colors.black38,
      fontSize: 14,
    ),

    prefixIcon: Icon(
      icon,
      color: Colors.grey,
      size: 20,
    ),

    suffixIcon: suffix,

    filled: true,
    fillColor: const Color(0xFFF8FAFC),

    contentPadding: const EdgeInsets.symmetric(vertical: 12),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),

    // ✅ Tambahan baru: border saat field aktif
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
  );
}