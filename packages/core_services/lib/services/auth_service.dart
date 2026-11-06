import 'dart:convert';

import 'package:core_services/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:core_services/user_role.dart';

class AdminMobileLoginException implements Exception {
  const AdminMobileLoginException();

  @override
  String toString() => 'The email or password is incorrect.';
}

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
        '/api/auth/login',
        data: {'email': email, 'password': password, 'role': role},
      );
      final data = response.data as Map<String, dynamic>;
      final serverRole = UserRole.fromApi(data['role'] as String?);
      if (!serverRole.canLoginOnMobile) {
        throw const AdminMobileLoginException();
      }
      final prefs = await SharedPreferences.getInstance();
      final token = data['token'] as String;
      final responseUserId = data['userId']?.toString();
      final userId =
          responseUserId != null &&
                  responseUserId.isNotEmpty &&
                  responseUserId != 'null'
              ? responseUserId
              : _userIdFromToken(token);

      await prefs.setString('auth_token', token);
      await prefs.setString('user_role', data['role'] as String);
      await prefs.setString('user_name', data['fullName'] as String);
      if (userId != null) {
        await prefs.setString('user_id', userId);
      }
      await prefs.setString('user_email', email);

      // Ambil data profil (termasuk URL foto)
      try {
        await fetchProfile();
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }

  String? _userIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;

      for (final entry in payload.entries) {
        final key = entry.key.toLowerCase();
        if (key == 'sub' ||
            key == 'nameid' ||
            key.endsWith('/nameidentifier')) {
          final value = entry.value?.toString();
          if (value != null && value.isNotEmpty) return value;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // POST /api/auth/register
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await apiService.client.post(
        '/api/auth/register',
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
          throw Exception(
            ApiService.englishErrorMessage(
              data['message'],
              fallback:
                  'Registration failed. Check your information or contact an administrator.',
            ),
          );
        }
        if (data is Map && data['title'] != null) {
          throw Exception(
            ApiService.englishErrorMessage(
              data['title'],
              fallback: 'Registration failed. Please check your information.',
            ),
          ); // ASP.NET Core error format
        }
        if (data is String) {
          throw Exception(
            ApiService.englishErrorMessage(
              data,
              fallback: 'Registration failed. Please try again.',
            ),
          );
        }
      }
      throw Exception(
        'Registration failed. Check your information or contact an administrator.',
      );
    } catch (e) {
      throw Exception('An error occurred during registration.');
    }
  }

  /// Backend membatasi percobaan OTP (HTTP 429). `remainingTime` dalam detik.
  String? _rateLimitMessage(Object e) {
    if (e is! DioException || e.response?.statusCode != 429) return null;
    final data = e.response?.data;
    int? seconds;
    if (data is Map) seconds = (data['remainingTime'] as num?)?.toInt();
    seconds ??= int.tryParse(e.response?.headers.value('retry-after') ?? '');
    if (seconds != null && seconds > 0) {
      final minutes = (seconds / 60).ceil();
      return 'Too many OTP attempts. Please try again in $minutes '
          '${minutes == 1 ? 'minute' : 'minutes'}.';
    }
    return 'Too many OTP attempts. Please try again later.';
  }

  // POST /api/auth/verify-email
  Future<void> verifyEmail({required String email, required String otp}) async {
    try {
      await apiService.client.post(
        '/api/auth/verify-email',
        data: {'email': email, 'otp': otp},
      );
    } catch (e) {
      throw Exception(
        _rateLimitMessage(e) ?? 'The OTP is incorrect or has expired.',
      );
    }
  }

  // POST /api/auth/resend-otp
  Future<void> resendOtp({required String email}) async {
    try {
      await apiService.client.post(
        '/api/auth/resend-otp',
        data: {'email': email},
      );
    } catch (e) {
      throw Exception('Failed to resend the OTP.');
    }
  }

  // POST /api/auth/forgot-password/request-otp
  Future<void> requestForgotPasswordOtp({required String email}) async {
    try {
      await apiService.client.post(
        '/api/auth/forgot-password/request-otp',
        data: {'email': email},
      );
    } catch (e) {
      throw Exception('Email address not found.');
    }
  }

  // POST /api/auth/forgot-password/verify-otp
  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await apiService.client.post(
        '/api/auth/forgot-password/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final data = response.data as Map<String, dynamic>;
      return data['resetToken'] as String;
    } catch (e) {
      throw Exception(
        _rateLimitMessage(e) ?? 'The OTP is incorrect or has expired.',
      );
    }
  }

  // POST /api/auth/forgot-password/reset
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiService.client.post(
        '/api/auth/forgot-password/reset',
        data: {
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    } catch (e) {
      throw Exception('Failed to reset the password.');
    }
  }

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

  Future<UserRole> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    return UserRole.fromApi(prefs.getString('user_role'));
  }

  Future<void> updateProfile({required String name}) async {
    try {
      await apiService.client.put('/api/profile', data: {'fullName': name});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
    } catch (e) {
      throw Exception('Failed to save your profile to the server.');
    }
  }

  Future<void> requestEmailChangeOtp({required String newEmail}) async {
    try {
      await apiService.client.post(
        '/api/auth/request-email-change-otp',
        data: {'newEmail': newEmail},
      );
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        throw Exception(
          ApiService.englishErrorMessage(
            data is Map ? data['message'] : data,
            fallback: 'Failed to send an OTP to the new email address.',
          ),
        );
      }
      throw Exception('Failed to send an OTP to the new email address.');
    }
  }

  Future<void> verifyEmailChange({required String otp}) async {
    try {
      final response = await apiService.client.post(
        '/api/auth/verify-email-change',
        data: {'otp': otp},
      );
      final data = response.data as Map<String, dynamic>;
      final newEmail = data['newEmail'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', newEmail);
    } catch (e) {
      final limited = _rateLimitMessage(e);
      if (limited != null) throw Exception(limited);
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        throw Exception(
          ApiService.englishErrorMessage(
            data is Map ? data['message'] : data,
            fallback: 'The OTP is invalid.',
          ),
        );
      }
      throw Exception('The OTP is invalid.');
    }
  }

  // Pesan backend (Indonesia) -> pesan UI (Inggris).
  static const Map<String, String> _changePasswordMessages = {
    'Password baru wajib diisi': 'Please enter a new password.',
    'Konfirmasi password wajib diisi': 'Please confirm your new password.',
    'Password baru dan konfirmasi password tidak sama':
        'The new password and confirmation do not match.',
    'Password minimal 8 karakter':
        'The password must be at least 8 characters long.',
    'Password harus mengandung huruf besar dan huruf kecil':
        'The password must contain both uppercase and lowercase letters.',
    'Password harus mengandung angka': 'The password must contain a number.',
    'Password harus mengandung karakter spesial':
        'The password must contain a special character.',
    'Password baru tidak boleh sama dengan password lama':
        'The new password must be different from your current password.',
    'User tidak ditemukan': 'User not found.',
  };

  /// Baca `errors` dulu (key PascalCase, mis. ConfirmPassword), lalu `message`.
  String _changePasswordError(Object e) {
    const fallback = 'Failed to change the password on the server.';
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        String? raw;
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          raw = first is List && first.isNotEmpty
              ? first.first?.toString()
              : first?.toString();
        }
        raw ??= data['message']?.toString();
        if (raw != null && raw.trim().isNotEmpty) {
          return _changePasswordMessages[raw.trim()] ?? fallback;
        }
      }
      return ApiService.englishErrorMessage(e, fallback: fallback);
    }
    return fallback;
  }

  Future<void> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiService.client.post(
        '/api/auth/change-password',
        data: {
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    } catch (e) {
      throw Exception(_changePasswordError(e));
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await apiService.client.get('/api/profile');
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
        '/api/profile/photo',
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      final url = data['url'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_photo', url);
    } catch (e) {
      throw Exception('Failed to upload the profile photo.');
    }
  }
}