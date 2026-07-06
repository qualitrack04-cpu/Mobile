import 'package:core_services/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthService {
  final ApiService apiService;

  AuthService({required this.apiService});

  // POST /api/Auth/login
  Future<void> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await apiService.client.post(
        '/api/Auth/login',
        data: {'email': email, 'password': password, 'role': role},
      );
      final data = response.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token'] as String);
      await prefs.setString('user_role', data['role'] as String);
      await prefs.setString('user_name', data['fullName'] as String);
      await prefs.setString('user_id', data['userId'].toString());
      await prefs.setString('user_email', email);
      
      // Ambil data profil (termasuk URL foto)
      try {
        await fetchProfile();
      } catch (_) {}
    } catch (e) {
      rethrow;
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
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          throw Exception(data['message']);
        }
        if (data is Map && data['title'] != null) {
          throw Exception(data['title']); // Untuk format ASP.NET Core
        }
        if (data is String) {
          throw Exception(data);
        }
      }
      throw Exception('Registrasi gagal. Cek kembali data Anda atau hubungi admin.');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat registrasi.');
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
// POST /api/Auth/forgot-password/verify-otp
  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await apiService.client.post(
        '/api/Auth/forgot-password/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final data = response.data as Map<String, dynamic>;
      return data['resetToken'] as String;
    } catch (e) {
      throw Exception('OTP salah atau sudah kadaluarsa');
    }
  }

  // POST /api/Auth/forgot-password/reset
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiService.client.post(
        '/api/Auth/forgot-password/reset',
        data: {
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
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
  }) async {
    try {
      await apiService.client.put(
        '/api/Auth/update-profile',
        data: {
          'fullName': name,
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
    } catch (e) {
      throw Exception('Gagal menyimpan profil ke server');
    }
  }

  Future<void> requestEmailChangeOtp({required String newEmail}) async {
    try {
      await apiService.client.post(
        '/api/Auth/request-email-change-otp',
        data: {'newEmail': newEmail},
      );
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        throw Exception(data is Map ? data['message'] : 'Gagal mengirim OTP ke email baru');
      }
      throw Exception('Gagal mengirim OTP ke email baru');
    }
  }

  Future<void> verifyEmailChange({required String otp}) async {
    try {
      final response = await apiService.client.post(
        '/api/Auth/verify-email-change',
        data: {'otp': otp},
      );
      final data = response.data as Map<String, dynamic>;
      final newEmail = data['newEmail'] as String;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', newEmail);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        throw Exception(data is Map ? data['message'] : 'Kode OTP tidak valid');
      }
      throw Exception('Kode OTP tidak valid');
    }
  }

  Future<void> changePassword({required String newPassword}) async {
    try {
      await apiService.client.post(
        '/api/Auth/change-password',
        data: {
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      throw Exception('Gagal mengganti password di server');
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await apiService.client.get('/api/Auth/profile');
      final data = response.data as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', data['fullName'] ?? '');
      await prefs.setString('user_email', data['email'] ?? '');
      await prefs.setString('user_role', data['role'] ?? '');
      
      final photoUrl = data['profilePhotoUrl'] as String? ?? '';
      debugPrint('[fetchProfile] profilePhotoUrl = $photoUrl');
      await prefs.setString('user_photo', photoUrl);
    } catch (e) {
      debugPrint('[fetchProfile] ERROR: $e');
    }
  }

  Future<void> updateProfilePhoto(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(photoPath),
      });

      final response = await apiService.client.post(
        '/api/Auth/upload-profile-photo',
        data: formData,
      );
      
      final data = response.data as Map<String, dynamic>;
      final url = data['url'] as String;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_photo', url);
    } catch (e) {
      throw Exception('Gagal mengupload foto profil');
    }
  }
}