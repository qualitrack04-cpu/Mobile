import 'app_colors.dart';
import 'package:flutter/material.dart';

/// Nama dan warna departemen untuk tampilan.
abstract final class DepartmentStyle {
  static const List<String> _defaults = [
    'Production',
    'Packaging',
    'Warehouse',
    'Quality Control',
  ];

  static List<String> _registered = _defaults;

  /// Departemen yang dikenal aplikasi, urutannya mengikuti backend.
  static List<String> get standard => _registered;

  /// Dipanggil setelah daftar dari backend dimuat. Nama dinormalisasi
  /// supaya "Produksi" dan "Production" tidak dihitung dua kali.
  static void register(Iterable<String> rawNames) {
    final names = <String>[];
    for (final raw in rawNames) {
      final name = normalize(raw);
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
    }
    if (names.isNotEmpty) _registered = List.unmodifiable(names);
  }

  /// Menyeragamkan alias lama dari backend. Nama yang tidak dikenal
  /// (department baru dari admin) dikembalikan apa adanya.
  static String normalize(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'produksi':
      case 'production':
        return 'Production';
      case 'qc':
      case 'quality control':
      case 'quality manager':
        return 'Quality Control';
      case 'packaging':
        return 'Packaging';
      case 'warehouse':
        return 'Warehouse';
      default:
        return raw.trim();
    }
  }

  static const List<Color> _extraPalette = [
    Color(0xFFF59E0B),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF65A30D),
    Color(0xFF0EA5E9),
    Color(0xFFEA580C),
    Color(0xFF64748B),
  ];

  static Color colorOf(String raw) {
    final name = normalize(raw);
    switch (name) {
      case 'Production':
        return AppColors.deptProduction;
      case 'Packaging':
        return AppColors.deptPackaging;
      case 'Warehouse':
        return AppColors.deptWarehouse;
      case 'Quality Control':
        return AppColors.deptQualityControl;
      default:
        if (name.isEmpty) return AppColors.primary;
        final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
        return _extraPalette[sum % _extraPalette.length];
    }
  }
}