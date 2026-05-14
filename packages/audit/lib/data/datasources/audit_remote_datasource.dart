import 'package:core_services/services/api_service.dart';
import 'package:audit/data/models/audit_model.dart';
import 'package:audit/domain/entities/audit_entity.dart';
import 'package:dio/dio.dart';

/// Ekstrak pesan error yang user-friendly dari DioException atau exception apapun.
String _parseError(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Koneksi timeout. Pastikan internet aktif dan coba lagi.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
  }
  return fallback;
}

class AuditRemoteDatasource {
  final ApiService apiService;

  AuditRemoteDatasource({required this.apiService});

  // GET /api/AuditPlan
  Future<List<AuditEntity>> getAudits() async {
    try {
      final response = await apiService.client.get('/api/AuditPlan');
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((json) => AuditModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal mengambil data audit. Coba lagi.'));
    }
  }

  // POST /api/AuditPlan
  Future<AuditEntity> createAudit({
    required String title,
    required List<String> isoTemplates,
    required int year,
    required String description,
    required bool isPriority,
    required List<Map<String, dynamic>> schedules,
    // schedules: [{ "clauseRef": "...", "auditorId": "guid", "scheduledDate": "2026-05-12", "department": "Warehouse" }]
  }) async {
    try {
      final body = {
        'title': title,
        'standard': isoTemplates.isNotEmpty ? isoTemplates.first : '',
        'year': year,
        'description': description,
        'priority': isPriority ? 'Priority' : 'Common',
        'schedules': schedules,
      };

      final response = await apiService.client.post(
        '/api/AuditPlan',
        data: body,
      );
      return AuditModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal membuat audit. Coba lagi.'));
    }
  }

  // PUT /api/AuditPlan/{id}
  Future<AuditEntity> updateAudit({
    required String id,
    required String title,
    required List<String> isoTemplates,
    required int year,
    required String description,
    required bool isPriority,
    required List<Map<String, dynamic>> schedules,
  }) async {
    try {
      final body = {
        'title': title,
        'standard': isoTemplates.isNotEmpty ? isoTemplates.first : '',
        'year': year,
        'description': description,
        'priority': isPriority ? 'Priority' : 'Common',
        'schedules': schedules,
      };

      final response = await apiService.client.put(
        '/api/AuditPlan/$id',
        data: body,
      );
      return AuditModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal mengupdate audit. Coba lagi.'));
    }
  }

  // DELETE /api/AuditPlan/{id}
  Future<void> deleteAudit(String id) async {
    try {
      await apiService.client.delete('/api/AuditPlan/$id');
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal menghapus audit. Coba lagi.'));
    }
  }
}
