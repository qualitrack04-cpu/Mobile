import 'package:core_services/services/api_service.dart';
import 'package:capa/data/models/capa_model.dart';
import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'dart:convert';

String _parseError(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      if (data.containsKey('errors')) {
        // ASP.NET validation errors
        final errors = data['errors'] as Map<String, dynamic>;
        return ApiService.englishErrorMessage(
          errors.values.map((e) => e.toString()).join('\n'),
          fallback: fallback,
        );
      }
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) {
        return ApiService.englishErrorMessage(msg, fallback: fallback);
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'The request timed out. Check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to the server.';
    }
  }
  return fallback;
}

class CapaRemoteDatasource {
  final ApiService apiService;

  CapaRemoteDatasource({required this.apiService});

  /// GET /api/system-config/capa-statuses. Gagal diam-diam: status lama dipakai.
  Future<void> syncStatuses() async {
    try {
      final res = await apiService.client.get(
        '/api/system-config/capa-statuses',
      );
      final body = res.data;
      final raw =
          body is List
              ? body
              : (body is Map ? (body['data'] as List? ?? []) : <dynamic>[]);

      final list = <CapaStatusInfo>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final id = e['id']?.toString() ?? '';
        final name = e['name']?.toString().trim() ?? '';
        if (id.isEmpty || name.isEmpty) continue;
        final hex = e['hexaCode']?.toString().trim();
        list.add(
          CapaStatusInfo(
            id: id,
            name: name,
            colorHex: (hex == null || hex.isEmpty) ? null : hex,
            orderIndex: (e['orderIndex'] as num?)?.toInt() ?? 0,
            isTerminal: e['isTerminal'] == true,
            isActive: e['isActive'] != false,
          ),
        );
      }
      CapaStatusStyle.register(list);
    } catch (_) {}
  }

  // GET /api/capas
  Future<List<CapaModel>> getCapas() async {
    try {
      // Status dimuat dulu (paralel) supaya registry siap sebelum CapaModel di-parse.
      final (response, _) =
          await (apiService.client.get('/api/capas'), syncStatuses()).wait;
      final data = response.data as List<dynamic>;
      return data
          .map((json) => CapaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(_parseError(e, 'Failed to load CAPA items.'));
    }
  }

  // GET /api/capas/{id}
  Future<CapaModel> getCapaDetail(String id) async {
    try {
      final (response, _) =
          await (apiService.client.get('/api/capas/$id'), syncStatuses()).wait;
      return CapaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Failed to load CAPA details.'));
    }
  }

  // PATCH /api/capas/{id}/status
  Future<void> updateCapaStatus({
    required String id,
    required String status,
  }) async {
    try {
      await apiService.client.patch(
        '/api/capas/$id/status',
        data: jsonEncode(_statusPayload(status)),
        options: Options(contentType: Headers.jsonContentType),
      );
    } catch (e) {
      throw Exception(_parseError(e, 'Failed to update the CAPA status.'));
    }
  }

  /// Status sekarang baris database dengan id, bukan enum 0..3.
  /// Id dikirim kalau ada; kalau registry belum termuat, jatuh ke angka lama.
  dynamic _statusPayload(String status) {
    final id = CapaStatusStyle.find(status)?.id;
    if (id != null && id.isNotEmpty) return id;

    const legacy = {
      'open': 0,
      'inprogress': 1,
      'pendingverification': 2,
      'done': 3,
      'closed': 3,
    };
    return legacy[status.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase()] ?? 0;
  }

  // POST /api/capas/finding/{findingId}
  Future<CapaModel> createCapa({
    required String findingId,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
    required String status,
  }) async {
    try {
      final body = {
        'rootCause': rootCause,
        'correctiveAction': correctiveAction,
        'preventiveAction': preventiveAction,
        'picId': picId, // ✅ picId di Flutter isinya nama, kirim ke picName
        'deadline':
            '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      };
      final response = await apiService.client.post(
        '/api/capas/finding/$findingId',
        data: body,
      );
      return CapaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Failed to create the CAPA.'));
    }
  }

  // PUT /api/capas/{id}
  Future<CapaModel> updateCapa({
    required String id,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
    required String status,
  }) async {
    try {
      final body = {
        'rootCause': rootCause,
        'correctiveAction': correctiveAction,
        'preventiveAction': preventiveAction,
        'picId': picId,
        'deadline':
            '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      };
      final response = await apiService.client.put(
        '/api/capas/$id',
        data: body,
      );
      return CapaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Failed to update the CAPA.'));
    }
  }

  // POST /api/capas/{id}/closeout
  Future<void> closeoutCapa({
    required String id,
    required bool isEffective,
    required String verificationNotes,
    required String verifiedById,
  }) async {
    try {
      final body = {
        'isEffective': isEffective,
        'verificationNotes': verificationNotes,
        if (verifiedById.isNotEmpty && verifiedById.toLowerCase() != 'null')
          'verifiedById': verifiedById,
      };
      await apiService.client.post('/api/capas/$id/closeout', data: body);
    } catch (e) {
      throw Exception(_parseError(e, 'Failed to close out the CAPA.'));
    }
  }
}
