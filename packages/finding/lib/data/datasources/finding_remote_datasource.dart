import 'package:core_services/services/api_service.dart';
import 'package:finding/data/models/finding_model.dart';
import 'package:finding/domain/entities/finding_severity.dart';

class FindingRemoteDatasource {
  final ApiService apiService;

  FindingRemoteDatasource({required this.apiService});

  Future<List<FindingModel>> getFindings({
  FindingStatus? status,
  FindingCategory? category,
}) async {
  try {
    print('🔍 Fetching findings from API...'); // ← tambah ini
    
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status.toBackendString();
    if (category != null) queryParams['category'] = category.toBackendString();

    final response = await apiService.client.get(
      '/api/Finding',
      queryParameters: queryParams,
    );

    print('✅ Response: ${response.data}'); // ← tambah ini
    
    final List<dynamic> data = response.data;
    return data.map((json) => FindingModel.fromJson(json)).toList();
  } catch (e) {
    print('❌ Error: $e'); // ← tambah ini
    throw Exception('Gagal mengambil data finding: $e');
  }
}

  Future<FindingModel> getFindingDetail(String id) async {
    try {
      final response = await apiService.client.get('/api/Finding/$id');
      return FindingModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Gagal mengambil detail finding: $e');
    }
  }

  Future<FindingModel> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
  }) async {
    try {
      final response = await apiService.client.post(
        '/api/Finding',
        data: {
          'category': category.toBackendString(),
          'description': description,
          'clauseRef': clauseRef,
          'department': department,
        },
      );
      return FindingModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Gagal membuat finding: $e');
    }
  }

  Future<FindingModel> updateFinding({
    required String id,
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
  }) async {
    try {
      final response = await apiService.client.put(
        '/api/Finding/$id',
        data: {
          'category': category.toBackendString(),
          'description': description,
          'clauseRef': clauseRef,
          'department': department,
        },
      );
      return FindingModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Gagal update finding: $e');
    }
  }

  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  }) async {
    try {
      await apiService.client.patch(
        '/api/Finding/$id/status',
        data: status.toBackendString(),
      );
    } catch (e) {
      throw Exception('Gagal update status finding: $e');
    }
  }

  Future<void> deleteFinding(String id) async {
    try {
      await apiService.client.delete('/api/Finding/$id');
    } catch (e) {
      throw Exception('Gagal menghapus finding: $e');
    }
  }
}