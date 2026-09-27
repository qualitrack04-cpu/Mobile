import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://173.249.63.40:5144'; 
  static final RegExp _indonesianErrorTerms = RegExp(
    r'\b(gagal|tidak|belum|sudah|silakan|mohon|pastikan|ditemukan|terdaftar|tersedia|wajib|harus|salah|kadaluarsa|kedaluwarsa|berhasil|terjadi|dapat|mengirim|mengambil|menyimpan|mengunggah|mengupload|masukkan|periksa|coba lagi|ditolak|dibatalkan|dihapus|digunakan)\b',
    caseSensitive: false,
  );

  static String englishErrorMessage(
    Object? message, {
    required String fallback,
  }) {
    if (message is DioException) {
      if (message.type == DioExceptionType.connectionTimeout ||
          message.type == DioExceptionType.receiveTimeout ||
          message.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Check your internet connection and try again.';
      }
      if (message.type == DioExceptionType.connectionError) {
        return 'Could not connect to the server. Check your internet connection.';
      }
      return fallback;
    }

    var text = message?.toString().trim() ?? '';
    while (text.startsWith('Exception:')) {
      text = text.substring('Exception:'.length).trim();
    }
    if (text.isEmpty ||
        text.contains('DioException') ||
        _indonesianErrorTerms.hasMatch(text)) {
      return fallback;
    }
    return text;
  }

  // Untuk server dika :'http://173.249.63.40:5144'
  // Untuk server pens : 'https://be.qualitrack.labs.it.pens.ac.id'

  static String fixImageUrl(String url) {
    if (url.startsWith('http://localhost:5144')) {
      return url.replaceFirst('http://localhost:5144', baseUrl);
    }
    if (url.startsWith('/uploads')) {
      return '$baseUrl$url';
    }
    return url;
  }

  late final Dio _dio;

  void Function()? onUnauthorized;

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
            // Jangan trigger auto-logout jika 401 berasal dari percobaan login
            if (!error.requestOptions.path.contains('/api/Auth/login')) {
              // Server sudah nyala, trigger auto-logout
              onUnauthorized?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;
}