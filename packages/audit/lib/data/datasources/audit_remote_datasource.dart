import 'package:core/services/api_service.dart';
import 'package:audit/data/models/audit_model.dart';
import 'package:audit/domain/entities/audit_entity.dart';

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
      throw Exception('Gagal mengambil data audit: $e');
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

      final response = await apiService.client.post('/api/AuditPlan', data: body);
      return AuditModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal membuat audit: $e');
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

      final response =
          await apiService.client.put('/api/AuditPlan/$id', data: body);
      return AuditModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal mengupdate audit: $e');
    }
  }

  // DELETE /api/AuditPlan/{id}
  Future<void> deleteAudit(String id) async {
    try {
      await apiService.client.delete('/api/AuditPlan/$id');
    } catch (e) {
      throw Exception('Gagal menghapus audit: $e');
    }
  }
}