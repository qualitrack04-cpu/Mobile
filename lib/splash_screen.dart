import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_services/core_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auth/presentation/pages/login_page.dart';
import 'package:dashboard/presentation/pages/dashboard_screen.dart';
import 'injector.dart' as di;

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

    final isLoggedIn = results[0] as bool;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isLoggedIn ? const DashboardScreen() : const LoginPage(),
        ),
      );
    }
  }

  Future<bool> _doInit() async {
    // Semua proses yang dulu ada di main.dart, sekarang di sini
    await di.init();                              // Initialize injector
    await NotificationService().init();           // Initialize notification service
    await Permission.notification.request();      // Request notification permissions

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;     // Return status login
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
