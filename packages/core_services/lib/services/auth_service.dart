import 'package:core_services/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'maintenance_exception.dart';

class AuthService {
  final ApiService apiService;

  AuthService({required this.apiService});

  // POST /api/Auth/login
  Future<void> login({required String email, required String password}) async {
    try {
      final response = await apiService.client.post(
        '/api/Auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_token', data['token'] as String);

      await prefs.setString('user_role', data['role'] as String);

      await prefs.setString('user_name', data['fullName'] as String);

      await prefs.setString('user_id', data['userId'].toString());
    } on DioException catch (e) {
      // Maintenance dari ApiService
      if (e.error is MaintenanceException) {
        rethrow;
      }

      throw Exception('Email atau password salah');
    } catch (e) {
      throw Exception('Email atau password salah');
    }
  }

  // POST /api/Auth/register
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await apiService.client.post(
        '/api/Auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );
    } catch (e) {
      throw Exception('Registrasi gagal, email mungkin sudah terdaftar');
    }
  }

  // POST /api/Auth/verify-email
  Future<void> verifyEmail({required String email, required String otp}) async {
    try {
      await apiService.client.post(
        '/api/Auth/verify-email',
        data: {'email': email, 'otp': otp},
      );
    } catch (e) {
      throw Exception('OTP salah atau sudah kadaluarsa');
    }
  }

  // POST /api/Auth/resend-otp
  Future<void> resendOtp({required String email}) async {
    try {
      await apiService.client.post(
        '/api/Auth/resend-otp',
        data: {'email': email},
      );
    } catch (e) {
      throw Exception('Gagal kirim ulang OTP');
    }
  }

  // POST /api/Auth/forgot-password/request-otp
  Future<void> requestForgotPasswordOtp({required String email}) async {
    try {
      await apiService.client.post(
        '/api/Auth/forgot-password/request-otp',
        data: {'email': email},
      );
    } catch (e) {
      throw Exception('Email tidak ditemukan');
    }
  }

  // POST /api/Auth/forgot-password/verify-otp
  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await apiService.client.post(
        '/api/Auth/forgot-password/verify-otp',
        data: {'email': email, 'otp': otp},
      );
    } catch (e) {
      throw Exception('OTP salah atau sudah kadaluarsa');
    }
  }

  // POST /api/Auth/forgot-password/reset
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await apiService.client.post(
        '/api/Auth/forgot-password/reset',
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      );
    } catch (e) {
      throw Exception('Gagal reset password');
    }
  }

  // // POST /api/Auth/forgot-password (alur tanpa OTP - dinonaktifkan)
  // Future<void> forgotPassword({
  //   required String email,
  //   required String newPassword,
  //   required String confirmPassword,
  // }) async {
  //   try {
  //     await apiService.client.post(
  //       '/api/Auth/forgot-password',
  //       data: {
  //         'email': email,
  //         'newPassword': newPassword,
  //         'confirmPassword': confirmPassword,
  //       },
  //     );
  //   } catch (e) {
  //     throw Exception('Gagal reset password, pastikan email terdaftar');
  //   }
  // }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_photo');
  }

  // Ambil data user yang sedang login
  Future<Map<String, String>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? '',
      'role': prefs.getString('user_role') ?? '',
      'id': prefs.getString('user_id') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'photo': prefs.getString('user_photo') ?? '',
    };
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
  }

  Future<void> updateProfilePhoto(String photoPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo', photoPath);
  }
}