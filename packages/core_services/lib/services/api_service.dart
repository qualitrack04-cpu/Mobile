import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://be.qualitrack.labs.it.pens.ac.id'; 
  // Untuk railway : 'https://backendqualitrack-production.up.railway.app'
  // Untuk server pens : 'https://be.qualitrack.labs.it.pens.ac.id'

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor: otomatis sisipkan JWT token di setiap request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('REQUEST: ${options.method} ${options.baseUrl}${options.path}');
          print('BODY: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE ${response.statusCode}: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          print('ERROR: ${error.type}');
          print('ERROR MESSAGE: ${error.message}');
          print('ERROR RESPONSE: ${error.response?.data}');
          print('STATUS CODE: ${error.response?.statusCode}');
          if (error.response?.statusCode == 401) {
            // TODO: redirect ke halaman login
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;
}