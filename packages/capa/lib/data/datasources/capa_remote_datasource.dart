import 'package:core_services/services/api_service.dart';
import 'package:capa/data/models/capa_model.dart';
import 'package:dio/dio.dart';

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
      return 'Koneksi timeout. Pastikan internet aktif.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
  }
  return fallback;
}

class CapaRemoteDatasource {
  final ApiService apiService;

  CapaRemoteDatasource({required this.apiService});

  // GET /api/Capa
  Future<List<CapaModel>> getCapas() async {
    try {
      final response = await apiService.client.get('/api/Capa');
      final data = response.data as List<dynamic>;
      return data
          .map((json) => CapaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal mengambil data CAPA.'));
    }
  }

  // GET /api/Capa/{id}
  Future<CapaModel> getCapaDetail(String id) async {
    try {
      final response = await apiService.client.get('/api/Capa/$id');
      return CapaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal mengambil detail CAPA.'));
    }
  }

  // POST /api/Capa/finding/{findingId}
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
        'picId': picId,  // ✅ picId di Flutter isinya nama, kirim ke picName
        'deadline': '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      };
      final response = await apiService.client.post(
        '/api/Capa/finding/$findingId',
        data: body,
      );
      return CapaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal membuat CAPA.'));
    }
  }

  // PUT /api/Capa/{id}
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
        'deadline': '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      };
      final response = await apiService.client.put('/api/Capa/$id', data: body);
      return CapaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal update CAPA.'));
    }
  }

  // PATCH /api/Capa/{id}/status
  Future<void> updateCapaStatus({
    required String id,
    required String status,
  }) async {
    try {
      // Backend menerima CAPAStatus enum: 0=Open, 1=InProgress, 2=Closed
      final statusMap = {
        'Open': 0,
        'InProgress': 1,
        'In Progress': 1,
        'Pending Verification': 2,
        'PendingVerification': 2,
        'Done': 3,
        'Closed': 3,
      };
      final statusInt = statusMap[status] ?? 0;
      await apiService.client.patch('/api/Capa/$id/status', data: statusInt);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal update status CAPA.'));
    }
  }

  // POST /api/Capa/{id}/closeout
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
        'verifiedById': verifiedById,
      };
      await apiService.client.post('/api/Capa/$id/closeout', data: body);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal closeout CAPA.'));
    }
  }
}