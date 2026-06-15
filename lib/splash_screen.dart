import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_services/core_services.dart';
import 'package:core_services/global_navigator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auth/presentation/pages/login_page.dart';
import 'package:dashboard/presentation/pages/dashboard_screen.dart';
import 'package:core/presentation/pages/maintenance_page.dart';
import 'injector.dart' as di;
import 'startup_checker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  void _initAndNavigate() async {
    // Jalankan init dan timer minimum secara bersamaan
    // Splash screen tampil selama proses ini berjalan
    final results = await Future.wait([
      _doInit(),                                          // Semua proses loading
      Future.delayed(const Duration(milliseconds: 2000)), // Minimal splash 2 detik
    ]);

    final initData = results[0] as Map<String, bool>;
    final isServerAvailable = initData['isServerAvailable'] ?? false;
    final isLoggedIn = initData['isLoggedIn'] ?? false;

    if (mounted) {
      if (!isServerAvailable) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MaintenancePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                isLoggedIn ? const DashboardScreen() : const LoginPage(),
          ),
        );
      }
    }
  }

  Future<Map<String, bool>> _doInit() async {
    // Semua proses yang dulu ada di main.dart, sekarang di sini
    await di.init();                              // Initialize injector

    // Setup unauthenticated (401) handler
    final apiService = di.sl<ApiService>();
    apiService.onUnauthorized = () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_name');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_photo');

      globalNavigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    };

    await NotificationService().init();           // Initialize notification service
    await Permission.notification.request();      // Request notification permissions

    final isServerAvailable = await StartupChecker.isServerAvailable();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    // TODO: KEMBALIKAN KODE DI BAWAH INI JIKA SERVER SUDAH NYALA
    final isLoggedIn = token != null && token.isNotEmpty;     // Return status login
    
    return {
      'isServerAvailable': isServerAvailable,
      'isLoggedIn': isLoggedIn,
    };
    // return true; // Bypass sementara agar bisa nyoba UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF103E6C), // Navy blue atas
              Color(0xFF1F79D2), // Sky blue bawah
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/icon/splash.png',
            width: 250,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
