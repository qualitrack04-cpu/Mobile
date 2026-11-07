import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:finding/domain/entities/finding_severity.dart';

abstract final class FindingCategoryStyle {
  static String _key(String n) =>
      n.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();

  /// Warna dari backend, kuncinya nama kategori yang sudah dinormalisasi.
  static Map<String, Color> _backendColors = const {};

  /// Dipanggil setiap kali daftar kategori dimuat. Diganti total, jadi warna
  /// yang dihapus di backend kembali ke warna cadangan.
  static void register(Iterable<FindingCategory> categories) {
    final parsed = <String, Color>{};
    for (final c in categories) {
      final color = DepartmentStyle.parseHex(c.colorHex);
      if (color != null) parsed[_key(c.name)] = color;
    }
    if (parsed.isNotEmpty) _backendColors = parsed;
  }

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
    // Warna dari backend menang atas warna bawaan.
    final fromBackend = _backendColors[_key(name)];
    if (fromBackend != null) return fromBackend;

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

  /// Latar kartu Major NC ikut warna kategorinya (tipis), bukan merah tetap.
  static Color cardBackground(String name) => _key(name) == 'majornc'
      ? Color.alphaBlend(color(name).withValues(alpha: 0.08), Colors.white)
      : Colors.white;
}