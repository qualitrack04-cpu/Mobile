import 'package:dio/dio.dart';
import 'package:core_services/services/api_service.dart';
import 'package:finding/data/models/finding_model.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        var fullUrl = urlStr.startsWith('http')
            ? urlStr
            : '${ApiService.baseUrl}$urlStr';
        
        if (fullUrl.startsWith('http://backendqualitrack')) {
          fullUrl = fullUrl.replaceFirst('http://', 'https://');
        }
        
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
    final findings = data
        .map((json) => FindingModel.fromJson(json as Map<String, dynamic>))
        .toList();

    try {
      final capaResponse = await apiService.client.get('/api/Capa');
      final capaData = capaResponse.data as List<dynamic>;
      final now = DateTime.now();

      // Map findingId -> Capa
      final capaMap = <String, Map<String, dynamic>>{};
      for (final capa in capaData) {
        final fId = capa['findingId'] as String?;
        if (fId != null) {
          capaMap[fId] = capa as Map<String, dynamic>;
        }
      }

      final toRemove = <String>{};

      for (final finding in findings) {
        DateTime? closedTime;

        // 1. Cek CAPA terkait
        final capa = capaMap[finding.id];
        if (capa != null) {
          final statusRaw = capa['status'];
          const statusIntMap = {0: 'Open', 1: 'In Progress', 2: 'Pending Verification', 3: 'Closed'};
          const statusStrMap = {
            'Open': 'Open',
            'InProgress': 'In Progress',
            'PendingVerification': 'Pending Verification',
            'Closed': 'Closed',
          };
          final statusStr = statusRaw is int
              ? (statusIntMap[statusRaw] ?? 'Open')
              : statusStrMap[statusRaw as String? ?? ''] ?? 'Open';

          if (statusStr == 'Closed') {
            // Cek closeOut.verifiedAt
            final closeOut = capa['closeOut'] as Map<String, dynamic>?;
            final verifiedAtStr = closeOut?['verifiedAt'] as String?;
            if (verifiedAtStr != null && verifiedAtStr.isNotEmpty) {
              closedTime = DateTime.tryParse(verifiedAtStr);
            } else {
              // Jika CAPA ditutup secara paksa tanpa verifikasi (tidak ada record waktu di database),
              // langsung hilangkan saja dari daftar.
              toRemove.add(finding.id);
              continue;
            }
          }
        }

        // 2. Jika tidak ada CAPA tapi status finding sendiri adalah Closed (Jika diperlukan, fallback langsung hilangkan)
        if (closedTime == null && finding.status == FindingStatus.closed) {
           toRemove.add(finding.id);
           continue;
        }

        // 3. Jika terdeteksi closedTime dan sudah lewat 24 jam, tandai untuk dihapus
        if (closedTime != null) {
          final diff = now.difference(closedTime);
          // UBAH DISINI: Ganti inSeconds >= 10 kembali menjadi inHours >= 24 setelah selesai testing
          if (diff.inSeconds >= 10) {
            toRemove.add(finding.id);
          }
        }
      }

      findings.removeWhere((f) => toRemove.contains(f.id));
    } catch (e) {
      print('Error filtering findings with 24h delay: $e');
    }

    return findings;
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
    required String reporter,
    String? reporterId,
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
        'reporterName': reporter,
        if (reporterId != null && reporterId.isNotEmpty && reporterId != 'null') 'reporterId': reporterId,
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
    required String reporter,
    String? reporterId,
  }) async {
    final response = await apiService.client.put(
      '/api/Finding/$id',
      data: {
        'title': description,
        'department': department,
        'category': category.toBackendString(),
        'description': description,
        'clauseRef': clauseRef,
        'reporterName': reporter,
        if (reporterId != null && reporterId.isNotEmpty && reporterId != 'null') 'reporterId': reporterId,
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