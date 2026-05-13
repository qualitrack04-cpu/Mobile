import 'package:core_services/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService apiService;

  AuthService({required this.apiService});

  // POST /api/Auth/login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiService.client.post(
        '/api/Auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Simpan token & info user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token'] as String);
      await prefs.setString('user_role', data['role'] as String);
      await prefs.setString('user_name', data['fullName'] as String);
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
          'role': 'QualityManager', // untuk sekarang hanya Quality Manager
        },
      );
    } catch (e) {
      throw Exception('Registrasi gagal, email mungkin sudah terdaftar');
    }
  }

  // Logout — hapus semua data tersimpan
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
  }

  // Ambil data user yang sedang login
  Future<Map<String, String>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? '',
      'role': prefs.getString('user_role') ?? '',
    };
  }
}