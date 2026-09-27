import 'package:core_services/services/api_service.dart';
import 'package:audit/domain/entities/auditor_entity.dart';
import 'package:dio/dio.dart';

String _parseAuditorError(Object e) {
  const fallback = 'Failed to load auditors. Please try again.';
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) {
        return ApiService.englishErrorMessage(msg, fallback: fallback);
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to the server.';
    }
  }
  return fallback;
}

class AuditorRemoteDatasource {
  final ApiService apiService;

  AuditorRemoteDatasource({required this.apiService});

  // GET /api/Auth/auditors
  Future<List<AuditorEntity>> getAuditors() async {
    try {
      final response = await apiService.client.get('/api/Auth/auditors');
      final data = response.data['data'] as List<dynamic>;
      return data.map((json) {
        final map = json as Map<String, dynamic>;
        return AuditorEntity(
          id: map['id'] as String,
          fullName: map['fullName'] as String,
          role: map['role'] as String,
        );
      }).toList();
    } catch (e) {
      throw Exception(_parseAuditorError(e));
    }
  }
}
