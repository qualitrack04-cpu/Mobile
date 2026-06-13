import 'package:dio/dio.dart';
import 'package:core_services/services/api_service.dart';

class StartupChecker {
  static Future<bool> isServerAvailable() async {
    try {
      final dio = Dio();

      await dio.get(
        '${ApiService.baseUrl}/swagger/index.html',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      return true;
    } catch (_) {
      return false;
    }
  }
}
