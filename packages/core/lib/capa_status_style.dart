import 'package:flutter/material.dart';

import 'department_style.dart';

/// Satu status CAPA dari GET /api/system-config/capa-statuses.
class CapaStatusInfo {
  const CapaStatusInfo({
    required this.id,
    required this.name,
    this.colorHex,
    this.orderIndex = 0,
    this.isTerminal = false,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Field `hexaCode`, mis. "#006AFF".
  final String? colorHex;
  final int orderIndex;

  /// Status akhir (CAPA dianggap selesai).
  final bool isTerminal;
  final bool isActive;
}

abstract final class CapaStatusStyle {
  static String _key(String n) =>
      n.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();

  /// Cadangan saat backend belum/gagal dimuat.
  static const List<CapaStatusInfo> _defaults = [
    CapaStatusInfo(id: '', name: 'Open', colorHex: '#F44336', orderIndex: 0),
    CapaStatusInfo(
        id: '', name: 'In Progress', colorHex: '#FF9800', orderIndex: 1),
    CapaStatusInfo(
        id: '', name: 'Pending Verification', colorHex: '#9E9E9E', orderIndex: 2),
    CapaStatusInfo(
        id: '',
        name: 'Closed',
        colorHex: '#4CAF50',
        orderIndex: 3,
        isTerminal: true),
  ];

  static List<CapaStatusInfo> _registered = _defaults;
  static Map<String, CapaStatusInfo> _byKey = {
    for (final s in _defaults) _key(s.name): s,
  };

  /// Diganti total setiap dipanggil. Status nonaktif tetap didaftarkan supaya
  /// CAPA lama yang memakainya tetap punya warna.
  static void register(Iterable<CapaStatusInfo> statuses) {
    final list = statuses.where((s) => s.name.trim().isNotEmpty).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (list.isEmpty) return;
    _registered = List.unmodifiable(list);
    _byKey = {for (final s in list) _key(s.name): s};
  }

  /// Nama status aktif, urut sesuai `orderIndex` backend. Untuk dropdown.
  static List<String> get names =>
      _registered.where((s) => s.isActive).map((s) => s.name).toList();

  static CapaStatusInfo? find(String name) => _byKey[_key(name)];

  /// "InProgress" -> "In Progress".
  static String label(String raw) => raw.trim().replaceAllMapped(
        RegExp(r'(?<=[a-z])(?=[A-Z])'),
        (_) => ' ',
      );

  /// Nama persis seperti di backend kalau dikenal, selain itu dirapikan.
  static String canonical(String raw) => find(raw)?.name ?? label(raw);

  static bool isTerminal(String name) {
    final info = find(name);
    if (info != null) return info.isTerminal;
    return _key(name) == 'closed';
  }

  static Color color(String name) =>
      DepartmentStyle.parseHex(find(name)?.colorHex) ?? const Color(0xFF9E9E9E);

  static Color background(String name) =>
      Color.alphaBlend(color(name).withValues(alpha: 0.15), Colors.white);
}