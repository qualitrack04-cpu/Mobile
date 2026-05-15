import 'package:dio/dio.dart';
import 'package:core_services/services/api_service.dart';
import 'package:finding/data/models/finding_model.dart';
import 'package:finding/domain/entities/finding_severity.dart';

class FindingRemoteDatasource {
  final ApiService apiService;

  FindingRemoteDatasource({required this.apiService});

  /// Ambil daftar evidence (id + url) untuk finding tertentu
  /// GET /api/Upload/finding/{findingId}
  Future<List<Map<String, String>>> getEvidences(String findingId) async {
    try {
      final response =
          await apiService.client.get('/api/Upload/finding/$findingId');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) {
        final urlStr = e['url'] as String;
        // Ambil id evidence — sesuaikan key-nya jika berbeda dari backend
        final id = e['id'] as String? ?? e['fileId'] as String? ?? '';
        final fullUrl = urlStr.startsWith('http')
            ? urlStr
            : '${ApiService.baseUrl}$urlStr';
        return {'id': id, 'url': fullUrl};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Upload foto evidence untuk finding
  Future<void> uploadEvidence(String findingId, String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await apiService.client.post(
      '/api/Upload/finding/$findingId',
      data: formData,
    );
  }

  /// Hapus satu evidence — DELETE /api/Upload/{fileId}
  Future<void> deleteEvidence(String fileId) async {
    await apiService.client.delete('/api/Upload/$fileId');
  }

  Future<List<FindingModel>> getFindings({
    FindingStatus? status,
    FindingCategory? category,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status.toBackendString();
    if (category != null) params['category'] = category.toBackendString();

    final response = await apiService.client.get(
      '/api/Finding',
      queryParameters: params.isNotEmpty ? params : null,
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => FindingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FindingModel> getFindingDetail(String id) async {
    final response = await apiService.client.get('/api/Finding/$id');
    return FindingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FindingModel> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
    String? auditorName,
    String? sessionId,
    String? checklistItemId,
  }) async {
    final response = await apiService.client.post(
      '/api/Finding',
      data: {
        'title': description,
        'department': department,
        'sessionId': sessionId,
        'checklistItemId': checklistItemId,
        'category': category.toBackendString(),
        'description': description,
        'clauseRef': clauseRef,
        'auditorName': auditorName ?? '',
      },
    );
    return FindingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FindingModel> updateFinding({
    required String id,
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
  }) async {
    final response = await apiService.client.put(
      '/api/Finding/$id',
      data: {
        'title': description,
        'department': department,
        'category': category.toBackendString(),
        'description': description,
        'clauseRef': clauseRef,
      },
    );
    return FindingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  }) async {
    await apiService.client.patch(
      '/api/Finding/$id/status',
      data: status.toBackendString(),
    );
  }

  Future<void> deleteFinding(String id) async {
    await apiService.client.delete('/api/Finding/$id');
  }
}