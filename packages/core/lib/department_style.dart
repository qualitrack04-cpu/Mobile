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

  /// Warna dari backend (field `color` di /api/departments), kuncinya
  /// nama yang sudah dinormalisasi.
  static Map<String, Color> _backendColors = const {};

  /// Departemen yang dikenal aplikasi, urutannya mengikuti backend.
  static List<String> get standard => _registered;

  /// Dipanggil setelah daftar dari backend dimuat. Nama dinormalisasi
  /// supaya "Produksi" dan "Production" tidak dihitung dua kali.
  ///
  /// [colors] berisi nama mentah -> hex (mis. "#059669"). Warna yang
  /// tidak valid diabaikan dan departemennya memakai warna cadangan.
  static void register(
    Iterable<String> rawNames, {
    Map<String, String>? colors,
  }) {
    final names = <String>[];
    for (final raw in rawNames) {
      final name = normalize(raw);
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
    }
    if (names.isEmpty) return;

    _registered = List.unmodifiable(names);

    // Diganti total setiap register, jadi warna yang dihapus di backend
    // kembali ke warna cadangan.
    final parsed = <String, Color>{};
    colors?.forEach((raw, hex) {
      final color = parseHex(hex);
      if (color != null) parsed[normalize(raw)] = color;
    });
    _backendColors = parsed;
  }

  /// Menerima "#RRGGBB", "RRGGBB", "#RGB", atau "#AARRGGBB".
  /// Mengembalikan null jika formatnya tidak valid.
  static Color? parseHex(String? hex) {
    if (hex == null) return null;
    var h = hex.trim().replaceFirst('#', '');
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final value = int.tryParse(h, radix: 16);
    return value == null ? null : Color(value);
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

    // Warna dari backend menang atas warna bawaan.
    final fromBackend = _backendColors[name];
    if (fromBackend != null) return fromBackend;

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