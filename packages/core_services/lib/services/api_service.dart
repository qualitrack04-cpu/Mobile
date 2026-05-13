import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://backendqualitrack-production.up.railway.app'; // emulator Android
  // Untuk device fisik: ganti dengan IP lokal, misal 'http://192.168.1.x:5000'
  // Untuk production: ganti dengan URL server

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor: otomatis sisipkan JWT token di setiap request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // Token expired atau unauthorized
        if (error.response?.statusCode == 401) {
          // TODO: redirect ke halaman login
        }
        return handler.next(error);
      },
    ));
  }

  Dio get client => _dio;
}