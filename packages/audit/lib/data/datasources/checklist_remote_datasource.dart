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
        queryParameters: {'standard': isoTemplate, 'department': department},
      );

      final checklists = listResponse.data as List<dynamic>;
      if (checklists.isEmpty) return [];

      // Step 2: Ambil items dari checklist pertama yang cocok
      final checklistId = checklists[0]['id'] as String;
      final itemsResponse = await apiService.client.get(
        '/api/Checklist/$checklistId/items',
      );

      final items = itemsResponse.data['items'] as List<dynamic>;

      // ✅ Map ChecklistItem backend ke ChecklistEntity mobile
      return items.map((item) {
        final json = item as Map<String, dynamic>;
        return ChecklistModel(
          id: json['id'] as String,
          title: json['question'] as String? ?? '', // Question → title
          description:
              json['description'] as String? ?? '', // Description → description
          category: department,
          isPassed: null,
          hasFinding: false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil checklist: $e');
    }
  }

  // POST /api/AuditSession/{sessionId}/summary
  Future<void> submitAuditSummary({
    required String sessionId,
    required String content,
  }) async {
    try {
      await apiService.client.post(
        '/api/AuditSession/$sessionId/summary',
        data: {'content': content},
      );
    } catch (e) {
      // Abaikan jika summary sudah pernah disubmit
    }
  }

  // GET /api/AuditSession/{sessionId}/summary
  Future<String?> getAuditSummary(String sessionId) async {
    try {
      final response = await apiService.client.get('/api/AuditSession/$sessionId/summary');
      return response.data['data']['content'] as String?;
    } catch (e) {
      return null;
    }
  }

  // GET /api/AuditResponse/by-session/{sessionId}
  Future<List<Map<String, dynamic>>> getChecklistResponses(String sessionId) async {
    try {
      final response = await apiService.client.get('/api/AuditResponse/by-session/$sessionId');
      final dataList = response.data['data'] as List<dynamic>;
      return dataList.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Gagal mengambil respons checklist: $e');
    }
  }

  // GET /api/Upload/audit-response/{responseId}
  Future<List<String>> getEvidencesForResponse(String responseId) async {
    try {
      final response = await apiService.client.get('/api/Upload/audit-response/$responseId');
      final dataList = response.data as List<dynamic>;
      return dataList.map((e) => e['url'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getEvidencesForFinding(String findingId) async {
    try {
      final response = await apiService.client.get(
        '/api/Upload/finding/$findingId',
      );
      final data = response.data as List<dynamic>;
      return data.map((e) => e['url'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // GET /api/Finding/by-session/{sessionId}
  Future<List<Map<String, dynamic>>> getFindingsBySession(String sessionId) async {
    try {
      final response = await apiService.client.get('/api/Finding/by-session/$sessionId');
      final dataList = response.data['data'] as List<dynamic>;
      return dataList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
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
        data: {'scheduleId': scheduleId, 'checklistId': checklistId},
      );
      final data = response.data['data'] as Map<String, dynamic>;

      // Ambil id (bisa huruf kecil 'id', camelCase 'sessionId', atau PascalCase 'Id'/'SessionId')
      final dynamic rawId =
          data['sessionId'] ?? data['SessionId'] ?? data['id'] ?? data['Id'];

      if (rawId == null) {
        throw Exception(
          "Backend tidak mengembalikan ID Sesi. Data dari server: $data",
        );
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
      final responses = checklists
          .map(
            (c) => {
              'checklistItemId': c.id,
              'isPassed': c.isPassed ?? false,
              'notes': null,
            },
          )
          .toList();

      await apiService.client.post(
        '/api/AuditResponse/batch',
        data: {'sessionId': sessionId, 'responses': responses},
      );

      // (Dihapus: Step 2: Tandai sesi selesai) -> Pindah ke saat Create PDF
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message']?.toString() ?? data['title']?.toString() ?? data.toString();
          // Jika backend menolak karena session sudah selesai, abaikan error ini (lanjutkan ke Preview)
          if (msg.toLowerCase().contains('sudah selesai')) {
            return;
          }
          throw Exception(msg);
        }
        throw Exception(data.toString());
      }
      throw Exception('Gagal menyimpan hasil checklist: $e');
    }
  }


  // Fungsi baru khusus untuk menandai audit selesai (setelah PDF digenerate)
  Future<void> markSessionComplete(String sessionId) async {
    try {
      await apiService.client.patch('/api/AuditSession/$sessionId/complete');
    } catch (e) {
      throw Exception('Gagal menandai sesi selesai: $e');
    }
  }


  // GET /api/AuditResponse/by-session/{sessionId}
  // Ambil jawaban yang sudah tersimpan untuk sesi ini
  Future<Map<String, Map<String, dynamic>>> getExistingResponses(String sessionId) async {
    try {
      final response = await apiService.client.get(
        '/api/AuditResponse/by-session/$sessionId',
      );
      final data = response.data['data'] as List<dynamic>;

      // Kembalikan Map<checklistItemId, isPassed>
      return {
        for (final r in data)
          (r['checklistItemId'] as String): { 'isPassed': r['isPassed'] as bool? ?? false, 'responseId': r['id'] as String?},
      };
    } catch (e) {
      return {}; // Kalau gagal, anggap belum ada progress
    }
  }

  // GET /api/Finding/by-session/{sessionId}
  // Ambil findings yang terkait dengan sesi ini
  Future<Map<String, Map<String, dynamic>>> getExistingFindings(
    String sessionId,
  ) async {
    try {
      final response = await apiService.client.get(
        '/api/Finding/by-session/$sessionId',
      );
      final data = response.data['data'] as List<dynamic>;

      // Kembalikan Map<checklistItemId, findingJson>
      final result = <String, Map<String, dynamic>>{};
      for (final f in data) {
        final itemId = f['checklistItemId'] as String?;
        if (itemId != null) {
          result[itemId] = f as Map<String, dynamic>;
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  // POST /api/AuditResponse/progress
  // Auto-save setiap kali user tap Pass/Fail (bukan final submit)
  // POST /api/AuditResponse/progress — satu item per call
  Future<void> saveProgress({
    required String sessionId,
    required String checklistItemId,
    required bool isPassed,
  }) async {
    try {
      await apiService.client.post(
        '/api/AuditResponse/progress',
        data: {
          'sessionId': sessionId,
          'checklistItemId': checklistItemId,
          'isPassed': isPassed,
          'notes': null,
        },
      );
    } catch (_) {
      // Silent fail — jangan crash
    }
  }
  Future<String?> uploadAuditEvidence(String responseId, String filePath) async {
    try {
      // CEGAH PENUMPUKAN: Hapus evidence lama di backend sebelum upload yang baru
      await deleteAuditEvidence(responseId);

      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await apiService.client.post(
        '/api/Upload/audit-response/$responseId',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url'] as String?; // Kembalikan URL gambar
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAuditEvidence(String responseId) async {
    try {
      final response = await apiService.client.get(
        '/api/Upload/audit-response/$responseId',
      );
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        return data.first['url'] as String?; // Ambil URL gambar pertama
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAuditEvidence(String responseId) async {
    try {
      // 1. Ambil daftar semua evidence yang tersangkut di responseId ini
      final response = await apiService.client.get(
        '/api/Upload/audit-response/$responseId',
      );
      final data = response.data as List<dynamic>;
      
      // 2. Hapus semuanya satu per satu dari database backend
      for (var item in data) {
        final fileId = item['id'];
        if (fileId != null) {
          await apiService.client.delete('/api/Upload/$fileId');
        }
      }
    } catch (e) {
      // Silent fail
    }
  }
}
