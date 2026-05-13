import 'package:core/services/api_service.dart';
import 'package:audit/data/models/checklist_model.dart';
import 'package:audit/domain/entities/checklist_entity.dart';

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
          description: json['clauseRef'] as String? ?? '', // ClauseRef → description
          category: department,
          isPassed: null,
          hasFinding: false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil checklist: $e');
    }
  }
}