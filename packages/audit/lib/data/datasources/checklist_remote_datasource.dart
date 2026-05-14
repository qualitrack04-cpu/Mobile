import 'package:core_services/services/api_service.dart';
import 'package:audit/data/models/checklist_model.dart';
import 'package:audit/domain/entities/checklist_entity.dart';
import 'package:dio/dio.dart';

class ChecklistRemoteDatasource {
  final ApiService apiService;

  ChecklistRemoteDatasource({required this.apiService});

  // GET /api/Checklist?standard=ISO9001&department=Warehouse
  // Lalu ambil items dari GET /api/Checklist/{id}/items
  Future<List<ChecklistEntity>> getChecklistFor({
    required String isoTemplate,
    required String department,
  }) async {
    try {
      // Step 1: Cari checklist yang cocok
      final listResponse = await apiService.client.get(
        '/api/Checklist',
        queryParameters: {
          'standard': isoTemplate,
          'department': department,
        },
      );

      final checklists = listResponse.data as List<dynamic>;
      if (checklists.isEmpty) return [];

      // Step 2: Ambil items dari checklist pertama yang cocok
      final checklistId = checklists[0]['id'] as String;
      final itemsResponse =
          await apiService.client.get('/api/Checklist/$checklistId/items');

      final items = itemsResponse.data['items'] as List<dynamic>;

      // ✅ Map ChecklistItem backend ke ChecklistEntity mobile
      return items.map((item) {
        final json = item as Map<String, dynamic>;
        return ChecklistModel(
          id: json['id'] as String,
          title: json['question'] as String? ?? '',       // Question → title
          description: json['description'] as String? ?? '', // Description → description
          category: department,
          isPassed: null,
          hasFinding: false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil checklist: $e');
    }
  }

  // POST /api/AuditSession
  // Buat sesi audit baru, kembalikan sessionId (String guid)
  Future<String> createAuditSession({
    required String scheduleId,
    required String checklistId,
  }) async {
    try {
      final response = await apiService.client.post(
        '/api/AuditSession',
        data: {
          'scheduleId': scheduleId,
          'checklistId': checklistId,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      
      // Ambil id (bisa huruf kecil 'id', camelCase 'sessionId', atau PascalCase 'Id'/'SessionId')
      final dynamic rawId = data['sessionId'] ?? data['SessionId'] ?? data['id'] ?? data['Id'];
      
      if (rawId == null) {
        throw Exception("Backend tidak mengembalikan ID Sesi. Data dari server: $data");
      }
      return rawId.toString();
    } catch (e) {
      throw Exception('Gagal membuat sesi audit: $e');
    }
  }

  // POST /api/AuditResponse/batch  →  simpan semua jawaban PASS/FAIL
  // PATCH /api/AuditSession/{id}/complete  →  tandai sesi selesai
  Future<void> submitChecklistResponses({
    required String sessionId,
    required List<ChecklistEntity> checklists,
  }) async {
    try {
      // Step 1: Kirim semua jawaban
      final responses = checklists.map((c) => {
        'checklistItemId': c.id,
        'isPassed': c.isPassed ?? false,
        'notes': null,
      }).toList();

      await apiService.client.post(
        '/api/AuditResponse/batch',
        data: {
          'sessionId': sessionId,
          'responses': responses,
        },
      );

      // Step 2: Tandai sesi selesai
      await apiService.client.patch('/api/AuditSession/$sessionId/complete');
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          // Coba ekstrak pesan dari BadRequest biasa atau dari Validation Problem Details
          final msg = data['message'] ?? data['title'] ?? data.toString();
          throw Exception(msg);
        }
        throw Exception(data.toString());
      }
      throw Exception('Gagal menyimpan hasil checklist: $e');
    }
  }
}