import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:auth/presentation/pages/login_page.dart';
import 'package:dashboard/presentation/pages/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'injector.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // ✅ initialize injector
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final isLoggedIn = token != null && token.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QualiTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
      ),
      home: isLoggedIn ? const DashboardScreen() : const LoginPage(),
    );
  }
}