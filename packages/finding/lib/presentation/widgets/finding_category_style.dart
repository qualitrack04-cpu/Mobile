import 'package:flutter/material.dart';

/// Warna dan urutan kategori. Kategori baru dari admin otomatis
/// mendapat warna cadangan yang stabil.
abstract final class FindingCategoryStyle {
  static String _key(String n) =>
      n.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();

  /// Makin kecil makin parah, dipakai untuk mengurutkan list.
  static int rank(String name) {
    switch (_key(name)) {
      case 'majornc':
        return 0;
      case 'minornc':
        return 1;
      default:
        return 2;
    }
  }

  static const _palette = [
    Color(0xFF7C3AED),
    Color(0xFF0D9488),
    Color(0xFFDB2777),
    Color(0xFF65A30D),
  ];

  static Color color(String name) {
    switch (_key(name)) {
      case 'majornc':
        return Colors.red;
      case 'minornc':
        return Colors.orange;
      case 'ofi':
      case 'observation':
        return const Color(0xFF3B6FD4);
      default:
        final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
        return _palette[sum % _palette.length];
    }
  }

  static Color badgeBackground(String name) =>
      color(name).withValues(alpha: 0.15);

  static Color cardBackground(String name) =>
      _key(name) == 'majornc' ? const Color(0xFFFFF0F0) : Colors.white;
}