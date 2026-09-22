import 'package:core_services/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:spc/data/models/spc_history_model.dart';
import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/data/models/spc_result_model.dart';

String _parseError(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      if (data.containsKey('errors')) {
        final errors = data['errors'] as Map<String, dynamic>;
        return errors.values.map((e) => e.toString()).join('\n');
      }
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

class SpcRemoteDatasource {
  final ApiService apiService;

  SpcRemoteDatasource({required this.apiService});

  /// GET /api/Spc/history?period=3m&status=...&productName=...
  ///
  /// Response dibungkus objek berisi period, startDate, endDate, total,
  /// dan data. Daftarnya ada di field `data`, bukan di root.
  Future<List<SpcHistoryModel>> getHistory({
    required SpcPeriod period,
    SpcStatus? status,
    String? productName,
  }) async {
    try {
      final response = await apiService.client.get(
        '/api/Spc/history',
        queryParameters: {
          'period': period.apiValue,
          if (status != null) 'status': status.apiValue,
          if (productName != null && productName.isNotEmpty)
            'productName': productName,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];

      return data
          .map((json) => SpcHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal mengambil riwayat analisis SPC.'));
    }
  }
    /// POST /api/Spc/analyze
  ///
  /// Dikirim sebagai multipart/form-data, bukan JSON, karena ada file Excel.
  Future<SpcResultModel> analyze({
    required String filePath,
    required String fileName,
    required String parameterName,
    required double lsl,
    required double usl,
    double? target,
    String? unit,
    String? description,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'lsl': lsl,
        'usl': usl,
        // Nama field mengikuti signature backend, yang masih memakai
        // `productName` meski di database tersimpan sebagai ParameterName.
        'productName': parameterName,
        if (target != null) 'target': target,
        if (unit != null && unit.isNotEmpty) 'unit': unit,
        if (description != null && description.isNotEmpty)
          'description': description,
      });

      final response = await apiService.client.post(
        '/api/Spc/analyze',
        data: formData,
      );

      return SpcResultModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal menganalisis data SPC.'));
    }
  }
    /// GET /api/Spc/{id}
  Future<SpcResultModel> getById(String id) async {
    try {
      final response = await apiService.client.get('/api/Spc/$id');
      return SpcResultModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_parseError(e, 'Gagal mengambil detail analisis.'));
    }
  }
}
