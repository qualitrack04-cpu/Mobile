import 'package:core_services/services/api_service.dart';
import 'package:flutter/foundation.dart';

/// Daftar department dan standard (ISO) dari backend.
/// Department: GET /api/departments (hanya yang isActive).
/// Nilai yang dikembalikan adalah nama mentah backend.
class DepartmentService {
  DepartmentService({required this.apiService});

  final ApiService apiService;

  /// Dipakai kalau API gagal dan belum pernah ada cache.
  static const List<String> fallback = [
    'Produksi',
    'Packaging',
    'Warehouse',
    'QC',
  ];
  static const List<String> fallbackStandards = ['ISO9001', 'ISO14001', 'GMP'];

  List<String>? _departmentCache;
  List<String>? _standardCache;

  List<dynamic> _asList(dynamic body) =>
      body is List
          ? body
          : (body is Map ? (body['data'] as List? ?? []) : <dynamic>[]);

  List<String> _names(List<dynamic> list, [String key = 'name']) {
    final result = <String>[];
    for (final e in list) {
      final v = e is Map ? e[key]?.toString() : e?.toString();
      final name = v?.trim() ?? '';
      if (name.isNotEmpty && !result.contains(name)) result.add(name);
    }
    return result;
  }

  Future<List<dynamic>> _fetchChecklists() async {
    final res = await apiService.client.get('/api/checklists');
    return _asList(res.data);
  }

  Future<List<String>> getDepartments({bool forceRefresh = false}) async {
    if (!forceRefresh && _departmentCache != null) return _departmentCache!;

    // 1. Endpoint department (array langsung, ada isActive)
    try {
      final res = await apiService.client.get('/api/departments');
      final active =
          _asList(res.data).where((e) {
            return e is! Map || e['isActive'] != false;
          }).toList();
      final names = _names(active);
      if (names.isNotEmpty) return _departmentCache = names;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getDepartments: $e');
    }

    // 2. Cadangan: turunan dari checklist
    try {
      final names = _names(await _fetchChecklists(), 'department');
      if (names.isNotEmpty) return _departmentCache = names;
    } catch (_) {}

    return _departmentCache ?? fallback;
  }

    List<String> _isoNames(List<dynamic> list) {
    final result = <String>[];
    for (final e in list) {
      String? v;
      if (e is Map) {
        v = (e['name'] ??
                e['code'] ??
                e['standard'] ??
                e['standardName'] ??
                e['title'])
            ?.toString();
      } else {
        v = e?.toString();
      }
      final name = v?.trim() ?? '';
      if (name.isNotEmpty && !result.contains(name)) result.add(name);
    }
    return result;
  }

  /// Daftar ISO dari admin. Sengaja tanpa cadangan hardcode: kalau gagal,
  /// hasilnya kosong supaya form menampilkan error, bukan data usang.
  Future<List<String>> getStandards({bool forceRefresh = false}) async {
    if (!forceRefresh && _standardCache != null) return _standardCache!;

    try {
      final res = await apiService.client.get('/api/admin/iso-standards');
      if (kDebugMode) {
        debugPrint('iso-standards ${res.statusCode}: ${res.data}');
      }
      final active = _asList(res.data).where((e) {
        return e is! Map || e['isActive'] != false;
      }).toList();
      final names = _isoNames(active);
      if (names.isNotEmpty) return _standardCache = names;
    } catch (e) {
      // Cek status code di sini (403 = tidak punya akses, 404 = path salah).
      if (kDebugMode) debugPrint('Error getStandards: $e');
    }

    return _standardCache ?? [];
  }
}
