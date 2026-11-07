import 'package:core_services/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemConfig {
  const SystemConfig({
    required this.utcOffsetHours,
    required this.timeZoneLabel,
    required this.dateFormat,
  });

  /// Selisih terhadap UTC dalam jam, mis. 7 untuk WIB.
  final double utcOffsetHours;

  /// Label singkat, mis. "WIB".
  final String timeZoneLabel;

  /// Pola tanggal, mis. "yyyy-MM-dd".
  final String dateFormat;
}

/// Timezone dan format tanggal dari backend, dengan cache lokal supaya
/// tanggal sudah benar sejak app dibuka, bahkan saat offline.
class SystemConfigService {
  SystemConfigService({required this.apiService});

  final ApiService apiService;

  static const _kOffset = 'system_utc_offset';
  static const _kLabel = 'system_tz_label';
  static const _kFormat = 'system_date_format';

  Future<SystemConfig?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = prefs.getDouble(_kOffset);
    final format = prefs.getString(_kFormat);
    if (offset == null && format == null) return null;

    return SystemConfig(
      utcOffsetHours: offset ?? _deviceOffsetHours,
      timeZoneLabel: prefs.getString(_kLabel) ?? '',
      dateFormat: format ?? 'yyyy-MM-dd',
    );
  }

  /// Mengambil kedua endpoint. Kalau salah satu gagal, nilai dari cache
  /// dipakai untuk bagian itu. Null hanya jika keduanya gagal dan belum
  /// ada cache.
  Future<SystemConfig?> fetch() async {
    final cached = await loadCached();
    final results = await Future.wait([
      _get('/api/system-config/timezone'),
      _get('/api/system-config/date-format'),
    ]);
    final tz = results[0];
    final df = results[1];

    if (tz == null && df == null) return cached;

    final config = SystemConfig(
      utcOffsetHours:
          (tz?['utcOffsets'] as num?)?.toDouble() ??
          cached?.utcOffsetHours ??
          _deviceOffsetHours,
      timeZoneLabel:
          tz?['timeZone']?.toString() ?? cached?.timeZoneLabel ?? '',
      dateFormat:
          df?['dateFormat']?.toString() ?? cached?.dateFormat ?? 'yyyy-MM-dd',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kOffset, config.utcOffsetHours);
    await prefs.setString(_kLabel, config.timeZoneLabel);
    await prefs.setString(_kFormat, config.dateFormat);
    return config;
  }

  double get _deviceOffsetHours =>
      DateTime.now().timeZoneOffset.inMinutes / 60;

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final res = await apiService.client.get(path);
      final body = res.data;
      if (body is! Map) return null;
      final inner = body['data'];
      return Map<String, dynamic>.from(inner is Map ? inner : body);
    } catch (e) {
      if (kDebugMode) debugPrint('Error $path: $e');
      return null;
    }
  }
}